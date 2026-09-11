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
}

enum BookChooserStyle {
  grid('Grid'),
  list('List');

  const BookChooserStyle(this.displayName);
  final String displayName;
}

