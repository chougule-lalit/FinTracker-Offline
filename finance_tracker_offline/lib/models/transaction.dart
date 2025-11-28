import 'package:isar_community/isar.dart';
import 'account.dart';
import 'category.dart';

part 'transaction.g.dart';

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  late double amount;

  late String note;

  late DateTime date;

  late bool isExpense;

  bool isTransfer = false;

  String? smsRawText;

  String? smsId;

  String? receiptPath;

  final category = IsarLink<Category>();

  final account = IsarLink<Account>();

  final transferAccount = IsarLink<Account>();

  Transaction();

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction()
      ..id = json['id'] as int
      ..amount = (json['amount'] as num).toDouble()
      ..note = json['note'] as String
      ..date = DateTime.parse(json['date'] as String)
      ..isExpense = json['isExpense'] as bool
      ..isTransfer = json['isTransfer'] as bool? ?? false
      ..smsRawText = json['smsRawText'] as String?
      ..smsId = json['smsId'] as String?
      ..receiptPath = json['receiptPath'] as String?;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'isExpense': isExpense,
      'isTransfer': isTransfer,
      'smsRawText': smsRawText,
      'smsId': smsId,
      'receiptPath': receiptPath,
      'categoryId': category.value?.id,
      'accountId': account.value?.id,
      'transferAccountId': transferAccount.value?.id,
    };
  }
}
