import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/db_service.dart';

class CategoryStat {
  final String name;
  final double total;
  final Color color;
  final double percentage;
  final String? iconCode;

  CategoryStat({
    required this.name,
    required this.total,
    required this.color,
    required this.percentage,
    this.iconCode,
  });
}

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return DateTime.now();
  }

  void update(DateTime date) {
    state = date;
  }

  void previous() {
    state = DateTime(state.year, state.month - 1);
  }

  void next() {
    state = DateTime(state.year, state.month + 1);
  }
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(SelectedMonthNotifier.new);

final monthlyStatsProvider = FutureProvider<List<CategoryStat>>((ref) async {
  final dbService = ref.watch(dbServiceProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);

  final transactions = await dbService.getTransactionsForMonth(selectedMonth);
  
  // Filter for expenses only
  final expenseTransactions = transactions.where((t) => t.isExpense).toList();

  if (expenseTransactions.isEmpty) return [];

  final totalExpense = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);

  // Group by category
  final Map<String, double> categoryTotals = {};
  final Map<String, Color> categoryColors = {};
  final Map<String, String> categoryIcons = {};

  for (var txn in expenseTransactions) {
    // Ensure category is loaded if not already
    if (!txn.category.isLoaded) {
      await txn.category.load();
    }
    final category = txn.category.value;
    
    final categoryName = category?.name ?? 'Uncategorized';
    final iconCode = category?.iconCode;
    // Handle potential parsing errors or missing colors
    Color color;
    try {
      final colorHex = category?.colorHex ?? 'FF9E9E9E'; 
      color = Color(int.parse(colorHex, radix: 16));
    } catch (e) {
      color = Colors.grey;
    }

    categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + txn.amount;
    categoryColors[categoryName] = color;
    if (iconCode != null) {
      categoryIcons[categoryName] = iconCode;
    }
  }

  final List<CategoryStat> stats = [];
  categoryTotals.forEach((name, total) {
    final percentage = totalExpense > 0 ? (total / totalExpense) * 100 : 0.0;
    stats.add(CategoryStat(
      name: name,
      total: total,
      color: categoryColors[name]!,
      percentage: percentage,
      iconCode: categoryIcons[name],
    ));
  });

  // Sort by total descending
  stats.sort((a, b) => b.total.compareTo(a.total));

  return stats;
});
