import 'package:hive_ce/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 13)
class Expense extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String categoryId;

  @HiveField(3)
  String categoryName;

  @HiveField(4)
  String description;

  @HiveField(5)
  String notes;

  @HiveField(6)
  DateTime date;

  @HiveField(7)
  String? receiptImagePath;

  @HiveField(8)
  String? linkedTaskId; // For task-expense integration

  @HiveField(9)
  bool isRecurring;

  @HiveField(10)
  String? recurringId;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.notes,
    required this.date,
    this.receiptImagePath,
    this.linkedTaskId,
    required this.isRecurring,
    this.recurringId,
    required this.createdAt,
    required this.updatedAt,
  });
}
