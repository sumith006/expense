import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_ce/hive.dart';
import '../database/boxes.dart';
import '../models/task.dart';

final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier();
});

class TaskNotifier extends StateNotifier<List<Task>> {
  late final Box<Task> _taskBox;

  TaskNotifier() : super([]) {
    _init();
  }

  void _init() {
    _taskBox = Hive.box<Task>(Boxes.tasks);
    _loadTasks();
  }

  void _loadTasks() {
    state = _taskBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void refresh() {
    _loadTasks();
  }

  Future<void> addTask(Task task) async {
    await _taskBox.put(task.id, task);
    _loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _taskBox.put(task.id, task);
    _loadTasks();
  }

  Future<void> deleteTask(String id) async {
    await _taskBox.delete(id);
    _loadTasks();
  }

  Future<void> toggleTaskCompletion(String id) async {
    final task = _taskBox.get(id);
    if (task != null) {
      task.status = task.status == TaskStatus.completed ? TaskStatus.pending : TaskStatus.completed;
      task.completedAt = task.status == TaskStatus.completed ? DateTime.now() : null;
      await task.save();
      _loadTasks();
    }
  }

  Future<void> toggleSubtaskCompletion(String taskId, String subtaskId) async {
    final task = _taskBox.get(taskId);
    if (task != null) {
      final updatedSubtasks = task.subtasks.map((sub) {
        if (sub.id == subtaskId) {
          final nextCompleted = !sub.isCompleted;
          return Subtask(
            id: sub.id,
            title: sub.title,
            isCompleted: nextCompleted,
            completedAt: nextCompleted ? DateTime.now() : null,
          );
        }
        return sub;
      }).toList();
      task.subtasks = updatedSubtasks;
      await task.save();
      _loadTasks();
    }
  }

  Future<void> linkExpenseToTask(String taskId, String expenseId) async {
    final task = _taskBox.get(taskId);
    if (task != null) {
      final updatedExpenses = List<String>.from(task.linkedExpenseIds);
      if (!updatedExpenses.contains(expenseId)) {
        updatedExpenses.add(expenseId);
        task.linkedExpenseIds = updatedExpenses;
        await task.save();
        _loadTasks();
      }
    }
  }
}

// Keep the old providers for compatibility if needed elsewhere
final taskBoxProvider = Provider<Box<Task>>((ref) {
  return Hive.box<Task>(Boxes.tasks);
});

final taskListProvider = StreamProvider<List<Task>>((ref) {
  final box = ref.watch(taskBoxProvider);
  final controller = StreamController<List<Task>>();
  controller.add(box.values.toList());
  final subscription = box.watch().listen((event) {
    controller.add(box.values.toList());
  });
  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });
  return controller.stream;
});
