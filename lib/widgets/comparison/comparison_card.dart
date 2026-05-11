import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/comparison_data.dart';
import '../common/app_icon_widget.dart';

/// Card widget for displaying comparison metrics
class ComparisonCard extends StatelessWidget {
  final String title;
  final String currentValue;
  final String previousValue;
  final double changePercent;
  final TrendDirection trend;
  final IconData icon;
  final VoidCallback? onTap;
  final bool invertColors; // For cases where "up" is good (e.g., productivity)

  const ComparisonCard({
    super.key,
    required this.title,
    required this.currentValue,
    required this.previousValue,
    required this.changePercent,
    required this.trend,
    required this.icon,
    this.onTap,
    this.invertColors = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = invertColors ? trend == TrendDirection.up : trend == TrendDirection.down;
    final isNegative = invertColors ? trend == TrendDirection.down : trend == TrendDirection.up;
    
    final primaryColor = isPositive
        ? const Color(0xFF10B981) // Green
        : isNegative
            ? const Color(0xFFEF4444) // Red
            : const Color(0xFF6B7280); // Gray

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                // Trend indicator
                _buildTrendBadge(primaryColor, isDark),
              ],
            ),
            const SizedBox(height: 16),
            // Current value (large)
            Text(
              currentValue,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Previous value comparison
            Row(
              children: [
                Text(
                  'vs $previousValue',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(width: 8),
                _buildChangeIndicator(primaryColor),
              ],
            ),
            // Tap hint
            if (onTap != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap for details',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 12,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTrendBadge(Color color, bool isDark) {
    final icon = trend == TrendDirection.up
        ? LucideIcons.trendingUp
        : trend == TrendDirection.down
            ? LucideIcons.trendingDown
            : LucideIcons.minus;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${changePercent.abs().toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeIndicator(Color color) {
    final prefix = changePercent >= 0 ? '+' : '';
    final changeText = '$prefix${changePercent.toStringAsFixed(1)}%';
    
    return Text(
      changeText,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

/// Compact comparison card for app lists
class AppComparisonCard extends StatelessWidget {
  final AppComparison comparison;
  final VoidCallback? onTap;
  final int index;

  const AppComparisonCard({
    super.key,
    required this.comparison,
    this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isImprovement = comparison.isImprovement;
    final color = isImprovement
        ? const Color(0xFF10B981)
        : comparison.isRegression
            ? const Color(0xFFEF4444)
            : const Color(0xFF6B7280);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            // App Icon
            AppIconWidget(
              packageName: comparison.packageName,
              appName: comparison.appName,
              size: 40,
            ),
            const SizedBox(width: 12),
            // App name and usage
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comparison.appName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${comparison.currentUsageFormatted} → ${comparison.previousUsageFormatted}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            // Change indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isImprovement ? LucideIcons.arrowDown : LucideIcons.arrowUp,
                    size: 12,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${comparison.absoluteChangePercent.toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (50 * index).ms).fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }
}

/// Summary insight card
class InsightCard extends StatelessWidget {
  final String message;
  final TrendDirection trend;
  final VoidCallback? onDismiss;

  const InsightCard({
    super.key,
    required this.message,
    required this.trend,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = trend == TrendDirection.down;
    
    final gradientColors = isPositive
        ? [const Color(0xFF10B981), const Color(0xFF059669)]
        : trend == TrendDirection.up
            ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
            : [const Color(0xFF6B7280), const Color(0xFF4B5563)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(LucideIcons.x, size: 18),
              color: Colors.white70,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}

/// Period selector button
class PeriodSelectorButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const PeriodSelectorButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C3AED)
              : isDark
                  ? const Color(0xFF2A2A2A)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C3AED)
                : isDark
                    ? const Color(0xFF3A3A3A)
                    : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : isDark
                    ? Colors.white60
                    : Colors.black54,
          ),
        ),
      ),
    );
  }
}
