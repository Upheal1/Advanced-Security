import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'app_glass_container.dart';

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding,
    this.showHandle = true,
    this.semanticLabel,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final bool showHandle;
  final String? semanticLabel;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    Widget? trailing,
    bool isScrollControlled = true,
    bool useSafeArea = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: AppEffects.scrimAlpha),
      builder: (BuildContext context) {
        final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: AppBottomSheet(
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Semantics(
      container: true,
      label: semanticLabel ?? title,
      child: AppGlassContainer(
        margin: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xxl, AppSpacing.sm, AppSpacing.sm),
        padding: padding ?? const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        borderRadius: const BorderRadius.vertical(top: AppRadius.xlUnit, bottom: AppRadius.lgUnit),
        shadows: theme.appShadows.medium,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (showHandle)
              Center(
                child: Container(
                  width: AppComponentSizes.bottomSheetHandleWidth,
                  height: AppComponentSizes.bottomSheetHandleHeight,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: AppRadius.pill,
                  ),
                ),
              ),
            if (showHandle) const SizedBox(height: AppSpacing.md),
            if (title != null || subtitle != null || trailing != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (title != null)
                          Text(title!, style: theme.textTheme.titleLarge),
                        if (subtitle != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...<Widget>[
                    const SizedBox(width: AppSpacing.md),
                    trailing!,
                  ],
                ],
              ),
            if (title != null || subtitle != null || trailing != null)
              const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}
