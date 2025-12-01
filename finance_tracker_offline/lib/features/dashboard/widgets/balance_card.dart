import 'package:finance_tracker_offline/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.currencySymbol,
  });

  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.brandDark,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Text(
            'Total Balance',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currencySymbol${totalBalance.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                context,
                label: 'Income',
                amount: totalIncome,
                color: Colors.white,
                icon: Icons.arrow_downward,
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white24,
              ),
              _buildSummaryItem(
                context,
                label: 'Expenses',
                amount: totalExpense,
                color: AppColors.brandRed,
                icon: Icons.arrow_upward,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$currencySymbol${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
