package com.dontforget.dont_forget

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import org.json.JSONObject

/** One native database owns both plans and occurrences, including while Flutter is absent. */
class ReminderStore(context: Context) : SQLiteOpenHelper(context, "dont_forget.db", null, 1) {
    override fun onConfigure(db: SQLiteDatabase) { db.setForeignKeyConstraintsEnabled(true) }
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("CREATE TABLE plans (id TEXT PRIMARY KEY, payload TEXT NOT NULL)")
        db.execSQL("CREATE TABLE occurrences (id TEXT PRIMARY KEY, plan_id TEXT NOT NULL, status TEXT NOT NULL, next_at INTEGER NOT NULL, payload TEXT NOT NULL, FOREIGN KEY(plan_id) REFERENCES plans(id) ON DELETE CASCADE)")
        db.execSQL("CREATE INDEX occurrence_state ON occurrences(status, next_at)")
        db.execSQL("CREATE TABLE events (id INTEGER PRIMARY KEY AUTOINCREMENT, at INTEGER NOT NULL, kind TEXT NOT NULL, payload TEXT NOT NULL)")
    }
    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        // Never silently clear personal reminders on an unknown migration.
        error("Missing database migration $oldVersion -> $newVersion")
    }
    override fun onDowngrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        error("Database downgrade is not supported")
    }
    fun <T> transaction(block: () -> T): T {
        val db = writableDatabase
        db.beginTransaction()
        try { val result = block(); db.setTransactionSuccessful(); return result }
        finally { db.endTransaction() }
    }
    fun plans(): List<JSONObject> = query("SELECT payload FROM plans")
    fun plan(id: String): JSONObject? = query("SELECT payload FROM plans WHERE id = ?", arrayOf(id)).firstOrNull()
    fun occurrence(id: String): JSONObject? = query("SELECT payload FROM occurrences WHERE id = ?", arrayOf(id)).firstOrNull()
    fun live(): List<JSONObject> = query("SELECT payload FROM occurrences WHERE status IN ('scheduled','ringing','snoozed','reviewPending') ORDER BY next_at")
    fun forPlan(id: String): List<JSONObject> = query("SELECT payload FROM occurrences WHERE plan_id = ? AND status IN ('scheduled','ringing','snoozed','reviewPending')", arrayOf(id))
    fun history(): List<JSONObject> = query("SELECT payload FROM events ORDER BY id DESC LIMIT 250")
    fun weeklyStats(): JSONObject {
        val stats = JSONObject()
        readableDatabase.rawQuery("SELECT kind, COUNT(*) FROM events WHERE at >= ? GROUP BY kind", arrayOf((System.currentTimeMillis() - 7 * 86400000L).toString())).use {
            while (it.moveToNext()) stats.put(it.getString(0), it.getInt(1))
        }
        return stats
    }
    fun putPlan(plan: JSONObject) {
        val values = ContentValues().apply { put("id", plan.getString("id")); put("payload", plan.toString()) }
        // REPLACE would delete child occurrences via ON DELETE CASCADE.
        if (writableDatabase.update("plans", values, "id = ?", arrayOf(plan.getString("id"))) == 0)
            writableDatabase.insertOrThrow("plans", null, values)
    }
    fun putOccurrence(item: JSONObject) {
        val values = ContentValues().apply {
            put("id", item.getString("id")); put("plan_id", item.getString("planId"))
            put("status", item.getString("status")); put("next_at", item.getLong("nextAt")); put("payload", item.toString())
        }
        if (writableDatabase.update("occurrences", values, "id = ?", arrayOf(item.getString("id"))) == 0)
            writableDatabase.insertOrThrow("occurrences", null, values)
    }
    fun deletePlan(id: String) { writableDatabase.delete("plans", "id = ?", arrayOf(id)) }
    fun event(kind: String, item: JSONObject, minutes: Int? = null, detail: String? = null) {
        val plan = item.getJSONObject("plan")
        val now = System.currentTimeMillis()
        val payload = JSONObject().put("at", now).put("kind", kind).put("title", plan.getString("title"))
            .put("category", plan.getString("category")).put("occurrenceId", item.getString("id"))
            .put("isReview", item.optBoolean("isReview"))
        if (minutes != null) payload.put("minutes", minutes)
        if (detail != null) payload.put("detail", detail)
        writableDatabase.insertOrThrow("events", null, ContentValues().apply { put("at", now); put("kind", kind); put("payload", payload.toString()) })
    }
    private fun query(sql: String, arguments: Array<String>? = null): List<JSONObject> {
        val result = mutableListOf<JSONObject>()
        readableDatabase.rawQuery(sql, arguments).use { cursor -> while (cursor.moveToNext()) result.add(JSONObject(cursor.getString(0))) }
        return result
    }
}
