import 'dart:ui';
import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/features/stats/models/category_stat.dart';
import 'package:finance_tracker_offline/features/stats/providers/date_filter_provider.dart';
import 'package:finance_tracker_offline/models/category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'monthly_stats_provider.g.dart';

enum TransactionType { expense, income }

@riverpod
Stream<List<CategoryStat>> stats(Ref ref, TransactionType type) async* {
  final filterState = ref.watch(dateFilterProvider);
  final dbService = ref.watch(dbServiceProvider);

  final start = filterState.startDate;
  final end = filterState.endDate;

  final stream = dbService.watchTransactionsByDateRange(start, end);

  await for (final transactions in stream) {
    // Filter by type
    final filtered = transactions.where((t) {
      if (type == TransactionType.expense) {
        return t.isExpense;
      } else {
        return !t.isExpense;
      }
    }).toList();

    if (filtered.isEmpty) {
      yield [];
      continue;
    }

    // Group by Category ID to avoid duplicates
    final categoryTotals = <int, double>{};
    final categoryObjects = <int, Category>{};
    double grandTotal = 0.0;

    for (final t in filtered) {
      t.category.loadSync();
      final category = t.category.value;
      
      if (category != null) {
        final id = category.id;
        categoryTotals[id] = (categoryTotals[id] ?? 0.0) + t.amount;
        categoryObjects[id] = category;
      } else {
        // Handle transactions with no category (optional, group under -1)
        categoryTotals[-1] = (categoryTotals[-1] ?? 0.0) + t.amount;
      }
      grandTotal += t.amount;
    }

    final stats = categoryTotals.entries.map((entry) {
      final id = entry.key;
      final total = entry.value;
      final percentage = grandTotal > 0 ? (total / grandTotal) * 100 : 0.0;
      
      final category = categoryObjects[id]; // Null if id is -1

      // Parse color
      Color color = const Color(0xFF9E9E9E); // Default grey
      final hexColor = category?.colorHex;
      if (hexColor != null) {
        try {
          // Remove # if present (though usually stored as hex string like FF...)
          String hex = hexColor;
          if (hex.startsWith('#')) hex = hex.substring(1);
          color = Color(int.parse(hex, radix: 16));
        } catch (_) {}
      }

      return CategoryStat(
        categoryName: category?.name ?? 'Unknown',
        totalAmount: total,
        percentage: percentage,
        color: color,
        iconCode: category?.iconCode,
        category: category,
      );
    }).toList();

    // Sort by total amount descending
    stats.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    yield stats;
  }
}
