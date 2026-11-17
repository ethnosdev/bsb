import 'package:bsb/core/font_scale.dart';
import 'package:bsb/core/theme.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:material_ui/material_ui.dart';

class AppState extends ChangeNotifier {
  final UserSettings userSettings;
  final DatabaseHelper? dbHelper;

  AppState({UserSettings? userSettings, this.dbHelper})
    : userSettings = userSettings ?? getIt<UserSettings>() {
    themeNotifier.addListener(notifyListeners);
    appThemeIdNotifier.addListener(notifyListeners);
    customThemeNotifier.addListener(notifyListeners);
    textSizeNotifier.addListener(notifyListeners);
    bookChooserStyleNotifier.addListener(notifyListeners);
    chapterChooserStyleNotifier.addListener(notifyListeners);
    showVerseGridNotifier.addListener(notifyListeners);
    verseChooserStyleNotifier.addListener(notifyListeners);
    wordsOfJesusInRedNotifier.addListener(notifyListeners);
    useBritishSpellingNotifier.addListener(notifyListeners);
    keepScreenAwakeNotifier.addListener(notifyListeners);
  }

  DatabaseHelper? get _effectiveDbHelper =>
      dbHelper ??
      (getIt.isRegistered<DatabaseHelper>() ? getIt<DatabaseHelper>() : null);

  final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
  final appThemeIdNotifier = ValueNotifier<String>(
    AppThemePreset.defaultPresetId,
  );
  final customThemeNotifier = ValueNotifier<CustomThemeConfig>(
    CustomThemeConfig.defaultConfig(),
  );
  final textSizeNotifier = ValueNotifier<double>(FontScale.defaultBaseSize);
  final bookChooserStyleNotifier = ValueNotifier<BookChooserStyle>(
    BookChooserStyle.grid,
  );
  final chapterChooserStyleNotifier = ValueNotifier<ChapterChooserStyle>(
    ChapterChooserStyle.keypad,
  );
  final showVerseGridNotifier = ValueNotifier<bool>(false);
  final verseChooserStyleNotifier = ValueNotifier<VerseChooserStyle>(
    VerseChooserStyle.sidebar,
  );
  final wordsOfJesusInRedNotifier = ValueNotifier<bool>(false);
  final useBritishSpellingNotifier = ValueNotifier<bool>(false);
  final keepScreenAwakeNotifier = ValueNotifier<bool>(true);

  ThemeMode get themeMode => themeNotifier.value;
  String get appThemeId => appThemeIdNotifier.value;
  bool get isCustomTheme => appThemeId == AppThemePreset.customPresetId;
  CustomThemeConfig get customTheme => customThemeNotifier.value;
  AppThemePreset get currentThemePreset => AppThemePreset.findById(appThemeId);

  ThemeData get _customThemeData => MaterialTheme.buildTheme(
    colorScheme: customTheme.toColorScheme(),
    wordsOfJesusColor: customTheme.wordsOfJesusColor,
    verseNumberColor: customTheme.verseNumberColor,
  );

  ThemeData get lightThemeData {
    if (isCustomTheme) return _customThemeData;
    return MaterialTheme.buildTheme(
      colorScheme: currentThemePreset.lightScheme,
      wordsOfJesusColor: getWordsOfJesusColor(Brightness.light),
    );
  }

  ThemeData get darkThemeData {
    if (isCustomTheme) return _customThemeData;
    return MaterialTheme.buildTheme(
      colorScheme: currentThemePreset.darkScheme,
      wordsOfJesusColor: getWordsOfJesusColor(Brightness.dark),
    );
  }

  /// Returns the effective color for the Words of Jesus based on the current theme and brightness.
  Color getWordsOfJesusColor(Brightness brightness) {
    if (isCustomTheme) {
      return customTheme.wordsOfJesusColor;
    }
    return ScriptureTheme.defaultWordsOfJesusColor(brightness);
  }

  double get textSize => textSizeNotifier.value;
  BookChooserStyle get bookChooserStyle => bookChooserStyleNotifier.value;
  ChapterChooserStyle get chapterChooserStyle =>
      chapterChooserStyleNotifier.value;
  bool get showVerseGrid => showVerseGridNotifier.value;
  VerseChooserStyle get verseChooserStyle => verseChooserStyleNotifier.value;
  bool get wordsOfJesusInRed => wordsOfJesusInRedNotifier.value;
  bool get useBritishSpelling => useBritishSpellingNotifier.value;
  bool get keepScreenAwake => keepScreenAwakeNotifier.value;

  Brightness _safePlatformBrightness() {
    try {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    } catch (_) {
      return Brightness.light;
    }
  }

  Future<void> init({Brightness? platformBrightness}) async {
    await userSettings.migrateCustomThemeIfNeeded(
      platformBrightness: platformBrightness ?? _safePlatformBrightness(),
    );
    themeNotifier.value = userSettings.themeMode;
    appThemeIdNotifier.value = userSettings.appThemeId;
    customThemeNotifier.value = userSettings.customTheme;
    textSizeNotifier.value = userSettings.textSize;
    bookChooserStyleNotifier.value = userSettings.bookChooserStyle;
    chapterChooserStyleNotifier.value = userSettings.chapterChooserStyle;
    showVerseGridNotifier.value = userSettings.showVerseGrid;
    verseChooserStyleNotifier.value = userSettings.verseChooserStyle;
    wordsOfJesusInRedNotifier.value = userSettings.wordsOfJesusInRed;
    final british = userSettings.useBritishSpelling;
    _effectiveDbHelper?.setUseBritishSpelling(british);
    useBritishSpellingNotifier.value = british;
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

  Future<void> setCustomTheme(CustomThemeConfig config) async {
    customThemeNotifier.value = config;
    await userSettings.setCustomTheme(config);
  }

  Future<void> applyThemeSelection({
    required String themeId,
    CustomThemeConfig? customConfig,
    ThemeMode? mode,
  }) async {
    if (customConfig != null) {
      customThemeNotifier.value = customConfig;
      await userSettings.setCustomTheme(customConfig);
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
    verseChooserStyleNotifier.value = show
        ? VerseChooserStyle.grid
        : VerseChooserStyle.sidebar;
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

  Future<void> setUseBritishSpelling(bool value) async {
    _effectiveDbHelper?.setUseBritishSpelling(value);
    useBritishSpellingNotifier.value = value;
    await userSettings.setUseBritishSpelling(value);
  }

  Future<void> setKeepScreenAwake(bool value) async {
    keepScreenAwakeNotifier.value = value;
    await userSettings.setKeepScreenAwake(value);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(notifyListeners);
    appThemeIdNotifier.removeListener(notifyListeners);
    customThemeNotifier.removeListener(notifyListeners);
    textSizeNotifier.removeListener(notifyListeners);
    bookChooserStyleNotifier.removeListener(notifyListeners);
    chapterChooserStyleNotifier.removeListener(notifyListeners);
    showVerseGridNotifier.removeListener(notifyListeners);
    verseChooserStyleNotifier.removeListener(notifyListeners);
    wordsOfJesusInRedNotifier.removeListener(notifyListeners);
    useBritishSpellingNotifier.removeListener(notifyListeners);
    keepScreenAwakeNotifier.removeListener(notifyListeners);
    themeNotifier.dispose();
    appThemeIdNotifier.dispose();
    customThemeNotifier.dispose();
    textSizeNotifier.dispose();
    bookChooserStyleNotifier.dispose();
    chapterChooserStyleNotifier.dispose();
    showVerseGridNotifier.dispose();
    verseChooserStyleNotifier.dispose();
    wordsOfJesusInRedNotifier.dispose();
    useBritishSpellingNotifier.dispose();
    keepScreenAwakeNotifier.dispose();
    super.dispose();
  }
}
