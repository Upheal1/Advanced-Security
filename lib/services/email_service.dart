// lib/services/email_service.dart
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../config.dart';

class EmailService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// إرسال OTP للمستخدم عبر البريد
  static Future<void> sendOtp(String toEmail, String otp) async {
    try {
      // 🔹 أولاً: محاولة إرسال عبر SMTP إذا متاح
      if (SMTP_USERNAME.isNotEmpty && SMTP_PASSWORD.isNotEmpty) {
        final ok = await _sendEmailRaw(
          toEmail,
          'UpHeal OTP Verification',
          'Your OTP code is: $otp\n\nDo not share it with anyone.',
        );

        if (ok) return;
      }

      // 🔹 fallback للتطوير: طباعة OTP في الكونسل
      if (kDebugMode) {
        print('*** OTP fallback (email failed or SMTP not configured) for $toEmail => $otp ***');
      }
    } catch (e) {
      if (kDebugMode) print('Failed to send OTP: $e');
    }
  }

  /// إرسال طلب إعادة تعيين كلمة المرور
  static Future<void> sendPasswordResetRequest(String toEmail) async {
    try {
      if (SMTP_USERNAME.isNotEmpty && SMTP_PASSWORD.isNotEmpty) {
        final ok = await _sendEmailRaw(
          toEmail,
          'UpHeal Password Reset',
          'We received a request to reset your password.\n'
          'If this was you, please follow the instructions in the app.\n'
          'If not, ignore this message.',
        );
        if (ok) return;
      }

      // 🔹 إذا لم يتم تكوين SMTP أو فشل، نرسل عبر Firebase Auth
      await _auth.sendPasswordResetEmail(email: toEmail);

      if (kDebugMode) print('Password reset email sent to $toEmail');
    } catch (e) {
      if (kDebugMode) print('Failed to send password reset email: $e');
    }
  }

  /// دالة مساعدة لإرسال البريد عبر SMTP
  static Future<bool> _sendEmailRaw(String toEmail, String subject, String body) async {
    if (SMTP_USERNAME.isEmpty || SMTP_PASSWORD.isEmpty) {
      if (kDebugMode) print('*** SMTP not configured. Email not sent to $toEmail ***');
      return false;
    }

    final smtpServer = SmtpServer(
      SMTP_HOST,
      port: SMTP_PORT,
      username: SMTP_USERNAME,
      password: SMTP_PASSWORD,
      ssl: SMTP_PORT == 465,
      ignoreBadCertificate: true,
    );

    final message = Message()
      ..from = Address(FROM_EMAIL, FROM_NAME)
      ..recipients.add(toEmail)
      ..subject = subject
      ..text = body;

    try {
      final sendReport = await send(message, smtpServer);
      if (kDebugMode) print('Email sent: $sendReport');
      return true;
    } on MailerException catch (e) {
      if (kDebugMode) print('MailerException: ${e.toString()}');
      for (var p in e.problems) {
        if (kDebugMode) print(' - problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Unexpected email error: $e');
      return false;
    }
  }
}
