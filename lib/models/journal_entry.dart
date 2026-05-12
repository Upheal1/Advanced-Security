// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';

/// Journal entry model for MindQuest app.
/// Follows the project's manual serialization pattern.
class JournalEntry {
  final String id;
  final DateTime date;
  final List<QuestionAnswer> answers;
  final String? mood;
  final DateTime timestamp;
  final int? xpAwarded;

  JournalEntry({
    required this.id,
    required this.date,
    required this.answers,
    this.mood,
    required this.timestamp,
    this.xpAwarded,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'answers': answers.map((a) => a.toJson()).toList(),
        'mood': mood,
        'timestamp': timestamp.toIso8601String(),
        'xpAwarded': xpAwarded,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        answers: (json['answers'] as List)
            .map((a) => QuestionAnswer.fromJson(a as Map<String, dynamic>))
            .toList(),
        mood: json['mood'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        xpAwarded: json['xpAwarded'] as int?,
      );

  /// Create a [JournalEntry] from a Supabase `journal_entries` row.
  factory JournalEntry.fromSupabase(Map<String, dynamic> json) {
    List<QuestionAnswer> answers = [];
    try {
      final raw = json['content'] as String? ?? '[]';
      final decoded = jsonDecode(raw) as List;
      answers = decoded
          .map((a) => QuestionAnswer.fromJson(a as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Plain-text content — wrap as a single answer so UI doesn't break.
      final text = json['content'] as String? ?? '';
      if (text.isNotEmpty) {
        answers = [QuestionAnswer(question: 'Entry', answer: text)];
      }
    }
    final createdAt = DateTime.parse(json['created_at'] as String);
    return JournalEntry(
      id: json['id'] as String,
      date: DateTime(createdAt.year, createdAt.month, createdAt.day),
      answers: answers,
      mood: json['mood'] as String?,
      timestamp: createdAt,
      xpAwarded: null,
    );
  }

  /// Serialize to a Supabase insert payload (no `id` — let Supabase generate it).
  Map<String, dynamic> toSupabase(String userId) => {
        'user_id': userId,
        'content': jsonEncode(answers.map((a) => a.toJson()).toList()),
        'mood': mood,
        'is_archived': false,
        'created_at': date.toIso8601String(),
        'updated_at': timestamp.toIso8601String(),
      };
}

class QuestionAnswer {
  final String question;
  final String answer;

  QuestionAnswer({
    required this.question,
    required this.answer,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
      };

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) => QuestionAnswer(
        question: json['question'] as String,
        answer: json['answer'] as String,
      );
}

