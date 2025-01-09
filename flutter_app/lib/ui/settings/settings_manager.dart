import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';

class SettingsManager extends ChangeNotifier {
  final userSettings = getIt<UserSettings>();

  double get textSize => userSettings.textSize;

  Future<void> setTextSize(double size) async {
    await userSettings.setTextSize(size);
    notifyListeners();
  }

  ThemeMode get themeMode => userSettings.themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    await userSettings.setThemeMode(mode);
    getIt<AppState>().themeNotifier.value = mode;
    notifyListeners();
  }
}
