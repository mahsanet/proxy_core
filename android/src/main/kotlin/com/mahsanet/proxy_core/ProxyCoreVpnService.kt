package com.mahsanet.proxy_core

import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.Parcelable
import android.os.ResultReceiver
import android.util.Log
import android.os.ParcelFileDescriptor
import com.mahsanet.proxy_core.enums.VpnMethods

private const val VPN_STATUS_ACTION = "com.mahsanet.proxy_core.VPN_STATUS_CHANGED"

class ProxyCoreVpnService : VpnService() {
    @Volatile private var vpnFd: Int = -1
    @Volatile private var vpnState: VpnMethods = VpnMethods.STOP_VPN
    @Volatile private var vpnInterface: ParcelFileDescriptor? = null
    @Volatile private var isFdDetached: Boolean = false

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.action?.let { action ->
            when (VpnMethods.fromMethodName(action)) {
                VpnMethods.START_VPN -> handleStartVpn(intent)
                VpnMethods.STOP_VPN -> handleStopVpn()
                VpnMethods.IS_VPN_RUNNING -> checkVpnStatus(intent)
                else -> Log.e(VpnMethods.TAG, "Unknown action: $action")
            }
        }
            ?: Log.e(VpnMethods.TAG, "Intent is null!")
        return START_STICKY
    }

    override fun onRevoke() {
        super.onRevoke()
        Log.i(VpnMethods.TAG, "VPN revoked by system - cleaning up state")
        handleVpnRevoked()
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.i(VpnMethods.TAG, "VPN service destroyed - cleaning up")
        cleanupVpnResources()
    }

    private fun handleVpnRevoked() {
        synchronized(this) {
            Log.i(VpnMethods.TAG, "VPN was revoked - resetting state")
            cleanupVpnResources()
            broadcastVpnStatus(false)
        }
    }

    private fun cleanupVpnResources() {
        try {
            // Only close if FD was not detached
            if (!isFdDetached) {
                vpnInterface?.close()
            } else {
                Log.i(VpnMethods.TAG, "FD was detached, skipping close() to avoid fdsan error")
            }
        } catch (e: Exception) {
            Log.e(VpnMethods.TAG, "Error closing VPN interface", e)
        }
        vpnInterface = null
        vpnFd = -1
        vpnState = VpnMethods.STOP_VPN
        isFdDetached = false
    }

    private fun checkVpnStatus(intent: Intent) {
        synchronized(this) {
            val actuallyRunning = isVpnActuallyRunning()
            if (!actuallyRunning && vpnState == VpnMethods.START_VPN) {
                Log.w(VpnMethods.TAG, "VPN state inconsistent - fixing")
                cleanupVpnResources()
                broadcastVpnStatus(false)
            }

            val resultReceiver: ResultReceiver? =
                getParcelableExtraCompat(intent, ResultReceiver::class.java)
            val resultCode = if (actuallyRunning && vpnState == VpnMethods.START_VPN) 1 else 0
            resultReceiver?.send(resultCode, null)
        }
    }

    private fun isVpnActuallyRunning(): Boolean {
        return vpnInterface != null && vpnFd > 0 && vpnState == VpnMethods.START_VPN
    }

    private fun handleStartVpn(intent: Intent) {
        synchronized(this) {
            Log.i(VpnMethods.TAG, "Starting VPN - current state: $vpnState, fd: $vpnFd")

            // Always clean up previous state before starting
            if (vpnState == VpnMethods.START_VPN || vpnFd != -1 || vpnInterface != null) {
                Log.i(VpnMethods.TAG, "Cleaning up previous VPN state before starting new one")
                cleanupVpnResources()
            }

            val result = createVPNInterface()
            if (result != null && result.first != -1) {
                vpnInterface = result.second
                vpnFd = result.first
                vpnState = VpnMethods.START_VPN
                broadcastVpnStatus(true)
                Log.i(VpnMethods.TAG, "VPN started successfully with fd: $vpnFd")
                sendResultReceiver(intent, vpnFd)
            } else {
                Log.e(VpnMethods.TAG, "Failed to create VPN interface")
                cleanupVpnResources()
                sendResultReceiver(intent, -1)
            }
        }
    }

    private fun handleStopVpn() {
        synchronized(this) {
            Log.i(VpnMethods.TAG, "Stopping VPN - current state: $vpnState")
            if (vpnState == VpnMethods.START_VPN) {
                stopVPN()
                broadcastVpnStatus(false)
            } else {
                Log.i(VpnMethods.TAG, "VPN not running, ensuring clean state")
                cleanupVpnResources()
                broadcastVpnStatus(false)
            }
        }
    }

    private fun broadcastVpnStatus(isRunning: Boolean) {
        val intent = Intent(VPN_STATUS_ACTION).apply {
            putExtra("is_running", isRunning)
        }
        sendBroadcast(intent)
        Log.d(VpnMethods.TAG, "Broadcasted VPN status: $isRunning")
    }

    private fun sendResultReceiver(intent: Intent, fd: Int) {
        val resultReceiver: ResultReceiver? =
            getParcelableExtraCompat(intent, ResultReceiver::class.java)
        resultReceiver?.send(fd.takeIf { it >= 0 } ?: -1, null)
    }

    private fun createVPNInterface(): Pair<Int, ParcelFileDescriptor>? {
        return try {
            Log.i(VpnMethods.TAG, "Creating VPN interface")

            val builder = Builder().apply {
                setSession("${this@ProxyCoreVpnService.packageName}-vpn")
                setBlocking(false)
                setMtu(1500)

                addAddress(VpnMethods.PRIVATE_VLAN_4_CLIENT, 24)
                addAddress(VpnMethods.PRIVATE_VLAN_6_CLIENT, 128)

                addDnsServer("1.1.1.1")
                addDnsServer("1.0.0.1")
                addDnsServer("2606:4700:4700::1111")
                addDnsServer("2606:4700:4700::1001")

                // Exclude our own app from VPN
                try {
                    addDisallowedApplication(this@ProxyCoreVpnService.packageName)
                } catch (e: Exception) {
                    Log.w(VpnMethods.TAG, "Could not exclude own package from VPN", e)
                }

                // Route all traffic through VPN
                addRoute("0.0.0.0", 0)
                addRoute("::", 0)
            }

            val vpnInterface = builder.establish()
            if (vpnInterface != null) {
                val fd = vpnInterface.detachFd()
                isFdDetached = true
                Log.i(VpnMethods.TAG, "VPN interface created with fd: $fd (detached)")
                Pair(fd, vpnInterface)
            } else {
                Log.e(VpnMethods.TAG, "Failed to establish VPN interface")
                null
            }
        } catch (e: SecurityException) {
            Log.e(VpnMethods.TAG, "Security exception creating VPN interface - permission revoked?", e)
            null
        } catch (e: Exception) {
            Log.e(VpnMethods.TAG, "Error creating VPN interface", e)
            null
        }
    }

    private fun stopVPN() {
        synchronized(this) {
            Log.i(VpnMethods.TAG, "Stopping VPN and cleaning up resources")
            cleanupVpnResources()

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_DETACH)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }

            stopSelf()
        }
    }

    private fun <T : Parcelable> getParcelableExtraCompat(intent: Intent, clazz: Class<T>): T? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(VpnMethods.EXTRA_RESULT_RECEIVER, clazz)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(VpnMethods.EXTRA_RESULT_RECEIVER) as? T
        }
    }
}