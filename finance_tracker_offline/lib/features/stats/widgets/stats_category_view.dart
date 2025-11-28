import 'package:finance_tracker_offline/features/settings/providers/settings_provider.dart';
import 'package:finance_tracker_offline/features/stats/category_detail_screen.dart';
import 'package:finance_tracker_offline/models/category.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/monthly_stats_provider.dart';

class StatsCategoryView extends ConsumerWidget {
  final TransactionType type;

  const StatsCategoryView({
    required this.type,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final statsAsync = ref.watch(statsProvider(type));

    return statsAsync.when(
      data: (stats) {
        if (stats.isEmpty) {
          return const Center(
            child: Text('No Data for this Period'),
          );
        }

        return Column(
          children: [
            // Top Section: Pie Chart
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: stats.map((stat) {
                    final isLarge = stat.percentage > 3;
                    return PieChartSectionData(
                      color: stat.color,
                      value: stat.totalAmount,
                      title: isLarge ? '${stat.percentage.toStringAsFixed(1)}%' : '',
                      radius: 50,
                      titlePositionPercentageOffset: 1.4,
                      showTitle: true,
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Bottom Section: List
            Expanded(
              child: ListView.builder(
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  return InkWell(
                    onTap: () {
                      // We need to reconstruct the Category object or pass ID
                      // Since CategoryStat only has name/color/icon, we might need to fetch or pass full object
                      // For now, let's assume we can find it or pass minimal info.
                      // Ideally, CategoryStat should hold the Category ID or object.
                      // Let's update CategoryStat to hold the Category object if possible, or just ID.
                      // Assuming we update CategoryStat to hold the Category object:
                      if (stat.category != null) {
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryDetailScreen(category: stat.category!),
                          ),
                        );
                      }
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: stat.color,
                        child: Text(
                          '${stat.percentage.round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(stat.categoryName),
                      trailing: Text(
                        '${settings.currencySymbol} ${stat.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
