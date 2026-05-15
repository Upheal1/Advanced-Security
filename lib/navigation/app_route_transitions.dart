import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/tokens/design_tokens.dart';

class AppRouteTransitions {
  AppRouteTransitions._();

  static CustomTransitionPage<T> buildPage<T>({
    required GoRouterState state,
    required Widget child,
    bool fullscreenDialog = false,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      name: state.name,
      child: child,
      fullscreenDialog: fullscreenDialog,
      transitionDuration: AppMotion.fast,
      reverseTransitionDuration: AppMotion.fast,
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final Animation<double> fade = CurvedAnimation(
          parent: animation,
          curve: AppMotion.standard,
          reverseCurve: AppMotion.exit,
        );
        final Animation<Offset> slide = Tween<Offset>(
          begin: const Offset(0.035, 0),
          end: Offset.zero,
        ).animate(fade);

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}
