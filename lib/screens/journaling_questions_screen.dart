import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/journal_entry.dart';
import '../constants/app_colors.dart';

// ─────────────────────────── Design tokens ────────────────────────────────

const Color _dvSky  = Color(0xFF72B4D5);
const Color _dvTeal = Color(0xFF4ECDC4);
const Color _dvGray = Color(0xFF6B7280);
const Color _dvGold = Color(0xFFD97706);

// ─────────────────────────── Screen ───────────────────────────────────────

class JournalingDetailsScreen extends StatelessWidget {
  final JournalEntry entry;
  const JournalingDetailsScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = _formatDate(entry.date);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1419) : const Color(0xFFFAFAF8),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft,
            color: isDark ? Colors.white : AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Journal Entry',
          style: GoogleFonts.inter(
            fontSize: 17, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary)),
        actions: [
          if (entry.xpAwarded != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _dvGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _dvGold.withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('${entry.xpAwarded} XP',
                  style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _dvGold)),
              ]),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header card ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2535) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(dateStr,
                    style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('${entry.answers.length} question${entry.answers.length != 1 ? 's' : ''} answered',
                    style: GoogleFonts.inter(
                      fontSize: 13, color: isDark ? Colors.white54 : _dvGray)),
                ]),
              ),
              if (entry.mood != null) _MoodBadge(mood: entry.mood!, isDark: isDark),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Q&A cards ──────────────────────────────────────────────
          ...entry.answers.asMap().entries.map((e) => _QACard(
            index: e.key,
            qa: e.value,
            isDark: isDark,
          )),
        ]),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ─────────────────────────── Sub-widgets ──────────────────────────────────

String _moodEmoji(String? mood) {
  switch (mood?.toLowerCase()) {
    case 'great':   return '😄';
    case 'good':    return '😊';
    case 'calm':    return '😌';
    case 'neutral': return '😐';
    case 'down':    return '😔';
    case 'anxious': return '😰';
    case 'sad':     return '😢';
    default:        return '🌿';
  }
}

Color _moodColor(String? mood) {
  switch (mood?.toLowerCase()) {
    case 'great':   return const Color(0xFFFFD60A);
    case 'good':    return const Color(0xFF6B9E5E);
    case 'calm':    return _dvSky;
    case 'neutral': return const Color(0xFF9CA3AF);
    case 'down':    return const Color(0xFF9B8EC4);
    case 'anxious': return const Color(0xFFFF8F6B);
    case 'sad':     return const Color(0xFF7BA7BC);
    default:        return _dvTeal;
  }
}

class _MoodBadge extends StatelessWidget {
  final String mood;
  final bool isDark;
  const _MoodBadge({required this.mood, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = _moodColor(mood);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(_moodEmoji(mood), style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(mood,
          style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

class _QACard extends StatelessWidget {
  final int index;
  final QuestionAnswer qa;
  final bool isDark;
  const _QACard({required this.index, required this.qa, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2535) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: _dvTeal.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, color: _dvTeal)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(qa.question,
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : _dvGray, height: 1.4)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(qa.answer,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: isDark ? Colors.white : AppColors.textPrimary,
              height: 1.65)),
        ]),
      ),
    );
  }
}
