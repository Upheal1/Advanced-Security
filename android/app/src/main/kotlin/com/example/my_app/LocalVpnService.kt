package com.example.flutter_my_app_main

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log

class LocalVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val domains = intent?.getStringArrayListExtra("blocked_domains") ?: arrayListOf()
        Log.d("LocalVpnService", "Starting VPN... Blocked domains: $domains")

        setupVpn()
        return START_STICKY
    }

    private fun setupVpn() {
        if (vpnInterface != null) return

        try {
            val builder = Builder()

            // إعدادات الـ VPN الوهمي لفلترة الداتا
            builder.addAddress("10.0.0.2", 32)
            builder.addRoute("0.0.0.0", 0) // توجيه كل الترافيك للـ VPN
            builder.addDnsServer("8.8.8.8")
            builder.setSession("UpHeal Shield")

            // النقطة السحرية: إنشاء واجهة الـ VPN لتفعيل المفتاح 🔑
            vpnInterface = builder.establish()

            Log.d("LocalVpnService", "VPN established successfully! 🔑")
        } catch (e: Exception) {
            Log.e("LocalVpnService", "Error establishing VPN: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            vpnInterface?.close()
            vpnInterface = null
            Log.d("LocalVpnService", "VPN Disconnected")
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}