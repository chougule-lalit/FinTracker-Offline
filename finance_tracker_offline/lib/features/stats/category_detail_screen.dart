import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/features/stats/providers/date_filter_provider.dart';
import 'package:finance_tracker_offline/models/category.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final Category category;

  const CategoryDetailScreen({
    required this.category,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(dateFilterProvider);
    final dbService = ref.watch(dbServiceProvider);

    final start = filterState.startDate;
    final end = filterState.endDate;

    final transactionsStream = dbService.watchTransactionsByCategoryAndDate(category.id, start, end);

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: StreamBuilder<List<Transaction>>(
        stream: transactionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final transactions = snapshot.data ?? [];

          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions found for this period.'));
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final txn = transactions[index];
              final hexColor = category.colorHex;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(int.parse(hexColor.replaceAll('#', ''), radix: 16)),
                  child: Icon(
                    _getIconData(category.iconCode),
                    color: Colors.white,
                  ),
                ),
                title: Text(txn.note.isNotEmpty ? txn.note : category.name),
                subtitle: Text(DateFormat('MMM d, yyyy').format(txn.date)),
                trailing: Text(
                  '\$${txn.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: txn.isExpense ? Colors.red : Colors.green,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconData(String? iconCode) {
    switch (iconCode) {
      case 'fastfood': return Icons.fastfood;
      case 'directions_bus': return Icons.directions_bus;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'payments': return Icons.payments;
      case 'work': return Icons.work;
      case 'movie': return Icons.movie;
      case 'local_hospital': return Icons.local_hospital;
      case 'flight': return Icons.flight;
      case 'school': return Icons.school;
      case 'fitness_center': return Icons.fitness_center;
      case 'pets': return Icons.pets;
      default: return Icons.category;
    }
  }
}
