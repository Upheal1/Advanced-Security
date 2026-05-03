package com.example.flutter_my_app_main

import android.content.Context
import android.util.Log
import org.tensorflow.lite.task.text.nlclassifier.NLClassifier

class EdgeAIToxicityClassifier(context: Context) {
    private var classifier: NLClassifier? = null

    init {
        try {
            // تحميل النموذج محلياً من مجلد assets
            classifier = NLClassifier.createFromFile(context, "toxicity_model.tflite")
            Log.d("EdgeAI", "Model loaded successfully.")
        } catch (e: Exception) {
            Log.e("EdgeAI", "Error loading model: ${e.message}")
        }
    }

    fun analyzeText(text: String): Float {
        if (classifier == null || text.isBlank()) return 0.0f

        return try {
            val results = classifier?.classify(text)

            // 1. طباعة النتائج في الكونسول عشان تراجع الموديل بيقرأ إيه
            results?.forEach { Log.d("EdgeAI_Debug", "Label: ${it.label}, Score: ${it.score}") }

            // 2. البحث عن أشهر أسماء التصنيفات للمحتوى السيئ
            val toxicResult = results?.find {
                it.label.equals("toxic", ignoreCase = true) ||
                        it.label.equals("negative", ignoreCase = true) ||
                        it.label == "1"
            }

            // 3. لو ملقاش اسم معين، ياخد النتيجة الأعلى كحل بديل
            val finalScore = toxicResult?.score ?: (results?.maxByOrNull { it.score }?.score ?: 0.0f)

            Log.d("EdgeAI", "Final Confidence: $finalScore | Text: $text")
            finalScore
        } catch (e: Exception) {
            Log.e("EdgeAI", "Inference error: ${e.message}")
            0.0f
        }
    }

    fun close() {
        classifier?.close()
    }
}