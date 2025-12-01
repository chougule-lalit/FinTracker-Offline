import 'package:finance_tracker_offline/features/settings/providers/settings_provider.dart';
import 'package:finance_tracker_offline/features/stats/models/category_stat.dart';
import 'package:finance_tracker_offline/features/stats/widgets/date_filter_controls.dart';
import 'package:finance_tracker_offline/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          title: Text('Statistics', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.scaffoldBackground,
          elevation: 0,
        ),
        body: Column(
          children: [
            const DateFilterControls(),
            const SizedBox(height: 16),
            // TabBar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                indicator: const ShapeDecoration(
                  color: AppColors.brandDark,
                  shape: StadiumBorder(),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.secondaryGrey,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
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

