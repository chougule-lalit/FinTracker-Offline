import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:finance_tracker_offline/core/services/settings_service.dart';
import 'package:flutter/material.dart';

part 'settings_provider.g.dart';

class SettingsState {
  final String currencySymbol;
  final String currencyCode;
  final ThemeMode themeMode;

  SettingsState({
    required this.currencySymbol,
    required this.currencyCode,
    required this.themeMode,
  });
}

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  @override
  SettingsState build() {
    final service = ref.watch(settingsServiceProvider);
    final themeString = service.getThemeMode();
    
    ThemeMode mode;
    if (themeString == 'dark') {
      mode = ThemeMode.dark;
    } else if (themeString == 'light') {
      mode = ThemeMode.light;
    } else {
      mode = ThemeMode.system;
    }

    return SettingsState(
      currencySymbol: service.getCurrencySymbol(),
      currencyCode: service.getCurrencyCode(),
      themeMode: mode,
    );
  }

  Future<void> updateCurrency(String code, String symbol) async {
    final service = ref.read(settingsServiceProvider);
    await service.setCurrency(code, symbol);
    state = SettingsState(
      currencySymbol: symbol,
      currencyCode: code,
      themeMode: state.themeMode,
    );
  }

  Future<void> toggleTheme(bool isDark) async {
    final service = ref.read(settingsServiceProvider);
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    await service.setThemeMode(isDark ? 'dark' : 'light');
    state = SettingsState(
      currencySymbol: state.currencySymbol,
      currencyCode: state.currencyCode,
      themeMode: mode,
    );
  }
}
