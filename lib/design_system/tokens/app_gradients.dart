import 'package:flutter/material.dart';

class AppGradientTheme extends ThemeExtension<AppGradientTheme> {
  const AppGradientTheme({
    required this.heroSurface,
    required this.progressTrack,
    required this.cinematicBackdrop,
  });

  final LinearGradient heroSurface;
  final LinearGradient progressTrack;
  final LinearGradient cinematicBackdrop;

  factory AppGradientTheme.fromColorScheme(ColorScheme scheme) {
    final bool isDark = scheme.brightness == Brightness.dark;
    return AppGradientTheme(
      heroSurface: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          scheme.primary.withValues(alpha: isDark ? 0.30 : 0.16),
          scheme.secondary.withValues(alpha: isDark ? 0.22 : 0.10),
        ],
      ),
      progressTrack: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[scheme.primary, scheme.secondary],
      ),
      cinematicBackdrop: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          scheme.surface.withValues(alpha: isDark ? 0.96 : 1),
          scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.84 : 0.9),
          scheme.surface.withValues(alpha: isDark ? 0.98 : 1),
        ],
      ),
    );
  }

  @override
  AppGradientTheme copyWith({
    LinearGradient? heroSurface,
    LinearGradient? progressTrack,
    LinearGradient? cinematicBackdrop,
  }) {
    return AppGradientTheme(
      heroSurface: heroSurface ?? this.heroSurface,
      progressTrack: progressTrack ?? this.progressTrack,
      cinematicBackdrop: cinematicBackdrop ?? this.cinematicBackdrop,
    );
  }

  @override
  AppGradientTheme lerp(ThemeExtension<AppGradientTheme>? other, double t) {
    if (other is! AppGradientTheme) {
      return this;
    }

    return AppGradientTheme(
      heroSurface: LinearGradient.lerp(heroSurface, other.heroSurface, t) ?? heroSurface,
      progressTrack: LinearGradient.lerp(progressTrack, other.progressTrack, t) ?? progressTrack,
      cinematicBackdrop:
          LinearGradient.lerp(cinematicBackdrop, other.cinematicBackdrop, t) ?? cinematicBackdrop,
    );
  }
}
