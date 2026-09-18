import 'package:bsb/core/font_scale.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';

class AppState {
  final userSettings = getIt<UserSettings>();
  final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
  final textSizeNotifier = ValueNotifier<double>(FontScale.defaultBaseSize);
  final bookChooserStyleNotifier =
      ValueNotifier<BookChooserStyle>(BookChooserStyle.grid);
  final chapterChooserStyleNotifier =
      ValueNotifier<ChapterChooserStyle>(ChapterChooserStyle.keypad);
  final showVerseGridNotifier = ValueNotifier<bool>(false);

  Future<void> init() async {
    themeNotifier.value = userSettings.themeMode;
    textSizeNotifier.value = userSettings.textSize;
    bookChooserStyleNotifier.value = userSettings.bookChooserStyle;
    chapterChooserStyleNotifier.value = userSettings.chapterChooserStyle;
    showVerseGridNotifier.value = userSettings.showVerseGrid;
  }

  Future<void> setTextSize(double size) async {
    final clamped = FontScale.clampBase(size);
    textSizeNotifier.value = clamped;
    await userSettings.setTextSize(clamped);
  }

  Future<void> setBookChooserStyle(BookChooserStyle style) async {
    bookChooserStyleNotifier.value = style;
    await userSettings.setBookChooserStyle(style);
  }

  Future<void> setChapterChooserStyle(ChapterChooserStyle style) async {
    chapterChooserStyleNotifier.value = style;
    await userSettings.setChapterChooserStyle(style);
  }

  Future<void> setShowVerseGrid(bool show) async {
    showVerseGridNotifier.value = show;
    await userSettings.setShowVerseGrid(show);
  }
}

