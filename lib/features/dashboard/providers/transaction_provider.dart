import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionListProvider = StreamProvider<List<Transaction>>((ref) {
  final dbService = ref.watch(dbServiceProvider);
  return dbService.listenToTransactions();
});
