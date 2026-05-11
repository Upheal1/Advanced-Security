import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../avatar/services/avatar_provider.dart';
import '../../avatar/ui/avatar_widget.dart';
import '../../constants/app_colors.dart';

/// Challenge hub header: avatar + layered captions + XP chip.
class AvatarHeader extends StatelessWidget {
  final String message;
  final VoidCallback onAvatarTap;

  const AvatarHeader({
    super.key,
    required this.message,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avatarProvider = context.watch<AvatarProvider>();

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : AppColors.textPrimary.withValues(alpha: 0.08);
    final surfaceHi = theme.colorScheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  surfaceHi.withValues(alpha: 0.55),
                  theme.colorScheme.surface.withValues(alpha: 0.35),
                ]
              : [
                  Colors.white.withValues(alpha: 0.92),
                  AppColors.purple.withValues(alpha: 0.04),
                ],
        ),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gradient ring draws focus to the avatar without crowding the layout.
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.purple.withValues(alpha: 0.85),
                  AppColors.green.withValues(alpha: 0.65),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
              ),
              child: AvatarWidget(
                config: avatarProvider.config,
                mood: avatarProvider.mood,
                avatarAssetPath: avatarProvider.selectedAvatarAsset,
                size: 54,
                onTap: onAvatarTap,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.flag,
                      size: 13,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: isDark ? 0.55 : 0.45),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'UPHEAL QUEST',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.15,
                        height: 1.1,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: isDark ? 0.55 : 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    letterSpacing: -0.2,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [
                  AppColors.purple.withValues(alpha: 0.14),
                  AppColors.purple.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.sparkles,
                  size: 14,
                  color: AppColors.purple.withValues(alpha: 0.95),
                ),
                const SizedBox(width: 5),
                Text(
                  'Daily XP',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
