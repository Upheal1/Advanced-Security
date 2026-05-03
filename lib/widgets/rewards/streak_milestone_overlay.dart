import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StreakMilestoneOverlay {
  static Future<void> show(
    BuildContext context, {
    required int days,
    required String label,
    required int freezeTokens,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _StreakMilestoneSheet(
          days: days,
          label: label,
          freezeTokens: freezeTokens,
        );
      },
    );
  }
}

class _StreakMilestoneSheet extends StatelessWidget {
  final int days;
  final String label;
  final int freezeTokens;

  const _StreakMilestoneSheet({
    required this.days,
    required this.label,
    required this.freezeTokens,
  });

  String get _message {
    switch (days) {
      case 7:
        return "One week clean. Your brain is already rewiring.";
      case 14:
        return "Two weeks. The habit loop is forming.";
      case 30:
        return "One month. You've proven you can do hard things.";
      case 60:
        return "Two months. You're in the top 5% of UpHeal users.";
      case 90:
        return "90 days. This is who you are now.";
      default:
        return "You're building momentum. Keep going gently.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: max(20, bottomInset + safeBottom + 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),

          // Fire emoji
          const Text(
            '🔥',
            style: TextStyle(fontSize: 48),
          )
              .animate(onPlay: (c) => c.repeat())
              .shake(duration: 900.ms, hz: 2, curve: Curves.easeInOut),

          const SizedBox(height: 12),

          // Counting number
          DefaultTextStyle(
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.0,
            ),
            child: TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: days),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Text('$value');
              },
            ),
          ),

          const SizedBox(height: 8),

          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.65),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Text(
              'You have $freezeTokens freeze tokens remaining',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

