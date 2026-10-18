package com.dontforget.dont_forget

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import org.json.JSONObject

/** Audio belongs to a native foreground service, never a Dart timer or page lifecycle. */
class AlarmService : Service() {
    private var player: MediaPlayer? = null
    private var tone: ToneGenerator? = null
    private var focus: AudioFocusRequest? = null
    private val handler = Handler(Looper.getMainLooper())
    private var currentId: String? = null
    private var audioStarted = false
    private lateinit var engine: ReminderEngine
    override fun onCreate() { super.onCreate(); running = this; engine = ReminderEngine.get(this); createChannel(this) }
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val items = engine.ringing()
        val notification = notification(this, items.firstOrNull(), items.size)
        if (Build.VERSION.SDK_INT >= 29) startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        else startForeground(NOTIFICATION_ID, notification)
        if (items.isEmpty()) {
            stopForeground(STOP_FOREGROUND_REMOVE); stopSelf(); return START_NOT_STICKY
        }
        val item = items.first()
        if (!audioStarted || currentId != item.getString("id")) {
            releaseAudio(); currentId = item.getString("id"); play(item)
        }
        return START_STICKY
    }
    private fun play(item: JSONObject) {
        val attributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
        val manager = getSystemService(AudioManager::class.java)
        focus = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT).setAudioAttributes(attributes)
            .setOnAudioFocusChangeListener { /* An outstanding alarm stays pending until explicitly resolved. */ }.build()
        manager.requestAudioFocus(focus!!)
        try {
            player = MediaPlayer().also { media ->
                media.setAudioAttributes(attributes)
                media.setWakeMode(this, PowerManager.PARTIAL_WAKE_LOCK)
                val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                media.setDataSource(this, uri)
                media.isLooping = true
                media.setOnErrorListener { _, _, _ -> startFallback(item); true }
                media.prepare(); media.start()
            }
        } catch (error: Exception) { Log.w("DontForget", "System alarm tone unavailable", error); startFallback(item) }
        if (item.getJSONObject("plan").optBoolean("vibrate", true)) {
            @Suppress("DEPRECATION") val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            vibrator.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 600, 450, 600, 800), 0))
        }
        audioStarted = true
    }
    private fun startFallback(item: JSONObject) {
        if (tone != null) return
        engine.recordSoundFailure(item)
        tone = ToneGenerator(AudioManager.STREAM_ALARM, 100)
        handler.post(object : Runnable {
            override fun run() { tone?.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 800); if (tone != null) handler.postDelayed(this, 1300) }
        })
    }
    private fun releaseAudio() {
        handler.removeCallbacksAndMessages(null)
        player?.run { try { stop() } catch (_: Exception) { }; release() }; player = null
        tone?.release(); tone = null
        @Suppress("DEPRECATION") val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        vibrator.cancel()
        focus?.let { getSystemService(AudioManager::class.java).abandonAudioFocusRequest(it) }; focus = null
        audioStarted = false
    }
    override fun onDestroy() { running = null; releaseAudio(); super.onDestroy() }
    companion object {
        const val CHANNEL = "mission_alarms_v1"
        const val NOTIFICATION_ID = 4041
        @Volatile private var running: AlarmService? = null
        fun start(context: Context) { context.startForegroundService(Intent(context, AlarmService::class.java)) }
        fun refresh(context: Context) {
            // Reusing the existing service avoids an illegal new background service start.
            if (running != null) context.startService(Intent(context, AlarmService::class.java))
            else if (ReminderEngine.get(context).ringing().isEmpty())
                context.getSystemService(NotificationManager::class.java).cancel(NOTIFICATION_ID)
        }
        fun createChannel(context: Context) {
            val engine = ReminderEngine.get(context)
            val channel = NotificationChannel(CHANNEL, engine.text("任务提醒", "Mission reminders"), NotificationManager.IMPORTANCE_HIGH).apply {
                description = engine.text("正在响铃的提醒，点击后完成任务或长按推迟", "Open a ringing reminder to finish its mission or hold to snooze")
                setSound(null, null); enableVibration(false); lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
        private fun notification(context: Context, item: JSONObject?, count: Int): Notification {
            val engine = ReminderEngine.get(context)
            val id = item?.optString("id") ?: ""
            val launch = Intent(context, MainActivity::class.java).setAction("com.dontforget.OPEN_ALARM")
                .setData(Uri.parse("dontforget://open/$id")).putExtra("occurrenceId", id)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            val pending = PendingIntent.getActivity(context, 4041, launch, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val title = item?.getJSONObject("plan")?.getString("title") ?: engine.text("别忘了", "Don't Forget")
            return Notification.Builder(context, CHANNEL).setSmallIcon(R.drawable.ic_alarm)
                .setContentTitle(if (count > 1) engine.text("$count 项提醒待处理", "$count reminders need you") else title)
                .setContentText(engine.text("完成任务才能解除 · 按住可推迟", "Finish the mission to dismiss · Hold to snooze"))
                .setCategory(Notification.CATEGORY_ALARM).setVisibility(Notification.VISIBILITY_PUBLIC)
                .setOngoing(true).setAutoCancel(false).setOnlyAlertOnce(true)
                .setContentIntent(pending).setFullScreenIntent(pending, true).build()
        }
        fun postFallback(context: Context) {
            createChannel(context)
            val items = ReminderEngine.get(context).ringing()
            if (items.isNotEmpty()) context.getSystemService(NotificationManager::class.java)
                .notify(NOTIFICATION_ID, notification(context, items.first(), items.size))
        }
    }
}
