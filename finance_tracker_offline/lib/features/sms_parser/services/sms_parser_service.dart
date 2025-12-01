import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/models/account.dart';
import 'package:finance_tracker_offline/models/category.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:isar_community/isar.dart';

class SmsParserService {
  final DbService _dbService = DbService();

  Future<Transaction?> parseSmsToTransaction(
      String body, int timestamp, String address) async {
    final lowerBody = body.toLowerCase();

    // 1. Check Keywords
    if (!_hasKeywords(lowerBody)) return null;

    // 2. Extract Account & Match
    String? accountDigits;
    final accountRegex = RegExp(
        r'(?:XX|ending with |A\/C\s?(?:No)?\s?|acct\s?|account\s?)[:\s\-\.]*(?:XX|xx)?\s*([0-9]{3,4})',
        caseSensitive: false);
    final accountMatch = accountRegex.firstMatch(body);
    if (accountMatch != null) {
      accountDigits = accountMatch.group(1);
    }

    Account? matchedAccount;
    if (accountDigits != null) {
      matchedAccount = await _dbService.getAccountByDigits(accountDigits);
    }

    // 3. Transaction Type (Context Aware)
    int debitedIndex = _findMinIndex(lowerBody,
        ['debited', 'deducted', 'spent', 'purchase', 'withdrawn', 'paid']);
    int creditedIndex = _findMinIndex(
        lowerBody, ['credited', 'deposited', 'received', 'refund', 'added']);

    bool isExpense = true;
    if (debitedIndex != -1 && creditedIndex != -1) {
      isExpense = debitedIndex < creditedIndex;
    } else if (creditedIndex != -1) {
      isExpense = false;
    } else if (debitedIndex != -1) {
      isExpense = true;
    } else {
      return null;
    }

    // 4. Extract Amount
    final amountRegex =
        RegExp(r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(body);
    if (amountMatch == null) return null;

    String amountStr = amountMatch.group(1)!.replaceAll(',', '');
    double? amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return null;

    // 5. Extract Merchant (Note)
    String merchant = '';
    if (isExpense) {
      final merchantRegex = RegExp(
          r'(?:to|at|towards|for)\s+([A-Za-z0-9\s\.\-]+?)(?:\s+(?:on|from|using|ref|txn|date|credited)|$)',
          caseSensitive: false);
      final match = merchantRegex.firstMatch(body);
      if (match != null) merchant = match.group(1)!.trim();
    } else {
      final merchantRegex = RegExp(
          r'(?:from|by|for)\s+([A-Za-z0-9\s\.\-]+?)(?:\s+(?:on|to|using|ref|txn|date)|$)',
          caseSensitive: false);
      final match = merchantRegex.firstMatch(body);
      if (match != null) merchant = match.group(1)!.trim();
    }

    // Fallback Merchant Logic
    if (merchant.isEmpty) {
      final suffixRegex = RegExp(
          r'([A-Za-z0-9\s\.\-]+?)\s+(?:credited|deposited|debited)',
          caseSensitive: false);
      final match = suffixRegex.firstMatch(body);
      if (match != null) {
        String raw = match.group(1)!.trim();
        final parts = raw.split(RegExp(r'[;:]'));
        merchant = parts.last.trim();
      }
    }

    final noteText = merchant.isNotEmpty
        ? merchant
        : (isExpense ? "Unknown Expense" : "Unknown Deposit");

    // 6. Category Logic (Read-Only here)
    // We check DB to see if Uncategorized exists so we can link it, but we don't create it here.
    Category? uncategorized = await _dbService.isar.categorys
        .filter()
        .nameEqualTo('Uncategorized')
        .findFirst();

    // Note: If uncategorized is null here, we handle it by not linking,
    // or relying on the batch method to have created it already.

    // 7. Create Object
    final transaction = Transaction()
      ..amount = amount
      ..isExpense = isExpense
      ..date = DateTime.fromMillisecondsSinceEpoch(timestamp)
      ..note = noteText
      ..smsRawText = body
      ..smsId = '${address}_$timestamp';

    // Link relationships
    if (uncategorized != null) {
      transaction.category.value = uncategorized;
    }

    if (matchedAccount != null) {
      transaction.account.value = matchedAccount;
    }

    return transaction;
  }

  Future<int> syncBatchMessages(List<SmsMessage> messages) async {
    final isar = _dbService.isar;

    // --- STEP 1: PRE-CHECK (Read/Write safe) ---
    // Ensure Uncategorized category exists before we start anything.
    Category? uncategorized =
        await isar.categorys.filter().nameEqualTo('Uncategorized').findFirst();
    if (uncategorized == null) {
      uncategorized = Category()
        ..name = 'Uncategorized'
        ..iconCode = 'help_outline'
        ..colorHex = 'FF9E9E9E'
        ..isExpense = true
        ..isDefault = true;
      // We can safely call addCategory here because we are NOT in a writeTxn yet.
      await _dbService.addCategory(uncategorized);
    }

    final List<Transaction> transactionsToSave = [];

    // --- STEP 2: PARSE (Read Only) ---
    for (final message in messages) {
      final body = message.body ?? '';
      final address = message.address ?? 'Unknown';
      final date = message.date?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch;

      // Check duplication (Read only)
      final existing = await isar.transactions
          .filter()
          .smsIdEqualTo('${address}_$date')
          .findFirst();
      if (existing != null) continue;

      final transaction = await parseSmsToTransaction(body, date, address);
      if (transaction != null) {
        // Ensure we link the fresh Uncategorized category we just fetched/created
        if (transaction.category.value == null) {
          transaction.category.value = uncategorized;
        }
        transactionsToSave.add(transaction);
      } else {
        // Log silent failures
        print('Skipped SMS from $address: Body: $body');
      }
    }

    if (transactionsToSave.isEmpty) return 0;

    // --- STEP 3: BATCH WRITE (Synchronous / Nuclear Option) ---
    // We use writeTxnSync to BLOCK all other app logic while this runs.
    // This prevents "Ghost" listeners from trying to write at the same time.
    
    isar.writeTxnSync(() {
      for (final txn in transactionsToSave) {
        
        // 1. Save Transaction (Synchronous)
        isar.transactions.putSync(txn);

        // 2. Handle Account Balance (Synchronous)
        final linkedAccount = txn.account.value;
        if (linkedAccount != null) {
          // Use getSync (No await)
          final freshAccount = isar.accounts.getSync(linkedAccount.id);

          if (freshAccount != null) {
            if (txn.isExpense) {
              freshAccount.currentBalance -= txn.amount;
            } else {
              freshAccount.currentBalance += txn.amount;
            }
            // Use putSync (No await)
            isar.accounts.putSync(freshAccount);
          }
        }
      }
    });

    return transactionsToSave.length;
  }

  bool _hasKeywords(String body) {
    final keywords = [
      'debited',
      'credited',
      'spent',
      'deposited',
      'paid',
      'sent',
      'received',
      'withdrawn',
      'purchase',
      'refund',
      'deducted'
    ];
    for (var k in keywords) {
      if (body.contains(k)) return true;
    }
    return false;
  }

  int _findMinIndex(String text, List<String> keywords) {
    int minIndex = -1;
    for (final keyword in keywords) {
      final index = text.indexOf(keyword);
      if (index != -1) {
        if (minIndex == -1 || index < minIndex) {
          minIndex = index;
        }
      }
    }
    return minIndex;
  }
}
