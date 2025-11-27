import 'package:isar_community/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  late String name;

  late String iconCode;

  late String colorHex;

  bool isDefault = false;

  late bool isExpense;
}
