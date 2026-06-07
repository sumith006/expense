import 'package:hive_ce/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 5)
class Budget extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  double monthlyTotalBudget;
  
  @HiveField(2)
  Map<String, double> categoryBudgets; // categoryId -> budget amount
  
  @HiveField(3)
  int month; // 1-12
  
  @HiveField(4)
  int year;
  
  @HiveField(5)
  DateTime lastUpdated;

  Budget({
    required this.id,
    required this.monthlyTotalBudget,
    required this.categoryBudgets,
    required this.month,
    required this.year,
    required this.lastUpdated,
  });
}
