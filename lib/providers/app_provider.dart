import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('es');
  String _currency = 'PYG';

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String get currency => _currency;

  AppProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode') ?? 'system';
    final lang = prefs.getString('locale') ?? 'es';
    final cur = prefs.getString('currency') ?? 'PYG';

    _themeMode = theme == 'light'
        ? ThemeMode.light
        : theme == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;
    _locale = Locale(lang);
    _currency = cur;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    _currency = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', code);
    notifyListeners();
  }
}