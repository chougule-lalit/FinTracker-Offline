import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'providers/stats_provider.dart';
import 'widgets/expense_pie_chart.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final statsAsync = ref.watch(monthlyStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: Column(
        children: [
          // Month Selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    ref.read(selectedMonthProvider.notifier).previous();
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(selectedMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    ref.read(selectedMonthProvider.notifier).next();
                  },
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: statsAsync.when(
              data: (stats) {
                if (stats.isEmpty) {
                  return const Center(child: Text('No data for this month'));
                }
                return Column(
                  children: [
                    ExpensePieChart(stats: stats),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: stats.length,
                        itemBuilder: (context, index) {
                          final stat = stats[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: stat.color.withOpacity(0.2),
                              child: Icon(
                                _getIconData(stat.iconCode),
                                color: stat.color,
                              ),
                            ),
                            title: Text(stat.name),
                            subtitle: LinearProgressIndicator(
                              value: stat.percentage / 100,
                              color: stat.color,
                              backgroundColor: stat.color.withOpacity(0.1),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${stat.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${stat.percentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
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
