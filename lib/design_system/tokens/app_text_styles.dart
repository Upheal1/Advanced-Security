import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextTheme create({
    required Brightness brightness,
    required ColorScheme colorScheme,
    TextTheme? base,
  }) {
    final TextTheme fallback = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final TextTheme seed = base ?? fallback;

    return seed
        .copyWith(
          displayLarge: seed.displayLarge?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.05,
            letterSpacing: -1.1,
          ),
          displayMedium: seed.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.08,
            letterSpacing: -0.8,
          ),
          headlineLarge: seed.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.1,
            letterSpacing: -0.6,
          ),
          headlineMedium: seed.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.14,
            letterSpacing: -0.4,
          ),
          headlineSmall: seed.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.16,
            letterSpacing: -0.2,
          ),
          titleLarge: seed.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: -0.15,
          ),
          titleMedium: seed.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
          titleSmall: seed.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
          bodyLarge: seed.bodyLarge?.copyWith(
            fontWeight: FontWeight.w400,
            height: 1.45,
            letterSpacing: 0.1,
          ),
          bodyMedium: seed.bodyMedium?.copyWith(
            fontWeight: FontWeight.w400,
            height: 1.4,
            letterSpacing: 0.1,
          ),
          bodySmall: seed.bodySmall?.copyWith(
            fontWeight: FontWeight.w400,
            height: 1.35,
            letterSpacing: 0.15,
            color: colorScheme.onSurfaceVariant,
          ),
          labelLarge: seed.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          labelMedium: seed.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
          ),
          labelSmall: seed.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
          ),
        )
        .apply(
          displayColor: colorScheme.onSurface,
          bodyColor: colorScheme.onSurface,
        );
  }
}
