package com.dontforget.dont_forget

import kotlin.math.pow

/** Defaults also apply to plans/occurrence snapshots created before sound settings existed. */
object AlarmSoundPolicy {
    val fadeDurations = setOf(0, 15, 30, 60, 120)

    fun validate(volumePercent: Int, fadeInSeconds: Int) {
        require(volumePercent in 10..100 && fadeInSeconds in fadeDurations) { "invalid_sound" }
    }

    fun gain(volumePercent: Int, fadeInSeconds: Int, elapsedMillis: Long): Float {
        validate(volumePercent, fadeInSeconds)
        // A perceptual slider: MediaPlayer expects an amplitude scalar, not a percentage.
        val target = 10.0.pow((volumePercent - 100) / 50.0)
        val progress = if (fadeInSeconds == 0) 1.0
            else (elapsedMillis.toDouble() / (fadeInSeconds * 1000)).coerceIn(0.0, 1.0)
        return (target * (0.05 + 0.95 * progress)).toFloat()
    }
}
