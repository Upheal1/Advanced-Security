import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'app_glass_container.dart';

class AppLoadingState extends StatefulWidget {
  const AppLoadingState({
    super.key,
    this.message,
    this.semanticLabel,
  });

  final String? message;
  final String? semanticLabel;

  @override
  State<AppLoadingState> createState() => _AppLoadingStateState();
}

class _AppLoadingStateState extends State<AppLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.celebratory,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Semantics(
      liveRegion: true,
      label: widget.semanticLabel ?? widget.message ?? 'Loading',
      child: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          child: AppGlassContainer(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            borderRadius: AppRadius.xl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: AppComponentSizes.loadingIndicatorLg,
                  height: AppComponentSizes.loadingIndicatorLg,
                  child: CircularProgressIndicator(
                    strokeWidth: AppElevations.md,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                  ),
                ),
                if (widget.message != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    widget.message!,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
