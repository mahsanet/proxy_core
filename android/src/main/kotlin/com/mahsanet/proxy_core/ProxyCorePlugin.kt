package com.mahsanet.proxy_core

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.VpnService
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ResultReceiver
import com.mahsanet.proxy_core.enums.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

private const val REQUEST_CODE_VPN_PERMISSION = 1001
private const val VPN_STATUS_ACTION = "com.mahsanet.proxy_core.VPN_STATUS_CHANGED"

class ProxyCorePlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener,
    EventChannel.StreamHandler {

    private var applicationContext: Context? = null
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var activity: Activity? = null
    private var vpnPermissionResult: MethodChannel.Result? = null
    private var permissionStatus: VpnPermissionStatus = VpnPermissionStatus.PENDING
    private var eventSink: EventChannel.EventSink? = null
    private var vpnStatusReceiver: BroadcastReceiver? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, VpnMethods.VPN_METHOD_CHANNEL)
        eventChannel = EventChannel(binding.binaryMessenger, "proxy_core/vpn_events")

        methodChannel?.setMethodCallHandler(this)
        eventChannel?.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        registerVpnStatusReceiver()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        unregisterVpnStatusReceiver()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        registerVpnStatusReceiver()
    }

    override fun onDetachedFromActivity() {
        activity = null
        unregisterVpnStatusReceiver()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun registerVpnStatusReceiver() {
        vpnStatusReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == VPN_STATUS_ACTION) {
                    val isRunning = intent.getBooleanExtra("is_running", false)

                    // If VPN was disconnected externally, reset permission status
                    if (!isRunning && permissionStatus == VpnPermissionStatus.GRANTED) {
                        // Check if permission is still valid
                        val vpnIntent = VpnService.prepare(applicationContext)
                        if (vpnIntent != null) {
                            // Permission was revoked
                            permissionStatus = VpnPermissionStatus.PENDING
                        }
                    }

                    sendVpnStatusEvent(isRunning)
                }
            }
        }

        val filter = IntentFilter(VPN_STATUS_ACTION)
        applicationContext?.registerReceiver(vpnStatusReceiver, filter)
    }

    private fun unregisterVpnStatusReceiver() {
        vpnStatusReceiver?.let {
            applicationContext?.unregisterReceiver(it)
        }
        vpnStatusReceiver = null
    }

    private fun sendVpnStatusEvent(isRunning: Boolean) {
        eventSink?.success(mapOf(
            "type" to "vpn_status_change",
            "status" to isRunning
        ))
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_VPN_PERMISSION) {
            vpnPermissionResult?.let { result ->
                permissionStatus =
                    if (resultCode == Activity.RESULT_OK) VpnPermissionStatus.GRANTED
                    else VpnPermissionStatus.DENIED
                result.success(permissionStatus == VpnPermissionStatus.GRANTED)
                vpnPermissionResult = null
            }
            return true
        }
        return false
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (VpnMethods.fromMethodName(call.method)) {
            VpnMethods.PREPARE -> prepareVPN(result)
            VpnMethods.START_VPN -> startVPN(result)
            VpnMethods.STOP_VPN -> stopVPN(result)
            VpnMethods.IS_VPN_RUNNING -> {
                val intent =
                    Intent(applicationContext, ProxyCoreVpnService::class.java).apply {
                        action = VpnMethods.IS_VPN_RUNNING.methodName
                        putExtra(VpnMethods.EXTRA_RESULT_RECEIVER, createResultReceiver(result))
                    }
                applicationContext?.startService(intent)
            }
            else -> result.notImplemented()
        }
    }

    private fun prepareVPN(result: MethodChannel.Result) {
        // Always check current permission status
        val vpnIntent = VpnService.prepare(applicationContext)

        if (vpnIntent == null) {
            // Permission already granted
            permissionStatus = VpnPermissionStatus.GRANTED
            result.success(true)
        } else {
            // Need to request permission
            permissionStatus = VpnPermissionStatus.PENDING
            vpnPermissionResult = result
            activity?.startActivityForResult(vpnIntent, REQUEST_CODE_VPN_PERMISSION)
        }
    }

    private fun startVPN(result: MethodChannel.Result) {
        // Always check permission before starting
        val vpnIntent = VpnService.prepare(applicationContext)

        if (vpnIntent != null) {
            // Permission not granted or revoked
            permissionStatus = VpnPermissionStatus.DENIED
            result.error("VPN_PERMISSION_REQUIRED", "VPN permission not granted or was revoked", null)
            return
        }

        // Permission is valid, proceed with starting VPN
        permissionStatus = VpnPermissionStatus.GRANTED
        val intent = Intent(applicationContext, ProxyCoreVpnService::class.java).apply {
            action = VpnMethods.START_VPN.methodName
            putExtra(VpnMethods.EXTRA_RESULT_RECEIVER, createResultReceiver(result))
        }
        applicationContext?.startService(intent)
    }

    private fun stopVPN(result: MethodChannel.Result) {
        val intent =
            Intent(applicationContext, ProxyCoreVpnService::class.java).apply {
                action = VpnMethods.STOP_VPN.methodName
            }
        applicationContext?.startService(intent)
        result.success("VPN stopped")
    }

    private fun createResultReceiver(result: MethodChannel.Result): ResultReceiver {
        return object : ResultReceiver(Handler(Looper.getMainLooper())) {
            override fun onReceiveResult(resultCode: Int, resultData: Bundle?) {
                result.success(resultCode.takeIf { it >= 0 } ?: -1)
            }
        }
    }
}