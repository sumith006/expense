import 'package:hive_ce/hive.dart';

part 'recurring_transaction.g.dart';

@HiveType(typeId: 12)
enum RecurringType {
  @HiveField(0)
  expense,
  @HiveField(1)
  income,
  @HiveField(2)
  task,
}

@HiveType(typeId: 7)
class RecurringTransaction extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  double amount;
  
  @HiveField(3)
  String categoryId;
  
  @HiveField(4)
  RecurringType type; // expense, income, task
  
  @HiveField(5)
  String frequency; // daily, weekly, monthly, yearly
  
  @HiveField(6)
  DateTime startDate;
  
  @HiveField(7)
  DateTime? endDate;
  
  @HiveField(8)
  int? dayOfMonth; // for monthly
  
  @HiveField(9)
  int? dayOfWeek; // for weekly (0-6, Monday=0)
  
  @HiveField(10)
  DateTime nextExecutionDate;
  
  @HiveField(11)
  bool isActive;

  RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.type,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.dayOfMonth,
    this.dayOfWeek,
    required this.nextExecutionDate,
    required this.isActive,
  });
}
