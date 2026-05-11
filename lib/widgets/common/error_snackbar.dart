import 'package:flutter/material.dart';
import '../../services/error_handler_service.dart';

class ErrorSnackBar {
  static SnackBar build({
    required ErrorMessageType type,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final Color bgColor;
    final Color fgColor;

    switch (type) {
      case ErrorMessageType.success:
        bgColor = const Color(0xFF0F9D58);
        fgColor = Colors.white;
        break;
      case ErrorMessageType.info:
        bgColor = const Color(0xFF1E88E5);
        fgColor = Colors.white;
        break;
      case ErrorMessageType.error:
        bgColor = const Color(0xFFd32f2f);
        fgColor = Colors.white;
        break;
    }

    return SnackBar(
      content: Text(
        message,
        style: TextStyle(color: fgColor, fontWeight: FontWeight.w600),
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: fgColor,
              onPressed: onAction ?? () {},
            )
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
