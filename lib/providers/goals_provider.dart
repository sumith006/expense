import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_ce/hive.dart';
import '../database/boxes.dart';
import '../models/savings_goal.dart';

final goalsProvider = StateNotifierProvider<GoalsNotifier, List<SavingsGoal>>((ref) {
  return GoalsNotifier();
});

class GoalsNotifier extends StateNotifier<List<SavingsGoal>> {
  late final Box<SavingsGoal> _goalBox;

  GoalsNotifier() : super([]) {
    _init();
  }

  void _init() {
    _goalBox = Hive.box<SavingsGoal>(Boxes.goals);
    _loadGoals();
  }

  void _loadGoals() {
    state = _goalBox.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> addGoal(SavingsGoal goal) async {
    await _goalBox.put(goal.id, goal);
    _loadGoals();
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    await _goalBox.put(goal.id, goal);
    _loadGoals();
  }

  Future<void> deleteGoal(String id) async {
    await _goalBox.delete(id);
    _loadGoals();
  }

  Future<void> addSavings(String id, double amount) async {
    final goal = _goalBox.get(id);
    if (goal != null) {
      goal.currentAmount += amount;
      if (goal.currentAmount >= goal.targetAmount) {
        goal.currentAmount = goal.targetAmount;
        goal.isAchieved = true;
      }
      await goal.save();
      _loadGoals();
    }
  }

  Future<void> incrementTaskCountForLinkedGoal(String taskId) async {
    // Find goals linked to this task ID, or simply any goals requiring task counts
    bool modified = false;
    for (var goal in _goalBox.values.where((g) => g.linkedTaskId == taskId && !g.isAchieved)) {
      goal.currentTaskCount += 1;
      if (goal.requiredTaskCount != null && goal.currentTaskCount >= goal.requiredTaskCount!) {
        goal.isAchieved = true;
      }
      await goal.save();
      modified = true;
    }
    if (modified) {
      _loadGoals();
    }
  }

  void refresh() {
    _loadGoals();
  }
}
