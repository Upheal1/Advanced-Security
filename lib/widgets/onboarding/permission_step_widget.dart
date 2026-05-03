import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A reusable widget for displaying a single onboarding step/page
class PermissionStepWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Widget? illustration;
  final List<String>? benefits;
  final Widget? customContent;
  final int animationDelay;

  const PermissionStepWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor = const Color(0xFF7C3AED),
    this.illustration,
    this.benefits,
    this.customContent,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon or illustration
          _buildIconSection(isDark)
              .animate(delay: Duration(milliseconds: animationDelay))
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 500.ms),
          
          const SizedBox(height: 40),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.2,
            ),
          )
              .animate(delay: Duration(milliseconds: animationDelay + 200))
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.3, end: 0, duration: 400.ms),

          const SizedBox(height: 16),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.5,
            ),
          )
              .animate(delay: Duration(milliseconds: animationDelay + 400))
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.3, end: 0, duration: 400.ms),

          // Benefits list
          if (benefits != null && benefits!.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildBenefitsList(isDark),
          ],

          // Custom content
          if (customContent != null) ...[
            const SizedBox(height: 32),
            customContent!
                .animate(delay: Duration(milliseconds: animationDelay + 600))
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 400.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildIconSection(bool isDark) {
    if (illustration != null) {
      return illustration!;
    }

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            iconColor.withValues(alpha: 0.2),
            iconColor.withValues(alpha: 0.1),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                iconColor,
                iconColor.withValues(alpha: 0.8),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 50,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitsList(bool isDark) {
    return Column(
      children: benefits!.asMap().entries.map((entry) {
        final index = entry.key;
        final benefit = entry.value;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  benefit,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: 600 + (index * 100)))
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.2, end: 0, duration: 300.ms);
      }).toList(),
    );
  }
}

/// A widget for displaying a mini chart preview in onboarding
class ChartPreviewWidget extends StatelessWidget {
  const ChartPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Screen Time',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '4h 32m',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(0.3, 'Mon', isDark),
                _buildBar(0.5, 'Tue', isDark),
                _buildBar(0.7, 'Wed', isDark),
                _buildBar(0.4, 'Thu', isDark),
                _buildBar(0.8, 'Fri', isDark),
                _buildBar(0.6, 'Sat', isDark),
                _buildBar(0.5, 'Sun', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, String label, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: 60 * height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                const Color(0xFF7C3AED),
                const Color(0xFF7C3AED).withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

/// A widget for displaying a limit preview in onboarding
class LimitPreviewWidget extends StatelessWidget {
  const LimitPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAppLimit(
            'Instagram',
            Icons.camera_alt_rounded,
            const Color(0xFFE1306C),
            0.7,
            '1h 24m / 2h',
            isDark,
          ),
          const SizedBox(height: 12),
          _buildAppLimit(
            'YouTube',
            Icons.play_circle_fill_rounded,
            const Color(0xFFFF0000),
            0.4,
            '48m / 2h',
            isDark,
          ),
          const SizedBox(height: 12),
          _buildAppLimit(
            'TikTok',
            Icons.music_note_rounded,
            Colors.black,
            0.9,
            '1h 48m / 2h',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildAppLimit(
    String name,
    IconData icon,
    Color color,
    double progress,
    String time,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    time,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation(
                    progress > 0.8 ? Colors.orange : const Color(0xFF7C3AED),
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
