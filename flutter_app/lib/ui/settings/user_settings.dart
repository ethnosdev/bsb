import 'dart:convert';

import 'package:bsb/core/theme.dart';
import 'package:bsb/infrastructure/audio/audio_models.dart';
import 'package:material_ui/material_ui.dart';
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

  static const _appThemeIdKey = 'appThemeId';

  String get appThemeId =>
      _prefs.getString(_appThemeIdKey) ?? AppThemePreset.defaultPresetId;

  Future<void> setAppThemeId(String id) async {
    if (id == AppThemePreset.defaultPresetId) {
      await _prefs.remove(_appThemeIdKey);
    } else {
      await _prefs.setString(_appThemeIdKey, id);
    }
  }

  static const _customThemeKey = 'customTheme';
  static const _legacyCustomThemeLightKey = 'customThemeLight';
  static const _legacyCustomThemeDarkKey = 'customThemeDark';

  CustomThemeConfig get customTheme {
    final raw = _prefs.getString(_customThemeKey);
    if (raw == null) return CustomThemeConfig.defaultConfig();
    return CustomThemeConfig.fromJsonString(raw);
  }

  Future<void> setCustomTheme(CustomThemeConfig config) async {
    await _prefs.setString(_customThemeKey, config.toJsonString());
  }

  bool get hasSavedCustomTheme => _prefs.containsKey(_customThemeKey);

  /// One-time migration from legacy paired light/dark custom theme keys into
  /// the single `customTheme` key.
  Future<void> migrateCustomThemeIfNeeded({
    Brightness platformBrightness = Brightness.light,
  }) async {
    if (_prefs.containsKey(_customThemeKey)) return;

    final lightRaw = _prefs.getString(_legacyCustomThemeLightKey);
    final darkRaw = _prefs.getString(_legacyCustomThemeDarkKey);
    if (lightRaw == null && darkRaw == null) return;

    late final String chosenRaw;
    if (lightRaw != null && darkRaw == null) {
      chosenRaw = lightRaw;
    } else if (darkRaw != null && lightRaw == null) {
      chosenRaw = darkRaw;
    } else {
      switch (themeMode) {
        case ThemeMode.dark:
          chosenRaw = darkRaw!;
        case ThemeMode.light:
          chosenRaw = lightRaw!;
        case ThemeMode.system:
          final lightCustomized = _isLegacySideCustomized(lightRaw!);
          final darkCustomized = _isLegacySideCustomized(darkRaw!);
          if (lightCustomized != darkCustomized) {
            chosenRaw = lightCustomized ? lightRaw : darkRaw;
          } else {
            chosenRaw = platformBrightness == Brightness.dark
                ? darkRaw
                : lightRaw;
          }
      }
    }

    final migrated = CustomThemeConfig.fromJsonString(chosenRaw);
    await setCustomTheme(migrated);
    await _prefs.remove(_legacyCustomThemeLightKey);
    await _prefs.remove(_legacyCustomThemeDarkKey);
  }

  bool _isLegacySideCustomized(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false;
      return decoded['isBackgroundAutoDerived'] != true;
    } catch (_) {
      return false;
    }
  }

  static const _customColorHistoryKey = 'customColorHistory';

  List<Color> get customColorHistory {
    final raw = _prefs.getStringList(_customColorHistoryKey);
    if (raw == null) return [];
    return raw
        .map((str) => int.tryParse(str))
        .whereType<int>()
        .map((val) => Color(val))
        .toList();
  }

  Future<void> addCustomColorToHistory(Color color) async {
    final valStr = color.toARGB32().toString();
    final list = _prefs.getStringList(_customColorHistoryKey) ?? [];
    list.remove(valStr);
    list.insert(0, valStr);
    if (list.length > 20) {
      list.removeRange(20, list.length);
    }
    await _prefs.setStringList(_customColorHistoryKey, list);
  }

  Future<void> clearCustomColorHistory() async {
    await _prefs.remove(_customColorHistoryKey);
  }

  static const _showInterlinearEnglishKey = 'showInterlinearEnglish';

  bool get showInterlinearEnglish =>
      _prefs.getBool(_showInterlinearEnglishKey) ?? true;

  Future<void> setShowInterlinearEnglish(bool show) async {
    await _prefs.setBool(_showInterlinearEnglishKey, show);
  }

  static const _openTabsKey = 'openTabs';

  List<String>? get savedTabsJson => _prefs.getStringList(_openTabsKey);

  Future<void> setSavedTabsJson(List<String> tabsJson) async {
    await _prefs.setStringList(_openTabsKey, tabsJson);
  }

  static const _activeTabIdKey = 'activeTabId';

  String? get savedActiveTabId => _prefs.getString(_activeTabIdKey);

  Future<void> setSavedActiveTabId(String? id) async {
    if (id == null) {
      await _prefs.remove(_activeTabIdKey);
    } else {
      await _prefs.setString(_activeTabIdKey, id);
    }
  }

  static const _recentSearchesKey = 'recentSearches';

  List<String> get recentSearches =>
      _prefs.getStringList(_recentSearchesKey) ?? [];

  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final list = recentSearches.where((q) => q != trimmed).toList();
    list.insert(0, trimmed);
    if (list.length > 10) {
      list.removeRange(10, list.length);
    }
    await _prefs.setStringList(_recentSearchesKey, list);
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(_recentSearchesKey);
  }

  static const _annotationSortOrderKey = 'annotationSortOrder';

  String? get annotationSortOrder => _prefs.getString(_annotationSortOrderKey);

  Future<void> setAnnotationSortOrder(String? sortOrder) async {
    if (sortOrder == null) {
      await _prefs.remove(_annotationSortOrderKey);
    } else {
      await _prefs.setString(_annotationSortOrderKey, sortOrder);
    }
  }

  static const _bookChooserStyleKey = 'bookChooserStyle';

  BookChooserStyle get bookChooserStyle {
    final value = _prefs.getString(_bookChooserStyleKey);
    if (value == 'list') {
      return BookChooserStyle.list;
    }
    return BookChooserStyle.grid;
  }

  Future<void> setBookChooserStyle(BookChooserStyle style) async {
    if (style == BookChooserStyle.grid) {
      await _prefs.remove(_bookChooserStyleKey);
    } else {
      await _prefs.setString(_bookChooserStyleKey, style.name);
    }
  }

  static const _chapterChooserStyleKey = 'chapterChooserStyle';

  ChapterChooserStyle get chapterChooserStyle {
    final value = _prefs.getString(_chapterChooserStyleKey);
    if (value == 'grid') {
      return ChapterChooserStyle.grid;
    }
    return ChapterChooserStyle.keypad;
  }

  Future<void> setChapterChooserStyle(ChapterChooserStyle style) async {
    if (style == ChapterChooserStyle.keypad) {
      await _prefs.remove(_chapterChooserStyleKey);
    } else {
      await _prefs.setString(_chapterChooserStyleKey, style.name);
    }
  }

  static const _verseChooserStyleKey = 'verseChooserStyle';

  VerseChooserStyle get verseChooserStyle {
    final value = _prefs.getString(_verseChooserStyleKey);
    if (value == 'grid') {
      return VerseChooserStyle.grid;
    }
    return VerseChooserStyle.sidebar;
  }

  Future<void> setVerseChooserStyle(VerseChooserStyle style) async {
    if (style == VerseChooserStyle.sidebar) {
      await _prefs.remove(_verseChooserStyleKey);
    } else {
      await _prefs.setString(_verseChooserStyleKey, style.name);
    }
  }

  bool get showVerseGrid => verseChooserStyle == VerseChooserStyle.grid;

  Future<void> setShowVerseGrid(bool show) async {
    await setVerseChooserStyle(
      show ? VerseChooserStyle.grid : VerseChooserStyle.sidebar,
    );
  }

  static const _wordsOfJesusInRedKey = 'wordsOfJesusInRed';

  bool get wordsOfJesusInRed => _prefs.getBool(_wordsOfJesusInRedKey) ?? false;

  Future<void> setWordsOfJesusInRed(bool value) async {
    if (!value) {
      await _prefs.remove(_wordsOfJesusInRedKey);
    } else {
      await _prefs.setBool(_wordsOfJesusInRedKey, true);
    }
  }

  static const _useBritishSpellingKey = 'useBritishSpelling';

  bool get useBritishSpelling =>
      _prefs.getBool(_useBritishSpellingKey) ?? false;

  Future<void> setUseBritishSpelling(bool value) async {
    if (!value) {
      await _prefs.remove(_useBritishSpellingKey);
    } else {
      await _prefs.setBool(_useBritishSpellingKey, true);
    }
  }

  static const _keepScreenAwakeKey = 'keepScreenAwake';

  /// Whether to prevent the screen from turning off while reading chapter text.
  /// Defaults to `true`.
  bool get keepScreenAwake => _prefs.getBool(_keepScreenAwakeKey) ?? true;

  Future<void> setKeepScreenAwake(bool value) async {
    if (value) {
      await _prefs.remove(_keepScreenAwakeKey);
    } else {
      await _prefs.setBool(_keepScreenAwakeKey, false);
    }
  }

  static const _audioSpeedKey = 'audioSpeed';
  static const _audioPauseBetweenVersesEnabledKey =
      'audioPauseBetweenVersesEnabled';
  static const _audioPauseBetweenVersesSecondsKey =
      'audioPauseBetweenVersesSeconds';
  static const _audioPlayModeKey = 'audioPlayMode';
  static const _lastAudioBookIdKey = 'lastAudioBookId';
  static const _lastAudioChapterKey = 'lastAudioChapter';
  static const _lastAudioPositionMsKey = 'lastAudioPositionMs';

  double get audioSpeed => _prefs.getDouble(_audioSpeedKey) ?? 1.0;
  Future<void> setAudioSpeed(double speed) =>
      _prefs.setDouble(_audioSpeedKey, speed);

  bool get audioPauseBetweenVersesEnabled =>
      _prefs.getBool(_audioPauseBetweenVersesEnabledKey) ?? false;
  Future<void> setAudioPauseBetweenVersesEnabled(bool enabled) =>
      _prefs.setBool(_audioPauseBetweenVersesEnabledKey, enabled);

  int get audioPauseBetweenVersesSeconds {
    final stored =
        _prefs.getInt(_audioPauseBetweenVersesSecondsKey) ??
        kDefaultVersePauseSeconds;
    return stored.clamp(kMinVersePauseSeconds, kMaxVersePauseSeconds);
  }

  Future<void> setAudioPauseBetweenVersesSeconds(int seconds) => _prefs.setInt(
    _audioPauseBetweenVersesSecondsKey,
    seconds.clamp(kMinVersePauseSeconds, kMaxVersePauseSeconds),
  );

  String get audioPlayMode =>
      _prefs.getString(_audioPlayModeKey) ?? 'continueOn';
  Future<void> setAudioPlayMode(String mode) =>
      _prefs.setString(_audioPlayModeKey, mode);

  int? get lastAudioBookId => _prefs.getInt(_lastAudioBookIdKey);
  int? get lastAudioChapter => _prefs.getInt(_lastAudioChapterKey);
  int? get lastAudioPositionMs => _prefs.getInt(_lastAudioPositionMsKey);

  Future<void> saveLastAudioState(
    int bookId,
    int chapter,
    int positionMs,
  ) async {
    await _prefs.setInt(_lastAudioBookIdKey, bookId);
    await _prefs.setInt(_lastAudioChapterKey, chapter);
    await _prefs.setInt(_lastAudioPositionMsKey, positionMs);
  }
}

enum BookChooserStyle {
  grid('Grid'),
  list('List');

  const BookChooserStyle(this.displayName);
  final String displayName;
}

enum ChapterChooserStyle {
  keypad('Keypad'),
  grid('Grid');

  const ChapterChooserStyle(this.displayName);
  final String displayName;
}

enum VerseChooserStyle {
  sidebar('Sidebar'),
  grid('Grid');

  const VerseChooserStyle(this.displayName);
  final String displayName;
}
