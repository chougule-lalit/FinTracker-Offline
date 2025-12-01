import 'package:finance_tracker_offline/features/dashboard/providers/transaction_provider.dart';
import 'package:finance_tracker_offline/features/dashboard/widgets/balance_card.dart';
import 'package:finance_tracker_offline/features/dashboard/widgets/transaction_card.dart';
import 'package:finance_tracker_offline/features/settings/providers/settings_provider.dart';
import 'package:finance_tracker_offline/features/settings/settings_screen.dart';
import 'package:finance_tracker_offline/features/sms_parser/providers/sms_provider.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:finance_tracker_offline/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final transactionListAsync = ref.watch(transactionListProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: AppColors.primaryBlack),
                  const SizedBox(width: 8),
                  Text(
                    "VaultFlow",
                    style: GoogleFonts.poppins(
                      color: AppColors.primaryBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.sync, color: AppColors.primaryBlack),
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Syncing SMS...')),
                      );
                      try {
                        final count = await ref.refresh(smsSyncProvider.future);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Synced $count new transactions')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sync failed: $e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactionListAsync.when(
                data: (transactions) {
                  // Calculate totals
                  double totalBalance = 0;
                  double totalIncome = 0;
                  double totalExpense = 0;

                  for (var txn in transactions) {
                    if (txn.isExpense) {
                      totalExpense += txn.amount;
                      totalBalance -= txn.amount;
                    } else {
                      totalIncome += txn.amount;
                      totalBalance += txn.amount;
                    }
                  }

                  if (transactions.isEmpty) {
                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: BalanceCard(
                            totalBalance: totalBalance,
                            totalIncome: totalIncome,
                            totalExpense: totalExpense,
                            currencySymbol: settings.currencySymbol,
                          ),
                        ),
                        const SliverFillRemaining(
                          child: Center(child: Text('No transactions yet')),
                        ),
                      ],
                    );
                  }

                  // Group transactions by date
                  final groupedTransactions = <String, List<Transaction>>{};
                  for (var txn in transactions) {
                    final dateKey = _getDateHeader(txn.date);
                    if (!groupedTransactions.containsKey(dateKey)) {
                      groupedTransactions[dateKey] = [];
                    }
                    groupedTransactions[dateKey]!.add(txn);
                  }

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: BalanceCard(
                          totalBalance: totalBalance,
                          totalIncome: totalIncome,
                          totalExpense: totalExpense,
                          currencySymbol: settings.currencySymbol,
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final dateKey = groupedTransactions.keys.elementAt(index);
                            final txns = groupedTransactions[dateKey]!;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    dateKey,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.secondaryGrey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                ...txns.map((txn) => InkWell(
                                  onTap: () => context.push('/add_transaction', extra: txn),
                                  child: TransactionCard(transaction: txn),
                                )),
                                const SizedBox(height: 16),
                              ],
                            );
                          },
                          childCount: groupedTransactions.length,
                        ),
                      ),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 80)), // Space for FAB
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
