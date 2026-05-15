import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

enum AppButtonSize { compact, regular }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.trailing,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.isLoading = false,
    this.expand = true,
    this.semanticLabel,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool expand;
  final String? semanticLabel;
  final String? tooltip;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool enabled = widget.onPressed != null && !widget.isLoading;
    final bool compact = widget.size == AppButtonSize.compact;
    final double height = compact
        ? AppComponentSizes.buttonCompactHeight
        : AppComponentSizes.buttonHeight;
    final double minHeight = AppSpacing.adaptive(
      context,
      height,
      minScale: 1,
      maxScale: 1.1,
    );

    final _AppButtonStyle style = _resolveStyle(theme, scheme, enabled);

    Widget child = Semantics(
      button: true,
      enabled: enabled,
      focusable: enabled,
      label: widget.semanticLabel ?? widget.label,
      hint: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip ?? widget.label,
        excludeFromSemantics: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: AnimatedScale(
            duration: AppMotion.fast,
            curve: AppMotion.emphasize,
            scale: _pressed && enabled ? 0.985 : 1,
            child: AnimatedContainer(
              duration: AppMotion.medium,
              curve: AppMotion.standard,
              width: widget.expand ? double.infinity : null,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.adaptive(
                  context,
                  compact ? AppSpacing.lg : AppSpacing.xl,
                  minScale: 1,
                  maxScale: 1.2,
                ),
                vertical: AppSpacing.adaptive(
                  context,
                  compact ? AppSpacing.sm : AppSpacing.md,
                  minScale: 1,
                  maxScale: 1.15,
                ),
              ),
              decoration: BoxDecoration(
                color: style.background,
                gradient: style.gradient,
                borderRadius: AppRadius.pill,
                border: _focused
                    ? Border.all(color: scheme.primary, width: 1.8)
                    : style.border,
                boxShadow: style.shadows,
              ),
              child: DefaultTextStyle(
                style: theme.textTheme.labelLarge!.copyWith(color: style.foreground),
                child: IconTheme(
                  data: IconThemeData(
                    color: style.foreground,
                    size: compact ? AppIconSizes.sm : AppIconSizes.md,
                  ),
                  child: Row(
                    mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (widget.isLoading)
                        const SizedBox(
                          width: AppComponentSizes.loadingIndicator,
                          height: AppComponentSizes.loadingIndicator,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      else if (widget.leading != null)
                        widget.leading!,
                      if (widget.isLoading || widget.leading != null)
                        const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 2,
                          overflow: TextOverflow.fade,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (widget.trailing != null && !widget.isLoading) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        widget.trailing!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    child = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.pill,
        canRequestFocus: enabled,
        focusColor: scheme.primary.withValues(alpha: 0.12),
        hoverColor: scheme.primary.withValues(alpha: 0.05),
        onFocusChange: (bool value) {
          if (_focused != value) {
            setState(() => _focused = value);
          }
        },
        onTap: enabled ? widget.onPressed : null,
        onHighlightChanged: (bool value) {
          if (_pressed != value) {
            setState(() => _pressed = value);
          }
        },
        child: child,
      ),
    );

    return child;
  }

  _AppButtonStyle _resolveStyle(ThemeData theme, ColorScheme scheme, bool enabled) {
    final bool isDark = theme.brightness == Brightness.dark;
    final Color disabledForeground = scheme.onSurface.withValues(alpha: AppEffects.subtleContentAlpha);
    final Color disabledBackground = scheme.surfaceContainerHighest.withValues(
      alpha: isDark ? AppEffects.glassHighlightAlphaDark : AppEffects.glassHighlightAlphaLight,
    );

    if (!enabled) {
      return _AppButtonStyle(
        background: disabledBackground,
        foreground: disabledForeground,
        shadows: const <BoxShadow>[],
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: AppEffects.borderAlphaLight)),
      );
    }

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return _AppButtonStyle(
          foreground: scheme.onPrimary,
          gradient: theme.appGradients.progressTrack,
          shadows: theme.appShadows.focusGlow,
        );
      case AppButtonVariant.secondary:
        return _AppButtonStyle(
          background: scheme.secondaryContainer.withValues(alpha: 0.88),
          foreground: scheme.onSecondaryContainer,
          shadows: theme.appShadows.soft,
          border: Border.all(
            color: scheme.secondary.withValues(alpha: AppEffects.borderAlphaLight),
          ),
        );
      case AppButtonVariant.ghost:
        return _AppButtonStyle(
          background: scheme.surface.withValues(
            alpha: isDark ? AppEffects.glassSurfaceAlphaDark : AppEffects.glassHighlightAlphaLight,
          ),
          foreground: scheme.onSurface,
          shadows: const <BoxShadow>[],
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: AppEffects.borderAlphaLight)),
        );
      case AppButtonVariant.destructive:
        return _AppButtonStyle(
          background: scheme.error,
          foreground: scheme.onError,
          shadows: theme.appShadows.soft,
        );
    }
  }
}

class _AppButtonStyle {
  const _AppButtonStyle({
    this.background,
    required this.foreground,
    this.gradient,
    this.border,
    required this.shadows,
  });

  final Color? background;
  final Color foreground;
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow> shadows;
}
