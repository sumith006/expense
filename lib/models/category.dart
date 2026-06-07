// lib/models/category.dart
import 'package:hive_ce/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 0)
enum CategoryType {
  @HiveField(0)
  expense,
  @HiveField(1)
  income,
  @HiveField(2)
  task,
}

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String iconCodePoint; // stored as string for consistency

  @HiveField(3)
  int colorValue; // ARGB int

  @HiveField(4)
  CategoryType type;

  @HiveField(5)
  bool isDefault;

  @HiveField(6)
  double? budgetLimit;

  Category({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.type,
    this.isDefault = false,
    this.budgetLimit,
  });
}
