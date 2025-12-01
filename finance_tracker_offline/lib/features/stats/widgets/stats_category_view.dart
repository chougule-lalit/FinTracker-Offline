import 'package:finance_tracker_offline/features/settings/providers/settings_provider.dart';
import 'package:finance_tracker_offline/features/stats/category_detail_screen.dart';
import 'package:finance_tracker_offline/models/category.dart';
import 'package:finance_tracker_offline/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
          return Center(
            child: Text('No Data for this Period', style: GoogleFonts.poppins()),
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
                      titleStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlack,
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
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(stat.categoryName, style: GoogleFonts.poppins()),
                      trailing: Text(
                        '${settings.currencySymbol} ${stat.totalAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
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
      error: (error, stack) => Center(child: Text('Error: $error', style: GoogleFonts.poppins())),
    );
  }
}
