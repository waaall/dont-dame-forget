package com.dontforget.dont_forget

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.security.SecureRandom

/** Pure rules shared by every entry point: UI, receiver and service. */
object ReminderPolicy {
    const val OATH = "我发誓我没忘，让我关上吧"
    val liveStates = setOf("scheduled", "ringing", "snoozed", "reviewPending")
    val protectedStates = setOf("ringing", "snoozed", "reviewPending")
    enum class Completion { REVIEW, COMPLETE, SKIP }
    fun completion(reviewEnabled: Boolean, isReview: Boolean, skipped: Boolean): Completion = when {
        skipped -> Completion.SKIP
        reviewEnabled && !isReview -> Completion.REVIEW
        else -> Completion.COMPLETE
    }

    fun nextAt(date: String, hour: Int, minute: Int, repeating: Boolean,
               days: Set<Int>, now: Long, zone: ZoneId = ZoneId.systemDefault()): Long {
        require(hour in 0..23 && minute in 0..59) { "invalid_time" }
        if (!repeating) {
            return LocalDate.parse(date).atTime(hour, minute).atZone(zone).toInstant().toEpochMilli()
        }
        require(days.isNotEmpty() && days.all { it in 1..7 }) { "invalid_days" }
        val today = Instant.ofEpochMilli(now).atZone(zone).toLocalDate()
        for (offset in 0L..7L) {
            val candidateDate = today.plusDays(offset)
            if (candidateDate.dayOfWeek.value !in days) continue
            val candidate = candidateDate.atTime(hour, minute).atZone(zone).toInstant().toEpochMilli()
            if (candidate > now) return candidate
        }
        error("No next occurrence")
    }

    fun snoozeAt(now: Long, minutes: Int): Long {
        require(minutes in 1..1440) { "invalid_duration" }
        // Snoozing is deliberately unlimited; no counter can finish an occurrence.
        return Math.addExact(now, minutes * 60_000L)
    }

    data class Question(val expression: String, val answer: Int)
    fun question(difficulty: String, random: SecureRandom = SecureRandom()): Question {
        val bound = when (difficulty) { "hard" -> 90; "medium" -> 40; else -> 10 }
        val a = random.nextInt(bound) + 2
        val b = random.nextInt(bound) + 2
        return when (random.nextInt(if (difficulty == "easy") 2 else 3)) {
            0 -> Question("$a + $b", a + b)
            1 -> Question("${maxOf(a, b)} − ${minOf(a, b)}", kotlin.math.abs(a - b))
            else -> {
                val factor = random.nextInt(if (difficulty == "hard") 12 else 8) + 2
                Question("$a × $factor", a * factor)
            }
        }
    }
}
