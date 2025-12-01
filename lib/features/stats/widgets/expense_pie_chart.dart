import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../providers/stats_provider.dart';

class ExpensePieChart extends StatelessWidget {
  final List<CategoryStat> stats;

  const ExpensePieChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.fold(0.0, (sum, item) => sum + item.total);

    if (stats.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No expenses this month')),
      );
    }

    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: stats.map((stat) {
                return PieChartSectionData(
                  color: stat.color,
                  value: stat.total,
                  title: '${stat.percentage.toStringAsFixed(1)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  badgeWidget: _Badge(
                    stat.iconCode,
                    stat.name,
                    size: 40,
                    borderColor: stat.color,
                  ),
                  badgePositionPercentageOffset: .98,
                );
              }).toList(),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
    this.iconCode,
    this.categoryName, {
    required this.size,
    required this.borderColor,
  });
  final String? iconCode;
  final String categoryName;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: Icon(
          _getIconData(iconCode),
          size: size * 0.5,
          color: borderColor,
        ),
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
