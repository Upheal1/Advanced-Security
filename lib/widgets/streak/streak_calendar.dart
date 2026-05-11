import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/streak_model.dart';
import '../../constants/app_colors.dart';

/// A beautiful 365-day streak calendar widget showing activity history
class StreakCalendar extends StatefulWidget {
  final StreakState streakState;
  final VoidCallback? onDayTapped;

  const StreakCalendar({
    super.key,
    required this.streakState,
    this.onDayTapped,
  });

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  DateTime _selectedMonth = DateTime.now();
  bool _showYearView = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ]
              : [
                  AppColors.textPrimary.withOpacity(0.05),
                  AppColors.textPrimary.withOpacity(0.02),
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : AppColors.textPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark),
          const SizedBox(height: 20),
          if (_showYearView)
            _buildYearGrid(context, isDark)
          else
            _buildMonthView(context, isDark),
          const SizedBox(height: 16),
          _buildLegend(context, isDark),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.calendar,
              color: isDark ? Colors.white : AppColors.textPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _showYearView ? 'Year View' : 'Activity Calendar',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Toggle view button
            GestureDetector(
              onTap: () => setState(() => _showYearView = !_showYearView),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : AppColors.textPrimary.withOpacity(0.1),
                ),
                child: Text(
                  _showYearView ? 'Month' : 'Year',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthView(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                LucideIcons.chevronLeft,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month - 1,
                  );
                });
              },
            ),
            Text(
              _getMonthName(_selectedMonth),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            IconButton(
              icon: Icon(
                LucideIcons.chevronRight,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              onPressed: () {
                final now = DateTime.now();
                final nextMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                );
                if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
                  setState(() => _selectedMonth = nextMonth);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Day headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((d) => SizedBox(
                    width: 36,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar grid
        _buildCalendarGrid(context, isDark),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context, bool isDark) {
    final firstDayOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final startingWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;
    final totalCells = startingWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNumber = cellIndex - startingWeekday + 1;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox(width: 36, height: 36);
            }

            final date = DateTime(
              _selectedMonth.year,
              _selectedMonth.month,
              dayNumber,
            );

            return _buildDayCell(context, date, isDark);
          }),
        );
      }),
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime date, bool isDark) {
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isFuture = date.isAfter(today);

    // Check if this day has activity
    final streakDay = _getStreakDayForDate(date);
    final hasActivity = streakDay?.isCompleted ?? false;
    final activityLevel = _getActivityLevel(streakDay);

    return GestureDetector(
      onTap: isFuture ? null : () => _showDayDetails(context, date, streakDay),
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isFuture
              ? Colors.transparent
              : hasActivity
                  ? _getActivityColor(activityLevel)
                  : isDark
                      ? Colors.white.withOpacity(0.05)
                      : AppColors.surface,
          border: Border.all(
            color: isToday
                ? const Color(0xFFFF6B35)
                : isDark
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.textPrimary.withOpacity(0.1),
            width: isToday ? 2 : 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasActivity && !isFuture)
                const Icon(
                  LucideIcons.flame,
                  color: Colors.white,
                  size: 10,
                ),
              Text(
                '${date.day}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: hasActivity
                      ? Colors.white
                      : isFuture
                          ? (isDark
                              ? Colors.white24
                              : AppColors.textSecondary.withOpacity(0.3))
                          : (isDark
                              ? Colors.white70
                              : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearGrid(BuildContext context, bool isDark) {
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 364));

    return Column(
      children: [
        // Month labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _getMonthLabels()
              .map((m) => Text(
                    m,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Year grid (GitHub style)
        SizedBox(
          height: 100,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemCount: 365,
            itemBuilder: (context, index) {
              final date = startDate.add(Duration(days: index));
              final streakDay = _getStreakDayForDate(date);
              final hasActivity = streakDay?.isCompleted ?? false;
              final activityLevel = _getActivityLevel(streakDay);

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: hasActivity
                      ? _getActivityColor(activityLevel)
                      : isDark
                          ? Colors.white.withOpacity(0.08)
                          : AppColors.textPrimary.withOpacity(0.08),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildYearStat(
              context,
              isDark,
              '${widget.streakState.totalDaysActive}',
              'Active Days',
              LucideIcons.flame,
            ),
            const SizedBox(width: 24),
            _buildYearStat(
              context,
              isDark,
              '${widget.streakState.longestStreak}',
              'Longest Streak',
              LucideIcons.trophy,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYearStat(
    BuildContext context,
    bool isDark,
    String value,
    String label,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFFFF6B35),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Less',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        _buildLegendBox(isDark ? Colors.white.withOpacity(0.08) : AppColors.textPrimary.withOpacity(0.08)),
        _buildLegendBox(const Color(0xFFFF6B35).withOpacity(0.3)),
        _buildLegendBox(const Color(0xFFFF6B35).withOpacity(0.5)),
        _buildLegendBox(const Color(0xFFFF6B35).withOpacity(0.7)),
        _buildLegendBox(const Color(0xFFFF6B35)),
        const SizedBox(width: 8),
        Text(
          'More',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: color,
      ),
    );
  }

  StreakDay? _getStreakDayForDate(DateTime date) {
    final matches = widget.streakState.streakHistory.where(
      (d) =>
          d.date.year == date.year &&
          d.date.month == date.month &&
          d.date.day == date.day,
    );
    return matches.isEmpty ? null : matches.first;
  }

  int _getActivityLevel(StreakDay? day) {
    if (day == null || !day.isCompleted) return 0;
    if (day.activitiesCount >= 5) return 4;
    if (day.activitiesCount >= 3) return 3;
    if (day.activitiesCount >= 2) return 2;
    return 1;
  }

  Color _getActivityColor(int level) {
    switch (level) {
      case 4:
        return const Color(0xFFFF6B35);
      case 3:
        return const Color(0xFFFF6B35).withOpacity(0.7);
      case 2:
        return const Color(0xFFFF6B35).withOpacity(0.5);
      case 1:
        return const Color(0xFFFF6B35).withOpacity(0.3);
      default:
        return Colors.transparent;
    }
  }

  String _getMonthName(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  List<String> _getMonthLabels() {
    const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    final today = DateTime.now();
    final startMonth = (today.month - 11) % 12;
    return List.generate(12, (i) => months[(startMonth + i) % 12]);
  }

  void _showDayDetails(BuildContext context, DateTime date, StreakDay? streakDay) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: streakDay?.isCompleted ?? false
                        ? const Color(0xFFFF6B35).withOpacity(0.2)
                        : (isDark
                            ? Colors.white.withOpacity(0.1)
                            : AppColors.textPrimary.withOpacity(0.1)),
                  ),
                  child: Icon(
                    streakDay?.isCompleted ?? false
                        ? LucideIcons.flame
                        : LucideIcons.calendar,
                    color: streakDay?.isCompleted ?? false
                        ? const Color(0xFFFF6B35)
                        : (isDark ? Colors.white54 : AppColors.textSecondary),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getMonthName(date).split(' ')[0] + ' ${date.day}, ${date.year}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      streakDay?.isCompleted ?? false
                          ? 'Streak Day Completed! 🔥'
                          : 'No activity recorded',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (streakDay != null && streakDay.isCompleted) ...[
              const SizedBox(height: 20),
              _buildDetailRow(
                context,
                isDark,
                'Activities Completed',
                '${streakDay.activitiesCount}',
                LucideIcons.checkCircle,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                isDark,
                'XP Earned',
                '+${streakDay.xpEarned}',
                LucideIcons.sparkles,
              ),
              if (streakDay.completedActivities.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: streakDay.completedActivities
                      .map((a) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: const Color(0xFFFF6B35).withOpacity(0.2),
                            ),
                            child: Text(
                              a,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFFFF6B35),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    bool isDark,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFFFF6B35),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
