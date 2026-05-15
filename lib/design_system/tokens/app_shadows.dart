import 'package:flutter/material.dart';

class AppShadowTheme extends ThemeExtension<AppShadowTheme> {
  const AppShadowTheme({
    required this.soft,
    required this.medium,
    required this.focusGlow,
  });

  final List<BoxShadow> soft;
  final List<BoxShadow> medium;
  final List<BoxShadow> focusGlow;

  factory AppShadowTheme.fromBrightness(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    return AppShadowTheme(
      soft: <BoxShadow>[
        BoxShadow(
          color: isDark
              ? const Color(0x33000000)
              : const Color(0x140F172A),
          blurRadius: isDark ? 20 : 16,
          offset: const Offset(0, 8),
        ),
      ],
      medium: <BoxShadow>[
        BoxShadow(
          color: isDark
              ? const Color(0x40000000)
              : const Color(0x1F0F172A),
          blurRadius: isDark ? 28 : 22,
          offset: const Offset(0, 12),
        ),
      ],
      focusGlow: <BoxShadow>[
        BoxShadow(
          color: isDark
              ? const Color(0x336B46C1)
              : const Color(0x296B46C1),
          blurRadius: 24,
          spreadRadius: 1,
        ),
      ],
    );
  }

  @override
  AppShadowTheme copyWith({
    List<BoxShadow>? soft,
    List<BoxShadow>? medium,
    List<BoxShadow>? focusGlow,
  }) {
    return AppShadowTheme(
      soft: soft ?? this.soft,
      medium: medium ?? this.medium,
      focusGlow: focusGlow ?? this.focusGlow,
    );
  }

  @override
  AppShadowTheme lerp(ThemeExtension<AppShadowTheme>? other, double t) {
    if (other is! AppShadowTheme) {
      return this;
    }

    return AppShadowTheme(
      soft: BoxShadow.lerpList(soft, other.soft, t) ?? soft,
      medium: BoxShadow.lerpList(medium, other.medium, t) ?? medium,
      focusGlow: BoxShadow.lerpList(focusGlow, other.focusGlow, t) ?? focusGlow,
    );
  }
}
