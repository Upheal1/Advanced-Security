import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

const double _compactBreakpoint = 600;
const double _tabletBreakpoint = 840;
const double _desktopBreakpoint = 1200;

enum AppBreakpoint {
  compact,
  medium,
  expanded,
  large,
}

class AppResponsiveInfo {
  const AppResponsiveInfo._({
    required this.size,
    required this.breakpoint,
    required this.textScale,
  });

  factory AppResponsiveInfo.of(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final Size size = mediaQuery.size;
    final double width = size.width;

    final AppBreakpoint breakpoint = width >= _desktopBreakpoint
        ? AppBreakpoint.large
        : width >= _tabletBreakpoint
            ? AppBreakpoint.expanded
            : width >= _compactBreakpoint
                ? AppBreakpoint.medium
                : AppBreakpoint.compact;

    return AppResponsiveInfo._(
      size: size,
      breakpoint: breakpoint,
      textScale: mediaQuery.textScaler.scale(1),
    );
  }

  final Size size;
  final AppBreakpoint breakpoint;
  final double textScale;

  bool get isCompact => breakpoint == AppBreakpoint.compact;
  bool get isMedium => breakpoint == AppBreakpoint.medium;
  bool get isExpanded => breakpoint == AppBreakpoint.expanded;
  bool get isLarge => breakpoint == AppBreakpoint.large;
  bool get isTabletOrWider => !isCompact;
  bool get useSidebarNavigation => size.width >= _tabletBreakpoint;

  int get contentColumns {
    if (isLarge) {
      return 3;
    }
    if (isTabletOrWider) {
      return 2;
    }
    return 1;
  }

  double get contentMaxWidth {
    if (isLarge) {
      return 1280;
    }
    if (isExpanded) {
      return 1120;
    }
    if (isMedium) {
      return 920;
    }
    return double.infinity;
  }

  double get spacingScale {
    final double breakpointScale = switch (breakpoint) {
      AppBreakpoint.compact => 1,
      AppBreakpoint.medium => 1.08,
      AppBreakpoint.expanded => 1.14,
      AppBreakpoint.large => 1.24,
    };
    final double accessibilityBoost =
        1 + (math.max(0, math.min(textScale - 1, 1)) * 0.18);
    return (breakpointScale * accessibilityBoost).clamp(1, 1.35).toDouble();
  }

  double space(
    double base, {
    double minScale = 1,
    double maxScale = 1.35,
  }) {
    final double scale = spacingScale.clamp(minScale, maxScale).toDouble();
    return base * scale;
  }

  double get horizontalPagePadding {
    final double base = switch (breakpoint) {
      AppBreakpoint.compact => AppSpacing.xl,
      AppBreakpoint.medium => AppSpacing.xxl,
      AppBreakpoint.expanded => AppSpacing.xxxl,
      AppBreakpoint.large => AppSpacing.xxxxl,
    };
    return space(base, minScale: 1, maxScale: 1.5);
  }

  EdgeInsets get pagePadding => EdgeInsets.symmetric(
        horizontal: horizontalPagePadding,
        vertical: space(AppSpacing.lg, minScale: 1, maxScale: 1.25),
      );
}

extension AppResponsiveContext on BuildContext {
  AppResponsiveInfo get responsive => AppResponsiveInfo.of(this);
}

typedef AppResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  AppResponsiveInfo responsive,
);

class AppResponsiveBuilder extends StatelessWidget {
  const AppResponsiveBuilder({
    super.key,
    required this.builder,
  });

  final AppResponsiveWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, context.responsive);
  }
}

class AppPageContainer extends StatelessWidget {
  const AppPageContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxContentWidth,
    this.alignment = Alignment.topCenter,
    this.expand = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxContentWidth;
  final AlignmentGeometry alignment;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final AppResponsiveInfo responsive = context.responsive;
    final double resolvedMaxWidth = maxContentWidth ?? responsive.contentMaxWidth;

    Widget content = child;
    if (resolvedMaxWidth.isFinite) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
        child: content,
      );
    }

    content = Align(
      alignment: alignment,
      child: content,
    );

    if (expand) {
      content = SizedBox(
        width: double.infinity,
        child: content,
      );
    }

    return Padding(
      padding: padding ?? responsive.pagePadding,
      child: content,
    );
  }
}

class AppAdaptiveWrap extends StatelessWidget {
  const AppAdaptiveWrap({
    super.key,
    required this.children,
    this.spacing,
    this.runSpacing,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
  });

  final List<Widget> children;
  final double? spacing;
  final double? runSpacing;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final AppResponsiveInfo responsive = context.responsive;
    return Wrap(
      spacing: spacing ?? responsive.space(AppSpacing.lg),
      runSpacing: runSpacing ?? responsive.space(AppSpacing.lg),
      alignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

class AppResponsiveRoot extends StatelessWidget {
  const AppResponsiveRoot({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: child,
    );
  }
}
