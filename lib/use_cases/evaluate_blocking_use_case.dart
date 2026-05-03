import '../services/app_blocking_service.dart';
import '../models/hive/block_rule.dart';

/// Domain use case: Evaluate if an app should be blocked
/// Returns structured result with reason and remaining time
class EvaluateBlockingUseCase {
  /// Execute the use case
  /// Returns: {isBlocked, reason, remainingMinutes, canEmergencyAllow}
  Map<String, dynamic> execute(String packageName) {
    final evaluation = AppBlockingService.evaluateBlock(packageName);
    final rule = AppBlockingService.getRule(packageName);
    
    return {
      'isBlocked': evaluation['isBlocked'] as bool,
      'reason': evaluation['reason'] as String?,
      'remainingMinutes': evaluation['remainingMinutes'] as int?,
      'canEmergencyAllow': rule?.emergencyAllowed ?? false,
      'hasUsedEmergencyToday': rule != null && !AppBlockingService.canUseEmergencyAllow(packageName),
    };
  }

  /// Get remaining time in human-readable format
  String getRemainingTimeText(int? remainingMinutes) {
    if (remainingMinutes == null || remainingMinutes == 0) {
      return '--:--';
    }

    final hours = remainingMinutes ~/ 60;
    final minutes = remainingMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// Get user-friendly reason text
  String getReasonText(String? reason) {
    switch (reason) {
      case 'daily_limit_reached':
        return 'Daily limit reached';
      case 'blocked_by_user':
        return 'Blocked by you';
      case 'focus_session':
        return 'Focus session active';
      case 'emergency_allowed':
        return 'Emergency allowed';
      default:
        return 'App is blocked';
    }
  }
}

/// Use case: Set daily limit for an app
class SetDailyLimitUseCase {
  Future<void> execute({
    required String packageName,
    String? appName,
    required int dailyLimitMinutes,
    bool emergencyAllowed = false,
  }) async {
    final existing = AppBlockingService.getRule(packageName);
    
    final rule = BlockRule(
      packageName: packageName,
      appName: appName ?? existing?.appName,
      dailyLimitMinutes: dailyLimitMinutes,
      isBlocked: existing?.isBlocked ?? false, // Preserve block status
      emergencyAllowed: emergencyAllowed,
      lastEmergencyDate: existing?.lastEmergencyDate,
    );

    await AppBlockingService.setRule(rule);
  }
}

/// Use case: Toggle permanent block status
class ToggleBlockUseCase {
  Future<void> execute({
    required String packageName,
    String? appName,
    required bool isBlocked,
  }) async {
    final existing = AppBlockingService.getRule(packageName);
    
    final rule = BlockRule(
      packageName: packageName,
      appName: appName ?? existing?.appName,
      dailyLimitMinutes: existing?.dailyLimitMinutes ?? 0,
      isBlocked: isBlocked,
      emergencyAllowed: existing?.emergencyAllowed ?? false,
      lastEmergencyDate: existing?.lastEmergencyDate,
    );

    await AppBlockingService.setRule(rule);
  }
}

/// Use case: Grant emergency allow (5 minutes)
class EmergencyAllowUseCase {
  Future<Map<String, dynamic>> execute(String packageName) async {
    try {
      final canUse = AppBlockingService.canUseEmergencyAllow(packageName);
      if (!canUse) {
        return {
          'success': false,
          'error': 'Emergency allow already used today',
        };
      }

      await AppBlockingService.grantEmergencyAllow(packageName);
      return {
        'success': true,
        'allowedUntil': DateTime.now().add(const Duration(minutes: 5)),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

/// Use case: Get remaining time for an app
class GetRemainingTimeUseCase {
  int? execute(String packageName) {
    return AppBlockingService.getRemainingToday(packageName);
  }
}
