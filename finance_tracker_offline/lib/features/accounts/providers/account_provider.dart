import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/models/account.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

// Change FutureProvider to StreamProvider for live updates
final accountsProvider = StreamProvider<List<Account>>((ref) {
  final dbService = ref.watch(dbServiceProvider);
  // Using .watch() instead of .findAll() creates a live stream
  return dbService.isar.accounts.where().watch(fireImmediately: true);
});