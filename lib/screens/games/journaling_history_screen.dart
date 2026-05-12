import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/journal_entry.dart';
import '../../models/journal_model.dart';
import '../../constants/app_colors.dart';
import '../journaling_details_screen.dart';
import '../journaling_questions_screen.dart';

// ─────────────────────────── Design tokens ────────────────────────────────

const Color _hiTeal = Color(0xFF4ECDC4);
const Color _hiSky  = Color(0xFF72B4D5);
const Color _hiGray = Color(0xFF6B7280);
const Color _hiGold = Color(0xFFD97706);

// ─────────────────────────── Screen ───────────────────────────────────────

class JournalingHistoryScreen extends StatefulWidget {
  const JournalingHistoryScreen({super.key});

  @override
  State<JournalingHistoryScreen> createState() => _JournalingHistoryScreenState();
}

class _JournalingHistoryScreenState extends State<JournalingHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searchActive = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalModel>().loadEntries();
    });
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<JournalEntry> _filtered(List<JournalEntry> entries) {
    if (_query.isEmpty) return entries;
    return entries.where((e) {
      final answersText = e.answers.map((a) => '${a.question} ${a.answer}').join(' ').toLowerCase();
      final moodText = (e.mood ?? '').toLowerCase();
      return answersText.contains(_query) || moodText.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        title: _searchActive
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search entries…',
                  hintStyle: GoogleFonts.inter(
                    color: isDark ? Colors.white38 : _hiGray.withValues(alpha: 0.6)),
                  border: InputBorder.none,
                ),
              )
            : Text('All Entries',
                style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(_searchActive ? LucideIcons.x : LucideIcons.search,
              color: isDark ? Colors.white : AppColors.textPrimary),
            onPressed: () {
              setState(() {
                _searchActive = !_searchActive;
                if (!_searchActive) {
                  _searchCtrl.clear();
                  _query = '';
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final model = context.read<JournalModel>();
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const JournalingQuestionsScreen()),
          );
          if (res == true && mounted) model.refresh();
        },
        backgroundColor: _hiTeal,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: Icon(LucideIcons.pencil, size: 20),
        label: Text('New Entry', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: Consumer<JournalModel>(
        builder: (context, model, _) {
          if (model.isLoading && model.entries.isEmpty) {
            return Center(child: CircularProgressIndicator(color: _hiTeal));
          }
          if (model.hasError && model.entries.isEmpty) {
            return _ErrorState(
              message: model.errorMessage ?? 'Unknown error',
              onRetry: model.loadEntries,
              isDark: isDark,
            );
          }
          final entries = _filtered(model.entries);

          if (entries.isEmpty) {
            return _EmptyState(
              isDark: isDark,
              isFiltered: _query.isNotEmpty,
              onNew: () async {
                final res = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const JournalingQuestionsScreen()),
                );
                if (res == true && mounted) model.refresh();
              },
            );
          }

          return RefreshIndicator(
            color: _hiTeal,
            onRefresh: model.refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: entries.length,
              itemBuilder: (_, i) => _HistoryCard(
                entry: entries[i],
                isDark: isDark,
                onDelete: () async {
                  final ok = await model.deleteEntry(entries[i].id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'Entry deleted' : 'Failed to delete',
                      style: GoogleFonts.inter()),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: ok ? Colors.grey.shade800 : Colors.red.shade400,
                  ));
                },
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JournalingDetailsScreen(entry: entries[i])),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────── History card ─────────────────────────────────

class _HistoryCard extends StatefulWidget {
  final JournalEntry entry;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const _HistoryCard({
    required this.entry,
    required this.isDark,
    required this.onDelete,
    required this.onTap,
  });
  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final isDark = widget.isDark;
    final dateStr = _dateLabel(e.date);
    final preview = e.answers.isNotEmpty ? e.answers.first.answer : '';
    final moodEmoji = _moodEmoji(e.mood);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2535) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Header row ──────────────────────────────────────
              Row(children: [
                Text(moodEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary)),
                    if (e.mood != null)
                      Text(e.mood!,
                        style: GoogleFonts.inter(
                          fontSize: 12, color: isDark ? Colors.white54 : _hiGray)),
                  ]),
                ),
                if (e.xpAwarded != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _hiGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _hiGold.withValues(alpha: 0.35)),
                    ),
                    child: Text('+${e.xpAwarded} XP',
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w700, color: _hiGold)),
                  ),
                const SizedBox(width: 8),
                Icon(_expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 18,
                  color: isDark ? Colors.white30 : _hiGray.withValues(alpha: 0.5)),
              ]),

              // ── Preview / expanded ───────────────────────────────
              const SizedBox(height: 10),
              Text(preview,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : AppColors.textPrimary, height: 1.55),
                maxLines: _expanded ? null : 2,
                overflow: _expanded ? null : TextOverflow.ellipsis),

              if (_expanded) ...[
                // Remaining Q&As
                if (e.answers.length > 1) ...[
                  const SizedBox(height: 14),
                  ...e.answers.skip(1).map((qa) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(qa.question,
                        style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w600, color: _hiTeal)),
                      const SizedBox(height: 4),
                      Text(qa.answer,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : _hiGray, height: 1.55)),
                    ]),
                  )),
                ],
                Divider(
                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                  height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton.icon(
                    onPressed: widget.onTap,
                    icon: const Icon(LucideIcons.externalLink, size: 14),
                    label: Text('Full View', style: GoogleFonts.inter(fontSize: 13)),
                    style: TextButton.styleFrom(foregroundColor: _hiSky),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(context, isDark),
                    icon: const Icon(LucideIcons.trash2, size: 14),
                    label: Text('Delete', style: GoogleFonts.inter(fontSize: 13)),
                    style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
                  ),
                ]),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, bool isDark) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2535) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete entry?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary)),
        content: Text('This cannot be undone.',
          style: GoogleFonts.inter(color: isDark ? Colors.white70 : _hiGray)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: _hiTeal))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); widget.onDelete(); },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const wdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${wdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _moodEmoji(String? mood) {
    switch (mood?.toLowerCase()) {
      case 'great':   return '😄';
      case 'good':    return '😊';
      case 'calm':    return '😌';
      case 'neutral': return '😐';
      case 'down':    return '😔';
      case 'anxious': return '😰';
      case 'sad':     return '😢';
      default:        return '📝';
    }
  }
}

// ─────────────────────────── Empty / error states ─────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark, isFiltered;
  final VoidCallback onNew;
  const _EmptyState({required this.isDark, required this.isFiltered, required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              color: _hiTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(isFiltered ? '🔍' : '📓',
              style: const TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 20),
          Text(
            isFiltered ? 'No matching entries' : 'No entries yet',
            style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try different search terms'
                : 'Your first reflection is just one tap away',
            style: GoogleFonts.inter(
              fontSize: 14, color: isDark ? Colors.white54 : _hiGray, height: 1.5),
            textAlign: TextAlign.center),
          if (!isFiltered) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onNew,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hiTeal, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Write First Entry',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;
  const _ErrorState({required this.message, required this.onRetry, required this.isDark});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('⚠️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('Something went wrong',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(message,
          style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white54 : _hiGray),
          textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: _hiTeal, foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ]),
    ),
  );
}

