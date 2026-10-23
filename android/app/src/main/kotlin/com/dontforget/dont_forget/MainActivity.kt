package com.dontforget.dont_forget

import android.Manifest
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private var eventSink: EventChannel.EventSink? = null
    private val reminderEngine by lazy { ReminderEngine.get(this) }
    private var ringtoneResult: MethodChannel.Result? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        updateAlarmWindow()
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "dont_forget/events").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) { eventSink = events }
            override fun onCancel(arguments: Any?) { eventSink = null }
        })
        reminderEngine.onChanged = { if (!isDestroyed) { updateAlarmWindow(); eventSink?.success("changed") } }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dont_forget/engine").setMethodCallHandler { call, result ->
            when (call.method) {
                "pickSound" -> {
                    if (ringtoneResult != null) { result.error("sound_picker_busy", null, null); return@setMethodCallHandler }
                    SoundPreview.stop()
                    val current = call.argument<String>("soundUri").orEmpty()
                    val picker = Intent(RingtoneManager.ACTION_RINGTONE_PICKER)
                        .putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALARM)
                        .putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                        .putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                        .putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI,
                            if (current.isBlank()) RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM) else Uri.parse(current))
                        .putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, reminderEngine.text("选择闹钟铃声", "Choose alarm sound"))
                    ringtoneResult = result
                    try { @Suppress("DEPRECATION") startActivityForResult(picker, 306) }
                    catch (error: Exception) { ringtoneResult = null; result.error("sound_picker_unavailable", error.message, null) }
                    return@setMethodCallHandler
                }
                "previewSound", "stopSoundPreview", "soundStatus" -> {
                    try {
                        val value: Any? = when (call.method) {
                            "previewSound" -> { SoundPreview.start(applicationContext, JSONObject((call.arguments as? Map<*, *>) ?: emptyMap<String, Any>())); null }
                            "stopSoundPreview" -> { SoundPreview.stop(); null }
                            else -> JSONObject().put("preview", SoundPreview.status()).put("alarm", AlarmService.soundStatus())
                        }
                        result.success(toDart(value))
                    } catch (error: Exception) {
                        result.error(if (error is RuleException) error.code else "invalid_sound", error.message, null)
                    }
                    return@setMethodCallHandler
                }
            }
            if (call.method == "openPermission") {
                try { openPermission(call.argument<String>("kind") ?: "app"); result.success(null) }
                catch (error: Exception) { result.error("settings_unavailable", error.message, null) }
                return@setMethodCallHandler
            }
            worker.execute {
                try {
                    val data = JSONObject((call.arguments as? Map<*, *>) ?: emptyMap<String, Any>())
                    val value: Any? = when (call.method) {
                        "snapshot" -> reminderEngine.snapshot()
                        "saveReminder" -> reminderEngine.savePlan(data)
                        "setEnabled" -> reminderEngine.setEnabled(data.getString("id"), data.getBoolean("enabled"))
                        "deleteReminder" -> reminderEngine.deletePlan(data.getString("id"))
                        "snooze" -> reminderEngine.snooze(data.getString("id"), data.getInt("minutes"))
                        "challenge" -> reminderEngine.challenge(data.getString("id"))
                        "answerMath" -> reminderEngine.answer(data.getString("id"), data.getString("answer"), data.getString("token"))
                        "scanCode" -> reminderEngine.scan(data.getString("id"), data.getString("value"))
                        "emergencyClose" -> reminderEngine.emergency(data.getString("id"), data.getString("phrase"), data.getString("password"))
                        "saveSettings" -> reminderEngine.saveSettings(data)
                        "setPassword" -> reminderEngine.setPassword(data.optString("currentPassword"), data.getString("password"))
                        "testReminder" -> reminderEngine.createTest(data)
                        else -> throw RuleException("unknown_method")
                    }
                    runOnUiThread { if (!isDestroyed) { updateAlarmWindow(); result.success(toDart(value)) } }
                } catch (error: Exception) {
                    val code = when (error) { is RuleException -> error.code; is IllegalArgumentException -> error.message ?: "invalid_input"; else -> "storage_error" }
                    runOnUiThread { if (!isDestroyed) result.error(code, error.message, null) }
                }
            }
        }
    }
    override fun onResume() {
        super.onResume()
        worker.execute {
            try {
                reminderEngine.repairScheduled()
                if (reminderEngine.ringing().isNotEmpty()) AlarmService.start(this)
                runOnUiThread { updateAlarmWindow(); eventSink?.success("changed") }
            } catch (_: Exception) { }
        }
    }
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent); setIntent(intent); updateAlarmWindow(); eventSink?.success("changed")
    }
    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 306) return
        val result = ringtoneResult ?: return
        ringtoneResult = null
        if (resultCode != RESULT_OK) { result.success(null); return }
        try {
            val uri = if (Build.VERSION.SDK_INT >= 33) data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java)
                else data?.getParcelableExtra<Uri>(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
            val useDefault = uri == null || RingtoneManager.isDefault(uri)
            val title = if (useDefault) "" else RingtoneManager.getRingtone(this, uri)?.getTitle(this).orEmpty()
            result.success(mapOf("soundUri" to if (useDefault) "" else uri.toString(), "soundName" to title))
        } catch (error: Exception) { result.error("sound_picker_unavailable", error.message, null) }
    }
    override fun onPause() {
        SoundPreview.stop()
        super.onPause()
    }
    private fun updateAlarmWindow() {
        // A storage failure must reach Flutter's retry screen, not crash Activity startup.
        val active = try { reminderEngine.ringing().isNotEmpty() } catch (_: Exception) { false }
        if (Build.VERSION.SDK_INT >= 27) { setShowWhenLocked(active); setTurnScreenOn(active) }
        else {
            @Suppress("DEPRECATION") val legacyFlags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (active) window.addFlags(legacyFlags) else window.clearFlags(legacyFlags)
        }
        if (active) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
    private fun openPermission(kind: String) {
        val packageUri = Uri.parse("package:$packageName")
        val intent = when (kind) {
            "exact" -> if (Build.VERSION.SDK_INT >= 31) Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, packageUri) else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri)
            "notifications" -> {
                if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 98); return
                }
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            }
            "fullScreen" -> if (Build.VERSION.SDK_INT >= 34) Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, packageUri) else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri)
            "battery" -> Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            "sound" -> Intent(Settings.ACTION_SOUND_SETTINGS)
            else -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri)
        }
        startActivity(intent)
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults); eventSink?.success("changed")
    }
    override fun onDestroy() {
        SoundPreview.stop()
        ringtoneResult?.success(null); ringtoneResult = null
        reminderEngine.onChanged = null; eventSink = null; worker.shutdown(); super.onDestroy()
    }
    private fun toDart(value: Any?): Any? = when (value) {
        null, JSONObject.NULL, is Unit -> null
        is JSONObject -> value.keys().asSequence().associateWith { toDart(value.get(it)) }
        is JSONArray -> (0 until value.length()).map { toDart(value.get(it)) }
        else -> value
    }
}
