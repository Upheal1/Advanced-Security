import '../domain/models/step_data.dart';
import '../domain/models/step_goal.dart';

class StepRepository {
  List<StepData> _cache = [];

  Future<List<StepData>> loadStepHistory() async {
    return _cache;
  }

  Future<void> saveStepHistory(List<StepData> data) async {
    _cache = data;
  }

  Future<StepGoal> loadStepGoal() async {
    return StepGoal(dailyGoal: StepGoal.defaultDailyGoal);
  }

  Future<void> saveStepGoal(StepGoal goal) async {
    // local mock storage
  }
}