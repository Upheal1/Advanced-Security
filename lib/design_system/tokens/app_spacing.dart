import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class AppSpacing {
  AppSpacing._();

  static const double xxxs = 2;
  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxxl = 40;
  static const double xxxxxl = 48;
  static const double screenPadding = lg;

  static double adaptive(
    BuildContext context,
    double base, {
    double minScale = 1,
    double maxScale = 1.35,
  }) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double shortestSide = mediaQuery.size.shortestSide;
    final double textScale = mediaQuery.textScaler.scale(1);

    double breakpointScale = 1;
    if (shortestSide >= 1200) {
      breakpointScale = 1.24;
    } else if (shortestSide >= 840) {
      breakpointScale = 1.14;
    } else if (shortestSide >= 600) {
      breakpointScale = 1.06;
    }

    final double accessibilityBoost =
        1 + (math.max(0, math.min(textScale - 1, 1)) * 0.18);
    final double scale =
        (breakpointScale * accessibilityBoost).clamp(minScale, maxScale)
            .toDouble();
    return base * scale;
  }

  static EdgeInsets pagePaddingFor(
    BuildContext context, {
    double horizontal = screenPadding,
    double vertical = lg,
  }) {
    return EdgeInsets.symmetric(
      horizontal: adaptive(
        context,
        horizontal,
        minScale: 1,
        maxScale: 1.6,
      ),
      vertical: adaptive(
        context,
        vertical,
        minScale: 1,
        maxScale: 1.25,
      ),
    );
  }
}

extension AppSpacingNumX on num {
  double get space => toDouble();

  EdgeInsets get insetsAll => EdgeInsets.all(toDouble());

  EdgeInsets get insetsHorizontal => EdgeInsets.symmetric(horizontal: toDouble());

  EdgeInsets get insetsVertical => EdgeInsets.symmetric(vertical: toDouble());

  SizedBox get gapH => SizedBox(width: toDouble());

  SizedBox get gapV => SizedBox(height: toDouble());
}

extension AppSpacingContextX on BuildContext {
  double adaptiveSpace(
    double base, {
    double minScale = 1,
    double maxScale = 1.35,
  }) {
    return AppSpacing.adaptive(
      this,
      base,
      minScale: minScale,
      maxScale: maxScale,
    );
  }

  EdgeInsets get pagePadding => AppSpacing.pagePaddingFor(this);
}
