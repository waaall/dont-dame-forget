package com.dontforget.dont_forget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra("id") ?: return
        val engine = ReminderEngine.get(context)
        if (!engine.fire(id, intent.getLongExtra("at", 0))) return
        try { AlarmService.start(context) }
        catch (error: Exception) { Log.e("DontForget", "Unable to start alarm audio", error); AlarmService.postFallback(context) }
    }
}

class RecoveryReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val result = goAsync()
        Thread({
            try {
                val clockChanged = intent.action == Intent.ACTION_TIME_CHANGED || intent.action == Intent.ACTION_TIMEZONE_CHANGED
                ReminderEngine.get(context).reconcile(clockChanged)
                // BOOT_COMPLETED never starts a media-playback service directly.
                // Re-scheduled exact alarms use the standard alarm receiver instead.
            } catch (error: Exception) { Log.e("DontForget", "Reminder recovery failed", error) }
            finally { result.finish() }
        }, "reminder-recovery").start()
    }
}
