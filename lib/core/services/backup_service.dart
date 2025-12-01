import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:finance_tracker_offline/models/account.dart';
import 'package:finance_tracker_offline/models/category.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  final Isar isar;

  BackupService(this.isar);

  Future<void> createBackup() async {
    // 1. Fetch ALL data
    final accounts = await isar.accounts.where().findAll();
    final categories = await isar.categorys.where().findAll();
    final transactions = await isar.transactions.where().findAll();

    // 2. Create a JSON Map
    final data = {
      "version": 1,
      "timestamp": DateTime.now().toIso8601String(),
      "accounts": accounts.map((e) => e.toJson()).toList(),
      "categories": categories.map((e) => e.toJson()).toList(),
      "transactions": transactions.map((e) => e.toJson()).toList(),
    };

    // 3. Write to File
    Directory directory;
    if (Platform.isAndroid) {
      // Direct path to public Downloads folder on Android
      directory = Directory('/storage/emulated/0/Download');
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    // Ensure directory exists (just in case)
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/finance_backup_$timestamp.json');
    
    await file.writeAsString(jsonEncode(data));

    debugPrint('Backup saved to: ${file.path}');

    // 4. Share File
    await Share.shareXFiles([XFile(file.path)], text: 'My Finance Backup');
  }

  Future<bool> restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result == null) return false;
      
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content);
      
      if (data['version'] != 1) {
        throw Exception("Unknown Backup Version");
      }

      final accounts = (data['accounts'] as List).map((e) => Account.fromJson(e)).toList();
      final categories = (data['categories'] as List).map((e) => Category.fromJson(e)).toList();
      
      final transactionList = data['transactions'] as List;
      final transactions = <Transaction>[];

      // Create a map for quick lookup
      final accountMap = {for (var e in accounts) e.id: e};
      final categoryMap = {for (var e in categories) e.id: e};

      for (var i = 0; i < transactionList.length; i++) {
        final txnJson = transactionList[i];
        final txn = Transaction.fromJson(txnJson);
        
        final accountId = txnJson['accountId'] as int?;
        final categoryId = txnJson['categoryId'] as int?;
        final transferAccountId = txnJson['transferAccountId'] as int?;

        if (accountId != null && accountMap.containsKey(accountId)) {
          txn.account.value = accountMap[accountId];
        }
        
        if (categoryId != null && categoryMap.containsKey(categoryId)) {
          txn.category.value = categoryMap[categoryId];
        }

        if (transferAccountId != null && accountMap.containsKey(transferAccountId)) {
          txn.transferAccount.value = accountMap[transferAccountId];
        }
        
        transactions.add(txn);
      }

      await isar.writeTxn(() async {
        // Fix: Clear specific collections manually to avoid nesting transactions
        await isar.transactions.clear();
        await isar.accounts.clear();
        await isar.categorys.clear();
        
        // Now insert
        await isar.accounts.putAll(accounts);
        await isar.categorys.putAll(categories);
        await isar.transactions.putAll(transactions);
        
        // Save links
        for (var txn in transactions) {
           await txn.account.save();
           await txn.category.save();
           await txn.transferAccount.save();
        }
      });

      return true;
    } catch (e) {
      debugPrint('Restore failed: $e');
      rethrow;
    }
  }
}
