import 'package:finance_tracker_offline/core/database/db_service.dart';
import 'package:finance_tracker_offline/models/account.dart';
import 'package:finance_tracker_offline/models/category.dart';
import 'package:finance_tracker_offline/models/transaction.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:isar_community/isar.dart';

class SmsParserService {
  final DbService _dbService = DbService();

  Future<Transaction?> parseSmsToTransaction(String body, int timestamp, String address) async {
    final lowerBody = body.toLowerCase();

    // 1. Check Keywords
    if (!_hasKeywords(lowerBody)) return null;

    // 2. Extract Account & Match
    String? accountDigits;
    // Fix: Updated regex to handle "A/c XX1234" where "XX" is between prefix and digits
    final accountRegex = RegExp(r'(?:XX|ending with |A\/C\s?(?:No)?\s?|acct\s?|account\s?)[:\s\-\.]*(?:XX|xx)?\s*([0-9]{3,4})', caseSensitive: false);
    final accountMatch = accountRegex.firstMatch(body);
    if (accountMatch != null) {
      accountDigits = accountMatch.group(1);
    }

    Account? matchedAccount;
    if (accountDigits != null) {
      matchedAccount = await _dbService.getAccountByDigits(accountDigits);
    }

    // 3. Transaction Type (Context Aware)
    // Priority: Debited > Credited
    int debitedIndex = _findMinIndex(lowerBody, ['debited', 'deducted', 'spent', 'purchase', 'withdrawn', 'paid']);
    int creditedIndex = _findMinIndex(lowerBody, ['credited', 'deposited', 'received', 'refund', 'added']);

    bool isExpense = true;
    if (debitedIndex != -1 && creditedIndex != -1) {
      // If both exist, checking if "credited" is after "to" (common in "paid to X credited")
      // Simple heuristic: If debit keyword appears first, it's likely a debit.
      isExpense = debitedIndex < creditedIndex;
    } else if (creditedIndex != -1) {
      isExpense = false;
    } else if (debitedIndex != -1) {
      isExpense = true;
    } else {
      return null;
    }

    // 4. Extract Amount
    final amountRegex = RegExp(r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(body);
    if (amountMatch == null) return null;

    String amountStr = amountMatch.group(1)!.replaceAll(',', '');
    double? amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return null;

    // 5. Extract Merchant (Note)
    String merchant = '';
    // Regex to find text between keywords
    if (isExpense) {
      // For Debit: "paid to Zomato", "at Zomato", "towards Zomato"
      final merchantRegex = RegExp(r'(?:to|at|towards|for)\s+([A-Za-z0-9\s\.\-]+?)(?:\s+(?:on|from|using|ref|txn|date|credited)|$)', caseSensitive: false);
      final match = merchantRegex.firstMatch(body);
      if (match != null) merchant = match.group(1)!.trim();
    } else {
      // For Credit: "from Zomato", "by Zomato", "for Salary" (Added 'for' support)
      final merchantRegex = RegExp(r'(?:from|by|for)\s+([A-Za-z0-9\s\.\-]+?)(?:\s+(?:on|to|using|ref|txn|date)|$)', caseSensitive: false);
      final match = merchantRegex.firstMatch(body);
      if (match != null) merchant = match.group(1)!.trim();
    }

    // Fallback for patterns like "Raj Auto Parts credited" (Merchant before keyword)
    if (merchant.isEmpty) {
       final suffixRegex = RegExp(r'([A-Za-z0-9\s\.\-]+?)\s+(?:credited|deposited|debited)', caseSensitive: false);
       final match = suffixRegex.firstMatch(body);
       if (match != null) {
         // Cleanup: remove common prefix words if caught
         String raw = match.group(1)!.trim();
         // If it captured the start of the message, split by common delimiters
         final parts = raw.split(RegExp(r'[;:]'));
         merchant = parts.last.trim();
       }
    }

    // Fallback: If regex failed, use a generic name based on type
    final noteText = merchant.isNotEmpty ? merchant : (isExpense ? "Unknown Expense" : "Unknown Deposit");

    // 6. Category Logic
    // Ensure "Uncategorized" exists
    Category? uncategorized = await _dbService.isar.categorys.filter().nameEqualTo('Uncategorized').findFirst();
    if (uncategorized == null) {
      // Create if missing but DO NOT SAVE yet
      uncategorized = Category()
        ..name = 'Uncategorized'
        ..iconCode = 'help_outline'
        ..colorHex = 'FF9E9E9E'
        ..isExpense = true
        ..isDefault = true;
      // await _dbService.addCategory(uncategorized); // REMOVED
    }

    // 7. Create & Save
    final transaction = Transaction()
      ..amount = amount
      ..isExpense = isExpense
      ..date = DateTime.fromMillisecondsSinceEpoch(timestamp)
      ..note = noteText // Fix: Explicitly assigning the merchant text here
      ..smsRawText = body
      ..smsId = '${address}_$timestamp';

    // Link relationships
    transaction.category.value = uncategorized;
    if (matchedAccount != null) {
      transaction.account.value = matchedAccount;
    }

    // Check duplicates
    final existing = await _dbService.isar.transactions.filter().smsIdEqualTo(transaction.smsId).findFirst();
    if (existing != null) {
       return null;
    }

    return transaction;
  }

  Future<int> syncBatchMessages(List<SmsMessage> messages) async {
    // Ensure Uncategorized category exists once
    Category? uncategorized = await _dbService.isar.categorys.filter().nameEqualTo('Uncategorized').findFirst();
    if (uncategorized == null) {
      uncategorized = Category()
        ..name = 'Uncategorized'
        ..iconCode = 'help_outline'
        ..colorHex = 'FF9E9E9E'
        ..isExpense = true
        ..isDefault = true;
      await _dbService.addCategory(uncategorized);
    }

    final List<Transaction> transactionsToSave = [];

    for (final message in messages) {
       final body = message.body ?? '';
       final address = message.address ?? 'Unknown';
       final date = message.date?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
       
       final transaction = await parseSmsToTransaction(body, date, address);
       if (transaction != null) {
         transactionsToSave.add(transaction);
       }
    }

    if (transactionsToSave.isEmpty) return 0;

    await _dbService.isar.writeTxn(() async {
      for (final txn in transactionsToSave) {
         await _dbService.isar.transactions.put(txn);
         await txn.category.save();
         
         // Handle Account Balance
         final linkedAccount = txn.account.value;
         if (linkedAccount != null) {
            final freshAccount = await _dbService.isar.accounts.get(linkedAccount.id);
            if (freshAccount != null) {
               if (txn.isExpense) {
                 freshAccount.currentBalance -= txn.amount;
               } else {
                 freshAccount.currentBalance += txn.amount;
               }
               await _dbService.isar.accounts.put(freshAccount);
               txn.account.value = freshAccount;
               await txn.account.save();
            }
         } else {
            await txn.account.save();
         }
      }
    });
    
    return transactionsToSave.length;
  }

  bool _hasKeywords(String body) {
    final keywords = [
      'debited', 'credited', 'spent', 'deposited', 'paid', 'sent', 'received', 
      'withdrawn', 'purchase', 'refund', 'deducted'
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
