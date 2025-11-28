import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:finance_tracker_offline/core/services/settings_service.dart';

part 'settings_provider.g.dart';

class SettingsState {
  final String currencySymbol;
  final String currencyCode;

  SettingsState({required this.currencySymbol, required this.currencyCode});
}

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  @override
  SettingsState build() {
    final service = ref.watch(settingsServiceProvider);
    return SettingsState(
      currencySymbol: service.getCurrencySymbol(),
      currencyCode: service.getCurrencyCode(),
    );
  }

  Future<void> updateCurrency(String code, String symbol) async {
    final service = ref.read(settingsServiceProvider);
    await service.setCurrency(code, symbol);
    state = SettingsState(currencySymbol: symbol, currencyCode: code);
  }
}
