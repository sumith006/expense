import 'package:flutter/material.dart' show TimeOfDay;
import 'package:hive_ce/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 10)
enum TaskPriority {
  @HiveField(0)
  high,
  @HiveField(1)
  medium,
  @HiveField(2)
  low,
}

@HiveType(typeId: 11)
enum TaskStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  completed,
}

@HiveType(typeId: 3)
class Subtask extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  bool isCompleted;
  
  @HiveField(3)
  DateTime? completedAt;

  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
  });
}

@HiveType(typeId: 2)
class Task extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String description;
  
  @HiveField(3)
  String categoryId;
  
  @HiveField(4)
  String categoryName;
  
  @HiveField(5)
  TaskPriority priority;
  
  @HiveField(6)
  TaskStatus status;
  
  @HiveField(7)
  DateTime dueDate;
  
  // Hive doesn't support TimeOfDay directly, so we serialize it as hours and minutes
  @HiveField(8)
  int? dueHour;
  
  @HiveField(9)
  int? dueMinute;
  
  @HiveField(10)
  List<Subtask> subtasks;
  
  @HiveField(11)
  String? notes;
  
  @HiveField(12)
  bool isRecurring;
  
  @HiveField(13)
  String? recurringRule; // daily, weekly, monthly, custom
  
  @HiveField(14)
  double? budgetAmount; // For task-expense integration
  
  @HiveField(15)
  List<String> linkedExpenseIds;
  
  @HiveField(16)
  DateTime createdAt;
  
  @HiveField(17)
  DateTime? completedAt;
  
  @HiveField(18)
  List<String> tags;
  
  @HiveField(19)
  int? estimatedMinutes;
  
  @HiveField(20)
  int? actualMinutes;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.priority,
    required this.status,
    required this.dueDate,
    this.dueHour,
    this.dueMinute,
    required this.subtasks,
    this.notes,
    required this.isRecurring,
    this.recurringRule,
    this.budgetAmount,
    required this.linkedExpenseIds,
    required this.createdAt,
    this.completedAt,
    required this.tags,
    this.estimatedMinutes,
    this.actualMinutes,
  });

  TimeOfDay? get dueTime {
    if (dueHour != null && dueMinute != null) {
      return TimeOfDay(hour: dueHour!, minute: dueMinute!);
    }
    return null;
  }

  set dueTime(TimeOfDay? time) {
    if (time != null) {
      dueHour = time.hour;
      dueMinute = time.minute;
    } else {
      dueHour = null;
      dueMinute = null;
    }
  }
}
