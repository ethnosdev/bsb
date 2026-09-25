import 'package:bsb/core/font_scale.dart';
import 'package:bsb/core/theme.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  final UserSettings userSettings;

  AppState({UserSettings? userSettings})
      : userSettings = userSettings ?? getIt<UserSettings>() {
    themeNotifier.addListener(notifyListeners);
    appThemeIdNotifier.addListener(notifyListeners);
    customThemeLightNotifier.addListener(notifyListeners);
    customThemeDarkNotifier.addListener(notifyListeners);
    textSizeNotifier.addListener(notifyListeners);
    bookChooserStyleNotifier.addListener(notifyListeners);
    chapterChooserStyleNotifier.addListener(notifyListeners);
    showVerseGridNotifier.addListener(notifyListeners);
    verseChooserStyleNotifier.addListener(notifyListeners);
    wordsOfJesusInRedNotifier.addListener(notifyListeners);
    keepScreenAwakeNotifier.addListener(notifyListeners);
  }

  final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
  final appThemeIdNotifier =
      ValueNotifier<String>(AppThemePreset.defaultPresetId);
  final customThemeLightNotifier =
      ValueNotifier<CustomThemeConfig>(CustomThemeConfig.defaultLight());
  final customThemeDarkNotifier =
      ValueNotifier<CustomThemeConfig>(CustomThemeConfig.defaultDark());
  final textSizeNotifier = ValueNotifier<double>(FontScale.defaultBaseSize);
  final bookChooserStyleNotifier =
      ValueNotifier<BookChooserStyle>(BookChooserStyle.grid);
  final chapterChooserStyleNotifier =
      ValueNotifier<ChapterChooserStyle>(ChapterChooserStyle.keypad);
  final showVerseGridNotifier = ValueNotifier<bool>(false);
  final verseChooserStyleNotifier =
      ValueNotifier<VerseChooserStyle>(VerseChooserStyle.sidebar);
  final wordsOfJesusInRedNotifier = ValueNotifier<bool>(false);
  final keepScreenAwakeNotifier = ValueNotifier<bool>(true);

  ThemeMode get themeMode => themeNotifier.value;
  String get appThemeId => appThemeIdNotifier.value;
  bool get isCustomTheme => appThemeId == AppThemePreset.customPresetId;
  CustomThemeConfig get customThemeLight => customThemeLightNotifier.value;
  CustomThemeConfig get customThemeDark => customThemeDarkNotifier.value;
  AppThemePreset get currentThemePreset => AppThemePreset.findById(appThemeId);

  ThemeData get lightThemeData {
    final colorScheme = isCustomTheme
        ? customThemeLight.toColorScheme()
        : currentThemePreset.lightScheme;
    return MaterialTheme.buildTheme(colorScheme: colorScheme);
  }

  ThemeData get darkThemeData {
    final colorScheme = isCustomTheme
        ? customThemeDark.toColorScheme()
        : currentThemePreset.darkScheme;
    return MaterialTheme.buildTheme(colorScheme: colorScheme);
  }

  double get textSize => textSizeNotifier.value;
  BookChooserStyle get bookChooserStyle => bookChooserStyleNotifier.value;
  ChapterChooserStyle get chapterChooserStyle =>
      chapterChooserStyleNotifier.value;
  bool get showVerseGrid => showVerseGridNotifier.value;
  VerseChooserStyle get verseChooserStyle => verseChooserStyleNotifier.value;
  bool get wordsOfJesusInRed => wordsOfJesusInRedNotifier.value;
  bool get keepScreenAwake => keepScreenAwakeNotifier.value;

  Future<void> init() async {
    themeNotifier.value = userSettings.themeMode;
    appThemeIdNotifier.value = userSettings.appThemeId;
    customThemeLightNotifier.value = userSettings.customThemeLight;
    customThemeDarkNotifier.value = userSettings.customThemeDark;
    textSizeNotifier.value = userSettings.textSize;
    bookChooserStyleNotifier.value = userSettings.bookChooserStyle;
    chapterChooserStyleNotifier.value = userSettings.chapterChooserStyle;
    showVerseGridNotifier.value = userSettings.showVerseGrid;
    verseChooserStyleNotifier.value = userSettings.verseChooserStyle;
    wordsOfJesusInRedNotifier.value = userSettings.wordsOfJesusInRed;
    keepScreenAwakeNotifier.value = userSettings.keepScreenAwake;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeNotifier.value = mode;
    await userSettings.setThemeMode(mode);
  }

  Future<void> setAppThemeId(String id) async {
    appThemeIdNotifier.value = id;
    await userSettings.setAppThemeId(id);
  }

  Future<void> setCustomThemeLight(CustomThemeConfig config) async {
    customThemeLightNotifier.value = config;
    await userSettings.setCustomThemeLight(config);
  }

  Future<void> setCustomThemeDark(CustomThemeConfig config) async {
    customThemeDarkNotifier.value = config;
    await userSettings.setCustomThemeDark(config);
  }

  Future<void> applyThemeSelection({
    required String themeId,
    CustomThemeConfig? lightConfig,
    CustomThemeConfig? darkConfig,
    ThemeMode? mode,
  }) async {
    if (lightConfig != null) {
      customThemeLightNotifier.value = lightConfig;
      await userSettings.setCustomThemeLight(lightConfig);
    }
    if (darkConfig != null) {
      customThemeDarkNotifier.value = darkConfig;
      await userSettings.setCustomThemeDark(darkConfig);
    }
    if (mode != null) {
      themeNotifier.value = mode;
      await userSettings.setThemeMode(mode);
    }
    appThemeIdNotifier.value = themeId;
    await userSettings.setAppThemeId(themeId);
  }

  void updateTextSizePreview(double size) {
    textSizeNotifier.value = FontScale.clampBase(size);
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
    verseChooserStyleNotifier.value =
        show ? VerseChooserStyle.grid : VerseChooserStyle.sidebar;
    await userSettings.setShowVerseGrid(show);
  }

  Future<void> setVerseChooserStyle(VerseChooserStyle style) async {
    verseChooserStyleNotifier.value = style;
    showVerseGridNotifier.value = style == VerseChooserStyle.grid;
    await userSettings.setVerseChooserStyle(style);
  }

  Future<void> setWordsOfJesusInRed(bool value) async {
    wordsOfJesusInRedNotifier.value = value;
    await userSettings.setWordsOfJesusInRed(value);
  }

  Future<void> setKeepScreenAwake(bool value) async {
    keepScreenAwakeNotifier.value = value;
    await userSettings.setKeepScreenAwake(value);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(notifyListeners);
    appThemeIdNotifier.removeListener(notifyListeners);
    customThemeLightNotifier.removeListener(notifyListeners);
    customThemeDarkNotifier.removeListener(notifyListeners);
    textSizeNotifier.removeListener(notifyListeners);
    bookChooserStyleNotifier.removeListener(notifyListeners);
    chapterChooserStyleNotifier.removeListener(notifyListeners);
    showVerseGridNotifier.removeListener(notifyListeners);
    verseChooserStyleNotifier.removeListener(notifyListeners);
    wordsOfJesusInRedNotifier.removeListener(notifyListeners);
    keepScreenAwakeNotifier.removeListener(notifyListeners);
    themeNotifier.dispose();
    appThemeIdNotifier.dispose();
    customThemeLightNotifier.dispose();
    customThemeDarkNotifier.dispose();
    textSizeNotifier.dispose();
    bookChooserStyleNotifier.dispose();
    chapterChooserStyleNotifier.dispose();
    showVerseGridNotifier.dispose();
    verseChooserStyleNotifier.dispose();
    wordsOfJesusInRedNotifier.dispose();
    keepScreenAwakeNotifier.dispose();
    super.dispose();
  }
}
