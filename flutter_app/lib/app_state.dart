import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';

class AppState {
  final userSettings = getIt<UserSettings>();
  final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

  Future<void> init() async {
    themeNotifier.value = userSettings.themeMode;
  }
}
