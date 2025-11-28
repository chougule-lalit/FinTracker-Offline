import 'package:finance_tracker_offline/features/settings/providers/settings_provider.dart';
import 'package:finance_tracker_offline/features/stats/models/category_stat.dart';
import 'package:finance_tracker_offline/features/stats/widgets/date_filter_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/monthly_stats_provider.dart';
import 'widgets/stats_category_view.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final expenseAsync = ref.watch(statsProvider(TransactionType.expense));
    final incomeAsync = ref.watch(statsProvider(TransactionType.income));

    double calculateTotal(AsyncValue<List<CategoryStat>> asyncValue) {
      return asyncValue.maybeWhen(
        data: (stats) => stats.fold(0.0, (sum, item) => sum + item.totalAmount),
        orElse: () => 0.0,
      );
    }

    final expenseTotal = calculateTotal(expenseAsync);
    final incomeTotal = calculateTotal(incomeAsync);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Statistics'),
        ),
        body: Column(
          children: [
            const DateFilterControls(),
            // TabBar
            Material(
              color: Colors.transparent,
              child: TabBar(
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'Expense (${settings.currencySymbol} ${expenseTotal.toStringAsFixed(0)})'),
                  Tab(text: 'Income (${settings.currencySymbol} ${incomeTotal.toStringAsFixed(0)})'),
                ],
              ),
            ),
            // TabBarView
            const Expanded(
              child: TabBarView(
                children: [
                  StatsCategoryView(type: TransactionType.expense),
                  StatsCategoryView(type: TransactionType.income),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

