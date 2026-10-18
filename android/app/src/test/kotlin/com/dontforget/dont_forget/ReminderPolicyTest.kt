package com.dontforget.dont_forget

import org.junit.Assert.*
import org.junit.Test
import java.time.Instant
import java.time.ZoneId

class ReminderPolicyTest {
    private val shanghai = ZoneId.of("Asia/Shanghai")
    @Test fun dailyPlanMovesToTomorrowAfterItsTime() {
        val now = Instant.parse("2026-10-18T00:00:00Z").toEpochMilli()
        assertEquals(Instant.parse("2026-10-18T23:00:00Z").toEpochMilli(), ReminderPolicy.nextAt("2026-10-18", 7, 0, true, (1..7).toSet(), now, shanghai))
    }
    @Test fun weekdaysSkipWeekend() {
        val now = Instant.parse("2026-10-16T01:00:00Z").toEpochMilli()
        assertEquals(Instant.parse("2026-10-18T23:00:00Z").toEpochMilli(), ReminderPolicy.nextAt("2026-10-16", 7, 0, true, (1..5).toSet(), now, shanghai))
    }
    @Test fun weeklySelectionHandlesNextWeek() {
        val now = Instant.parse("2026-10-19T01:00:00Z").toEpochMilli()
        assertEquals(Instant.parse("2026-10-25T23:00:00Z").toEpochMilli(), ReminderPolicy.nextAt("2026-10-19", 7, 0, true, setOf(1), now, shanghai))
    }
    @Test fun oneTimePlanUsesChosenDateInsteadOfRepeatDays() {
        val now = Instant.parse("2026-10-18T00:00:00Z").toEpochMilli()
        assertEquals(Instant.parse("2026-10-20T04:30:00Z").toEpochMilli(), ReminderPolicy.nextAt("2026-10-20", 12, 30, false, emptySet(), now, shanghai))
    }
    @Test fun daylightSavingGapUsesPlatformLocalTimeRules() {
        val zone = ZoneId.of("America/New_York")
        val now = Instant.parse("2026-03-08T05:00:00Z").toEpochMilli()
        assertEquals(Instant.parse("2026-03-08T07:30:00Z").toEpochMilli(), ReminderPolicy.nextAt("2026-03-08", 2, 30, true, setOf(7), now, zone))
    }
    @Test fun snoozingHasNoCountLimit() {
        var time = 123456L
        repeat(1000) { time = ReminderPolicy.snoozeAt(time, 10) }
        assertEquals(123456L + 1000 * 600000L, time)
        assertTrue("snoozed" in ReminderPolicy.protectedStates)
    }
    @Test(expected = IllegalArgumentException::class) fun rejectsZeroSnooze() { ReminderPolicy.snoozeAt(0, 0) }
    @Test(expected = IllegalArgumentException::class) fun repeatingPlanNeedsADay() { ReminderPolicy.nextAt("2026-10-18", 7, 0, true, emptySet(), 0, shanghai) }
    @Test fun emergencyPhraseMustStayExact() { assertEquals("我发誓我没忘，让我关上吧", ReminderPolicy.OATH) }
    @Test fun optionalReviewHappensOnlyOnce() {
        assertEquals(ReminderPolicy.Completion.REVIEW, ReminderPolicy.completion(true, false, false))
        assertEquals(ReminderPolicy.Completion.COMPLETE, ReminderPolicy.completion(true, true, false))
    }
    @Test fun disabledReviewCompletesImmediately() {
        assertEquals(ReminderPolicy.Completion.COMPLETE, ReminderPolicy.completion(false, false, false))
    }
    @Test fun emergencySkipsEvenWhenReviewWasConfigured() {
        assertEquals(ReminderPolicy.Completion.SKIP, ReminderPolicy.completion(true, false, true))
        assertEquals(ReminderPolicy.Completion.SKIP, ReminderPolicy.completion(true, true, true))
    }
    @Test fun generatedQuestionsHaveCorrectAnswers() {
        for (difficulty in listOf("easy", "medium", "hard")) repeat(100) {
            val question = ReminderPolicy.question(difficulty)
            val parts = question.expression.split(" ")
            val a = parts[0].toInt(); val b = parts[2].toInt()
            val expected = when (parts[1]) { "+" -> a + b; "−" -> a - b; else -> a * b }
            assertEquals(expected, question.answer); assertTrue(question.answer >= 0)
        }
    }
}
