import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';
import '../constants/app_colors.dart';

/// Calendar widget that displays mood entries on specific dates
class MoodCalendarWidget extends StatefulWidget {
  final List<MoodEntry> entries;
  final Function(DateTime)? onDateSelected;

  const MoodCalendarWidget({
    super.key,
    required this.entries,
    this.onDateSelected,
  });

  @override
  State<MoodCalendarWidget> createState() => _MoodCalendarWidgetState();
}

class _MoodCalendarWidgetState extends State<MoodCalendarWidget> {
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;

  // Create a map of dates to mood entries for quick lookup
  Map<DateTime, MoodEntry> get _moodMap {
    final map = <DateTime, MoodEntry>{};
    for (var entry in widget.entries) {
      final dateOnly = DateTime(entry.date.year, entry.date.month, entry.date.day);
      map[dateOnly] = entry;
    }
    return map;
  }

  // Get first day of month and number of days
  DateTime get _firstDayOfMonth => DateTime(_selectedMonth.year, _selectedMonth.month, 1);
  int get _daysInMonth => DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
  int get _firstWeekday => _firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month header with navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
                onPressed: () {
                  final now = DateTime.now();
                  final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                  if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
                    setState(() {
                      _selectedMonth = nextMonth;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Weekday headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          _buildCalendarGrid(isDark),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(bool isDark) {
    final rows = <Widget>[];
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    // Calculate starting position (offset for first day of month)
    int day = 1;
    int currentWeekday = _firstWeekday;

    // Create rows (weeks)
    while (day <= _daysInMonth) {
      final weekRow = <Widget>[];

      // Fill in days of the week
      for (int weekday = 1; weekday <= 7; weekday++) {
        if (weekday < currentWeekday && day == 1) {
          // Empty cell before first day of month
          weekRow.add(const Expanded(child: SizedBox()));
        } else if (day <= _daysInMonth) {
          final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
          final dateOnly = DateTime(date.year, date.month, date.day);
          final moodEntry = _moodMap[dateOnly];
          final isToday = dateOnly == todayOnly;
          final isSelected = _selectedDate != null &&
              DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day) ==
                  dateOnly;

          weekRow.add(
            Expanded(
              child: _buildDayCell(
                day: day,
                moodEntry: moodEntry,
                isToday: isToday,
                isSelected: isSelected,
                isDark: isDark,
                date: dateOnly,
              ),
            ),
          );

          day++;
        } else {
          // Empty cell after last day of month
          weekRow.add(const Expanded(child: SizedBox()));
        }
      }

      rows.add(Row(children: weekRow));
      currentWeekday = 1; // Reset for next week
    }

    return Column(children: rows);
  }

  Widget _buildDayCell({
    required int day,
    MoodEntry? moodEntry,
    required bool isToday,
    required bool isSelected,
    required bool isDark,
    required DateTime date,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        if (widget.onDateSelected != null) {
          widget.onDateSelected!(date);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200)
              : null,
          border: isToday
              ? Border.all(
                  color: isDark ? AppColors.purple : AppColors.teal,
                  width: 2,
                )
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: isDark
                    ? (isToday ? Colors.white : Colors.white70)
                    : (isToday ? Colors.black87 : Colors.grey.shade700),
              ),
            ),
            if (moodEntry != null) ...[
              const SizedBox(height: 2),
              Text(
                moodEntry.emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
