import 'package:flutter/foundation.dart';
import '../domain/models/step_data.dart';
import '../domain/models/step_goal.dart';
import '../data/step_repository.dart';
import '../services/step_sensor_service.dart';
import '../services/step_permission_service.dart';
import 'dart:async';
/// State management for step tracking feature
///
/// Architecture:
/// - Domain: Models (StepData, StepGoal) with business logic
/// - Data: Repository handles persistence (SharedPreferences)
/// - Services: Sensor service (pedometer) and permission service
/// - State: This class manages all state and coordinates between layers
/// - UI: Screens and widgets consume this state via Provider
///
/// Data flow: Sensor → State → Repository → UI
class StepTrackerState extends ChangeNotifier {
  final StepRepository _repository;
  final StepSensorService _sensorService;
  final StepPermissionService _permissionService;

  // State variables
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _hasPermission = false;
  bool _isTracking = false;
  bool _isStartingTracking = false; // Guard to prevent concurrent _startTracking calls
  String? _errorMessage;

  StepData? _todaySteps;
  List<StepData> _stepHistory = [];
  StepGoal _goal = StepGoal(dailyGoal: StepGoal.defaultDailyGoal);

  StreamSubscription<StepData>? _stepSubscription;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  bool get isTracking => _isTracking;
  String? get errorMessage => _errorMessage;
  StepData? get todaySteps => _todaySteps;
  List<StepData> get stepHistory => List.unmodifiable(_stepHistory);
  StepGoal get goal => _goal;
  int get todayStepCount => _todaySteps?.steps ?? 0;
  int get dailyGoal => _goal.dailyGoal;
  double get progressPercentage =>
      (todayStepCount / _goal.dailyGoal * 100).clamp(0, 100);
  bool get goalReached => todayStepCount >= _goal.dailyGoal;

  StepTrackerState({
    StepRepository? repository,
    StepSensorService? sensorService,
    StepPermissionService? permissionService,
  })  : _repository = repository ?? StepRepository(),
        _sensorService = sensorService ?? StepSensorService(),
        _permissionService = permissionService ?? StepPermissionService();

  /// Initialize step tracking (load data, check permissions, start sensor)
  Future<void> initialize() async {
    debugPrint('[StepState] initialize() called, isInitialized: $_isInitialized, isLoading: $_isLoading');
    // Prevent re-entrancy: if already initialized or currently initializing, return early
    if (_isInitialized) {
      debugPrint('[StepState] Already initialized, returning');
      return;
    }
    if (_isLoading) {
      debugPrint('[StepState] Initialization already in progress, returning to prevent concurrent initialization');
      return;
    }

    debugPrint('[StepState] Setting loading state');
    _setLoading(true);
    _clearError();

    try {
      debugPrint('[StepState] Starting timeout race');
      // Add timeout to prevent infinite hangs
      await Future.any([
        _initializeInternal(),
        Future.delayed(const Duration(seconds: 10), () {
          debugPrint('[StepState] TIMEOUT TRIGGERED after 10 seconds!');
          throw TimeoutException('Initialization timed out after 10 seconds');
        }),
      ]);
      debugPrint('[StepState] Initialization completed successfully');
    } catch (e) {
      debugPrint('[StepState] Initialization error: $e');
      _setError('Failed to initialize step tracking: $e');
    } finally {
      debugPrint('[StepState] Finally block - setting flags');
      // Always clear loading state, even if sensor is still initializing
      _setLoading(false);
      _isInitialized = true;
      notifyListeners();
      debugPrint('[StepState] Initialize finally completed');
    }
  }

  Future<void> _initializeInternal() async {
    debugPrint('[StepState] _initializeInternal started');

    // Load persisted data (fast operation)
    debugPrint('[StepState] Loading data...');
    await _loadData();
    debugPrint('[StepState] Data loaded');

    // Yield to event loop to prevent UI freeze
    await Future.delayed(Duration.zero);
    debugPrint('[StepState] First yield completed');

    // Check and request permissions (may show dialog, but won't block forever)
    debugPrint('[StepState] Checking permissions...');
    await _checkPermissions();
    debugPrint('[StepState] Permissions checked, hasPermission: $_hasPermission');

    // Yield to event loop
    await Future.delayed(Duration.zero);
    debugPrint('[StepState] Second yield completed');

    // Start sensor if permission granted (non-blocking - don't wait for first event)
    if (_hasPermission) {
      debugPrint('[StepState] Starting tracking (non-blocking)...');
      // Don't await - let it start in background to avoid blocking UI
      _startTracking().catchError((error) {
        // Handle errors but don't block initialization
        debugPrint('[StepState] Tracking error: $error');
        _setError('Sensor initialization warning: $error');
        notifyListeners();
      });
    } else {
      debugPrint('[StepState] No permission, skipping tracking');
    }
    debugPrint('[StepState] _initializeInternal completed');
  }

  /// Load data from repository
  Future<void> _loadData() async {
    debugPrint('[StepState] _loadData: Loading step history...');
    _stepHistory = await _repository.loadStepHistory();
    debugPrint('[StepState] _loadData: Loaded ${_stepHistory.length} step records');

    debugPrint('[StepState] _loadData: Loading step goal...');
    _goal = await _repository.loadStepGoal();
    debugPrint('[StepState] _loadData: Goal loaded: ${_goal.dailyGoal}');

    debugPrint('[StepState] _loadData: Updating today steps...');
    _updateTodaySteps();
    debugPrint('[StepState] _loadData: Today steps: ${_todaySteps?.steps ?? 0}');
  }

  /// Update today's steps from history
  void _updateTodaySteps() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    _todaySteps = _stepHistory.firstWhere(
      (data) {
        final dataDate = DateTime(data.date.year, data.date.month, data.date.day);
        return dataDate.isAtSameMomentAs(todayDate);
      },
      orElse: () => StepData(
        date: todayDate,
        steps: 0,
      ),
    );
  }

  /// Check permissions (read-only, does not request)
  /// Use requestPermission() method to actually request permissions from the user
  Future<void> _checkPermissions() async {
    debugPrint('[StepState] _checkPermissions: Checking has permission...');
    _hasPermission = await _permissionService.hasPermission();
    debugPrint('[StepState] _checkPermissions: Has permission: $_hasPermission');
    // Note: We do NOT auto-request permissions here. The user must explicitly
    // tap the "Grant Permission" button in StepPermissionWidget, which calls
    // requestPermission() method. This prevents showing permission dialogs
    // automatically during initialization/refresh.
  }

  /// Start tracking steps from sensor
  Future<void> _startTracking() async {
    // Prevent concurrent calls to avoid multiple subscriptions
    if (_isTracking) {
      debugPrint('[StepState] Already tracking, skipping _startTracking');
      return;
    }
    if (_isStartingTracking) {
      debugPrint('[StepState] Tracking start already in progress, skipping to prevent concurrent initialization');
      return;
    }

    _isStartingTracking = true;
    try {
      // Initialize sensor (non-blocking - won't wait for first stream event)
      final initialized = await _sensorService.initialize();
      if (!initialized) {
        throw Exception('Failed to initialize sensor');
      }

      _stepSubscription = _sensorService.stepStream.listen(
        _onStepUpdate,
        onError: (error) {
          _setError('Sensor error: $error');
        },
      );

      _isTracking = true;
    } catch (e) {
      _setError('Failed to start tracking: $e');
      _isTracking = false;
      rethrow; // Re-throw so caller can handle it
    } finally {
      _isStartingTracking = false;
    }
  }

  /// Handle step updates from sensor
  void _onStepUpdate(StepData stepData) {
    debugPrint('[StepState] _onStepUpdate: Received ${stepData.steps} steps');
    _todaySteps = stepData;
    _updateStepHistory(stepData);
    debugPrint('[StepState] _onStepUpdate: Calling notifyListeners');
    notifyListeners();
    debugPrint('[StepState] _onStepUpdate: notifyListeners completed');
  }

  /// Update step history with new data
  void _updateStepHistory(StepData stepData) {
    final existingIndex = _stepHistory.indexWhere((data) {
      final dataDate = DateTime(data.date.year, data.date.month, data.date.day);
      final stepDate = DateTime(stepData.date.year, stepData.date.month, stepData.date.day);
      return dataDate.isAtSameMomentAs(stepDate);
    });

    if (existingIndex >= 0) {
      _stepHistory[existingIndex] = stepData;
    } else {
      _stepHistory.add(stepData);
    }

    // Persist to storage (non-blocking - don't await)
    // This runs in background to avoid blocking UI updates
    _repository.saveStepHistory(_stepHistory).catchError((error) {
      debugPrint('[StepState] Error saving step history: $error');
    });
  }

  /// Manually update steps (for manual entry or testing)
  Future<void> updateSteps(int steps, {
    double? distance,
    int? calories,
    Duration? activeTime,
  }) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final calculatedDistance = distance ?? (steps * 0.0007);
    final calculatedCalories = calories ?? (steps * 0.04).round();

    final stepData = StepData(
      date: todayDate,
      steps: steps.clamp(0, 999999),
      distance: calculatedDistance,
      calories: calculatedCalories,
      activeTime: activeTime ?? const Duration(seconds: 0),
    );

    _onStepUpdate(stepData);
  }

  /// Add steps to current count
  Future<void> addSteps(int additionalSteps) async {
    final currentSteps = todayStepCount;
    await updateSteps(currentSteps + additionalSteps);
  }

  /// Set daily step goal
  Future<void> setGoal(int goalSteps) async {
    if (goalSteps <= 0) return;

    _goal = StepGoal(
      dailyGoal: goalSteps,
      lastUpdated: DateTime.now(),
    );

    await _repository.saveStepGoal(_goal);
    notifyListeners();
  }

  /// Request permission (can be called from UI)
  Future<bool> requestPermission() async {
    _hasPermission = await _permissionService.requestPermission();
    if (_hasPermission && !_isTracking) {
      // Start tracking without blocking - don't wait for first sensor event
      _startTracking().catchError((error) {
        // If tracking fails, still clear loading and show error
        _setError('Failed to start tracking: $error');
        _setLoading(false);
        notifyListeners();
      });
    }
    // Only notify listeners once at the end to avoid multiple rebuilds
    notifyListeners();
    return _hasPermission;
  }

  /// Open app settings (for permanently denied permissions)
  Future<bool> openSettings() async {
    return await _permissionService.openSettings();
  }

  /// Get steps for a specific date range
  List<StepData> getStepsForPeriod(DateTime startDate, DateTime endDate) {
    return _stepHistory.where((data) {
      return data.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
             data.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get total steps for a period
  int getTotalStepsForPeriod(DateTime startDate, DateTime endDate) {
    final steps = getStepsForPeriod(startDate, endDate);
    return steps.fold(0, (sum, data) => sum + data.steps);
  }

  /// Get average steps for a period
  double getAverageStepsForPeriod(DateTime startDate, DateTime endDate) {
    final steps = getStepsForPeriod(startDate, endDate);
    if (steps.isEmpty) return 0.0;
    return getTotalStepsForPeriod(startDate, endDate) / steps.length;
  }

  /// Refresh data (reload from storage and sensor)
  Future<void> refresh() async {
    // Prevent multiple simultaneous refreshes
    if (_isLoading) {
      debugPrint('Refresh already in progress, skipping...');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Add timeout to prevent hangs
      await Future.any([
        _refreshInternal(),
        Future.delayed(const Duration(seconds: 10), () {
          throw TimeoutException('Refresh timed out after 10 seconds');
        }),
      ]);
    } catch (e) {
      _setError('Failed to refresh: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> _refreshInternal() async {
    await _loadData();

    // Yield to event loop
    await Future.delayed(Duration.zero);

    // Re-check permissions (in case they changed)
    await _checkPermissions();

    // Yield to event loop
    await Future.delayed(Duration.zero);

    // Start tracking if permission granted and not already tracking
    if (_hasPermission && !_isTracking) {
      // Don't await - let it start in background
      _startTracking().catchError((error) {
        _setError('Sensor warning: $error');
      });
    }
  }

  /// Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    // Don't call notifyListeners here - let the calling method handle it
  }

  void _setError(String? error) {
    _errorMessage = error;
    // Don't call notifyListeners here - let the calling method handle it
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _sensorService.dispose();
    super.dispose();
  }
}

