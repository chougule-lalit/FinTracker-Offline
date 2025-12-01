import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/models/category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final dbService = ref.watch(dbServiceProvider);
  return await dbService.getAllCategories();
});
