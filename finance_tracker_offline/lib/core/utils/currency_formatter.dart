import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_tracker_offline/features/settings/providers/settings_provider.dart';

String formatCurrency(double amount, WidgetRef ref) {
  final settings = ref.watch(settingsProvider);
  return '${settings.currencySymbol} ${amount.toStringAsFixed(2)}';
}
