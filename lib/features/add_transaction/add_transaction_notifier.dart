import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/features/add_transaction/add_transaction_state.dart';
import 'package:finance_tracker_offline/models/category.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_transaction_notifier.g.dart';

@riverpod
class AddTransactionNotifier extends _$AddTransactionNotifier {
  @override
  AddTransactionState build() {
    return const AddTransactionState();
  }

  void setAmount(String value) {
    final amount = double.tryParse(value);
    state = state.copyWith(amount: amount);
  }

  void setDescription(String value) {
    state = state.copyWith(description: value);
  }

  Future<void> saveTransaction() async {
    if (state.amount == null) {
      state = state.copyWith(error: 'Please enter a valid amount');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final dbService = ref.read(dbServiceProvider);

      // Hardcoded category for now
      final category = Category()
        ..name = 'Groceries'
        ..iconCode = 'shopping_cart'
        ..colorHex = 'FF4CAF50'
        ..isDefault = true;

      final txn = Transaction()
        ..amount = state.amount!
        ..note = state.description
        ..date = DateTime.now()
        ..isExpense = true;

      txn.category.value = category;

      await dbService.addTransaction(txn);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
