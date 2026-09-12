import 'dart:async';
import 'package:bsb/infrastructure/search/bible_search_service.dart';
import 'package:bsb/infrastructure/search/search_models.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/foundation.dart';

class SearchManager {
  SearchManager({
    this.currentBookId,
    BibleSearchService? searchService,
    UserSettings? userSettings,
  })  : _searchService = searchService ?? getIt<BibleSearchService>(),
        _userSettings = userSettings ?? getIt<UserSettings>();

  final BibleSearchService _searchService;
  final UserSettings _userSettings;
  int? currentBookId;

  final isLoadingNotifier = ValueNotifier<bool>(false);
  final resultsNotifier = ValueNotifier<List<SearchResult>>([]);
  final recentSearchesNotifier = ValueNotifier<List<String>>([]);
  final scopeNotifier = ValueNotifier<SearchScope>(SearchScope.all);
  final isExactNotifier = ValueNotifier<bool>(false);

  String _currentQuery = '';
  String get currentQuery => _currentQuery;

  double scrollOffset = 0.0;
  Timer? _debounceTimer;

  void init() {
    recentSearchesNotifier.value = _userSettings.recentSearches;
  }

  void setScope(SearchScope scope) {
    if (scopeNotifier.value == scope) return;
    scopeNotifier.value = scope;
    scrollOffset = 0.0;
    if (_currentQuery.trim().length >= 2) {
      _executeSearch(_currentQuery);
    }
  }

  void setExactMatch(bool isExact) {
    if (isExactNotifier.value == isExact) return;
    isExactNotifier.value = isExact;
    scrollOffset = 0.0;
    if (_currentQuery.trim().length >= 2) {
      _executeSearch(_currentQuery.trim());
    }
  }

  void onQueryChanged(String query) {
    if (_currentQuery == query) return;
    _currentQuery = query;
    _debounceTimer?.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }

    scrollOffset = 0.0;

    // Debounce text search by 250ms
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (trimmed.length >= 2) {
        _executeSearch(trimmed);
      } else {
        resultsNotifier.value = [];
        isLoadingNotifier.value = false;
      }
    });
  }

  Future<void> _executeSearch(String query) async {
    isLoadingNotifier.value = true;
    final results = await _searchService.searchVerses(
      query: query,
      scope: scopeNotifier.value,
      specificBookId: currentBookId,
      isExact: isExactNotifier.value,
      // No limit: return all matching results
    );

    // Only update if query hasn't changed while searching
    if (_currentQuery.trim() == query.trim()) {
      resultsNotifier.value = results;
      isLoadingNotifier.value = false;
    }
  }

  void clearSearch() {
    _currentQuery = '';
    scrollOffset = 0.0;
    isLoadingNotifier.value = false;
    resultsNotifier.value = [];
  }

  Future<void> recordSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.length >= 2) {
      await _userSettings.addRecentSearch(trimmed);
      recentSearchesNotifier.value = _userSettings.recentSearches;
    }
  }

  Future<void> clearRecentSearches() async {
    await _userSettings.clearRecentSearches();
    recentSearchesNotifier.value = [];
  }

  void dispose() {
    _debounceTimer?.cancel();
    isLoadingNotifier.dispose();
    resultsNotifier.dispose();
    recentSearchesNotifier.dispose();
    scopeNotifier.dispose();
    isExactNotifier.dispose();
  }
}
