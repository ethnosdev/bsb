import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';

class SettingsManager extends ChangeNotifier {
  final userSettings = getIt<UserSettings>();

  bool get isDarkMode => userSettings.isDarkMode;

  double get textSize => userSettings.textSize;

  Future<void> setDarkMode(bool value) async {
    await userSettings.setDarkMode(value);
    notifyListeners();
  }

  Future<void> setTextSize(double size) async {
    await userSettings.setTextSize(size);
    notifyListeners();
  }
}
