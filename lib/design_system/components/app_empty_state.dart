import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'app_button.dart';
import 'app_glass_container.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.semanticLabel,
  });

  final String title;
  final String message;
  final Widget? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticLabel ?? '$title. $message',
      child: Center(
        child: AppGlassContainer(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          borderRadius: AppRadius.xl,
          gradient: theme.appGradients.heroSurface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.78),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: IconTheme(
                    data: IconThemeData(
                      size: AppComponentSizes.avatarLg,
                      color: scheme.onPrimaryContainer,
                    ),
                    child: icon ?? const Icon(Icons.auto_awesome_rounded),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (actionLabel != null && onAction != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  expand: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
