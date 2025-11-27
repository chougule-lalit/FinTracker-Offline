import 'package:isar_community/isar.dart';

part 'account.g.dart';

@collection
class Account {
  Id id = Isar.autoIncrement;

  late String name;

  late String type; // "Cash", "Bank", "Card"

  String? lastFourDigits;

  late double initialBalance;

  late double currentBalance;

  late String colorHex;
}
