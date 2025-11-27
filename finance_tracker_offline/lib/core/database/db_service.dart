import 'package:finance_tracker_offline/models/account.dart';
import 'package:finance_tracker_offline/models/category.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [TransactionSchema, CategorySchema, AccountSchema],
      directory: dir.path,
    );

    if (await isar.categorys.count() == 0) {
      await isar.writeTxn(() async {
        await isar.categorys.putAll([
          Category()
            ..name = 'Food'
            ..iconCode = 'fastfood'
            ..colorHex = 'FFEF5350' // Red 400
            ..isExpense = true
            ..isDefault = true,
          Category()
            ..name = 'Transport'
            ..iconCode = 'directions_bus'
            ..colorHex = 'FF42A5F5' // Blue 400
            ..isExpense = true
            ..isDefault = true,
          Category()
            ..name = 'Shopping'
            ..iconCode = 'shopping_bag'
            ..colorHex = 'FFAB47BC' // Purple 400
            ..isExpense = true
            ..isDefault = true,
          Category()
            ..name = 'Salary'
            ..iconCode = 'payments'
            ..colorHex = 'FF66BB6A' // Green 400
            ..isExpense = false
            ..isDefault = true,
          Category()
            ..name = 'Freelance'
            ..iconCode = 'work'
            ..colorHex = 'FFFFA726' // Orange 400
            ..isExpense = false
            ..isDefault = true,
        ]);
      });
    }
  }

  Future<void> addCategory(Category category) async {
    await isar.writeTxn(() async {
      await isar.categorys.put(category);
    });
  }

  Future<List<Category>> getAllCategories() async {
    return await isar.categorys.where().findAll();
  }

  Future<void> addTransaction(Transaction txn) async {
    await isar.writeTxn(() async {
      // 1. Save Transaction first
      await isar.transactions.put(txn);
      
      // 2. Save Links (Category & Account)
      // Important: Ensure the objects in .value are already saved in DB or save them now.
      await txn.category.save();
      await txn.account.save(); 

      // 3. Update Account Balance
      // We must load the account explicitly to ensure we are modifying the DB version
      final account = txn.account.value;
      if (account != null) {
        // Calculate new balance
        if (txn.isExpense) {
          account.currentBalance -= txn.amount;
        } else {
          account.currentBalance += txn.amount;
        }
        // SAVE the account with new balance
        await isar.accounts.put(account); 
      }
    });
  }

  Future<void> updateTransaction(Transaction txn, {
    required double oldAmount,
    required bool oldIsExpense,
    required Account? oldAccount,
  }) async {
    await isar.writeTxn(() async {
      // 1. Revert old balance effect
      if (oldAccount != null) {
        final accountToRevert = await isar.accounts.get(oldAccount.id);
        if (accountToRevert != null) {
          if (oldIsExpense) {
            accountToRevert.currentBalance += oldAmount;
          } else {
            accountToRevert.currentBalance -= oldAmount;
          }
          await isar.accounts.put(accountToRevert);
        }
      }

      // 2. Apply new balance effect
      final newAccount = txn.account.value;
      if (newAccount != null) {
        final accountToUpdate = await isar.accounts.get(newAccount.id);
        if (accountToUpdate != null) {
          if (txn.isExpense) {
            accountToUpdate.currentBalance -= txn.amount;
          } else {
            accountToUpdate.currentBalance += txn.amount;
          }
          await isar.accounts.put(accountToUpdate);
        }
      }

      // 3. Update transaction
      await isar.transactions.put(txn);
      await txn.category.save();
      await txn.account.save();
    });
  }

  Future<List<Transaction>> getAllTransactions() async {
    return await isar.transactions.where().findAll();
  }

  Stream<List<Transaction>> listenToTransactions() {
    return isar.transactions.where().sortByDateDesc().watch(fireImmediately: true);
  }

  Future<List<Transaction>> getTransactionsForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1).subtract(const Duration(microseconds: 1));
    
    return await isar.transactions
        .filter()
        .dateBetween(start, end)
        .findAll();
  }

  Future<void> addAccount(Account account) async {
    await isar.writeTxn(() async {
      await isar.accounts.put(account);
    });
  }

  Future<List<Account>> getAllAccounts() async {
    return await isar.accounts.where().findAll();
  }

  Future<Account?> getAccountByDigits(String last4) async {
    return await isar.accounts.filter().lastFourDigitsEqualTo(last4).findFirst();
  }
}

final dbServiceProvider = Provider<DbService>((ref) => DbService());
