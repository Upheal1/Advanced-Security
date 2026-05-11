import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class BlockFeedbackOverlay {
  static void show({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _BlockFeedbackOverlayEntry(
        message: message,
        duration: duration,
        onDismiss: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _BlockFeedbackOverlayEntry extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback onDismiss;

  const _BlockFeedbackOverlayEntry({
    required this.message,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_BlockFeedbackOverlayEntry> createState() =>
      _BlockFeedbackOverlayEntryState();
}

class _BlockFeedbackOverlayEntryState
    extends State<_BlockFeedbackOverlayEntry> {
  double _opacity = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _opacity = 1.0;
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    setState(() {
      _opacity = 0.0;
    });
    Future.delayed(const Duration(milliseconds: 200), widget.onDismiss);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : AppColors.textPrimary.withOpacity(0.1);

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: SafeArea(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppColors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _dismiss,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          isDark ? AppColors.purple : AppColors.teal,
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
