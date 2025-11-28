import 'package:finance_tracker_offline/features/dashboard/providers/transaction_provider.dart';
import 'package:finance_tracker_offline/features/dashboard/widgets/transaction_card.dart';
import 'package:finance_tracker_offline/features/settings/providers/settings_provider.dart';
import 'package:finance_tracker_offline/features/settings/settings_screen.dart';
import 'package:finance_tracker_offline/features/sms_parser/providers/sms_provider.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
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
      body: transactionListAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions yet'));
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

          return ListView.builder(
            itemCount: groupedTransactions.length,
            itemBuilder: (context, index) {
              final dateKey = groupedTransactions.keys.elementAt(index);
              final txns = groupedTransactions[dateKey]!;
              
              // Calculate total for the day
              double totalAmount = 0;
              for (var txn in txns) {
                if (txn.isExpense) {
                  totalAmount -= txn.amount;
                } else {
                  totalAmount += txn.amount;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateKey,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          totalAmount >= 0
                              ? '+${settings.currencySymbol}${totalAmount.toStringAsFixed(2)}'
                              : '${settings.currencySymbol}${totalAmount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ...txns.map((txn) => InkWell(
                    onTap: () => context.push('/add_transaction', extra: txn),
                    child: TransactionCard(transaction: txn),
                  )),
                  const Divider(),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add_transaction'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
