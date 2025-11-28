import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/features/dashboard/widgets/transaction_card.dart';
import 'package:finance_tracker_offline/models/account.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountDetailScreen extends ConsumerWidget {
  final Account account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbService = ref.watch(dbServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
      ),
      body: StreamBuilder<List<Transaction>>(
        stream: dbService.watchTransactionsForAccount(account.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data!;

          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions for this account'));
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return TransactionCard(transaction: transaction);
            },
          );
        },
      ),
    );
  }
}
