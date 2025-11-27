import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';

class DbService {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [TransactionSchema, CategorySchema],
      directory: dir.path,
    );
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
}

final dbServiceProvider = Provider<DbService>((ref) => DbService());
