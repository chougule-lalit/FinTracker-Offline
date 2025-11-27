import 'package:finance_tracker_offline/core/utils/icon_utils.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:flutter/material.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({
    required this.transaction,
    super.key,
  });

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final category = transaction.category.value;
    final isExpense = transaction.isExpense;
    final color = isExpense ? Colors.red : Colors.green;
    final amountPrefix = isExpense ? '-' : '+';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: category?.colorHex != null
            ? Color(int.parse(category!.colorHex, radix: 16))
            : Colors.grey.shade200,
        child: Icon(
          category != null
              ? IconUtils.getIconData(category.iconCode)
              : Icons.help_outline,
          color: Colors.white,
        ),
      ),
      title: Text(category?.name ?? 'Unknown'),
      subtitle: transaction.note.isNotEmpty ? Text(transaction.note) : null,
      trailing: Text(
        '$amountPrefix${transaction.amount.toStringAsFixed(2)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
