package com.example.flutter_my_app_main

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import org.tensorflow.lite.task.vision.classifier.ImageClassifier

class EdgeAIVisionClassifier(context: Context) {
    private var imageClassifier: ImageClassifier? = null

    init {
        try {
            // تحميل الموديل من مجلد assets
            val options = ImageClassifier.ImageClassifierOptions.builder()
                .setMaxResults(3)
                .build()
            imageClassifier = ImageClassifier.createFromFileAndOptions(context, "nsfw_model.tflite", options)
            Log.d("EdgeAIVision", "Vision Model loaded successfully.")
        } catch (e: Exception) {
            Log.e("EdgeAIVision", "Error loading vision model. Make sure nsfw_model.tflite is in assets folder: ${e.message}")
        }
    }

    fun analyzeImage(bitmap: Bitmap): Boolean {
        if (imageClassifier == null) return false

        return try {
            val tensorImage = org.tensorflow.lite.support.image.TensorImage.fromBitmap(bitmap)
            val results = imageClassifier?.classify(tensorImage)

            var isNsfw = false
            results?.forEach { classification ->
                classification.categories.forEach { category ->
                    // يمكنك مراجعة الكونسول لمعرفة التسميات الدقيقة التي يخرجها الموديل الخاص بك
                    Log.d("EdgeAIVision", "Detected: ${category.label} - Score: ${category.score}")

                    // إذا كان التصنيف غير لائق وبنسبة ثقة أعلى من 70%
                    if ((category.label.equals("nsfw", ignoreCase = true) ||
                                category.label.equals("porn", ignoreCase = true) ||
                                category.label.equals("hentai", ignoreCase = true)) &&
                        category.score > 0.70f) {
                        isNsfw = true
                    }
                }
            }
            isNsfw
        } catch (e: Exception) {
            Log.e("EdgeAIVision", "Vision Inference error: ${e.message}")
            false
        }
    }

    fun close() {
        imageClassifier?.close()
    }
}