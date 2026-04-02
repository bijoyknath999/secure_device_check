package io.github.bijoyknath.secure_device_check

import android.app.Activity
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

/** SecureDeviceCheckPlugin */
class SecureDeviceCheckPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {

    private lateinit var methodChannel: MethodChannel
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, "secure_device_check")
        methodChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isEmulator" -> result.success(checkIsEmulator())
            "isDeviceCompromised" -> result.success(checkIsRooted())
            "isDeveloperOptionsEnabled" -> result.success(checkDeveloperOptions())
            "enableScreenProtection" -> {
                enableScreenProtection()
                result.success(null)
            }
            "disableScreenProtection" -> {
                disableScreenProtection()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // Emulator Detection
    // ──────────────────────────────────────────────────────────────────────

    private fun checkIsEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.MODEL.contains("google_sdk")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for x86")
                || Build.MANUFACTURER.contains("Genymotion")
                || Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")
                || "google_sdk" == Build.PRODUCT
                || "sdk" == Build.PRODUCT
                || "sdk_x86" == Build.PRODUCT
                || "sdk_gphone_x86" == Build.PRODUCT
                || "sdk_gphone64_arm64" == Build.PRODUCT
                || "vbox86p" == Build.PRODUCT
                || Build.HARDWARE.contains("goldfish")
                || Build.HARDWARE.contains("ranchu")
                || Build.BOARD.lowercase().contains("nox")
                || Build.BOOTLOADER.lowercase().contains("nox")
                || Build.HARDWARE.lowercase().contains("nox")
                || Build.PRODUCT.lowercase().contains("nox")
                || Build.SERIAL.lowercase().contains("nox")
                || checkOperatorNameAndroid())
    }

    private fun checkOperatorNameAndroid(): Boolean {
        return try {
            val context = activity?.applicationContext ?: return false
            val telephonyManager = context.getSystemService(
                android.content.Context.TELEPHONY_SERVICE
            ) as? android.telephony.TelephonyManager
            telephonyManager?.networkOperatorName?.lowercase() == "android"
        } catch (e: Throwable) {
            false
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // Root Detection
    // ──────────────────────────────────────────────────────────────────────

    private fun checkIsRooted(): Boolean {
        return checkRootBinaries() || checkSuExists() || checkDangerousProps() || checkRootManagement()
    }

    private fun checkRootBinaries(): Boolean {
        val paths = arrayOf(
            "/system/app/Superuser.apk", "/sbin/su", "/system/bin/su",
            "/system/xbin/su", "/data/local/xbin/su", "/data/local/bin/su",
            "/system/sd/xbin/su", "/system/bin/failsafe/su", "/data/local/su",
            "/su/bin/su", "/su/bin", "/system/xbin/daemonsu"
        )
        return paths.any { File(it).exists() }
    }

    private fun checkSuExists(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("/system/xbin/which", "su"))
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val result = reader.readLine()
            reader.close()
            result != null
        } catch (e: Throwable) { false }
    }

    private fun checkDangerousProps(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec("getprop")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val props = reader.readText()
            reader.close()
            props.contains("ro.debuggable=1") || props.contains("ro.secure=0")
        } catch (e: Throwable) { false }
    }

    private fun checkRootManagement(): Boolean {
        val managementPaths = arrayOf(
            "/data/adb/magisk", "/sbin/.magisk", "/cache/.disable_magisk",
            "/dev/.magisk.unblock", "/system/xbin/busybox",
            "/system/bin/busybox", "/sbin/busybox"
        )
        return managementPaths.any { File(it).exists() }
    }

    // ──────────────────────────────────────────────────────────────────────
    // Developer Options Detection
    // ──────────────────────────────────────────────────────────────────────

    private fun checkDeveloperOptions(): Map<String, Boolean> {
        val context = activity?.applicationContext
        val result = mutableMapOf<String, Boolean>()
        if (context != null) {
            result["developerOptions"] = try {
                Settings.Global.getInt(context.contentResolver,
                    Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) != 0
            } catch (e: Throwable) { false }
            result["usbDebugging"] = try {
                Settings.Global.getInt(context.contentResolver,
                    Settings.Global.ADB_ENABLED, 0) != 0
            } catch (e: Throwable) { false }
        } else {
            result["developerOptions"] = false
            result["usbDebugging"] = false
        }
        return result
    }

    // ──────────────────────────────────────────────────────────────────────
    // Screen Protection (blocks screenshots + makes screen recordings black)
    //
    // Uses FLAG_SECURE which prevents screenshots from capturing content
    // and makes any screen recording show a black/blank screen.
    // ──────────────────────────────────────────────────────────────────────

    private fun enableScreenProtection() {
        activity?.runOnUiThread {
            activity?.window?.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        }
    }

    private fun disableScreenProtection() {
        activity?.runOnUiThread {
            activity?.window?.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // ActivityAware
    // ──────────────────────────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() { activity = null }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() { activity = null }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }
}
