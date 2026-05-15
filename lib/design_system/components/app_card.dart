import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'app_glass_container.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.footer,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.borderRadius = AppRadius.lg,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? footer;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return AppGlassContainer(
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      onTap: onTap,
      shadows: theme.appShadows.medium,
      semanticLabel: semanticLabel ?? title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null || subtitle != null || leading != null || trailing != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  leading!,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Semantics(
                    header: title != null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (title != null)
                          Text(title!, style: textTheme.titleLarge),
                        if (subtitle != null) ...<Widget>[
                          if (title != null) const SizedBox(height: AppSpacing.xxs),
                          Text(
                            subtitle!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.md),
                  trailing!,
                ],
              ],
            ),
          if (title != null || subtitle != null || leading != null || trailing != null)
            const SizedBox(height: AppSpacing.lg),
          child,
          if (footer != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            footer!,
          ],
        ],
      ),
    );
  }
}
