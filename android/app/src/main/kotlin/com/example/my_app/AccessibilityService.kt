package com.example.flutter_my_app_main

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log

/**
 * [DEFENSE RATIONALE]
 * Root Cause: We need a mechanism to read chat inputs to detect cyberbullying.
 * Impact: If this service is killed, the Edge AI gets no data.
 * Implementation: Binds to Android Accessibility API. Captures TYPE_VIEW_TEXT_CHANGED,
 *                 extracts strings, and securely passes them to EdgeThreatDetector.
 */
class MindQuestAccessibilityService : AccessibilityService() {
    private val TAG = "MindQuestAccessibility"

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        if (event.eventType == AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED ||
            event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {

            val textNodes = event.text
            if (textNodes.isNotEmpty()) {
                val capturedText = textNodes.joinToString(" ")
                // Securely pass to Edge AI. Does NOT log the raw text.
                EdgeThreatDetector.onTextCaptured(capturedText)
            }
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility Service Interrupted by OS.")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.i(TAG, "MindQuest Accessibility Service Connected & Active.")
    }
}