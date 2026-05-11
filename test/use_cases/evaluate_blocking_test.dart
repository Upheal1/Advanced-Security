import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:upheal/models/hive/block_rule.dart';
import 'package:upheal/services/app_blocking_service.dart';
import 'package:upheal/use_cases/evaluate_blocking_use_case.dart';

void main() {
  setUpAll(() async {
    // Initialize Hive for testing (in-memory)
    Hive.init('test_data');
    Hive.registerAdapter(BlockRuleAdapter());
    Hive.registerAdapter(DailyUsageAdapter());
  });

  setUp(() async {
    // Clear boxes before each test
    if (Hive.isBoxOpen('block_rules')) {
      await Hive.box<BlockRule>('block_rules').clear();
    }
    if (Hive.isBoxOpen('daily_usage')) {
      await Hive.box<DailyUsage>('daily_usage').clear();
    }
    
    // Initialize service
    await AppBlockingService.initialize();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('EvaluateBlockingUseCase', () {
    test('should return not blocked when no rule exists', () {
      final useCase = EvaluateBlockingUseCase();
      final result = useCase.execute('com.example.app');

      expect(result['isBlocked'], false);
      expect(result['reason'], null);
    });

    test('should return blocked when app is permanently blocked', () async {
      // Setup: block an app
      await AppBlockingService.setRule(
        BlockRule(
          packageName: 'com.tiktok.app',
          appName: 'TikTok',
          isBlocked: true,
        ),
      );

      final useCase = EvaluateBlockingUseCase();
      final result = useCase.execute('com.tiktok.app');

      expect(result['isBlocked'], true);
      expect(result['reason'], 'blocked_by_user');
      expect(result['remainingMinutes'], isNotNull);
    });

    test('should return blocked when daily limit is reached', () async {
      // Setup: set 30-minute limit
      await AppBlockingService.setRule(
        BlockRule(
          packageName: 'com.instagram.app',
          dailyLimitMinutes: 30,
        ),
      );

      // Simulate 30 minutes of usage today
      await AppBlockingService.addUsageToday('com.instagram.app', 30);

      final useCase = EvaluateBlockingUseCase();
      final result = useCase.execute('com.instagram.app');

      expect(result['isBlocked'], true);
      expect(result['reason'], 'daily_limit_reached');
    });

    test('should return not blocked when under daily limit', () async {
      // Setup: set 60-minute limit
      await AppBlockingService.setRule(
        BlockRule(
          packageName: 'com.spotify.app',
          dailyLimitMinutes: 60,
        ),
      );

      // Simulate 30 minutes of usage (under limit)
      await AppBlockingService.addUsageToday('com.spotify.app', 30);

      final useCase = EvaluateBlockingUseCase();
      final result = useCase.execute('com.spotify.app');

      expect(result['isBlocked'], false);
      expect(result['reason'], null);
    });

    test('should format remaining time correctly', () {
      final useCase = EvaluateBlockingUseCase();

      expect(useCase.getRemainingTimeText(125), '02:05');
      expect(useCase.getRemainingTimeText(60), '01:00');
      expect(useCase.getRemainingTimeText(5), '00:05');
      expect(useCase.getRemainingTimeText(0), '--:--');
      expect(useCase.getRemainingTimeText(null), '--:--');
    });

    test('should provide user-friendly reason text', () {
      final useCase = EvaluateBlockingUseCase();

      expect(useCase.getReasonText('daily_limit_reached'), 'Daily limit reached');
      expect(useCase.getReasonText('blocked_by_user'), 'Blocked by you');
      expect(useCase.getReasonText('focus_session'), 'Focus session active');
      expect(useCase.getReasonText(null), 'App is blocked');
    });
  });

  group('EmergencyAllowUseCase', () {
    test('should grant emergency allow once per day', () async {
      // Setup: block with emergency allowed
      await AppBlockingService.setRule(
        BlockRule(
          packageName: 'com.test.app',
          dailyLimitMinutes: 30,
          emergencyAllowed: true,
        ),
      );

      final useCase = EmergencyAllowUseCase();
      
      // First use - should succeed
      final result1 = await useCase.execute('com.test.app');
      expect(result1['success'], true);

      // Second use same day - should fail
      final result2 = await useCase.execute('com.test.app');
      expect(result2['success'], false);
      expect(result2['error'], contains('already used'));
    });

    test('should fail if emergency not enabled', () async {
      await AppBlockingService.setRule(
        BlockRule(
          packageName: 'com.nonemergency.app',
          dailyLimitMinutes: 30,
          emergencyAllowed: false, // Not enabled
        ),
      );

      final useCase = EmergencyAllowUseCase();
      final result = await useCase.execute('com.nonemergency.app');

      expect(result['success'], false);
      expect(result['error'], isNotNull);
    });
  });

  group('GetRemainingTimeUseCase', () {
    test('should return remaining minutes correctly', () async {
      await AppBlockingService.setRule(
        BlockRule(
          packageName: 'com.test.app',
          dailyLimitMinutes: 60,
        ),
      );

      await AppBlockingService.addUsageToday('com.test.app', 20);

      final useCase = GetRemainingTimeUseCase();
      final remaining = useCase.execute('com.test.app');

      expect(remaining, 40); // 60 - 20
    });

    test('should return null when no limit set', () {
      final useCase = GetRemainingTimeUseCase();
      final remaining = useCase.execute('com.no.limit.app');

      expect(remaining, null);
    });
  });
}
