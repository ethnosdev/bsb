import 'package:bsb/core/font_scale.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';

class AppState {
  final userSettings = getIt<UserSettings>();
  final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
  final textSizeNotifier = ValueNotifier<double>(FontScale.defaultBaseSize);

  Future<void> init() async {
    themeNotifier.value = userSettings.themeMode;
    textSizeNotifier.value = userSettings.textSize;
  }

  Future<void> setTextSize(double size) async {
    final clamped = FontScale.clampBase(size);
    textSizeNotifier.value = clamped;
    await userSettings.setTextSize(clamped);
  }
}

