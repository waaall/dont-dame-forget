package com.dontforget.dont_forget

import org.junit.Assert.*
import org.junit.Test

class AlarmSoundPolicyTest {
    @Test fun oldPlansKeepFullPlayerGainWithoutFading() {
        assertEquals(1f, AlarmSoundPolicy.gain(100, 0, 0), 0.0001f)
    }
    @Test fun eachReminderCanHaveADifferentLoudness() {
        assertTrue(AlarmSoundPolicy.gain(40, 0, 0) < AlarmSoundPolicy.gain(80, 0, 0))
        assertTrue(AlarmSoundPolicy.gain(10, 0, 0) > 0f)
    }
    @Test fun fadingStartsAudiblyAndReachesTheChosenTargetWithoutOvershoot() {
        for (seconds in listOf(15, 30, 60, 120)) {
            val target = AlarmSoundPolicy.gain(70, 0, 0)
            var previous = 0f
            for (elapsed in 0..seconds * 1000 step 100) {
                val gain = AlarmSoundPolicy.gain(70, seconds, elapsed.toLong())
                assertTrue(gain > 0 && gain >= previous && gain <= target)
                previous = gain
            }
            assertEquals(target, previous, 0.0001f)
            assertEquals(target, AlarmSoundPolicy.gain(70, seconds, 500000), 0.0001f)
        }
    }
    @Test fun restoringElapsedTimeDoesNotRestartTheFade() {
        assertTrue(AlarmSoundPolicy.gain(100, 30, 10000) > AlarmSoundPolicy.gain(100, 30, 0))
        assertEquals(AlarmSoundPolicy.gain(100, 30, 0), AlarmSoundPolicy.gain(100, 30, -1000), 0.0001f)
    }
    @Test(expected = IllegalArgumentException::class) fun rejectsMutedReminder() { AlarmSoundPolicy.validate(0, 0) }
    @Test(expected = IllegalArgumentException::class) fun rejectsUnsupportedFade() { AlarmSoundPolicy.validate(100, 999) }
}
