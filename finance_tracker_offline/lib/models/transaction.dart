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

  String? smsRawText;

  String? smsId;

  final category = IsarLink<Category>();

  final account = IsarLink<Account>();
}
