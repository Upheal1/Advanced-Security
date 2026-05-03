package com.example.flutter_my_app_main

import android.util.Log
import java.util.Timer
import java.util.TimerTask
import java.util.concurrent.atomic.AtomicBoolean

/**
 * [DEFENSE RATIONALE]
 * Root Cause: Sending every keystroke to a cloud server for threat analysis
 *             violates GDPR and compromises child privacy.
 * Impact: Cloud API delays, massive battery drain, and legal liability.
 * Implementation: On-Device Processing (Edge AI). We buffer keystrokes using a
 *                 3000ms Debouncer. The raw text is analyzed locally. If a threat
 *                 is found, ONLY the metadata (alert type) is sent.
 *                 CRITICAL: Raw text memory is wiped (cleared) immediately.
 */
object EdgeThreatDetector {
    private const val TAG = "EdgeThreatDetector"
    private const val DEBOUNCE_DELAY_MS = 3000L // Process every 3 seconds

    private var textBuffer = StringBuilder()
    private var timer: Timer? = null
    private val isProcessing = AtomicBoolean(false)

    // Heuristic pattern engine simulating a local ML model
    private val threatKeywords = listOf(
        "kill myself", "hate my life", "bully", "depressed", "worthless", "suicide"
    )

    fun onTextCaptured(newText: String) {
        if (newText.isBlank()) return

        synchronized(this) {
            textBuffer.append(newText).append(" ")
        }
        resetDebouncer()
    }

    private fun resetDebouncer() {
        timer?.cancel()
        timer = Timer().apply {
            schedule(object : TimerTask() {
                override fun run() {
                    analyzeAndWipeMemory()
                }
            }, DEBOUNCE_DELAY_MS)
        }
    }

    private fun analyzeAndWipeMemory() {
        if (!isProcessing.compareAndSet(false, true)) return

        val textToAnalyze: String
        synchronized(this) {
            textToAnalyze = textBuffer.toString().lowercase()
            // CRITICAL PRIVACY RULE: Wipe memory immediately
            textBuffer.clear()
        }

        if (textToAnalyze.isNotBlank()) {
            Log.d(TAG, "Edge AI analyzing ${textToAnalyze.length} characters locally...")

            var confidenceScore = 0.0
            var detectedThreat = "None"

            for (keyword in threatKeywords) {
                if (textToAnalyze.contains(keyword)) {
                    confidenceScore += 0.86 // Exceeds 0.85 threshold
                    detectedThreat = "Potential Self-Harm / Cyberbullying"
                    break
                }
            }

            // ACTION
            if (confidenceScore > 0.85) {
                Log.w(TAG, "THREAT DETECTED. Alerting Flutter.")

                SecurityEventBus.push(mapOf(
                    "type" to "CONTENT_THREAT",
                    "confidence" to confidenceScore,
                    "category" to detectedThreat,
                    "timestamp" to System.currentTimeMillis()
                ))
            }
        }
        isProcessing.set(false)
    }
}