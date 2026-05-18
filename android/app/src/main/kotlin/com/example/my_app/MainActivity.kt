package com.example.flutter_my_app_main

import android.app.Activity
import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.net.VpnService // ✅ تمت إضافة مكتبة الـ VPN
import android.os.Build
import android.os.Bundle
import android.os.Process
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel // ✅ تم إضافة مكتبة الـ EventChannel
import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.util.*

private const val CHANNEL = "com.appguard.native_calls"
private const val TAG = "AdminChecker"
private const val ACTION_BLOCK_EVENT = "com.example.flutter_my_app_main.BLOCK_EVENT"
private const val EXTRA_BLOCKED_PACKAGE = "blocked_package"
private const val EXTRA_BLOCK_REASON = "block_reason"

// =======================================================================================
// === Main Activity ===
// =======================================================================================

class MainActivity: FlutterActivity() {
    private var methodChannel: MethodChannel? = null
    private var blockEventReceiver: BroadcastReceiver? = null

    // ✅ متغير لحفظ الدومينات المحظورة عشان نبعتها لخدمة الـ VPN
    private var blockedDomains: List<String> = emptyList()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 🔹 Start GuardService in foreground (non-blocking)
        try {
            startGuardService()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start GuardService in onCreate: ${e.message}")
        }

        // Note: Device admin check moved to configureFlutterEngine to allow Flutter to initialize first
        registerBlockEventReceiver()
    }

    private fun startGuardService() {
        try {
            val intent = Intent(this, GuardService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            Log.d(TAG, "Requested GuardService start from MainActivity")
        } catch (e: Exception) {
            Log.e(TAG, "startGuardService error: ${e.message}")
        }
    }

    private fun checkAndRequestDeviceAdmin() {
        // Check device admin status asynchronously to not block app startup
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                if (!checkDeviceAdminActive(this)) {
                    // Request Device Admin permission (non-blocking)
                    requestDeviceAdminPermission(this)
                    Log.d(TAG, "Device Admin not active, permission requested")
                } else {
                    Log.d(TAG, "Device Admin is active")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking device admin: ${e.message}")
            }
        }, 1000) // Delay to allow Flutter UI to render first
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 🔹 Check Device Admin status after Flutter is initialized (non-blocking)
        checkAndRequestDeviceAdmin()

        // Initialize Health Data Handler (Samsung Health & Health Connect)
        val healthDataHandler = HealthDataHandler(this)
        healthDataHandler.registerWith(flutterEngine)

        // ✅ 1. تهيئة الـ EventChannel لمنع الكراش الخاص بـ Threat Monitor
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.mindquest/security_events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "Flutter is now listening to security events")
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "Flutter stopped listening to security events")
                }
            })

        // 2. تهيئة الـ MethodChannel العادية
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAdminActive" -> result.success(checkDeviceAdminActive(this))
                "requestAdminPermission" -> {
                    requestDeviceAdminPermission(this)
                    result.success(true)
                }
                "requestUsagePermission" -> {
                    requestUsageAccessPermission(this)
                    result.success(true)
                }
                "hasUsagePermission" -> result.success(hasUsageAccessPermission(this))
                "checkUsageStatsPermission" -> result.success(hasUsageAccessPermission(this))
                "requestUsageStatsPermission" -> {
                    requestUsageAccessPermission(this)
                    result.success(true)
                }
                "checkAccessibilityPermission" -> result.success(isAccessibilityServiceEnabled(this))
                "requestAccessibilityPermission" -> {
                    requestAccessibilityPermission(this)
                    result.success(true)
                }
                "getUsageStats" -> {
                    try {
                        val usageStatsList = UsageStatsUtils.getInstalledApps(this)
                        result.success(usageStatsList)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error fetching usage stats: ${e.message}")
                        result.error("USAGE_ERROR", "Failed to retrieve usage stats.", e.message)
                    }
                }
                "getInstalledApps" -> {
                    try {
                        val installedApps = UsageStatsUtils.getInstalledApps(this)
                        result.success(installedApps)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error fetching installed apps: ${e.message}")
                        result.error("APPS_ERROR", "Failed to retrieve installed apps.", e.message)
                    }
                }
                "getAppIcon" -> {
                    try {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            val iconBytes = getAppIcon(packageName)
                            result.success(iconBytes)
                        } else {
                            result.error("INVALID_ARGS", "Package name is required", null)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error fetching app icon: ${e.message}")
                        result.success(null) // Return null if icon not available
                    }
                }
                "setAppBlockStatus" -> {
                    val packageName = call.argument<String>("packageName")
                    val isBlocked = call.argument<Boolean>("isBlocked") ?: false
                    if (packageName != null) {
                        val database = AppBlockDatabase(this)
                        val success = database.setAppBlocked(packageName, isBlocked)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGS", "Package name is required", null)
                    }
                }
                "getBlockedApps" -> {
                    try {
                        val database = AppBlockDatabase(this)
                        val blockedApps = database.getAllBlockedApps()
                        result.success(blockedApps)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error fetching blocked apps: ${e.message}")
                        result.error("DB_ERROR", "Failed to retrieve blocked apps.", e.message)
                    }
                }
                "startBlockingService" -> {
                    try {
                        val serviceIntent = Intent(this, GuardService::class.java).apply {
                            action = "com.example.flutter_my_app_main.START_BLOCKING"
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error starting blocking service: ${e.message}")
                        result.error("SERVICE_ERROR", "Failed to start blocking service.", e.message)
                    }
                }
                "stopBlockingService" -> {
                    try {
                        val serviceIntent = Intent(this, GuardService::class.java).apply {
                            action = "com.example.flutter_my_app_main.STOP_BLOCKING"
                        }
                        startService(serviceIntent) // Send stop command
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error stopping blocking service: ${e.message}")
                        result.error("SERVICE_ERROR", "Failed to stop blocking service.", e.message)
                    }
                }
                "blockApp" -> {
                    val appName = call.argument<String>("appName")
                    Toast.makeText(this, "Block logic initiated for: $appName (Service Required)", Toast.LENGTH_LONG).show()
                    result.success(true)
                }
                "startGuardService" -> {
                    startGuardService()
                    result.success(true)
                }
                // ✅ إضافة أمر استقبال وتشغيل الـ VPN
                "startVpn" -> {
                    blockedDomains = call.argument<List<String>>("domains") ?: emptyList()
                    val vpnIntent = VpnService.prepare(this)
                    if (vpnIntent != null) {
                        startActivityForResult(vpnIntent, 0)
                    } else {
                        startVpnService()
                    }
                    result.success("VPN Initialization Started")
                }
                else -> result.notImplemented()
            }
        }
    }

    // ✅ دالة استقبال موافقة المستخدم على تصريح الـ VPN
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 0 && resultCode == RESULT_OK) {
            startVpnService()
        }
    }

    // ✅ دالة تشغيل خدمة الـ VPN
    private fun startVpnService() {
        try {
            val intent = Intent(this, LocalVpnService::class.java)
            intent.putStringArrayListExtra("blocked_domains", ArrayList(blockedDomains))
            startService(intent)
            Log.d(TAG, "VPN Service started from MainActivity")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start VPN Service: ${e.message}")
        }
    }

    override fun onDestroy() {
        unregisterBlockEventReceiver()
        super.onDestroy()
    }

    private fun registerBlockEventReceiver() {
        if (blockEventReceiver != null) return
        blockEventReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action != ACTION_BLOCK_EVENT) return
                val packageName = intent.getStringExtra(EXTRA_BLOCKED_PACKAGE) ?: return
                val reason = intent.getStringExtra(EXTRA_BLOCK_REASON) ?: "limit_exceeded"
                val payload = mapOf(
                    "packageName" to packageName,
                    "reason" to reason
                )
                runOnUiThread {
                    methodChannel?.invokeMethod("onBlockEvent", payload)
                }
            }
        }
        val filter = IntentFilter(ACTION_BLOCK_EVENT)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(blockEventReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(blockEventReceiver, filter)
        }
    }

    private fun unregisterBlockEventReceiver() {
        try {
            blockEventReceiver?.let { unregisterReceiver(it) }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to unregister block event receiver: ${e.message}")
        } finally {
            blockEventReceiver = null
        }
    }

    // =================== Device Admin Methods ===================

    private fun checkDeviceAdminActive(context: Context): Boolean {
        return try {
            val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val componentName = ComponentName(context, AdminReceiver::class.java)
            devicePolicyManager.isAdminActive(componentName)
        } catch (e: Exception) {
            Log.e(TAG, "checkDeviceAdminActive error: ${e.message}")
            false
        }
    }

    private fun requestDeviceAdminPermission(context: Context) {
        try {
            val componentName = ComponentName(context, AdminReceiver::class.java)
            val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager

            if (!devicePolicyManager.isAdminActive(componentName)) {
                val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
                intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "⚠️ You must enable this permission to use the app.")
                startActivity(intent)
            } else {
                Toast.makeText(context, "Device Admin already enabled.", Toast.LENGTH_SHORT).show()
            }
        } catch (e: Exception) {
            Log.e(TAG, "requestDeviceAdminPermission error: ${e.message}")
        }
    }

    private fun requestUsageAccessPermission(context: Context) {
        if (!hasUsageAccessPermission(context)) {
            try {
                val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                context.startActivity(intent)
            } catch (e: Exception) {
                Toast.makeText(context, "Cannot open Usage Access settings.", Toast.LENGTH_LONG).show()
            }
        } else {
            Toast.makeText(context, "Usage Access already granted.", Toast.LENGTH_SHORT).show()
        }
    }

    private fun hasUsageAccessPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName
                )
            }
            return mode == AppOpsManager.MODE_ALLOWED
        }
        return false
    }

    private fun isAccessibilityServiceEnabled(context: Context): Boolean {
        val accessibilityManager = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as android.view.accessibility.AccessibilityManager
        val enabledServices = accessibilityManager.getEnabledAccessibilityServiceList(android.view.accessibility.AccessibilityEvent.TYPES_ALL_MASK)
        return enabledServices.any { it.id == "${context.packageName}/.AppBlockAccessibilityService" }
    }

    private fun requestAccessibilityPermission(context: Context) {
        try {
            val intent = Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Cannot open Accessibility settings: ${e.message}")
        }
    }

    private fun getAppIcon(packageName: String): ByteArray? {
        return try {
            val packageManager = packageManager
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            val icon = packageManager.getApplicationIcon(appInfo)

            val bitmap = when (icon) {
                is android.graphics.drawable.BitmapDrawable -> icon.bitmap
                else -> {
                    val width = if (icon.intrinsicWidth > 0) icon.intrinsicWidth else 96
                    val height = if (icon.intrinsicHeight > 0) icon.intrinsicHeight else 96
                    val bitmap = android.graphics.Bitmap.createBitmap(width, height, android.graphics.Bitmap.Config.ARGB_8888)
                    val canvas = android.graphics.Canvas(bitmap)
                    icon.setBounds(0, 0, canvas.width, canvas.height)
                    icon.draw(canvas)
                    bitmap
                }
            }

            val stream = java.io.ByteArrayOutputStream()
            bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting app icon for $packageName: ${e.message}")
            null
        }
    }
}

// =======================================================================================
// === Device Admin Receiver ===
// =======================================================================================

class AdminReceiver : DeviceAdminReceiver() {

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence? {
        try {
            val warningIntent = Intent(context, WarningActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            }
            context.startActivity(warningIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch WarningActivity: ${e.message}")
        }

        try {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            context.startActivity(launchIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch app after disable request: ${e.message}")
        }

        return """
            ⚠️ Important Security Notice! ⚠️

            This application contains special security features that prevent disabling protection.

            1. Do not attempt to remove device admin privileges.
            2. Do not attempt to forcefully uninstall or disable the app.
            3. Usage may be monitored to ensure device safety.
            4. Attempting to bypass security features may result in automatic corrective actions.
            5. Read all conditions before proceeding.
        """.trimIndent()
    }

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Toast.makeText(context, "Device Admin Enabled!", Toast.LENGTH_SHORT).show()
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Toast.makeText(context, "Device Admin Disabled!", Toast.LENGTH_SHORT).show()
    }
}

// =======================================================================================
// === Warning Activity ===
// =======================================================================================

class WarningActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.RED)
            gravity = Gravity.CENTER
            setPadding(50, 50, 50, 50)
        }

        val textView = TextView(this).apply {
            text = """
                🛑 Security alert detected!
                Attempt to disable admin privileges is not allowed.

                Returning to the app...
            """.trimIndent()
            textSize = 24f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
        }

        layout.addView(textView)
        setContentView(layout)

        Handler(Looper.getMainLooper()).post {
            try {
                val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                startActivity(launchIntent)
                finish()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to relaunch app: ${e.message}")
            }
        }
    }
}