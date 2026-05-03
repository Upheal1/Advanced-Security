package com.example.flutter_my_app_main

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.util.Log

private const val TAG = "UsageStatsUtils"

object UsageStatsUtils {

    fun hasUsageAccessPermission(context: Context): Boolean {
        return try {
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
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            Log.e(TAG, "Error checking usage access permission: ${e.message}")
            false
        }
    }

    fun requestUsageAccessPermission(context: Context) {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening usage access settings: ${e.message}")
        }
    }

    fun getForegroundApp(context: Context): String? {
        return try {
            if (!hasUsageAccessPermission(context)) return null

            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val currentTime = System.currentTimeMillis()
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                currentTime - 1000 * 60 * 60 * 24, // Last 24 hours
                currentTime
            )

            if (stats != null && stats.isNotEmpty()) {
                // Find the most recent app
                val mostRecent = stats.maxByOrNull { it.lastTimeUsed }
                mostRecent?.packageName
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting foreground app: ${e.message}")
            null
        }
    }

    fun getInstalledApps(context: Context): List<Map<String, Any>> {
        val apps = mutableListOf<Map<String, Any>>()
        
        try {
            val packageManager = context.packageManager
            val installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)

            for (appInfo in installedApps) {
                // Skip system apps or apps without launch intent (services)
                if (appInfo.packageName == context.packageName) continue // Skip our own app

                // Check if app has a launch intent (user-launchable app)
                val launchIntent = packageManager.getLaunchIntentForPackage(appInfo.packageName)
                if (launchIntent == null) continue // Skip services without UI

                try {
                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                    val app = mapOf(
                        "appName" to appName,
                        "packageName" to appInfo.packageName,
                        "iconPath" to appInfo.packageName // Using package name as icon identifier
                    )
                    apps.add(app)
                } catch (e: Exception) {
                    Log.w(TAG, "Error getting app info for ${appInfo.packageName}: ${e.message}")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting installed apps: ${e.message}")
        }

        // Sort by app name
        apps.sortBy { it["appName"] as String }

        return apps
    }
}
