import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';

class ProgressCard extends StatelessWidget {
  final double completion; // 0..1
  final int xpEarnedToday;
  final int tasksCompleted;
  final int tasksTotal;

  const ProgressCard({
    super.key,
    required this.completion,
    required this.xpEarnedToday,
    required this.tasksCompleted,
    required this.tasksTotal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (completion * 100).clamp(0, 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purple.withOpacity(0.20),
            theme.colorScheme.surface.withOpacity(0.35),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Today',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Text(
                  '$percent%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(
                label: 'XP earned',
                value: '$xpEarnedToday',
              ),
              const SizedBox(width: 12),
              _Stat(
                label: 'Completed',
                value: '$tasksCompleted/$tasksTotal',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface.withOpacity(0.45),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
