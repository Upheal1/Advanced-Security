import 'package:flutter/material.dart';

import '../design_system/tokens/design_tokens.dart';

class AppColors {
  AppColors._();

  // Brand per spec
  static const Color purple = Color(0xFF7C3AED); 
  static const Color blue = Color(0xFF3B82F6);   
  static const Color teal = Color(0xFF14B8A6);   
  static const Color orange = Color(0xFFF97316); 
  static const Color pink = Color(0xFFEC4899);   
  static const Color green = Color(0xFF45D9A8);  
  static const Color red = Color(0xFFFF6B6B);    
  static const Color surface = Color(0xFFF7F8FA);
  static const Color surfaceDark = Color(0xFF111318);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  // Focus Blocker Colors
  static const Color primary = Color(0xFF6B46C1);
  static const Color secondary = Color(0xFF45D9A8);
  static const Color background = Color(0xFF0F0F23);
  static const Color card = Color(0xFF16213E);
  static const Color textMuted = Color(0xFF808080);
  static const Color success = Color(0xFF45D9A8);
  static const Color warning = Color(0xFFFFB347);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF4ECDC4);
  // Focus Blocker Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF6B46C1),
    Color(0xFF8B5CF6),
  ];
  
  static const List<Color> secondaryGradient = [
    Color(0xFF45D9A8),
    Color(0xFF4ECDC4),
  ];
  
  static const List<Color> backgroundGradient = [
    Color(0xFF0F0F23),
    Color(0xFF1A1A2E),
  ];

  // Gradient combinations for backgrounds
  static const List<Color> purpleToTeal = [purple, teal];

  static const List<Color> orangeToPink = [orange, pink];

  static LinearGradient backgroundPurpleTeal({Alignment begin = Alignment.topLeft, Alignment end = Alignment.bottomRight}) =>
      LinearGradient(begin: begin, end: end, colors: purpleToTeal);

  static LinearGradient backgroundOrangePink({Alignment begin = Alignment.topLeft, Alignment end = Alignment.bottomRight}) =>
      LinearGradient(begin: begin, end: end, colors: orangeToPink);
}

ThemeData buildTheme(
  Brightness brightness, {
  TextTheme? baseTextTheme,
}) {
  final bool isDark = brightness == Brightness.dark;
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.purple,
    brightness: brightness,
  );
  final TextTheme textTheme = AppTextStyles.create(
    brightness: brightness,
    colorScheme: colorScheme,
    base: baseTextTheme,
  );
  final AppShadowTheme shadowTheme = AppShadowTheme.fromBrightness(brightness);
  final AppGradientTheme gradientTheme = AppGradientTheme.fromColorScheme(colorScheme);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
    focusColor: colorScheme.primary.withValues(alpha: 0.14),
    hoverColor: colorScheme.primary.withValues(alpha: 0.06),
    dividerColor: colorScheme.outlineVariant.withValues(
      alpha: isDark ? 0.45 : 0.7,
    ),
    extensions: <ThemeExtension<dynamic>>[
      shadowTheme,
      gradientTheme,
    ],
    cardTheme: CardThemeData(
      elevation: AppElevations.none,
      margin: EdgeInsets.zero,
      shadowColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.xlUnit),
      ),
      showDragHandle: true,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: AppElevations.none,
      scrolledUnderElevation: AppElevations.none,
      titleTextStyle: textTheme.titleLarge,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      elevation: AppElevations.lg,
      selectedIconTheme: IconThemeData(size: AppIconSizes.md),
      unselectedIconTheme: IconThemeData(size: AppIconSizes.md),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: isDark
          ? const Color(0xFF171A22)
          : Colors.white.withValues(alpha: 0.96),
      surfaceTintColor: Colors.transparent,
      indicatorColor: colorScheme.secondaryContainer.withValues(
        alpha: isDark ? 0.9 : 0.8,
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final TextStyle base = textTheme.labelMedium ?? const TextStyle();
        if (states.contains(WidgetState.selected)) {
          return base.copyWith(
            color: colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w700,
          );
        }
        return base.copyWith(color: colorScheme.onSurfaceVariant);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: colorScheme.onSecondaryContainer,
            size: AppIconSizes.md,
          );
        }
        return IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: AppIconSizes.md,
        );
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      useIndicator: true,
      indicatorColor: colorScheme.secondaryContainer.withValues(
        alpha: isDark ? 0.9 : 0.8,
      ),
      selectedIconTheme: IconThemeData(
        color: colorScheme.onSecondaryContainer,
        size: AppIconSizes.lg,
      ),
      unselectedIconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: AppIconSizes.lg,
      ),
      selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: colorScheme.onSecondaryContainer,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 450),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface,
        borderRadius: AppRadius.md,
      ),
      textStyle: textTheme.bodySmall?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: AppElevations.none,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        textStyle: textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: const OutlineInputBorder(borderRadius: AppRadius.md),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: colorScheme.primary),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxxs,
      ),
      selectedColor: colorScheme.primaryContainer,
      backgroundColor: colorScheme.surfaceContainerHighest,
      labelStyle: textTheme.labelMedium,
    ),
  );
}


