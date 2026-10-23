package com.dontforget.dont_forget

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.util.Log
import org.json.JSONObject

/** Main-thread owned playback used by both previews and the foreground alarm service. */
class AlarmAudioPlayer(
    context: Context,
    private val onFallback: (Int) -> Unit = {},
    private val onFocusLost: (() -> Unit)? = null,
) {
    private val context = context.applicationContext
    private val handler = Handler(Looper.getMainLooper())
    private var player: MediaPlayer? = null
    private var tone: ToneGenerator? = null
    private var focus: AudioFocusRequest? = null
    private var volume = 100
    private var fade = 0
    private var startedAt = 0L
    private var candidates = emptyList<Uri>()
    private var candidateIndex = 0
    private var generation = 0
    private var active = false
    private var ready = false
    private var fallbackLevel = 0
    private var currentUri = ""
    private var gain = 1f

    fun play(plan: JSONObject, elapsedMillis: Long = 0) {
        stop()
        volume = plan.optInt("volumePercent", 100)
        fade = plan.optInt("fadeInSeconds", 0)
        AlarmSoundPolicy.validate(volume, fade)
        startedAt = SystemClock.elapsedRealtime() - elapsedMillis.coerceAtLeast(0)
        active = true
        candidateIndex = 0
        gain = AlarmSoundPolicy.gain(volume, fade, elapsedMillis)
        val selected = plan.optString("soundUri", "")
        candidates = (listOfNotNull(selected.takeIf { it.isNotBlank() }?.let(Uri::parse)) +
            listOfNotNull(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))).distinct()
        val attributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
        focus = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
            .setAudioAttributes(attributes).setOnAudioFocusChangeListener { change ->
                if (change < 0 && active) onFocusLost?.invoke()
            }.build()
        context.getSystemService(AudioManager::class.java).requestAudioFocus(focus!!)
        openCandidate(attributes, generation)
        handler.post(object : Runnable {
            override fun run() {
                if (!active) return
                gain = AlarmSoundPolicy.gain(volume, fade, SystemClock.elapsedRealtime() - startedAt)
                player?.let { try { it.setVolume(gain, gain) } catch (_: IllegalStateException) { } }
                handler.postDelayed(this, 100)
            }
        })
    }

    private fun openCandidate(attributes: AudioAttributes, token: Int) {
        if (!active || generation != token) return
        releasePlayer()
        if (candidateIndex >= candidates.size) {
            fallbackLevel = 2
            currentUri = "builtin:beep"
            ready = true
            onFallback(2)
            Log.i("DontForgetSound", "Using backup beep volume=$volume fade=$fade")
            handler.post(object : Runnable {
                override fun run() {
                    if (!active || generation != token) return
                    try {
                        tone?.release()
                        tone = ToneGenerator(AudioManager.STREAM_ALARM, (gain * 100).toInt().coerceAtLeast(1))
                        ready = tone?.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 800) == true
                    } catch (error: RuntimeException) {
                        ready = false
                        Log.e("DontForgetSound", "Backup audio unavailable; will retry", error)
                    }
                    handler.postDelayed(this, 1300)
                }
            })
            return
        }
        val uri = candidates[candidateIndex++]
        currentUri = uri.toString()
        val media = MediaPlayer()
        player = media
        fun next() {
            if (!active || generation != token || player !== media) return
            fallbackLevel = 1
            onFallback(1)
            Log.w("DontForgetSound", "Ringtone unavailable; trying fallback")
            openCandidate(attributes, token)
        }
        try {
            media.setAudioAttributes(attributes)
            media.setWakeMode(context, PowerManager.PARTIAL_WAKE_LOCK)
            media.isLooping = true
            media.setVolume(gain, gain)
            media.setOnErrorListener { _, _, _ -> next(); true }
            media.setOnPreparedListener {
                if (active && generation == token && player === media) {
                    try {
                        media.setVolume(gain, gain)
                        media.start()
                        ready = true
                        Log.i("DontForgetSound", "Playback started volume=$volume fade=$fade fallback=$fallbackLevel")
                    } catch (_: Exception) { next() }
                }
            }
            media.setDataSource(context, uri)
            media.prepareAsync()
            // A provider/decoder that never calls back must not leave an alarm silently pending.
            handler.postDelayed({
                if (active && generation == token && player === media && !ready) next()
            }, 3000)
        } catch (_: Exception) { next() }
    }

    private fun releasePlayer() {
        ready = false
        player?.let {
            it.setOnPreparedListener(null)
            it.setOnErrorListener(null)
            it.release()
        }
        player = null
    }

    fun stop() {
        generation++
        active = false
        handler.removeCallbacksAndMessages(null)
        releasePlayer()
        tone?.release(); tone = null
        focus?.let { context.getSystemService(AudioManager::class.java).abandonAudioFocusRequest(it) }
        focus = null
        fallbackLevel = 0
        currentUri = ""
    }

    fun status(): JSONObject = JSONObject().put("playing", active).put("ready", ready)
        .put("gain", gain.toDouble()).put("volumePercent", volume).put("fadeInSeconds", fade)
        .put("uri", currentUri).put("fallbackLevel", fallbackLevel)
}

/** A preview never survives backgrounding and can never compete with a real alarm. */
object SoundPreview {
    private val handler = Handler(Looper.getMainLooper())
    // Only an application Context is retained, and the player is cleared when previewing ends.
    @android.annotation.SuppressLint("StaticFieldLeak")
    private var player: AlarmAudioPlayer? = null
    @Volatile var playing = false
        private set
    @Volatile var fallbackLevel = 0
        private set
    private var changed: (() -> Unit)? = null

    fun start(context: Context, plan: JSONObject) {
        stop()
        val engine = ReminderEngine.get(context)
        if (engine.ringing().isNotEmpty()) throw RuleException("alarm_ringing")
        AlarmSoundPolicy.validate(plan.optInt("volumePercent", 100), plan.optInt("fadeInSeconds", 0))
        changed = { engine.soundPreviewChanged() }
        playing = true
        player = AlarmAudioPlayer(context.applicationContext,
            onFallback = { fallbackLevel = it; changed?.invoke() }, onFocusLost = { stop() })
        try {
            player!!.play(plan)
            handler.postDelayed({ stop() }, maxOf(10, plan.optInt("fadeInSeconds", 0) + 5) * 1000L)
            changed?.invoke()
        } catch (error: Exception) { stop(); throw error }
    }

    fun stop() {
        handler.removeCallbacksAndMessages(null)
        player?.stop(); player = null
        val wasPlaying = playing
        playing = false
        fallbackLevel = 0
        if (wasPlaying) changed?.invoke()
        changed = null
    }

    fun status(): JSONObject = player?.status() ?: JSONObject().put("playing", false).put("ready", false)
}
