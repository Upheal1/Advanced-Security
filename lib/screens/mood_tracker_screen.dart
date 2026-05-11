import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/mood_entry.dart';
import '../models/mood_model.dart';
import '../constants/app_colors.dart';
import '../widgets/drawer_menu_button.dart';
import '../widgets/mood_calendar_widget.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Load today's entry to check if already tracked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoodModel>().loadEntries();
    });
  }

  Future<void> _trackMood(String mood) async {
    if (_isSubmitting) return;

    final moodModel = context.read<MoodModel>();
    
    // Check if already tracked today
    if (moodModel.hasTrackedToday) {
      _showMessage('You have already tracked your mood today. Come back tomorrow!', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final entry = MoodEntry(
        id: const Uuid().v4(),
        mood: mood,
        date: today,
        timestamp: now,
      );

      final success = await moodModel.saveEntry(entry);

      if (success && mounted) {
        _showMessage('Your mood has been tracked! 😊', isError: false);
        // Refresh to update UI
        await moodModel.loadEntries();
      } else {
        if (mounted) {
          _showMessage(
            moodModel.errorMessage ?? 'Failed to save mood entry',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error tracking mood: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildMoodButton(String mood, String emoji, int colorValue, bool isSelected) {
    final isDisabled = _isSubmitting || context.watch<MoodModel>().hasTrackedToday;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: isDisabled ? null : () => _trackMood(mood),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
              decoration: BoxDecoration(
                gradient: isSelected 
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(colorValue).withOpacity(isDark ? 0.4 : 0.3),
                          Color(colorValue).withOpacity(isDark ? 0.2 : 0.1),
                        ],
                      )
                    : null,
                border: Border.all(
                  color: isSelected 
                      ? Color(colorValue)
                      : (isDark ? Colors.white24 : Colors.grey.shade300),
                  width: isSelected ? 2.5 : 1.5,
                ),
                borderRadius: BorderRadius.circular(20),
                color: isSelected 
                    ? null
                    : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Color(colorValue).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: TextStyle(
                      fontSize: 44,
                      shadows: isSelected ? [
                        Shadow(
                          color: Color(colorValue).withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ] : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    mood,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected 
                          ? Color(colorValue)
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moodModel = context.watch<MoodModel>();
    final todayEntry = moodModel.todayEntry;
    final hasTracked = moodModel.hasTrackedToday;
    final isLoading = moodModel.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine background color based on today's mood
    Color backgroundColor = isDark ? const Color(0xFF0F1419) : const Color(0xFFF8FAFB);
    if (todayEntry != null && !isDark) {
      backgroundColor = Color(todayEntry.colorValue).withOpacity(0.05);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1B1B1B) : Colors.white,
        elevation: 0,
            leading: DrawerMenuButton(
              iconColor: isDark ? Colors.white : AppColors.textPrimary,
            ),
        title: Text(
          'Mood Tracker',
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (moodModel.entries.isNotEmpty)
            IconButton(
              icon: Icon(
                LucideIcons.barChart3,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
              onPressed: () {
                _showMoodStats(context, moodModel);
              },
              tooltip: 'Statistics',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Question Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark 
                        ? [
                            const Color(0xFF1E1E1E),
                            const Color(0xFF2A2A2A),
                          ]
                        : [
                            Colors.white,
                            Colors.grey.shade50,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isDark 
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      size: 36,
                      color: isDark ? AppColors.purple : AppColors.teal,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'How are you feeling today?',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your emotional wellness matters',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (hasTracked) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: todayEntry != null 
                                ? [
                                    Color(todayEntry.colorValue).withOpacity(isDark ? 0.3 : 0.2),
                                    Color(todayEntry.colorValue).withOpacity(isDark ? 0.15 : 0.1),
                                  ]
                                : [
                                    Colors.green.shade100,
                                    Colors.green.shade50,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: todayEntry != null
                                ? Color(todayEntry.colorValue).withOpacity(0.5)
                                : Colors.green.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              todayEntry?.emoji ?? '✅',
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today\'s Mood',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  todayEntry?.mood ?? "Tracked",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: todayEntry != null 
                                        ? Color(todayEntry.colorValue)
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.checkCircle2,
                              size: 16,
                              color: isDark ? Colors.white60 : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Come back tomorrow to track again!',
                                style: GoogleFonts.inter(
                                  color: isDark ? Colors.white60 : Colors.grey.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Mood Buttons
              if (isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(
                      color: isDark ? AppColors.purple : AppColors.teal,
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        _buildMoodButton(
                          'Very Happy',
                          '😄',
                          MoodOptions.colors[0],
                          todayEntry?.mood == 'Very Happy',
                        ),
                        _buildMoodButton(
                          'Happy',
                          '😊',
                          MoodOptions.colors[1],
                          todayEntry?.mood == 'Happy',
                        ),
                        _buildMoodButton(
                          'Neutral',
                          '😐',
                          MoodOptions.colors[2],
                          todayEntry?.mood == 'Neutral',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Spacer(),
                        Expanded(
                          flex: 2,
                          child: _buildMoodButton(
                            'Sad',
                            '😢',
                            MoodOptions.colors[3],
                            todayEntry?.mood == 'Sad',
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _buildMoodButton(
                            'Very Sad',
                            '😭',
                            MoodOptions.colors[4],
                            todayEntry?.mood == 'Very Sad',
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              // Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.purple.withOpacity(0.2),
                            AppColors.purple.withOpacity(0.1),
                          ]
                        : [
                            AppColors.teal.withOpacity(0.1),
                            AppColors.teal.withOpacity(0.05),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark 
                        ? AppColors.purple.withOpacity(0.3)
                        : AppColors.teal.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? AppColors.purple.withOpacity(0.2)
                            : AppColors.teal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.lightbulb,
                        color: isDark ? AppColors.purple : AppColors.teal,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Track your mood daily to build emotional awareness and identify patterns over time.',
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF004D40),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Mood Calendar
              if (moodModel.entries.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mood Calendar',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '${moodModel.entries.length} tracked',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                MoodCalendarWidget(
                  entries: moodModel.entries,
                  onDateSelected: (date) {
                    // Show details when date with mood entry is selected
                    try {
                      final entry = moodModel.entries.firstWhere(
                        (e) {
                          final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
                          final selectedDate = DateTime(date.year, date.month, date.day);
                          return entryDate == selectedDate;
                        },
                      );
                      _showMoodDetails(context, entry, date);
                    } catch (e) {
                      // No mood entry for this date, do nothing
                    }
                  },
                ),
                const SizedBox(height: 28),
              ],

              // Recent Moods List
              if (moodModel.entries.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Moods',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '${moodModel.entries.length} total',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...moodModel.entries.take(7).map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark 
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade200,
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
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(entry.colorValue).withOpacity(isDark ? 0.2 : 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            entry.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.mood,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(entry.date),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Color(entry.colorValue).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getDaysAgo(entry.date),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(entry.colorValue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getDaysAgo(DateTime date) {
    final now = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return '1d ago';
    if (difference < 7) return '${difference}d ago';
    if (difference < 30) return '${(difference / 7).floor()}w ago';
    return '${(difference / 30).floor()}mo ago';
  }

  void _showMoodStats(BuildContext context, MoodModel moodModel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1B1B1B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final moodCounts = <String, int>{};
        for (var entry in moodModel.entries) {
          moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.pieChart,
                    color: isDark ? AppColors.purple : AppColors.teal,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Mood Statistics',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...moodCounts.entries.map((entry) {
                final index = MoodOptions.moods.indexOf(entry.key);
                final color = index >= 0 ? Color(MoodOptions.colors[index]) : Colors.grey;
                final percentage = (entry.value / moodModel.entries.length * 100).toStringAsFixed(1);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                MoodOptions.emojis[index],
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$percentage% (${entry.value})',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entry.value / moodModel.entries.length,
                          backgroundColor: isDark 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showMoodDetails(BuildContext context, MoodEntry entry, DateTime date) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Text(
              entry.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.mood,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    _formatDate(date),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(entry.colorValue).withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.calendar,
                color: Color(entry.colorValue),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Mood tracked on this day',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.inter(
                color: isDark ? AppColors.purple : AppColors.teal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

