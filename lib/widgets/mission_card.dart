import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/mission_model.dart';

class MissionCard extends StatelessWidget {
  const MissionCard({super.key, required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final missions = context.read<MissionsModel>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final bool completed = mission.completed;

    final _EmojiCircle emojiCircle = _buildEmojiCircle(completed);

    Color borderColor;
    Color backgroundColor;

    if (completed) {
      borderColor = const Color(0xFF1D9E75);
      backgroundColor = const Color(0xFF1D9E75).withOpacity(0.04);
    } else {
      borderColor = const Color(0xFFEEEDFE);
      backgroundColor = theme.cardColor;
    }

    return InkWell(
      onTap: () => missions.toggleMission(mission.id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: completed ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          // Left emoji circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: emojiCircle.backgroundColor,
            ),
            alignment: Alignment.center,
            child: Text(
              emojiCircle.emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 12),
          // Title + description
          Expanded(
            child: Opacity(
              opacity: completed ? 0.5 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mission.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // XP pill + animated checkbox
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _XpPill(xpReward: mission.xpReward),
              const SizedBox(height: 8),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed
                      ? const Color(0xFF1D9E75)
                      : Colors.transparent,
                  border: Border.all(
                    color: completed
                        ? const Color(0xFF1D9E75)
                        : const Color(0xFFD3D1C7),
                    width: 2,
                  ),
                ),
                child: completed
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              )
                  .animate(target: completed ? 1 : 0)
                  .scale(
                    duration: 200.ms,
                    curve: Curves.easeOutBack,
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                  ),
            ],
          ),
        ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideX(begin: 0.05, curve: Curves.easeOut);
  }

  _EmojiCircle _buildEmojiCircle(bool completed) {
    String emoji;
    Color baseColor;

    switch (mission.id) {
      case 'm1':
        emoji = '🌬️';
        baseColor = const Color(0xFF1D9E75); // teal
        break;
      case 'm2':
        emoji = '📓';
        baseColor = AppColors.purple;
        break;
      case 'm3':
        emoji = '⚡';
        baseColor = const Color(0xFFBA7517); // amber
        break;
      default:
        emoji = '✅';
        baseColor = Colors.grey;
        break;
    }

    if (completed) {
      baseColor = const Color(0xFF1D9E75);
    }

    return _EmojiCircle(
      emoji: emoji,
      backgroundColor: baseColor.withOpacity(0.15),
    );
  }
}

class _EmojiCircle {
  final String emoji;
  final Color backgroundColor;

  _EmojiCircle({
    required this.emoji,
    required this.backgroundColor,
  });
}

class _XpPill extends StatelessWidget {
  final int xpReward;

  const _XpPill({required this.xpReward});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '+$xpReward XP',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.purple,
            ),
      ),
    );
  }
}

