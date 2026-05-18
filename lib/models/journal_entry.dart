/// Journal entry model for MindQuest app.
/// Maps directly to the Supabase `journal_entries` table schema.
class JournalEntry {
  final String id;
  final DateTime date;
  final DateTime timestamp;
  final String entryText;
  final String? moodLabel;
  final int? moodScore;
  final String? title;
  final List<String> tags;
  final String? promptText;
  final String? sourceType;
  final int? wordCount;
  final int? xpAwarded;

  JournalEntry({
    required this.id,
    required this.date,
    required this.entryText,
    required this.timestamp,
    this.moodLabel,
    this.moodScore,
    this.title,
    this.tags = const [],
    this.promptText,
    this.sourceType,
    this.wordCount,
    this.xpAwarded,
  });

  /// Serialize for local Hive storage.
  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'timestamp': timestamp.toIso8601String(),
        'entryText': entryText,
        'moodLabel': moodLabel,
        'moodScore': moodScore,
        'title': title,
        'tags': tags,
        'promptText': promptText,
        'sourceType': sourceType,
        'wordCount': wordCount,
        'xpAwarded': xpAwarded,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
        entryText: json['entryText'] as String? ?? '',
        moodLabel: json['moodLabel'] as String?,
        moodScore: json['moodScore'] as int?,
        title: json['title'] as String?,
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        promptText: json['promptText'] as String?,
        sourceType: json['sourceType'] as String?,
        wordCount: json['wordCount'] as int?,
        xpAwarded: json['xpAwarded'] as int?,
      );

  /// Create a [JournalEntry] from a Supabase `journal_entries` row.
  factory JournalEntry.fromSupabase(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at'] as String);
    return JournalEntry(
      id: json['id'] as String,
      date: DateTime(createdAt.year, createdAt.month, createdAt.day),
      timestamp: createdAt,
      entryText: json['entry_text'] as String? ?? '',
      moodLabel: json['mood_label'] as String?,
      moodScore: json['mood_score'] as int?,
      title: json['title'] as String?,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      promptText: json['prompt_text'] as String?,
      sourceType: json['source_type'] as String?,
      wordCount: json['word_count'] as int?,
    );
  }

  /// Serialize to a Supabase insert payload (no `id` — let Supabase generate it).
  Map<String, dynamic> toSupabase(String userId) => {
        'user_id': userId,
        'entry_text': entryText,
        'mood_label': moodLabel,
        'mood_score': moodScore,
        'title': title,
        'tags': tags,
        'is_archived': false,
        'created_at': timestamp.toIso8601String(),
        'updated_at': timestamp.toIso8601String(),
        'prompt_text': promptText,
        'source_type': sourceType,
        'word_count': wordCount,
      };
}

