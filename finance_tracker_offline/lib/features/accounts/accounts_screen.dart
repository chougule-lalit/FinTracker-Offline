import 'package:finance_tracker_offline/features/accounts/providers/account_provider.dart';
import 'package:finance_tracker_offline/models/account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(
              child: Text('No accounts added yet.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return AccountCard(account: account);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add_account'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AccountCard extends StatelessWidget {
  final Account account;

  const AccountCard({super.key, required this.account});

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Bank':
        return Icons.account_balance;
      case 'Card':
        return Icons.credit_card;
      case 'Cash':
        return Icons.money;
      default:
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final color = Color(int.parse(account.colorHex, radix: 16));

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(
            _getIconForType(account.type),
            color: color,
          ),
        ),
        title: Text(
          account.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: account.lastFourDigits != null
            ? Text('Ends in: ${account.lastFourDigits}')
            : null,
        trailing: Text(
          currencyFormat.format(account.currentBalance),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: account.currentBalance >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
