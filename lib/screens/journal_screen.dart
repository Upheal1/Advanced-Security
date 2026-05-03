import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../widgets/drawer_menu_button.dart';
import '../models/journal_model.dart';
import '../constants/app_colors.dart';
import '../main.dart';
import 'journaling_details_screen.dart';
import 'games/journaling_history_screen.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: DrawerMenuButton(
          iconColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : AppColors.textPrimary,
        ),
        title: Text(
          'Journaling',
          style: GoogleFonts.inter(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [],
      ),
      body: Consumer<JournalModel>(
        builder: (context, journalModel, _) {
          final entries = journalModel.entries;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Reflection',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Capture your thoughts, track your mood, and earn XP for healthy reflection.',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const JournalingQuestionsScreen(),
                            ),
                          );
                          if (result == true) {
                            journalModel.refresh();
                          }
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('New Entry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.purple
                              : AppColors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const JournalingHistoryScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('History'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppColors.textPrimary,
                          side: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white30
                                : AppColors.textPrimary.withOpacity(0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Recent entry preview or empty state
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Text(
                            'No journal entries yet.\nStart by creating your first reflection.',
                            style: GoogleFonts.inter(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white60
                                  : AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Entries',
                              style: GoogleFonts.inter(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.builder(
                                itemCount: entries.length.clamp(0, 3),
                                itemBuilder: (context, index) {
                                  final entry = entries[index];
                                  final firstAnswer = entry.answers.isNotEmpty
                                      ? entry.answers.first.answer
                                      : '';
                                  final date = entry.date;
                                  final dateStr =
                                      '${date.day}/${date.month}/${date.year}';

                                  return Container(
                                    margin:
                                        const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withOpacity(0.05)
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white.withOpacity(0.08)
                                            : AppColors.textPrimary.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 14,
                                                  color: Theme.of(context).brightness == Brightness.dark
                                                      ? Colors.white70
                                                      : AppColors.textSecondary,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  dateStr,
                                                  style: GoogleFonts.inter(
                                                    color: Theme.of(context).brightness == Brightness.dark
                                                        ? Colors.white70
                                                        : AppColors.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (entry.xpAwarded != null)
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    size: 14,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '+${entry.xpAwarded} XP',
                                                    style: GoogleFonts.inter(
                                                      color: Colors.amber,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          firstAnswer.isEmpty
                                              ? 'No content'
                                              : firstAnswer,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final selectedColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.purple
        : AppColors.teal;

    return Drawer(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1B1B1B)
          : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          AppColors.purple.withOpacity(0.3),
                          AppColors.purple.withOpacity(0.1),
                        ]
                      : [
                          AppColors.teal.withOpacity(0.2),
                          AppColors.teal.withOpacity(0.05),
                        ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        colors: Theme.of(context).brightness == Brightness.dark
                            ? [AppColors.purple, const Color(0xFFF97316)]
                            : [AppColors.teal, AppColors.orange],
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.bookOpen,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Journaling',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Reflection & Growth',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : AppColors.textPrimary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white24
                  : AppColors.textPrimary.withOpacity(0.1),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: Icon(
                      LucideIcons.home,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : AppColors.textPrimary,
                      size: 24,
                    ),
                    title: Text(
                      'Home',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      // Navigation is handled by RootNav
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      LucideIcons.bookOpen,
                      color: selectedColor,
                      size: 24,
                    ),
                    title: Text(
                      'Journaling',
                      style: GoogleFonts.inter(
                        color: selectedColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    selected: true,
                    selectedTileColor: selectedColor.withOpacity(0.1),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

