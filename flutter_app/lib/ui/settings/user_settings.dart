import 'package:bsb/core/theme.dart';
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

  static const _customThemeLightKey = 'customThemeLight';

  CustomThemeConfig get customThemeLight {
    final raw = _prefs.getString(_customThemeLightKey);
    if (raw == null) return CustomThemeConfig.defaultLight();
    return CustomThemeConfig.fromJsonString(raw, isDarkFallback: false);
  }

  Future<void> setCustomThemeLight(CustomThemeConfig config) async {
    await _prefs.setString(_customThemeLightKey, config.toJsonString());
  }

  static const _customThemeDarkKey = 'customThemeDark';

  CustomThemeConfig get customThemeDark {
    final raw = _prefs.getString(_customThemeDarkKey);
    if (raw == null) return CustomThemeConfig.defaultDark();
    return CustomThemeConfig.fromJsonString(raw, isDarkFallback: true);
  }

  Future<void> setCustomThemeDark(CustomThemeConfig config) async {
    await _prefs.setString(_customThemeDarkKey, config.toJsonString());
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
    await _prefs.setInt(_lastSelectedCustomColorKey, color.toARGB32());
  }

  static const _lastSelectedCustomColorKey = 'lastSelectedCustomColor';

  Color? get lastSelectedCustomColor {
    final val = _prefs.getInt(_lastSelectedCustomColorKey);
    if (val != null) return Color(val);
    if (customColorHistory.isNotEmpty) return customColorHistory.first;
    return null;
  }

  Future<void> setLastSelectedCustomColor(Color color) async {
    await _prefs.setInt(_lastSelectedCustomColorKey, color.toARGB32());
  }

  bool get hasSavedCustomTheme =>
      _prefs.containsKey(_customThemeLightKey) ||
      _prefs.containsKey(_customThemeDarkKey);

  Future<void> clearCustomColorHistory() async {
    await _prefs.remove(_customColorHistoryKey);
    await _prefs.remove(_lastSelectedCustomColorKey);
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

