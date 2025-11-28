import 'package:finance_tracker_offline/core/utils/icon_utils.dart';
import 'package:finance_tracker_offline/features/settings/providers/settings_provider.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionCard extends ConsumerWidget {
  const TransactionCard({
    required this.transaction,
    super.key,
  });

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final category = transaction.category.value;
    final isTransfer = transaction.isTransfer;
    final isExpense = transaction.isExpense;

    // 1. Color Logic
    final Color color;
    if (isTransfer) {
      color = Colors.blue;
    } else {
      color = isExpense ? Colors.red : Colors.green;
    }

    final amountPrefix = isTransfer ? '' : (isExpense ? '-' : '+');

    // 2. Title Logic
    final String title;
    if (isTransfer) {
      final targetName = transaction.transferAccount.value?.name ?? 'Unknown';
      title = 'Transfer to $targetName';
    } else {
      title = category?.name ?? 'Unknown';
    }

    // 3. Icon Logic
    final IconData iconData;
    final Color iconColor;
    
    if (isTransfer) {
      iconData = Icons.swap_horiz;
      iconColor = Colors.blue;
    } else {
      iconData = category != null
          ? IconUtils.getIconData(category.iconCode)
          : Icons.help_outline;
      iconColor = category?.colorHex != null
          ? Color(int.parse(category!.colorHex, radix: 16))
          : Colors.grey.shade200;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor,
        child: Icon(
          iconData,
          color: Colors.white,
        ),
      ),
      title: Text(title),
      subtitle: transaction.note.isNotEmpty ? Text(transaction.note) : null,
      trailing: Text(
        '$amountPrefix${settings.currencySymbol} ${transaction.amount.toStringAsFixed(2)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
