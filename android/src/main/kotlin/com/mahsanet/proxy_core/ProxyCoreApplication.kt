package com.mahsanet.proxy_core

import android.os.Build
import android.util.Log

object ProxyCoreApplication {
    private const val TAG = "ProxyCoreApplication"
    
    init {
        // Load our native library that disables fdsan
        try {
            System.loadLibrary("fdsan_workaround")
        } catch (e: UnsatisfiedLinkError) {
            Log.w(TAG, "fdsan_workaround library not found: ${e.message}")
        }
    }
    
    // Native method to disable fdsan
    private external fun disableFdsanNative()
    
    /**
     * Call this method early in the application lifecycle to disable strict fdsan
     * for Android 10+ to avoid crashes when passing FDs between Java and Native code.
     * 
     * This should be called from the plugin's initialization, not from a custom Application class
     * since Flutter plugins don't have their own Application class.
     */
    fun initializeFdsanWorkaround() {
        // Disable strict fdsan for Android 10+ to avoid crashes
        // when passing FDs between Java and Native (Go) code
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                disableFdsanNative()
                Log.i(TAG, "fdsan configured to WARN mode successfully")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to configure fdsan: ${e.message}")
            }
        }
    }
}
