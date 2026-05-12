import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../widgets/drawer_menu_button.dart';
import '../models/journal_model.dart';
import '../models/journal_entry.dart';
import '../constants/app_colors.dart';
import 'journaling_details_screen.dart';
import 'games/journaling_history_screen.dart';

// ─────────────────────────── Design tokens ────────────────────────────────

const Color _jSky  = Color(0xFF72B4D5);
const Color _jTeal = Color(0xFF4ECDC4);
const Color _jGray = Color(0xFF6B7280);
const Color _jGold = Color(0xFFD97706);

const List<String> _dailyPrompts = [
  "What are three things you're grateful for today?",
  "What small victory did you have today?",
  "What emotion came up today, and where did you feel it?",
  "What would you tell a friend going through what you're experiencing?",
  "What is one thing you want to let go of today?",
  "How are you different than you were 30 days ago?",
  "What did today teach you?",
];

// ─────────────────────────── Screen ───────────────────────────────────────

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  bool _promptDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalModel>().loadEntries();
    });
  }

  String get _todayPrompt {
    final doy = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _dailyPrompts[doy % _dailyPrompts.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1419) : const Color(0xFFFAFAF8),
      body: Consumer<JournalModel>(
        builder: (context, model, _) => CustomScrollView(
          slivers: [
            _buildAppBar(context, model, isDark),
            SliverToBoxAdapter(child: _buildBody(context, model, isDark)),
            _buildEntryList(context, model, isDark),
          ],
        ),
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
        backgroundColor: _jTeal,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: Icon(LucideIcons.pencil, size: 20),
        label: Text('Write', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, JournalModel model, bool isDark) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: isDark ? const Color(0xFF1A1F2E) : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: DrawerMenuButton(
        iconColor: isDark ? Colors.white : AppColors.textPrimary,
      ),
      title: Text(
        'Your Journal',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _jGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _jGold.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '${model.entries.length}',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _jGold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, JournalModel model, bool isDark) {
    final thisWeek = model.entries.where((e) =>
      e.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length;
    final totalXp = model.entries.fold(0, (s, e) => s + (e.xpAwarded ?? 10));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats bar ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2535) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                _StatCell(icon: '📝', value: '${model.entries.length}', label: 'Reflections', isDark: isDark),
                _VertDiv(isDark: isDark),
                _StatCell(icon: '📅', value: '$thisWeek', label: 'This Week', isDark: isDark),
                _VertDiv(isDark: isDark),
                _StatCell(icon: '⭐', value: '$totalXp', label: 'XP Earned', isDark: isDark),
              ],
            ),
          ),

          // ── Prompt of the day ──────────────────────────────────────
          if (!_promptDismissed) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _jSky.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _jSky.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _jSky.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("Today's Prompt",
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _jSky, letterSpacing: 0.3)),
                        ),
                        const SizedBox(height: 8),
                        Text(_todayPrompt,
                          style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white70 : _jGray, height: 1.55)),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () async {
                            final model = context.read<JournalModel>();
                            final res = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (_) => const JournalingQuestionsScreen()),
                            );
                            if (res == true && mounted) model.refresh();
                          },
                          child: Text('Start Writing →',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _jSky)),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _promptDismissed = true),
                    child: Icon(LucideIcons.x, size: 18,
                      color: isDark ? Colors.white38 : _jGray.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Section heading ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                model.entries.isEmpty ? 'Begin Your Journey' : 'Recent Entries',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary),
              ),
              if (model.entries.isNotEmpty)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const JournalingHistoryScreen())),
                  child: Text('View All →',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: _jTeal)),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildEntryList(BuildContext context, JournalModel model, bool isDark) {
    if (model.isLoading && model.entries.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: _jTeal)));
    }
    if (model.entries.isEmpty) {
      return SliverFillRemaining(
        child: _EmptyState(isDark: isDark, onTap: () async {
          final model = context.read<JournalModel>();
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const JournalingQuestionsScreen()),
          );
          if (res == true && mounted) model.refresh();
        }),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final e = model.entries[i];
            return _JournalCard(entry: e, isDark: isDark, onDelete: () => model.deleteEntry(e.id));
          },
          childCount: model.entries.length.clamp(0, 3),
        ),
      ),
    );
  }
}

// ─────────────────────────── Sub-widgets ──────────────────────────────────

class _StatCell extends StatelessWidget {
  final String icon, value, label;
  final bool isDark;
  const _StatCell({required this.icon, required this.value, required this.label, required this.isDark});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 6),
      Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : AppColors.textPrimary)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white54 : _jGray)),
    ]),
  );
}

class _VertDiv extends StatelessWidget {
  final bool isDark;
  const _VertDiv({required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    height: 40, width: 1,
    color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07));
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _EmptyState({required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 96, height: 96,
        decoration: BoxDecoration(color: _jTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: const Center(child: Text('📓', style: TextStyle(fontSize: 44))),
      ),
      const SizedBox(height: 24),
      Text('Your journey starts with\na single word',
        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textPrimary),
        textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text('Write your first reflection and earn +10 XP',
        style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white54 : _jGray, height: 1.5),
        textAlign: TextAlign.center),
      const SizedBox(height: 28),
      ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _jTeal, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text('Begin Writing', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    ]),
  );
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

class _JournalCard extends StatefulWidget {
  final JournalEntry entry;
  final bool isDark;
  final Future<bool> Function() onDelete;
  const _JournalCard({required this.entry, required this.isDark, required this.onDelete});
  @override
  State<_JournalCard> createState() => _JournalCardState();
}

class _JournalCardState extends State<_JournalCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final isDark = widget.isDark;
    final dateStr = _dateLabel(e.date, e.timestamp);
    final preview = e.answers.isNotEmpty ? e.answers.first.answer : '';

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
              Row(children: [
                Text(_moodEmoji(e.mood), style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(child: Text(dateStr,
                  style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white60 : _jGray))),
                Icon(_expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 18, color: isDark ? Colors.white30 : _jGray.withValues(alpha: 0.5)),
              ]),
              const SizedBox(height: 8),
              Text(preview,
                style: GoogleFonts.inter(fontSize: 15,
                  color: isDark ? Colors.white.withValues(alpha: 0.87) : AppColors.textPrimary, height: 1.55),
                maxLines: _expanded ? null : 2,
                overflow: _expanded ? null : TextOverflow.ellipsis),
              if (_expanded) ...[
                if (e.answers.length > 1) ...[
                  const SizedBox(height: 12),
                  ...e.answers.skip(1).map((qa) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(qa.question,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _jTeal)),
                      const SizedBox(height: 3),
                      Text(qa.answer,
                        style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white70 : _jGray, height: 1.5)),
                    ]),
                  )),
                ],
                Divider(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06), height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await _confirmDelete(context, isDark);
                      if (confirm == true) widget.onDelete();
                    },
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

  Future<bool?> _confirmDelete(BuildContext ctx, bool isDark) => showDialog<bool>(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E2535) : Colors.white,
      title: Text('Delete entry?',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimary)),
      content: Text('This cannot be undone.',
        style: GoogleFonts.inter(color: isDark ? Colors.white70 : _jGray)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel', style: TextStyle(color: _jTeal))),
        TextButton(onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete')),
      ],
    ),
  );

  String _dateLabel(DateTime date, DateTime ts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today • ${_timeStr(ts)}';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const wdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${wdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _timeStr(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

