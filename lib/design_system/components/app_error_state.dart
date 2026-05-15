import 'package:flutter/material.dart';

import 'app_empty_state.dart';

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: title,
      message: message,
      icon: const Icon(Icons.error_outline_rounded),
      actionLabel: onRetry == null ? null : retryLabel,
      onAction: onRetry,
      semanticLabel: '$title. $message',
    );
  }
}
