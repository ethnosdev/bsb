import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';

class SettingsManager extends ChangeNotifier {
  final userSettings = getIt<UserSettings>();
  AppState? get _appState =>
      getIt.isRegistered<AppState>() ? getIt<AppState>() : null;

  double get textSize =>
      _appState?.textSizeNotifier.value ?? userSettings.textSize;

  Future<void> setTextSize(double size) async {
    if (_appState != null) {
      await _appState!.setTextSize(size);
    } else {
      await userSettings.setTextSize(size);
    }
    notifyListeners();
  }

  ThemeMode get themeMode => userSettings.themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    await userSettings.setThemeMode(mode);
    if (_appState != null) {
      _appState!.themeNotifier.value = mode;
    }
    notifyListeners();
  }

  BookChooserStyle get bookChooserStyle =>
      _appState?.bookChooserStyleNotifier.value ??
      userSettings.bookChooserStyle;

  Future<void> setBookChooserStyle(BookChooserStyle style) async {
    if (_appState != null) {
      await _appState!.setBookChooserStyle(style);
    } else {
      await userSettings.setBookChooserStyle(style);
    }
    notifyListeners();
  }

  ChapterChooserStyle get chapterChooserStyle =>
      _appState?.chapterChooserStyleNotifier.value ??
      userSettings.chapterChooserStyle;

  Future<void> setChapterChooserStyle(ChapterChooserStyle style) async {
    if (_appState != null) {
      await _appState!.setChapterChooserStyle(style);
    } else {
      await userSettings.setChapterChooserStyle(style);
    }
    notifyListeners();
  }

  bool get showVerseGrid =>
      _appState?.showVerseGridNotifier.value ?? userSettings.showVerseGrid;

  Future<void> setShowVerseGrid(bool show) async {
    if (_appState != null) {
      await _appState!.setShowVerseGrid(show);
    } else {
      await userSettings.setShowVerseGrid(show);
    }
    notifyListeners();
  }
}
