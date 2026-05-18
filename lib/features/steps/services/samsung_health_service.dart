import 'dart:async';
import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';
import '../domain/models/step_data.dart';
import 'step_sensor_service.dart';

/// Unified step data service that can use multiple sources:
/// 1. Samsung Health (via platform channel)
/// 2. Health Connect (Android)
/// 3. Built-in Pedometer (fallback)
class StepDataService {
  static const MethodChannel _channel = MethodChannel('com.upheal/health_data');
  static const EventChannel _healthConnectChannel = EventChannel('com.upheal/health_connect/steps');

  final StepSensorService _pedometerService;
  SamsungHealthService? _samsungHealth;
  HealthConnectService? _healthConnect;

  StepDataSource _currentSource = StepDataSource.pedometer;
  bool _isInitialized = false;

  StepDataService({
    StepSensorService? pedometerService,
  }) : _pedometerService = pedometerService ?? StepSensorService();

  StepDataSource get currentSource => _currentSource;
  bool get isInitialized => _isInitialized;

  /// Initialize the best available step data source
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Try Samsung Health first
    _samsungHealth = SamsungHealthService();
    if (await _samsungHealth!.isSamsungHealthAvailable()) {
      if (await _samsungHealth!.connect()) {
        if (await _samsungHealth!.requestPermission()) {
          _currentSource = StepDataSource.samsungHealth;
          _isInitialized = true;
          return true;
        }
      }
    }

    // Try Health Connect
    _healthConnect = HealthConnectService();
    if (await _healthConnect!.isAvailable()) {
      if (await _healthConnect!.requestPermission()) {
        _currentSource = StepDataSource.healthConnect;
        _isInitialized = true;
        return true;
      }
    }

    // Fall back to built-in pedometer
    final pedometerResult = await _pedometerService.initialize();
    if (pedometerResult) {
      _currentSource = StepDataSource.pedometer;
      _isInitialized = true;
      return true;
    }

    return false;
  }

  /// Get today's step count
  Future<int> getTodaySteps() async {
    switch (_currentSource) {
      case StepDataSource.samsungHealth:
        return await _samsungHealth?.getTodaySteps() ?? 0;
      case StepDataSource.healthConnect:
        return await _healthConnect?.getTodaySteps() ?? 0;
      case StepDataSource.pedometer:
        return _pedometerService.getCurrentSteps();
    }
  }

  /// Get step data for a specific date
  Future<StepData?> getStepsForDate(DateTime date) async {
    switch (_currentSource) {
      case StepDataSource.samsungHealth:
        return await _samsungHealth?.getStepsForDate(date);
      case StepDataSource.healthConnect:
        return await _healthConnect?.getStepsForDate(date);
      case StepDataSource.pedometer:
        return null; // Pedometer doesn't support historical data
    }
  }

  /// Get step history
  Future<List<StepData>> getStepHistory(DateTime startDate, DateTime endDate) async {
    switch (_currentSource) {
      case StepDataSource.samsungHealth:
        return await _samsungHealth?.getStepHistory(startDate, endDate) ?? [];
      case StepDataSource.healthConnect:
        return await _healthConnect?.getStepHistory(startDate, endDate) ?? [];
      case StepDataSource.pedometer:
        return []; // Pedometer doesn't support historical data
    }
  }

  /// Get weekly steps
  Future<List<StepData>> getWeeklySteps() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return getStepHistory(startOfWeek, now);
  }

  /// Get monthly steps
  Future<List<StepData>> getMonthlySteps() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return getStepHistory(startOfMonth, now);
  }

  /// Stream of real-time step updates
  Stream<int>? get stepStream {
    switch (_currentSource) {
      case StepDataSource.samsungHealth:
        return _samsungHealth?.stepStream;
      case StepDataSource.healthConnect:
        return _healthConnect?.stepStream;
      case StepDataSource.pedometer:
        return _pedometerService.stepStream.map((data) => data.steps);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _samsungHealth?.disconnect();
    await _healthConnect?.disconnect();
    _pedometerService.dispose();
  }
}

/// Data source types
enum StepDataSource {
  samsungHealth,
  healthConnect,
  pedometer,
}

/// Samsung Health service implementation
class SamsungHealthService {
  static const MethodChannel _channel = MethodChannel('com.upheal/samsung_health');
  bool _isConnected = false;
  bool _hasPermission = false;

  bool get isConnected => _isConnected;
  bool get hasPermission => _hasPermission;

  Future<bool> isSamsungHealthAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> connect() async {
    try {
      final result = await _channel.invokeMethod<bool>('connect');
      _isConnected = result ?? false;
      return _isConnected;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      _hasPermission = result ?? false;
      return _hasPermission;
    } catch (_) {
      return false;
    }
  }

  Future<int> getTodaySteps() async {
    if (!_isConnected || !_hasPermission) return 0;
    try {
      final result = await _channel.invokeMethod<int>('getTodaySteps');
      return result ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<StepData?> getStepsForDate(DateTime date) async {
    if (!_isConnected || !_hasPermission) return null;
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getStepsForDate', {
        'year': date.year,
        'month': date.month,
        'day': date.day,
      });
      if (result != null) {
        return StepData(
          date: DateTime(result['year'] as int, result['month'] as int, result['day'] as int),
          steps: result['steps'] as int,
          distance: (result['distance'] as num?)?.toDouble() ?? 0.0,
          calories: result['calories'] as int? ?? 0,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<StepData>> getStepHistory(DateTime startDate, DateTime endDate) async {
    if (!_isConnected || !_hasPermission) return [];
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getStepHistory', {
        'startYear': startDate.year,
        'startMonth': startDate.month,
        'startDay': startDate.day,
        'endYear': endDate.year,
        'endMonth': endDate.month,
        'endDay': endDate.day,
      });
      if (result != null) {
        return result.map((item) {
          final map = item as Map<dynamic, dynamic>;
          return StepData(
            date: DateTime(map['year'] as int, map['month'] as int, map['day'] as int),
            steps: map['steps'] as int,
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Stream<int>? get stepStream => null;

  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
      _isConnected = false;
      _hasPermission = false;
    } catch (_) {}
  }
}

/// Health Connect service implementation
class HealthConnectService {
  static const MethodChannel _channel = MethodChannel('com.upheal/health_connect');
  static const EventChannel _stepEventChannel = EventChannel('com.upheal/health_connect/steps');

  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      _hasPermission = result ?? false;
      return _hasPermission;
    } catch (_) {
      return false;
    }
  }

  Future<int> getTodaySteps() async {
    if (!_hasPermission) return 0;
    try {
      final result = await _channel.invokeMethod<int>('getTodaySteps');
      return result ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<StepData?> getStepsForDate(DateTime date) async {
    if (!_hasPermission) return null;
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getStepsForDate', {
        'year': date.year,
        'month': date.month,
        'day': date.day,
      });
      if (result != null) {
        return StepData(
          date: DateTime(result['year'] as int, result['month'] as int, result['day'] as int),
          steps: result['steps'] as int,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<StepData>> getStepHistory(DateTime startDate, DateTime endDate) async {
    if (!_hasPermission) return [];
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getStepHistory', {
        'startYear': startDate.year,
        'startMonth': startDate.month,
        'startDay': startDate.day,
        'endYear': endDate.year,
        'endMonth': endDate.month,
        'endDay': endDate.day,
      });
      if (result != null) {
        return result.map((item) {
          final map = item as Map<dynamic, dynamic>;
          return StepData(
            date: DateTime(map['year'] as int, map['month'] as int, map['day'] as int),
            steps: map['steps'] as int,
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Stream<int>? get stepStream {
    try {
      return _stepEventChannel.receiveBroadcastStream().map((event) => event as int);
    } catch (_) {
      return null;
    }
  }

  Future<void> disconnect() async {
    _hasPermission = false;
  }
}