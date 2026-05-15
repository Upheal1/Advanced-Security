import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

enum AppAvatarSize { sm, md, lg, xl, xxl }

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageProvider,
    this.imageUrl,
    this.initials,
    this.semanticLabel,
    this.level,
    this.progress,
    this.size = AppAvatarSize.lg,
    this.accentColor,
  });

  final ImageProvider<Object>? imageProvider;
  final String? imageUrl;
  final String? initials;
  final String? semanticLabel;
  final int? level;
  final double? progress;
  final AppAvatarSize size;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double avatarSize = _sizeValue(size);
    final Color resolvedAccent = accentColor ?? scheme.primary;
    final ImageProvider<Object>? resolvedImage = imageProvider ??
        (imageUrl == null ? null : NetworkImage(imageUrl!));

    final Widget avatarBody = Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[
            resolvedAccent,
            scheme.secondary,
          ],
        ),
        boxShadow: theme.appShadows.soft,
      ),
      padding: const EdgeInsets.all(AppSpacing.xxxs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surface,
          image: resolvedImage == null
              ? null
              : DecorationImage(image: resolvedImage, fit: BoxFit.cover),
        ),
        child: resolvedImage == null
            ? Center(
                child: Text(
                  _resolveInitials(initials),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : null,
      ),
    );

    return Semantics(
      image: true,
      label: semanticLabel ?? initials ?? 'Avatar',
      child: SizedBox(
        width: avatarSize + AppSpacing.lg,
        height: avatarSize + AppSpacing.lg,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: progress == null
                  ? avatarBody
                  : TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress!.clamp(0, 1)),
                      duration: AppMotion.slow,
                      curve: AppMotion.emphasize,
                      builder: (BuildContext context, double value, Widget? child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: avatarSize + AppSpacing.xxs,
                              height: avatarSize + AppSpacing.xxs,
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: AppSpacing.xxs,
                                backgroundColor: scheme.outlineVariant.withValues(alpha: 0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(resolvedAccent),
                              ),
                            ),
                            child!,
                          ],
                        );
                      },
                      child: avatarBody,
                    ),
            ),
            if (level != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxxs,
                  ),
                  decoration: BoxDecoration(
                    gradient: theme.appGradients.progressTrack,
                    borderRadius: AppRadius.pill,
                    boxShadow: theme.appShadows.focusGlow,
                  ),
                  child: Text(
                    'Lv $level',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _sizeValue(AppAvatarSize size) {
    switch (size) {
      case AppAvatarSize.sm:
        return AppComponentSizes.avatarSm;
      case AppAvatarSize.md:
        return AppComponentSizes.avatarMd;
      case AppAvatarSize.lg:
        return AppComponentSizes.avatarLg;
      case AppAvatarSize.xl:
        return AppComponentSizes.avatarXl;
      case AppAvatarSize.xxl:
        return AppComponentSizes.avatarXxl;
    }
  }

  String _resolveInitials(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'U';
    }
    final List<String> parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.take(1).toString().toUpperCase();
    }
    return (parts.first.characters.take(1).toString() +
            parts.last.characters.take(1).toString())
        .toUpperCase();
  }
}
