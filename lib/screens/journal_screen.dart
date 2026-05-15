import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/journal_entry.dart';
import '../models/journal_model.dart';
import 'journaling_questions_screen.dart';

const Color _jInk = Color(0xFF0F172A);
const Color _jPage = Color(0xFFF7F8F4);
const Color _jSurface = Colors.white;
const Color _jMuted = Color(0xFF8A93A5);
const Color _jText = Color(0xFF1D2939);
const Color _jBlue = Color(0xFF69A9D8);
const Color _jBlueSoft = Color(0xFFEAF3FB);
const Color _jPill = Color(0xFFF1F5F9);
const Color _jLine = Color(0xFFE6EBF2);
const Color _jSuccess = Color(0xFF5C9FD6);
const Color _jHeaderMint = Color(0xFFEFF5EA);

const List<String> _dailyPrompts = [
  'What is one thing that challenged you today, and how did you respond to it?',
  'What moment today made you feel most like yourself?',
  'What would feel supportive to give yourself tonight?',
  'What thought or feeling keeps returning, and what might it need?',
];

class _JournalMood {
  final String label;
  final String emoji;

  const _JournalMood(this.label, this.emoji);
}

const List<_JournalMood> _journalMoods = [
  _JournalMood('Overwhelmed', '😩'),
  _JournalMood('Anxious', '😟'),
  _JournalMood('Okay', '😐'),
  _JournalMood('Steady', '🙂'),
  _JournalMood('Good', '😊'),
];

enum _JournalTab { write, history }

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _entryController = TextEditingController();
  final FocusNode _entryFocusNode = FocusNode();

  _JournalTab _selectedTab = _JournalTab.write;
  int _promptIndex = 0;
  String? _selectedMood;
  bool _saveAttempted = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _promptIndex = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays % _dailyPrompts.length;
    _entryController.addListener(_handleDraftChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalModel>().loadEntries();
    });
  }

  @override
  void dispose() {
    _entryController
      ..removeListener(_handleDraftChanged)
      ..dispose();
    _entryFocusNode.dispose();
    super.dispose();
  }

  void _handleDraftChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String get _activePrompt => _dailyPrompts[_promptIndex];

  int get _wordCount {
    final text = _entryController.text.trim();
    if (text.isEmpty) {
      return 0;
    }
    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  bool get _canSave {
    return !_isSaving && _selectedMood != null && _entryController.text.trim().length >= 10;
  }

  Future<void> _saveEntry() async {
    setState(() => _saveAttempted = true);

    final content = _entryController.text.trim();
    if (_selectedMood == null) {
      _showSnack('Select your current mood before saving.');
      return;
    }
    if (content.length < 10) {
      _showSnack('Write at least 10 characters before saving.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final entry = JournalEntry(
        id: now.microsecondsSinceEpoch.toString(),
        date: DateTime(now.year, now.month, now.day),
        answers: [
          QuestionAnswer(question: _activePrompt, answer: content),
        ],
        mood: _selectedMood,
        timestamp: now,
        xpAwarded: 10 + (_wordCount ~/ 25).clamp(0, 30),
      );

      final journalModel = context.read<JournalModel>();
      final success = await journalModel.saveEntry(entry);
      if (!mounted) {
        return;
      }
      if (!success) {
        _showSnack(journalModel.errorMessage ?? 'Failed to save journal entry.');
        return;
      }

      setState(() {
        _entryController.clear();
        _selectedMood = null;
        _saveAttempted = false;
        _selectedTab = _JournalTab.history;
      });
      _showSnack('Journal entry saved.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goToPreviousPage() {
    Navigator.maybePop(context);
  }

  void _showNextPrompt() {
    setState(() {
      _promptIndex = (_promptIndex + 1) % _dailyPrompts.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _jInk : _jPage,
      body: SafeArea(
        child: Consumer<JournalModel>(
          builder: (context, model, _) {
            return RefreshIndicator(
              color: _jSuccess,
              onRefresh: model.refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(model, isDark),
                    const SizedBox(height: 18),
                    _buildTabs(isDark),
                    const SizedBox(height: 16),
                    if (_selectedTab == _JournalTab.write)
                      _buildWriteTab(model, isDark)
                    else
                      _buildHistoryTab(model, isDark),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(JournalModel model, bool isDark) {
    final streak = _calculateStreak(model.entries);
    final totalXp = model.entries.fold<int>(0, (sum, entry) => sum + (entry.xpAwarded ?? 10));

    return Row(
      children: [
        _CircleActionButton(
          icon: LucideIcons.chevronLeft,
          onTap: _goToPreviousPage,
          isDark: isDark,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Journal',
                style: GoogleFonts.inter(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : _jText,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatHeaderDate(DateTime.now())} · $totalXp XP',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : _jMuted,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? _jHeaderMint.withValues(alpha: 0.14) : _jHeaderMint,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 16, color: isDark ? const Color(0xFFC7F5C3) : const Color(0xFF6C8C55)),
              const SizedBox(width: 4),
              Text(
                '$streak',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFC7F5C3) : const Color(0xFF6C8C55),
                ),
              ),
              const SizedBox(width: 4),
              const Text('🔥', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.07) : _jPill,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _JournalTabButton(
              label: 'Write',
              icon: '✍️',
              isSelected: _selectedTab == _JournalTab.write,
              onTap: () => setState(() => _selectedTab = _JournalTab.write),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _JournalTabButton(
              label: 'Past Entries',
              icon: '📚',
              isSelected: _selectedTab == _JournalTab.history,
              onTap: () => setState(() => _selectedTab = _JournalTab.history),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteTab(JournalModel model, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PromptCard(
          prompt: _activePrompt,
          promptIndex: _promptIndex,
          promptCount: _dailyPrompts.length,
          onNextPrompt: _showNextPrompt,
          isDark: isDark,
        ),
        const SizedBox(height: 18),
        _SectionCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current mood',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : _jText,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: _journalMoods.map((mood) {
                  final selected = _selectedMood == mood.label;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: mood == _journalMoods.last ? 0 : 10),
                      child: _MoodTile(
                        mood: mood,
                        isSelected: selected,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedMood = mood.label),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_saveAttempted && _selectedMood == null) ...[
                const SizedBox(height: 10),
                Text(
                  'Mood is required before you can save this entry.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : _jSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : _jLine,
            ),
            boxShadow: isDark
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x140D1B2A),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _entryController,
                focusNode: _entryFocusNode,
                minLines: 8,
                maxLines: 12,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.7,
                  color: isDark ? Colors.white : _jText,
                ),
                decoration: InputDecoration(
                  hintText: 'Start writing freely... there\'s no judgment here.\nLet it flow.',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.7,
                    color: isDark ? Colors.white60 : _jMuted,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  '$_wordCount words',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : _jMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.07) : _jPill,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.mic, size: 18, color: isDark ? Colors.white60 : _jMuted),
                      const SizedBox(width: 8),
                      Text(
                        'Voice Note',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : _jMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveEntry,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _canSave ? _jSuccess : _jSuccess.withValues(alpha: 0.45),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.send, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Save Entry',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryTab(JournalModel model, bool isDark) {
    final entries = model.entries;

    if (model.isLoading && entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator(color: _jSuccess)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT ENTRIES',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: isDark ? Colors.white60 : _jMuted,
              ),
            ),
            Text(
              '${entries.length} total',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _jBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (entries.isEmpty)
          _SectionCard(
            isDark: isDark,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  Text('📓', style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 10),
                  Text(
                    'No journal entries yet.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : _jText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Use the Write tab to create your first reflection.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : _jMuted,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryEntryCard(
                  entry: entry,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JournalingDetailsScreen(entry: entry),
                    ),
                  ),
                ),
              )),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF5F8FD),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text('🗓️', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text(
                'You\'ve journaled ${_calculateStreak(entries)} days in a row',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : _jText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Consistency is your superpower',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _jBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _calculateStreak(List<JournalEntry> entries) {
    if (entries.isEmpty) {
      return 0;
    }

    final uniqueDates = entries
        .map((entry) => DateTime(entry.date.year, entry.date.month, entry.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 1;
    for (int index = 1; index < uniqueDates.length; index++) {
      final previous = uniqueDates[index - 1];
      final current = uniqueDates[index];
      if (previous.difference(current).inDays == 1) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  String _formatHeaderDate(DateTime date) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _CircleActionButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.08) : _jPill,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _JournalTabButton extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _JournalTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? (isDark ? Colors.white : _jSurface) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected && !isDark
                ? const [
                    BoxShadow(
                      color: Color(0x120D1B2A),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? _jText : (isDark ? Colors.white60 : _jMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final String prompt;
  final int promptIndex;
  final int promptCount;
  final VoidCallback onNextPrompt;
  final bool isDark;

  const _PromptCard({
    required this.prompt,
    required this.promptIndex,
    required this.promptCount,
    required this.onNextPrompt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.05)]
              : [const Color(0xFFF2F8FB), const Color(0xFFE8F4EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: [
                  Icon(LucideIcons.bookOpen, size: 14, color: _jBlue),
                  const SizedBox(width: 6),
                  Text(
                    'TODAY\'S PROMPT',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: _jBlue,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${promptIndex + 1}/$promptCount',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : _jMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            prompt,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: isDark ? Colors.white : _jText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _PromptActionButton(
                icon: LucideIcons.chevronLeft,
                label: '',
                isDark: isDark,
                onTap: null,
              ),
              const SizedBox(width: 8),
              _PromptActionButton(
                icon: LucideIcons.chevronRight,
                label: 'Next prompt',
                isDark: isDark,
                onTap: onNextPrompt,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromptActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  const _PromptActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.09) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: label.isEmpty ? 12 : 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: enabled ? _jBlue : (isDark ? Colors.white24 : _jMuted.withValues(alpha: 0.45)),
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: enabled ? _jBlue : (isDark ? Colors.white24 : _jMuted.withValues(alpha: 0.45)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _SectionCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : _jSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : _jLine),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x140D1B2A),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _MoodTile extends StatelessWidget {
  final _JournalMood mood;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _MoodTile({
    required this.mood,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 56,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? _jBlue.withValues(alpha: 0.24) : _jBlueSoft)
                : (isDark ? Colors.white.withValues(alpha: 0.05) : _jPill),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? _jBlue
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
            ),
          ),
          child: Center(
            child: Text(
              mood.emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final bool isDark;
  final VoidCallback onTap;

  const _HistoryEntryCard({
    required this.entry,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preview = entry.answers.isEmpty ? '' : entry.answers.first.answer;
    final previewLines = preview.split(RegExp(r'\s+')).take(14).join(' ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : _jSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : _jLine),
            boxShadow: isDark
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x120D1B2A),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_moodEmoji(entry.mood), style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatEntryDate(entry.date),
                      style: GoogleFonts.inter(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : _jText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_wordCountForEntry(entry)} words',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _jBlue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$previewLines${preview.length > previewLines.length ? '...' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.55,
                        color: isDark ? Colors.white60 : _jMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(LucideIcons.chevronRight, size: 18, color: isDark ? Colors.white60 : _jMuted),
            ],
          ),
        ),
      ),
    );
  }

  int _wordCountForEntry(JournalEntry entry) {
    final text = entry.answers.map((answer) => answer.answer).join(' ').trim();
    if (text.isEmpty) {
      return 0;
    }
    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  String _formatEntryDate(DateTime date) {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (normalizedDate == normalizedNow) {
      return 'Today';
    }
    if (normalizedDate == normalizedNow.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

String _moodEmoji(String? mood) {
  switch (mood?.toLowerCase()) {
    case 'overwhelmed':
      return '😩';
    case 'anxious':
      return '😟';
    case 'okay':
      return '😐';
    case 'steady':
      return '🙂';
    case 'good':
      return '😊';
    case 'great':
      return '😄';
    case 'calm':
      return '😌';
    case 'neutral':
      return '😐';
    case 'down':
      return '😔';
    case 'sad':
      return '😢';
    default:
      return '📝';
  }
}
