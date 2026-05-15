import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.onTap,
    this.leading,
    this.selected = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool selected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color background = selected
        ? scheme.primaryContainer.withValues(alpha: 0.92)
        : scheme.surface.withValues(
            alpha: isDark ? AppEffects.glassSurfaceAlphaDark : AppEffects.glassHighlightAlphaLight,
          );
    final Color foreground = selected ? scheme.onPrimaryContainer : scheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.pill,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadius.pill,
              border: Border.all(
                color: selected
                    ? scheme.primary.withValues(alpha: AppEffects.borderAlphaDark)
                    : scheme.outlineVariant.withValues(alpha: AppEffects.borderAlphaLight),
              ),
              boxShadow: selected ? theme.appShadows.soft : const <BoxShadow>[],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  IconTheme(
                    data: IconThemeData(color: foreground, size: AppIconSizes.sm),
                    child: leading!,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
