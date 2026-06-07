import 'package:hive_ce/hive.dart';

part 'savings_goal.g.dart';

@HiveType(typeId: 4)
class SavingsGoal extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  double targetAmount;
  
  @HiveField(3)
  double currentAmount;
  
  @HiveField(4)
  DateTime targetDate;
  
  @HiveField(5)
  String? linkedTaskId; // task-based goals
  
  @HiveField(6)
  int? requiredTaskCount; // complete X tasks to unlock
  
  @HiveField(7)
  int currentTaskCount;
  
  @HiveField(8)
  bool isAchieved;
  
  @HiveField(9)
  DateTime createdAt;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    this.linkedTaskId,
    this.requiredTaskCount,
    this.currentTaskCount = 0,
    required this.isAchieved,
    required this.createdAt,
  });
}
