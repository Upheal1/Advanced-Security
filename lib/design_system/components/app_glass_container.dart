import 'dart:ui';

import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

class AppGlassContainer extends StatelessWidget {
  const AppGlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.borderRadius = AppRadius.lg,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    this.blurSigma = AppEffects.blurMd,
    this.shadows,
    this.alignment,
    this.width,
    this.height,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blurSigma;
  final List<BoxShadow>? shadows;
  final AlignmentGeometry? alignment;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color resolvedBackground = backgroundColor ??
        scheme.surface.withValues(
          alpha: isDark ? AppEffects.glassSurfaceAlphaDark : AppEffects.glassSurfaceAlphaLight,
        );
    final Color resolvedBorder = borderColor ??
        scheme.outlineVariant.withValues(
          alpha: isDark ? AppEffects.borderAlphaDark : AppEffects.borderAlphaLight,
        );

    final Widget content = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          width: width,
          height: height,
          alignment: alignment,
          padding: padding,
          decoration: BoxDecoration(
            color: resolvedBackground,
            gradient: gradient,
            borderRadius: borderRadius,
            border: Border.all(color: resolvedBorder),
            boxShadow: shadows ?? theme.appShadows.soft,
          ),
          child: child,
        ),
      ),
    );

    final Widget wrapped = onTap == null
        ? content
        : Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: borderRadius,
              canRequestFocus: true,
              focusColor: scheme.primary.withValues(alpha: 0.12),
              hoverColor: scheme.primary.withValues(alpha: 0.05),
              onTap: onTap,
              child: content,
            ),
          );

    return Semantics(
      container: true,
      button: onTap != null,
      enabled: onTap != null,
      label: semanticLabel,
      child: Padding(
        padding: margin ?? EdgeInsets.zero,
        child: wrapped,
      ),
    );
  }
}
