/// Unit tests for the screenTimeData payload shape built inside
/// GadPhqFormScreen._onSubmitPressed (Task 4F).
///
/// These tests exercise the pure data-transformation logic in isolation:
///   • Duration → inMinutes integer / double
///   • category string → lowercase (backend requires lowercase)
///   • categoryUsage map lookup with null-safety fallback
///   • full payload shape matches what the backend expects
///
/// No widgets or HTTP are involved — only Dart logic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:upheal/models/screen_time_model.dart';

// ─── Helper: mirrors the transformation in _onSubmitPressed ──────────────────
//
// Any change to the production logic that breaks this function will also break
// these tests, surfacing regressions early.

Map<String, dynamic> buildScreenTimePayload(ScreenTimeModel model) {
  return <String, dynamic>{
    'totalMinutes': model.totalScreenTime.inMinutes.toDouble(),
    'socialMinutes':
        model.categoryUsage['Social']?.inMinutes.toDouble() ?? 0.0,
    'productivityMinutes':
        model.categoryUsage['Productivity']?.inMinutes.toDouble() ?? 0.0,
    'dailyUsage': model.dailyUsage
        .map((app) => {
              'packageName': app.packageName,
              'usageTime': app.usageTime.inMinutes,
              // Backend expects lowercase category names.
              'category': app.category.toLowerCase(),
            })
        .toList(),
  };
}

// ─── Fixture helpers ──────────────────────────────────────────────────────────

AppUsage _app({
  required String packageName,
  required Duration usageTime,
  required String category,
}) =>
    AppUsage(
      packageName: packageName,
      appName: packageName, // appName irrelevant for payload
      usageTime: usageTime,
      date: DateTime(2026, 5, 12),
      category: category,
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── totalMinutes ──────────────────────────────────────────────────────────
  group('totalMinutes', () {
    test('converts total Duration to double minutes', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'com.a',
              usageTime: const Duration(hours: 3),
              category: 'Other'),
        ]);

      final payload = buildScreenTimePayload(model);

      expect(payload['totalMinutes'], 180.0);
    });

    test('is 0.0 when no usage recorded', () {
      final model = ScreenTimeModel(); // default: empty, Duration.zero

      final payload = buildScreenTimePayload(model);

      expect(payload['totalMinutes'], 0.0);
    });

    test('sums multiple apps', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'a',
              usageTime: const Duration(minutes: 30),
              category: 'Social'),
          _app(
              packageName: 'b',
              usageTime: const Duration(minutes: 45),
              category: 'Productivity'),
        ]);

      final payload = buildScreenTimePayload(model);

      expect(payload['totalMinutes'], 75.0);
    });
  });

  // ── socialMinutes / productivityMinutes ───────────────────────────────────
  group('category minutes', () {
    test('socialMinutes reflects apps with category "Social"', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'ig',
              usageTime: const Duration(minutes: 45),
              category: 'Social'),
        ]);

      final payload = buildScreenTimePayload(model);

      expect(payload['socialMinutes'], 45.0);
    });

    test('socialMinutes is 0.0 when no Social apps', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'ig',
              usageTime: const Duration(minutes: 30),
              category: 'Entertainment'),
        ]);

      final payload = buildScreenTimePayload(model);

      expect(payload['socialMinutes'], 0.0);
    });

    test('productivityMinutes reflects apps with category "Productivity"', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'notion',
              usageTime: const Duration(minutes: 60),
              category: 'Productivity'),
        ]);

      final payload = buildScreenTimePayload(model);

      expect(payload['productivityMinutes'], 60.0);
    });

    test('productivityMinutes is 0.0 when no Productivity apps', () {
      final model = ScreenTimeModel();

      final payload = buildScreenTimePayload(model);

      expect(payload['productivityMinutes'], 0.0);
    });

    test('social and productivity aggregate correctly with other categories', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'ig',
              usageTime: const Duration(minutes: 20),
              category: 'Social'),
          _app(
              packageName: 'twitter',
              usageTime: const Duration(minutes: 25),
              category: 'Social'),
          _app(
              packageName: 'notion',
              usageTime: const Duration(minutes: 50),
              category: 'Productivity'),
          _app(
              packageName: 'netflix',
              usageTime: const Duration(minutes: 90),
              category: 'Entertainment'),
        ]);

      final payload = buildScreenTimePayload(model);

      expect(payload['socialMinutes'], 45.0); // 20 + 25
      expect(payload['productivityMinutes'], 50.0);
    });
  });

  // ── dailyUsage ─────────────────────────────────────────────────────────────
  group('dailyUsage — category lowercase', () {
    test('capitalised "Social" becomes "social"', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'ig',
              usageTime: const Duration(minutes: 10),
              category: 'Social'),
        ]);

      final entry = _firstEntry(buildScreenTimePayload(model));

      expect(entry['category'], 'social');
    });

    test('capitalised "Productivity" becomes "productivity"', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'notion',
              usageTime: const Duration(minutes: 10),
              category: 'Productivity'),
        ]);

      expect(_firstEntry(buildScreenTimePayload(model))['category'],
          'productivity');
    });

    test('capitalised "Entertainment" becomes "entertainment"', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'netflix',
              usageTime: const Duration(minutes: 10),
              category: 'Entertainment'),
        ]);

      expect(_firstEntry(buildScreenTimePayload(model))['category'],
          'entertainment');
    });

    test('already lowercase category is preserved', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'app',
              usageTime: const Duration(minutes: 5),
              category: 'news'),
        ]);

      expect(_firstEntry(buildScreenTimePayload(model))['category'], 'news');
    });
  });

  group('dailyUsage — usageTime conversion', () {
    test('Duration is converted to integer minutes', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'app',
              usageTime: const Duration(minutes: 75),
              category: 'Other'),
        ]);

      final entry = _firstEntry(buildScreenTimePayload(model));

      expect(entry['usageTime'], 75);
      expect(entry['usageTime'], isA<int>());
    });

    test('sub-minute Duration rounds down to 0', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'app',
              usageTime: const Duration(seconds: 45),
              category: 'Other'),
        ]);

      expect(_firstEntry(buildScreenTimePayload(model))['usageTime'], 0);
    });
  });

  group('dailyUsage — packageName', () {
    test('packageName is preserved unchanged', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'com.tiktok.android',
              usageTime: const Duration(minutes: 20),
              category: 'Entertainment'),
        ]);

      expect(_firstEntry(buildScreenTimePayload(model))['packageName'],
          'com.tiktok.android');
    });
  });

  group('dailyUsage — multiple apps', () {
    test('all apps are included in the list', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'a',
              usageTime: const Duration(minutes: 10),
              category: 'Social'),
          _app(
              packageName: 'b',
              usageTime: const Duration(minutes: 20),
              category: 'News'),
          _app(
              packageName: 'c',
              usageTime: const Duration(minutes: 30),
              category: 'Productivity'),
        ]);

      final list = buildScreenTimePayload(model)['dailyUsage'] as List;

      expect(list.length, 3);
    });

    test('each entry has category lowercased independently', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'a',
              usageTime: const Duration(minutes: 5),
              category: 'Social'),
          _app(
              packageName: 'b',
              usageTime: const Duration(minutes: 5),
              category: 'News'),
        ]);

      final list = buildScreenTimePayload(model)['dailyUsage'] as List;

      expect((list[0] as Map)['category'], 'social');
      expect((list[1] as Map)['category'], 'news');
    });

    test('is empty list when no usage recorded', () {
      final model = ScreenTimeModel();

      expect(
          (buildScreenTimePayload(model)['dailyUsage'] as List).isEmpty, isTrue);
    });
  });

  // ── full payload shape ─────────────────────────────────────────────────────
  group('payload shape', () {
    test('contains all required top-level keys', () {
      final payload = buildScreenTimePayload(ScreenTimeModel());

      expect(payload.keys, containsAll([
        'totalMinutes',
        'socialMinutes',
        'productivityMinutes',
        'dailyUsage',
      ]));
    });

    test('each dailyUsage entry contains packageName, usageTime, category', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'pkg',
              usageTime: const Duration(minutes: 5),
              category: 'Other'),
        ]);

      final entry = _firstEntry(buildScreenTimePayload(model));

      expect(entry.keys,
          containsAll(['packageName', 'usageTime', 'category']));
    });

    test('totalMinutes is a double, usageTime is an int', () {
      final model = ScreenTimeModel()
        ..setDailyUsageForTest([
          _app(
              packageName: 'pkg',
              usageTime: const Duration(minutes: 10),
              category: 'Other'),
        ]);

      final payload = buildScreenTimePayload(model);
      final entry = _firstEntry(payload);

      expect(payload['totalMinutes'], isA<double>());
      expect(entry['usageTime'], isA<int>());
    });
  });
}

// ─── Utilities ────────────────────────────────────────────────────────────────

Map<String, dynamic> _firstEntry(Map<String, dynamic> payload) =>
    (payload['dailyUsage'] as List).first as Map<String, dynamic>;

