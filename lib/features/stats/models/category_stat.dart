import 'dart:ui';
import 'package:finance_tracker_offline/models/category.dart';

class CategoryStat {
  final String categoryName;
  final double totalAmount;
  final double percentage;
  final Color color;
  final String? iconCode;
  final Category? category;

  CategoryStat({
    required this.categoryName,
    required this.totalAmount,
    required this.percentage,
    required this.color,
    this.iconCode,
    this.category,
  });
}
