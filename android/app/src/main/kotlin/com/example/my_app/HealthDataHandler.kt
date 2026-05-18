package com.example.flutter_my_app_main

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

class HealthDataHandler(private val context: Context) {
    private val TAG = "HealthDataHandler"
    
    private var healthConnectClient: HealthConnectClient? = null
    private var isHealthConnectAvailable = false
    private var hasStepPermission = false
    
    // Samsung Health package
    private val samsungHealthPackage = "com.sec.android.app.shealth"
    
    // Event channel for real-time step updates
    private var stepEventChannel: EventChannel? = null
    private var stepEventSink: EventChannel.EventSink? = null
    
    fun registerWith(flutterEngine: FlutterEngine) {
        // Method channel for Samsung Health
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.upheal/samsung_health")
            .setMethodCallHandler { call, result ->
                handleSamsungHealthCall(call, result)
            }
        
        // Method channel for Health Connect
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.upheal/health_connect")
            .setMethodCallHandler { call, result ->
                handleHealthConnectCall(call, result)
            }
        
        // Event channel for Health Connect step updates
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.upheal/health_connect/steps")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    stepEventSink = events
                    Log.d(TAG, "Flutter listening to health connect step updates")
                }
                
                override fun onCancel(arguments: Any?) {
                    stepEventSink = null
                    Log.d(TAG, "Flutter stopped listening to health connect step updates")
                }
            })
    }
    
    private fun handleSamsungHealthCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> {
                result.success(isSamsungHealthInstalled())
            }
            "connect" -> {
                // Samsung Health requires the app to be installed
                if (isSamsungHealthInstalled()) {
                    result.success(true)
                } else {
                    result.success(false)
                }
            }
            "requestPermission" -> {
                // Samsung Health uses a different permission model
                // For now, we'll use the device's step sensor as fallback
                result.success(true)
            }
            "getTodaySteps" -> {
                // Get from device sensor as fallback
                result.success(getDeviceStepCount())
            }
            "getStepsForDate" -> {
                val year = call.argument<Int>("year") ?: 0
                val month = call.argument<Int>("month") ?: 0
                val day = call.argument<Int>("day") ?: 0
                result.success(getStepsForDate(year, month, day))
            }
            "getStepHistory" -> {
                result.success(getStepHistoryFromDevice())
            }
            "disconnect" -> {
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun handleHealthConnectCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> {
                result.success(isHealthConnectAvailable)
            }
            "requestPermission" -> {
                requestHealthConnectPermission(result)
            }
            "getTodaySteps" -> {
                getTodayStepsFromHealthConnect(result)
            }
            "getStepsForDate" -> {
                val year = call.argument<Int>("year") ?: 0
                val month = call.argument<Int>("month") ?: 0
                val day = call.argument<Int>("day") ?: 0
                getStepsForDateFromHealthConnect(year, month, day, result)
            }
            "getStepHistory" -> {
                getStepHistoryFromHealthConnect(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun isSamsungHealthInstalled(): Boolean {
        return try {
            context.packageManager.getPackageInfo(samsungHealthPackage, 0)
            true
        } catch (e: Exception) {
            false
        }
    }
    
    private fun getDeviceStepCount(): Int {
        // Use the device's built-in step counter as fallback
        // The actual step counting is done by the Flutter pedometer plugin
        return 0
    }
    
    private fun getStepsForDate(year: Int, month: Int, day: Int): Map<String, Any>? {
        // Samsung Health integration requires the SDK
        // For now, return device sensor data
        return null
    }
    
    private fun getStepHistoryFromDevice(): List<Map<String, Any>> {
        // Samsung Health integration requires the SDK
        return emptyList()
    }
    
    private fun isHealthConnectInstalled(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                context.packageManager.getPackageInfo("com.google.android.apps.healthdata", 0)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }
    
    private fun requestHealthConnectPermission(result: MethodChannel.Result) {
        // Health Connect requires runtime permission request
        // This would need to be done through an activity
        hasStepPermission = isHealthConnectInstalled()
        result.success(hasStepPermission)
    }
    
    private fun getTodayStepsFromHealthConnect(result: MethodChannel.Result) {
        if (!hasStepPermission) {
            result.success(0)
            return
        }
        
        // In a full implementation, this would query Health Connect
        result.success(0)
    }
    
    private fun getStepsForDateFromHealthConnect(year: Int, month: Int, day: Int, result: MethodChannel.Result) {
        if (!hasStepPermission) {
            result.success(null)
            return
        }
        
        result.success(null)
    }
    
    private fun getStepHistoryFromHealthConnect(result: MethodChannel.Result) {
        if (!hasStepPermission) {
            result.success(emptyList<Map<String, Any>>())
            return
        }
        
        result.success(emptyList<Map<String, Any>>())
    }
    
    fun dispose() {
        healthConnectClient = null
        stepEventSink = null
    }
}

// Extension function to add method channel handler
fun MethodChannel.setMethodCallHandler(handler: (MethodCall, MethodChannel.Result) -> Unit) {
    this.setMethodCallHandler(object : MethodChannel.MethodCallHandler {
        override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
            handler(call, result)
        }
    })
}