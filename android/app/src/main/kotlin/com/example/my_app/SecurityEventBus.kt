package com.example.flutter_my_app_main

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import android.util.Log

/**
 * [DEFENSE RATIONALE]
 * Root Cause: Background services (like VPN and Accessibility) run on background
 *             threads and cannot directly communicate with Flutter's UI thread.
 * Impact: App crashes if a background thread attempts to write to a Flutter MethodChannel/EventChannel.
 * Implementation: A thread-safe Singleton EventBus. It queues alerts and ensures
 *                 they are dispatched to the Flutter EventSink strictly on the Main (UI) Looper.
 */
object SecurityEventBus {
    private const val TAG = "SecurityEventBus"
    private var sink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    fun setSink(eventSink: EventChannel.EventSink?) {
        sink = eventSink
        Log.i(TAG, "EventSink attached: ${sink != null}")
    }

    fun push(event: Map<String, Any>) {
        if (sink == null) {
            Log.w(TAG, "Dropped event (No active Flutter UI attached): $event")
            return
        }
        // Force execution on Main Thread
        mainHandler.post {
            try {
                sink?.success(event)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to push event to Flutter: ${e.message}")
            }
        }
    }
}