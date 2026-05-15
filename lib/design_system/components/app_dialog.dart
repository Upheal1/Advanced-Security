import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'app_button.dart';
import 'app_glass_container.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.leading,
    this.actions = const <Widget>[],
    this.semanticLabel,
  });

  final String title;
  final String? message;
  final Widget? content;
  final Widget? leading;
  final List<Widget> actions;
  final String? semanticLabel;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    Widget? leading,
    List<Widget> actions = const <Widget>[],
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: AppElevations.none,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: AppDialog(
          title: title,
          message: message,
          content: content,
          leading: leading,
          actions: actions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Semantics(
      namesRoute: true,
      label: semanticLabel ?? title,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppComponentSizes.dialogMaxWidth),
        child: AppGlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          borderRadius: AppRadius.xl,
          shadows: theme.appShadows.medium,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (leading != null) ...<Widget>[
                leading!,
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(title, style: theme.textTheme.headlineSmall),
              if (message != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (content != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                content!,
              ],
              if (actions.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.end,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppDialogActions extends StatelessWidget {
  const AppDialogActions({
    super.key,
    this.cancelLabel,
    this.confirmLabel,
    this.onCancel,
    this.onConfirm,
    this.confirmVariant = AppButtonVariant.primary,
  });

  final String? cancelLabel;
  final String? confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final AppButtonVariant confirmVariant;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.end,
      children: <Widget>[
        if (cancelLabel != null)
          AppButton(
            label: cancelLabel!,
            onPressed: onCancel,
            variant: AppButtonVariant.ghost,
            expand: false,
          ),
        if (confirmLabel != null)
          AppButton(
            label: confirmLabel!,
            onPressed: onConfirm,
            variant: confirmVariant,
            expand: false,
          ),
      ],
    );
  }
}
