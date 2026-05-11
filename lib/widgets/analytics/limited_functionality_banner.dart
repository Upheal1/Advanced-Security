import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Banner shown when analytics permissions are not granted
/// Explains limited functionality and provides option to enable
class LimitedFunctionalityBanner extends StatelessWidget {
  final VoidCallback onEnablePressed;
  final bool isCollapsed;
  final VoidCallback? onDismiss;

  const LimitedFunctionalityBanner({
    super.key,
    required this.onEnablePressed,
    this.isCollapsed = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCollapsed) {
      return _buildCollapsedBanner(isDark);
    }

    return _buildExpandedBanner(isDark);
  }

  Widget _buildExpandedBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF4A3500),
                  const Color(0xFF3D2E00),
                ]
              : [
                  const Color(0xFFFFF9E6),
                  const Color(0xFFFFF3CC),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFFF59E0B).withOpacity(0.3)
              : const Color(0xFFF59E0B).withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.alertTriangle,
                    color: Color(0xFFF59E0B),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Limited Analytics',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Permission required for full features',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: isDark
                ? const Color(0xFFF59E0B).withOpacity(0.15)
                : const Color(0xFFF59E0B).withOpacity(0.2),
          ),

          // Features list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable usage access to:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  icon: LucideIcons.barChart2,
                  text: 'Track app usage and screen time',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildFeatureItem(
                  icon: LucideIcons.timer,
                  text: 'Set daily limits for apps',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildFeatureItem(
                  icon: LucideIcons.bell,
                  text: 'Get usage notifications',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildFeatureItem(
                  icon: LucideIcons.trendingUp,
                  text: 'View usage trends and insights',
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onEnablePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.shield, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Enable Now',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCollapsedBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF4A3500).withOpacity(0.8)
            : const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.alertCircle,
            color: Color(0xFFF59E0B),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Limited mode - Enable usage access for full analytics',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onEnablePressed,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF59E0B),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Enable',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF7C3AED).withOpacity(0.2)
                : const Color(0xFF7C3AED).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF7C3AED),
            size: 14,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}

/// A minimal inline banner for tight spaces
class LimitedFunctionalityInlineBanner extends StatelessWidget {
  final VoidCallback onEnablePressed;

  const LimitedFunctionalityInlineBanner({
    super.key,
    required this.onEnablePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.amber.withOpacity(0.1)
            : Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.info,
            color: Colors.amber,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Usage data requires permission',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          GestureDetector(
            onTap: onEnablePressed,
            child: Text(
              'Grant',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state widget for when analytics are unavailable
class AnalyticsUnavailableWidget extends StatelessWidget {
  final VoidCallback onEnablePressed;

  const AnalyticsUnavailableWidget({
    super.key,
    required this.onEnablePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF7C3AED).withOpacity(0.1)
                    : const Color(0xFF7C3AED).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.barChartHorizontal,
                size: 48,
                color: isDark
                    ? Colors.white24
                    : Colors.black26,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 1,
                  end: 1.05,
                  duration: 2.seconds,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 24),
            // Title
            Text(
              'Analytics Unavailable',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              'Enable usage access permission to view your screen time analytics, app usage trends, and set daily limits.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Enable button
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onEnablePressed,
                icon: const Icon(LucideIcons.shield, size: 18),
                label: Text(
                  'Enable Permission',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}
