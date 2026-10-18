package com.dontforget.dont_forget

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.util.Locale
import java.util.UUID

/** All mutations are serialized here, including receiver/service work on other threads. */
class ReminderEngine private constructor(private val context: Context) {
    private val protectedContext = context.createDeviceProtectedStorageContext()
    private val store = ReminderStore(protectedContext)
    private val preferences = protectedContext.getSharedPreferences("settings", Context.MODE_PRIVATE)
    private val vault = PasswordVault(preferences)
    private val alarms = context.getSystemService(AlarmManager::class.java)
    private val notifications = context.getSystemService(NotificationManager::class.java)
    private val mainHandler = Handler(Looper.getMainLooper())
    var onChanged: (() -> Unit)? = null

    fun english(): Boolean = when (preferences.getString("language", "system")) {
        "en" -> true; "zh" -> false; else -> !Locale.getDefault().language.startsWith("zh")
    }
    fun text(zh: String, en: String) = if (english()) en else zh
    private fun changed() { mainHandler.post { onChanged?.invoke() } }
    fun exactAllowed() = Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms()
    fun permissions(): JSONObject {
        val channel = notifications.getNotificationChannel(AlarmService.CHANNEL)
        val notificationAllowed = notifications.areNotificationsEnabled() && (channel == null || channel.importance != NotificationManager.IMPORTANCE_NONE)
        val audio = context.getSystemService(AudioManager::class.java)
        return JSONObject().put("exact", exactAllowed()).put("notifications", notificationAllowed)
            .put("fullScreen", Build.VERSION.SDK_INT < 34 || notifications.canUseFullScreenIntent())
            .put("battery", context.getSystemService(PowerManager::class.java).isIgnoringBatteryOptimizations(context.packageName))
            .put("alarmVolume", audio.getStreamVolume(AudioManager.STREAM_ALARM))
            .put("manufacturer", Build.MANUFACTURER)
    }
    @Synchronized fun snapshot(): JSONObject {
        val live = store.live()
        val plans = store.plans().map { plan ->
            val occurrence = live.firstOrNull { it.getString("planId") == plan.getString("id") }
            plan.put("nextAt", occurrence?.getLong("nextAt") ?: JSONObject.NULL)
                .put("occurrenceStatus", occurrence?.getString("status") ?: JSONObject.NULL)
        }
        val publicOccurrences = live.map { item -> JSONObject(item.toString()).apply { remove("answer"); remove("questionToken") } }
        return JSONObject().put("plans", JSONArray(plans)).put("occurrences", JSONArray(publicOccurrences))
            .put("history", JSONArray(store.history())).put("weeklyStats", store.weeklyStats()).put("permissions", permissions())
            .put("settings", JSONObject().put("language", preferences.getString("language", "system"))
                .put("theme", preferences.getString("theme", "system"))
                .put("defaultSnoozeMinutes", preferences.getInt("default_snooze", 10)).put("hasPassword", vault.configured()))
    }
    @Synchronized fun saveSettings(data: JSONObject) {
        val language = data.optString("language", preferences.getString("language", "system") ?: "system")
        val theme = data.optString("theme", preferences.getString("theme", "system") ?: "system")
        require(language in setOf("system", "zh", "en") && theme in setOf("system", "light", "dark")) { "invalid_settings" }
        val minutes = data.optInt("defaultSnoozeMinutes", preferences.getInt("default_snooze", 10))
        ReminderPolicy.snoozeAt(0, minutes)
        check(preferences.edit().putString("language", language).putString("theme", theme).putInt("default_snooze", minutes).commit())
        changed()
    }
    @Synchronized fun setPassword(current: String, password: String) { vault.set(current, password); changed() }
    private fun ensureReady() {
        if (!vault.configured()) throw RuleException("password_required")
        if (!exactAllowed()) throw RuleException("exact_required")
        if (!permissions().getBoolean("notifications")) throw RuleException("notifications_required")
    }
    private fun nextAt(plan: JSONObject, now: Long): Long = ReminderPolicy.nextAt(
        plan.getString("date"), plan.getInt("hour"), plan.getInt("minute"), plan.getBoolean("repeating"),
        plan.getJSONArray("days").let { days -> (0 until days.length()).map { days.getInt(it) }.toSet() }, now)

    @Synchronized fun savePlan(input: JSONObject, testAt: Long? = null): String {
        ensureReady()
        val id = input.optString("id").ifEmpty { UUID.randomUUID().toString() }
        val previous = store.forPlan(id)
        if (previous.any { it.getString("status") in ReminderPolicy.protectedStates }) throw RuleException("active_locked")
        val title = input.optString("title").trim()
        require(title.isNotEmpty() && title.length <= 100) { "invalid_title" }
        require(input.optString("mission") in setOf("math", "qr")) { "invalid_mission" }
        require(input.optString("category") in setOf("alarm", "todo", "habit", "other")) { "invalid_category" }
        require(input.optString("difficulty") in setOf("easy", "medium", "hard")) { "invalid_difficulty" }
        require(input.optInt("mathCount") in 1..10) { "invalid_count" }
        if (input.getString("mission") == "qr" && input.optString("qrValue").isBlank()) throw RuleException("qr_required")
        ReminderPolicy.snoozeAt(0, input.getInt("snoozeMinutes"))
        ReminderPolicy.snoozeAt(0, input.getInt("reviewMinutes"))
        val plan = JSONObject(input.toString()).put("id", id).put("title", title).put("enabled", true)
        plan.remove("nextAt"); plan.remove("occurrenceStatus")
        val time = testAt ?: nextAt(plan, System.currentTimeMillis())
        if (time <= System.currentTimeMillis()) throw RuleException("past_time")
        val occurrence = makeOccurrence(plan, time)
        store.transaction {
            previous.forEach { store.putOccurrence(it.put("status", "cancelled")) }
            store.putPlan(plan); store.putOccurrence(occurrence)
        }
        previous.forEach { cancel(it.getString("id")) }
        schedule(occurrence); changed(); return id
    }
    private fun makeOccurrence(plan: JSONObject, time: Long) = JSONObject().put("id", UUID.randomUUID().toString())
        .put("planId", plan.getString("id")).put("plan", JSONObject(plan.toString()))
        .put("status", "scheduled").put("nextAt", time).put("originalAt", time).put("isReview", false)
        .put("mathDone", 0).put("snoozeCount", 0)

    @Synchronized fun setEnabled(id: String, enabled: Boolean) {
        val plan = store.plan(id) ?: throw RuleException("not_found")
        val live = store.forPlan(id)
        if (live.any { it.getString("status") in ReminderPolicy.protectedStates }) throw RuleException("active_locked")
        if (enabled) {
            ensureReady()
            val next = nextAt(plan, System.currentTimeMillis())
            if (next <= System.currentTimeMillis()) throw RuleException("past_time")
            val occurrence = makeOccurrence(plan, next)
            store.transaction {
                live.forEach { store.putOccurrence(it.put("status", "cancelled")) }
                store.putPlan(plan.put("enabled", true)); store.putOccurrence(occurrence)
            }
            live.forEach { cancel(it.getString("id")) }; schedule(occurrence)
        } else {
            store.transaction {
                store.putPlan(plan.put("enabled", false))
                live.forEach { store.putOccurrence(it.put("status", "cancelled")) }
            }
            live.forEach { cancel(it.getString("id")) }
        }
        changed()
    }
    @Synchronized fun deletePlan(id: String) {
        val live = store.forPlan(id)
        if (live.any { it.getString("status") in ReminderPolicy.protectedStates }) throw RuleException("active_locked")
        store.deletePlan(id); live.forEach { cancel(it.getString("id")) }; changed()
    }
    private fun openOccurrence(id: String, allowPendingReview: Boolean = false): JSONObject {
        val item = store.occurrence(id) ?: throw RuleException("not_found")
        if (item.getString("status") !in ReminderPolicy.protectedStates) throw RuleException("not_active")
        if (!allowPendingReview && item.getString("status") == "reviewPending") throw RuleException("not_active")
        return item
    }
    @Synchronized fun snooze(id: String, minutes: Int) {
        ensureReady()
        val item = openOccurrence(id)
        val time = ReminderPolicy.snoozeAt(System.currentTimeMillis(), minutes)
        item.put("status", "snoozed").put("nextAt", time).put("mathDone", 0)
            .put("snoozeCount", item.optInt("snoozeCount") + 1)
        item.remove("question"); item.remove("answer"); item.remove("questionToken")
        store.transaction { store.putOccurrence(item); store.event("snoozed", item, minutes) }
        schedule(item); refreshService(); changed()
    }
    @Synchronized fun challenge(id: String): JSONObject {
        val item = openOccurrence(id)
        if (item.getJSONObject("plan").getString("mission") != "math") throw RuleException("wrong_mission")
        if (!item.has("question")) newQuestion(item)
        return publicChallenge(item)
    }
    private fun newQuestion(item: JSONObject) {
        val question = ReminderPolicy.question(item.getJSONObject("plan").getString("difficulty"))
        item.put("question", question.expression).put("answer", question.answer).put("questionToken", UUID.randomUUID().toString())
        store.putOccurrence(item)
    }
    private fun publicChallenge(item: JSONObject) = JSONObject().put("expression", item.getString("question"))
        .put("token", item.getString("questionToken")).put("done", item.optInt("mathDone"))
        .put("total", item.getJSONObject("plan").getInt("mathCount"))
    @Synchronized fun answer(id: String, answer: String, token: String): JSONObject {
        val item = openOccurrence(id)
        if (item.getJSONObject("plan").getString("mission") != "math") throw RuleException("wrong_mission")
        if (token != item.optString("questionToken")) throw RuleException("stale_question")
        if (answer.toIntOrNull() != item.getInt("answer")) return JSONObject().put("correct", false).put("completed", false)
        item.put("mathDone", item.optInt("mathDone") + 1)
        if (item.getInt("mathDone") >= item.getJSONObject("plan").getInt("mathCount")) {
            finish(item, false); return JSONObject().put("correct", true).put("completed", true)
        }
        newQuestion(item)
        return JSONObject().put("correct", true).put("completed", false).put("challenge", publicChallenge(item))
    }
    @Synchronized fun scan(id: String, value: String) {
        val item = openOccurrence(id)
        val plan = item.getJSONObject("plan")
        if (plan.getString("mission") != "qr") throw RuleException("wrong_mission")
        if (value != plan.getString("qrValue")) throw RuleException("wrong_qr")
        finish(item, false)
    }
    @Synchronized fun emergency(id: String, phrase: String, password: String) {
        val item = openOccurrence(id, true)
        if (phrase != ReminderPolicy.OATH) throw RuleException("wrong_oath")
        if (!vault.matches(password)) throw RuleException("wrong_password")
        finish(item, true)
    }
    private fun finish(item: JSONObject, skipped: Boolean) {
        val planSnapshot = item.getJSONObject("plan")
        if (ReminderPolicy.completion(planSnapshot.getBoolean("reviewEnabled"), item.getBoolean("isReview"), skipped) == ReminderPolicy.Completion.REVIEW) {
            item.put("status", "reviewPending").put("isReview", true).put("mathDone", 0)
                .put("nextAt", ReminderPolicy.snoozeAt(System.currentTimeMillis(), planSnapshot.getInt("reviewMinutes")))
            item.remove("question"); item.remove("answer"); item.remove("questionToken")
            store.transaction { store.putOccurrence(item); store.event("reviewScheduled", item, planSnapshot.getInt("reviewMinutes")) }
            schedule(item)
        } else {
            var next: JSONObject? = null
            store.transaction {
                item.put("status", if (skipped) "skipped" else "completed")
                store.putOccurrence(item); store.event(if (skipped) "skipped" else "completed", item)
                val plan = store.plan(item.getString("planId")) ?: throw RuleException("not_found")
                if (plan.getBoolean("repeating") && plan.getBoolean("enabled")) {
                    next = makeOccurrence(plan, nextAt(plan, System.currentTimeMillis()))
                    store.putOccurrence(next!!)
                } else store.putPlan(plan.put("enabled", false))
            }
            cancel(item.getString("id")); next?.let { schedule(it) }
        }
        refreshService(); changed()
    }

    @Synchronized fun fire(id: String, expectedAt: Long): Boolean {
        val item = store.occurrence(id) ?: return false
        if (item.getString("status") !in ReminderPolicy.liveStates || item.getLong("nextAt") != expectedAt) return false
        // Stale PendingIntents must never resurrect an already snoozed occurrence.
        if (expectedAt > System.currentTimeMillis() + 1500) return false
        val alreadyRinging = item.getString("status") == "ringing"
        item.put("status", "ringing")
        store.transaction { store.putOccurrence(item); if (!alreadyRinging) store.event("ringing", item) }
        changed(); return true
    }
    @Synchronized fun ringing(): List<JSONObject> = store.live().filter { it.getString("status") == "ringing" }
    @Synchronized fun reconcile(clockChanged: Boolean = false) {
        val live = store.live()
        live.forEach { item ->
            if (clockChanged && item.getString("status") == "scheduled") {
                val next = nextAt(item.getJSONObject("plan"), System.currentTimeMillis())
                item.put("nextAt", next).put("originalAt", next); store.putOccurrence(item)
            }
            // After a reboot, also restart a previously ringing item via a real exact alarm.
            if (item.getString("status") == "ringing") {
                val time = System.currentTimeMillis() + 2000
                item.put("nextAt", time); store.putOccurrence(item)
            }
            try { schedule(item) } catch (_: SecurityException) { /* visible in permission diagnostics */ }
        }
        changed()
    }
    @Synchronized fun repairScheduled() {
        // Called when returning to the foreground; never postpone a currently sounding alarm.
        store.live().filter { it.getString("status") != "ringing" }.forEach { item ->
            try { schedule(item) } catch (_: SecurityException) { }
        }
    }
    private fun pending(id: String, at: Long = 0): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).setAction("com.dontforget.FIRE")
            .setData(Uri.parse("dontforget://occurrence/$id")).putExtra("id", id).putExtra("at", at)
        return PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
    private fun schedule(item: JSONObject) {
        if (!exactAllowed()) throw SecurityException("Exact alarm access denied")
        val id = item.getString("id")
        val show = PendingIntent.getActivity(context, id.hashCode(), Intent(context, MainActivity::class.java)
            .setData(Uri.parse("dontforget://open/$id")).putExtra("occurrenceId", id), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        alarms.setAlarmClock(AlarmManager.AlarmClockInfo(maxOf(item.getLong("nextAt"), System.currentTimeMillis() + 1000), show), pending(id, item.getLong("nextAt")))
    }
    private fun cancel(id: String) { alarms.cancel(pending(id)); pending(id).cancel() }
    private fun refreshService() { AlarmService.refresh(context) }
    @Synchronized fun recordSoundFailure(item: JSONObject) { store.event("soundFallback", item); changed() }
    @Synchronized fun createTest(): String {
        val now = java.time.ZonedDateTime.now()
        return savePlan(JSONObject().put("title", text("测试提醒", "Test reminder")).put("note", "")
            .put("category", "other").put("mission", "math").put("difficulty", "easy").put("mathCount", 1)
            .put("date", now.toLocalDate().toString()).put("hour", now.hour).put("minute", now.minute)
            .put("days", JSONArray()).put("repeating", false).put("snoozeMinutes", preferences.getInt("default_snooze", 10))
            .put("reviewEnabled", false).put("reviewMinutes", 10).put("vibrate", true).put("qrValue", "").put("qrLabel", ""), System.currentTimeMillis() + 30_000)
    }
    companion object {
        // get() always replaces any supplied Activity/Service with applicationContext.
        @android.annotation.SuppressLint("StaticFieldLeak")
        @Volatile private var instance: ReminderEngine? = null
        fun get(context: Context): ReminderEngine = instance ?: synchronized(this) {
            instance ?: ReminderEngine(context.applicationContext).also { instance = it }
        }
    }
}
