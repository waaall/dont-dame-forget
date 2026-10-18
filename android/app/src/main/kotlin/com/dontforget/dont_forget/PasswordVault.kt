package com.dontforget.dont_forget

import android.content.SharedPreferences
import android.util.Base64
import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

class PasswordVault(private val preferences: SharedPreferences) {
    fun configured() = preferences.contains("password_hash")
    private fun derive(password: String, salt: ByteArray): ByteArray {
        val spec = PBEKeySpec(password.toCharArray(), salt, 120_000, 256)
        return try { SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).encoded }
        finally { spec.clearPassword() }
    }
    fun matches(password: String): Boolean {
        if (!configured()) return false
        val salt = Base64.decode(preferences.getString("password_salt", ""), Base64.NO_WRAP)
        val expected = Base64.decode(preferences.getString("password_hash", ""), Base64.NO_WRAP)
        return MessageDigest.isEqual(expected, derive(password, salt))
    }
    fun set(current: String, password: String) {
        require(password.length in 4..128) { "invalid_password" }
        if (configured() && !matches(current)) throw RuleException("wrong_password")
        val salt = ByteArray(24).also { SecureRandom().nextBytes(it) }
        val hash = derive(password, salt)
        if (!preferences.edit().putString("password_salt", Base64.encodeToString(salt, Base64.NO_WRAP))
                .putString("password_hash", Base64.encodeToString(hash, Base64.NO_WRAP)).commit()) error("Unable to save password")
    }
}

class RuleException(val code: String) : RuntimeException(code)
