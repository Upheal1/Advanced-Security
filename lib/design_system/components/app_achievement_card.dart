import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'app_card.dart';

class AppAchievementCard extends StatelessWidget {
  const AppAchievementCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.progress,
    this.unlocked = false,
    this.accentColor,
    this.onTap,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final Widget? icon;
  final double? progress;
  final bool unlocked;
  final Color? accentColor;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color resolvedAccent = accentColor ?? (unlocked ? scheme.secondary : scheme.primary);

    return AppCard(
      onTap: onTap,
      semanticLabel: semanticLabel ?? title,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: AppComponentSizes.avatarLg,
                height: AppComponentSizes.avatarLg,
                decoration: BoxDecoration(
                  color: resolvedAccent.withValues(alpha: 0.14),
                  borderRadius: AppRadius.md,
                ),
                child: IconTheme(
                  data: IconThemeData(
                    color: resolvedAccent,
                    size: AppComponentSizes.achievementIcon,
                  ),
                  child: icon ?? const Icon(Icons.workspace_premium_rounded),
                ),
              ),
              const Spacer(),
              AnimatedScale(
                duration: AppMotion.medium,
                scale: unlocked ? 1 : 0.96,
                child: Icon(
                  unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                  color: unlocked ? scheme.secondary : scheme.outline,
                  size: AppIconSizes.lg,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: theme.textTheme.titleMedium),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (progress != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: AppRadius.pill,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress!.clamp(0, 1)),
                duration: AppMotion.slow,
                curve: AppMotion.emphasize,
                builder: (BuildContext context, double value, Widget? child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: AppSpacing.sm,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(resolvedAccent),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
