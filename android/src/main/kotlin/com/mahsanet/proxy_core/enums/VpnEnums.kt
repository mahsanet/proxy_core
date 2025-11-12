package com.mahsanet.proxy_core.enums

enum class VpnMethods(val methodName: String) {
    PREPARE("prepare"),
    START_VPN("startVPN"),
    STOP_VPN("stopVPN"),
    IS_VPN_RUNNING("isVPNRunning");

    companion object {
        const val TAG = "ProxyCoreVpnService"
        const val EXTRA_RESULT_RECEIVER = "proxy_core.EXTRA_RESULT_RECEIVER"
        const val VPN_METHOD_CHANNEL = "proxy_core/vpn"

        // VPN Client IP addresses
        const val PRIVATE_VLAN_4_CLIENT = "172.19.0.1"
        const val PRIVATE_VLAN_6_CLIENT = "fdfe:dcba:9876::1"

        /**
         * Safely retrieves a VpnMethods enum based on a provided method name.
         * Returns null if the method name doesn't match any enum values.
         *
         * @param methodName the name of the method as a String
         * @return VpnMethods instance or null if not found
         */
        fun fromMethodName(methodName: String?): VpnMethods? {
            return methodName?.let {
                values().find { it.methodName == methodName }
            }
        }
    }
}

enum class VpnPermissionStatus(val isGranted: Boolean) {
    GRANTED(true),
    DENIED(false),
    PENDING(false);

    companion object {
        /**
         * Creates a VpnPermissionStatus from a boolean value.
         * True corresponds to GRANTED, false to DENIED.
         *
         * @param isGranted boolean representing permission status
         * @return VpnPermissionStatus instance
         */
        fun fromBoolean(isGranted: Boolean): VpnPermissionStatus {
            return if (isGranted) GRANTED else DENIED
        }

        /**
         * Creates a VpnPermissionStatus from an integer value.
         * 1 -> GRANTED, 0 -> DENIED, otherwise PENDING.
         *
         * @param status integer representing permission status
         * @return VpnPermissionStatus instance
         */
        fun fromInt(status: Int): VpnPermissionStatus {
            return when (status) {
                1 -> GRANTED
                0 -> DENIED
                else -> PENDING
            }
        }
    }
}