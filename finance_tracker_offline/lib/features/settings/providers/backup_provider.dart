import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/core/services/backup_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_provider.g.dart';

@riverpod
BackupService backupService(Ref ref) {
  final dbService = ref.watch(dbServiceProvider);
  return BackupService(dbService.isar);
}
