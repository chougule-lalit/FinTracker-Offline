import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_service.g.dart';

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) => throw UnimplementedError();

@Riverpod(keepAlive: true)
SettingsService settingsService(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsService(prefs);
}

class SettingsService {
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static const String _currencyCodeKey = 'currency_code';
  static const String _currencySymbolKey = 'currency_symbol';

  Future<void> setCurrency(String code, String symbol) async {
    await _prefs.setString(_currencyCodeKey, code);
    await _prefs.setString(_currencySymbolKey, symbol);
  }

  String getCurrencySymbol() {
    return _prefs.getString(_currencySymbolKey) ?? "₹";
  }

  String getCurrencyCode() {
    return _prefs.getString(_currencyCodeKey) ?? "INR";
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
