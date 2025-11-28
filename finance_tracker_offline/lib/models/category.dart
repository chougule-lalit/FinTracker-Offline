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

  Category();

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category()
      ..id = json['id'] as int
      ..name = json['name'] as String
      ..iconCode = json['iconCode'] as String
      ..colorHex = json['colorHex'] as String
      ..isDefault = json['isDefault'] as bool
      ..isExpense = json['isExpense'] as bool;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCode': iconCode,
      'colorHex': colorHex,
      'isDefault': isDefault,
      'isExpense': isExpense,
    };
  }
}
