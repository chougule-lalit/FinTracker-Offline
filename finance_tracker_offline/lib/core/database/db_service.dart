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
      [TransactionSchema, CategorySchema],
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
      await isar.transactions.put(txn);
      await txn.category.save();
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
}

final dbServiceProvider = Provider<DbService>((ref) => DbService());
