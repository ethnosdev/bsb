import 'dart:convert';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/foundation.dart';
import 'bible_tab.dart';

class TabManager extends ChangeNotifier {
  final _userSettings = getIt<UserSettings>();

  final List<BibleTab> _tabs = [];
  String? _activeTabId;
  final List<String> _history = [];
  bool _isAddingTab = false;

  List<BibleTab> get tabs => List.unmodifiable(_tabs);

  String? get activeTabId => _activeTabId;

  BibleTab? get activeTab {
    if (_activeTabId == null) return null;
    for (final tab in _tabs) {
      if (tab.id == _activeTabId) return tab;
    }
    return _tabs.isNotEmpty ? _tabs.first : null;
  }

  int get activeIndex {
    if (_activeTabId == null) return -1;
    return _tabs.indexWhere((t) => t.id == _activeTabId);
  }

  bool get isAddingTab => _isAddingTab;

  int get tabCount => _tabs.length;

  Future<void> init() async {
    final savedJsonList = _userSettings.savedTabsJson;
    if (savedJsonList != null && savedJsonList.isNotEmpty) {
      final seen = <String>{};
      for (final jsonStr in savedJsonList) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final tab = BibleTab.fromJson(map);
          final key = '${tab.bookId}_${tab.chapter}';
          if (seen.add(key)) {
            _tabs.add(tab);
          }
        } catch (e) {
          debugPrint('Error parsing saved tab: $e');
        }
      }
    }

    final savedActiveId = _userSettings.savedActiveTabId;
    if (savedActiveId != null && _tabs.any((t) => t.id == savedActiveId)) {
      _activeTabId = savedActiveId;
    } else if (_tabs.isNotEmpty) {
      _activeTabId = _tabs.first.id;
    } else {
      _activeTabId = null;
    }

    if (_activeTabId != null) {
      _history.add(_activeTabId!);
    }
    notifyListeners();
  }

  void startAddingTab() {
    _isAddingTab = true;
    notifyListeners();
  }

  void cancelAddingTab() {
    _isAddingTab = false;
    notifyListeners();
  }

  void openTab(int bookId, int chapter, [String? sectionHeading]) {
    _isAddingTab = false;

    // Check if chapter is already open
    final existingIndex = _tabs.indexWhere(
      (t) => t.bookId == bookId && t.chapter == chapter,
    );

    if (existingIndex != -1) {
      final existingTab = _tabs[existingIndex];
      if (sectionHeading != null) {
        existingTab.sectionHeading = sectionHeading;
      }
      _activeTabId = existingTab.id;
      _recordHistory(_activeTabId!);
      _saveToPrefs();
      notifyListeners();
      return;
    }

    final newTab = BibleTab(
      bookId: bookId,
      chapter: chapter,
      sectionHeading: sectionHeading,
    );
    _tabs.add(newTab);
    _activeTabId = newTab.id;
    _recordHistory(newTab.id);
    _saveToPrefs();
    notifyListeners();
  }

  void selectTab(String tabId) {
    if (!_tabs.any((t) => t.id == tabId)) return;
    _activeTabId = tabId;
    _isAddingTab = false;
    _recordHistory(tabId);
    _saveToPrefs();
    notifyListeners();
  }

  void closeTab(String tabId) {
    final index = _tabs.indexWhere((t) => t.id == tabId);
    if (index == -1) return;

    final isClosingActive = _activeTabId == tabId;
    _tabs.removeAt(index);
    _history.removeWhere((id) => id == tabId);

    if (isClosingActive) {
      if (_history.isNotEmpty) {
        // Find most recently visited remaining tab
        String? nextActiveId;
        for (int i = _history.length - 1; i >= 0; i--) {
          final id = _history[i];
          if (_tabs.any((t) => t.id == id)) {
            nextActiveId = id;
            break;
          }
        }
        _activeTabId = nextActiveId ?? (_tabs.isNotEmpty ? _tabs.last.id : null);
      } else if (_tabs.isNotEmpty) {
        final newIndex = index.clamp(0, _tabs.length - 1);
        _activeTabId = _tabs[newIndex].id;
      } else {
        _activeTabId = null;
        _isAddingTab = false;
      }
    }

    _saveToPrefs();
    notifyListeners();
  }

  void updateActiveChapter(int bookId, int chapter) {
    final current = activeTab;
    if (current == null) return;
    if (current.bookId == bookId && current.chapter == chapter) return;

    current.bookId = bookId;
    current.chapter = chapter;
    current.sectionHeading = null;

    _saveToPrefs();
    notifyListeners();
  }

  void reorderTabs(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _tabs.length) return;
    if (newIndex < 0 || newIndex > _tabs.length) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _tabs.removeAt(oldIndex);
    _tabs.insert(newIndex, item);
    _saveToPrefs();
    notifyListeners();
  }

  void _recordHistory(String tabId) {
    _history.remove(tabId);
    _history.add(tabId);
  }

  Future<void> _saveToPrefs() async {
    // Deduplicate when saving across runs
    final seen = <String>{};
    final uniqueTabsJson = <String>[];

    for (final tab in _tabs) {
      final key = '${tab.bookId}_${tab.chapter}';
      if (seen.add(key)) {
        uniqueTabsJson.add(jsonEncode(tab.toJson()));
      }
    }

    await _userSettings.setSavedTabsJson(uniqueTabsJson);
    await _userSettings.setSavedActiveTabId(_activeTabId);
  }
}
