import 'package:hive_ce/hive.dart';

part 'income.g.dart';

@HiveType(typeId: 6)
class Income extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  /// ID of the income category
  @HiveField(2)
  String categoryId;

  /// Display name of the income category
  @HiveField(3)
  String categoryName;

  /// Human-readable source label (e.g. "Salary", "Freelance")
  @HiveField(4)
  String source;

  /// Additional notes
  @HiveField(5)
  String notes;

  @HiveField(6)
  DateTime date;

  @HiveField(7)
  bool isRecurring;

  @HiveField(8)
  String? recurringId;

  @HiveField(9)
  DateTime createdAt;

  // Legacy fields kept for Hive adapter compatibility — not used actively
  @HiveField(10)
  String? sourceId;

  @HiveField(11)
  String? sourceName;

  @HiveField(12)
  String? description;

  @HiveField(13)
  DateTime? updatedAt;

  Income({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.source,
    required this.notes,
    required this.date,
    this.isRecurring = false,
    this.recurringId,
    required this.createdAt,
    this.sourceId,
    this.sourceName,
    this.description,
    this.updatedAt,
  });

  /// Convenience getter — returns [source] as the display title
  String get title => source;
}
