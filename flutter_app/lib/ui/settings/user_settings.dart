import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettings {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const _textSizeKey = 'textSize';

  double get textSize => _prefs.getDouble(_textSizeKey) ?? 20.0;

  Future<void> setTextSize(double size) async {
    _prefs.setDouble(_textSizeKey, size);
  }

  static const _isDarkModeKey = 'isDarkMode';

  ThemeMode get themeMode {
    final isDark = _prefs.getBool(_isDarkModeKey);
    if (isDark == null) return ThemeMode.system;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == ThemeMode.system) {
      await _prefs.remove(_isDarkModeKey);
      return;
    }
    final isDark = mode == ThemeMode.dark;
    await _prefs.setBool(_isDarkModeKey, isDark);
  }

  static const _showInterlinearEnglishKey = 'showInterlinearEnglish';

  bool get showInterlinearEnglish =>
      _prefs.getBool(_showInterlinearEnglishKey) ?? true;

  Future<void> setShowInterlinearEnglish(bool show) async {
    await _prefs.setBool(_showInterlinearEnglishKey, show);
  }
}
