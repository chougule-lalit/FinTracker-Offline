import 'package:flutter/material.dart';

class IconUtils {
  static IconData getIconData(String iconCode) {
    switch (iconCode) {
      case 'fastfood':
        return Icons.fastfood;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'payments':
        return Icons.payments;
      case 'work':
        return Icons.work;
      default:
        return Icons.category;
    }
  }
}
