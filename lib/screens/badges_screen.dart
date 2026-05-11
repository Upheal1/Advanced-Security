import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/badge_model.dart';
import '../services/badge_provider.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0D12) : theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Badges',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: Consumer<BadgeProvider>(
        builder: (context, provider, _) {
          final earned = provider.earned;
          final locked = provider.locked;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              _SectionHeader(
                title: 'Earned',
                subtitle: '${earned.length} unlocked',
              ),
              const SizedBox(height: 12),
              if (earned.isEmpty)
                _EmptyState(
                  title: 'No badges yet',
                  subtitle: 'Complete streaks and challenges to unlock badges.',
                )
              else
                _BadgesGrid(badges: earned, locked: false),
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'Locked',
                subtitle: '${locked.length} remaining',
              ),
              const SizedBox(height: 12),
              _BadgesGrid(badges: locked, locked: true),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
      ],
    );
  }
}

class _BadgesGrid extends StatelessWidget {
  final List<BadgeModel> badges;
  final bool locked;

  const _BadgesGrid({required this.badges, required this.locked});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final b = badges[index];
        return _BadgeTile(badge: b, isLocked: locked)
            .animate()
            .fadeIn(duration: 220.ms, delay: (index * 35).ms)
            .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1));
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeModel badge;
  final bool isLocked;

  const _BadgeTile({required this.badge, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final glow = !isLocked;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface.withOpacity(0.55),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.purple.withOpacity(0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Opacity(
        opacity: isLocked ? 0.45 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: _BadgeIcon(path: badge.iconPath, locked: isLocked),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              badge.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isLocked ? 'Unlock at ${badge.requiredValue}' : 'Unlocked',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isLocked ? onSurface.withOpacity(0.6) : AppColors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final String path;
  final bool locked;

  const _BadgeIcon({required this.path, required this.locked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallback = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.onSurface.withOpacity(0.08),
      ),
      alignment: Alignment.center,
      child: Text(
        locked ? '🔒' : '🏅',
        style: const TextStyle(fontSize: 22),
      ),
    );

    if (path.isEmpty) return fallback;

    return Image.asset(
      path,
      width: 52,
      height: 52,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface.withOpacity(0.55),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
