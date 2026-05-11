import 'package:flutter/material.dart';

/// Shared calm / premium visuals for the UpHeal community surfaces.
class CommunityDecor {
  CommunityDecor._();

  // ── Brand palette ──────────────────────────────────────────────────────────
  static const Color lavender = Color(0xFF7C6EE6);
  static const Color lavenderLight = Color(0xFFB4AEFF);
  static const Color mint = Color(0xFF4ECDC4);
  static const Color peach = Color(0xFFFF9A8B);
  static const Color roseAccent = Color(0xFFFF6B9D);
  static const Color warmGold = Color(0xFFFFD166);

  // ── Card / surface ─────────────────────────────────────────────────────────

  /// Clean white card with a soft shadow (light) or dark-slate surface (dark).
  static BoxDecoration glassCard(BuildContext context, {double radius = 22}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: isDark ? const Color(0xFF1E2235) : Colors.white,
      border: isDark
          ? Border.all(color: Colors.white.withOpacity(0.07))
          : Border.all(color: const Color(0xFFEEEFF4)),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: const Color(0xFF6B7280).withOpacity(0.07),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  static BoxDecoration pillAccent(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      gradient: LinearGradient(
        colors: [lavender.withOpacity(0.18), mint.withOpacity(0.14)],
      ),
      border: Border.all(color: lavender.withOpacity(0.22)),
    );
  }

  // ── Backgrounds ────────────────────────────────────────────────────────────

  static Gradient calmBackdrop(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF131722), Color(0xFF0F1320), Color(0xFF131722)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF8F9FF), Color(0xFFF1F4FF), Color(0xFFFAF8FF)],
    );
  }

  static Gradient headerGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lavender.withOpacity(0.18), mint.withOpacity(0.10)],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [lavender.withOpacity(0.10), mint.withOpacity(0.07)],
    );
  }

  // ── FAB gradient ───────────────────────────────────────────────────────────
  static const Gradient fabGradient = LinearGradient(
    colors: [lavender, mint],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Shimmer colors ─────────────────────────────────────────────────────────
  static Color shimmerBase(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF232636)
        : const Color(0xFFEEEFF4);
  }

  static Color shimmerHighlight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C3050)
        : const Color(0xFFF8F9FF);
  }
}
