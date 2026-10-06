import 'dart:async';
import 'package:bsb/infrastructure/search/bible_search_service.dart';
import 'package:bsb/infrastructure/search/search_models.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/foundation.dart';

class SearchManager {
  SearchManager({
    BibleSearchService? searchService,
    UserSettings? userSettings,
  })  : _searchService = searchService ?? getIt<BibleSearchService>(),
        _userSettings = userSettings ?? getIt<UserSettings>();

  final BibleSearchService _searchService;
  final UserSettings _userSettings;

  final isLoadingNotifier = ValueNotifier<bool>(false);
  final resultsNotifier = ValueNotifier<List<SearchResult>>([]);
  final recentSearchesNotifier = ValueNotifier<List<String>>([]);
  final isExactNotifier = ValueNotifier<bool>(false);
  final matchingBooksNotifier = ValueNotifier<List<BookMatch>>([]);
  final selectedBookIdNotifier = ValueNotifier<int?>(null);

  List<SearchResult> _allResults = [];
  String _currentQuery = '';
  String get currentQuery => _currentQuery;

  double scrollOffset = 0.0;
  double bookFilterScrollOffset = 0.0;
  Timer? _debounceTimer;

  void init() {
    recentSearchesNotifier.value = _userSettings.recentSearches;
  }

  void selectBook(int? bookId) {
    if (selectedBookIdNotifier.value == bookId) return;
    selectedBookIdNotifier.value = bookId;
    scrollOffset = 0.0;
    _updateFilteredResults();
  }

  void _updateFilteredResults() {
    final selectedId = selectedBookIdNotifier.value;
    if (selectedId == null) {
      resultsNotifier.value = _allResults;
    } else {
      resultsNotifier.value = _allResults
          .where((r) => r.reference.bookId == selectedId)
          .toList();
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
    bookFilterScrollOffset = 0.0;

    // Debounce text search by 250ms
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (trimmed.length >= 2) {
        _executeSearch(trimmed);
      } else {
        _allResults = [];
        resultsNotifier.value = [];
        matchingBooksNotifier.value = [];
        selectedBookIdNotifier.value = null;
        isLoadingNotifier.value = false;
      }
    });
  }

  Future<void> _executeSearch(String query) async {
    isLoadingNotifier.value = true;
    final results = await _searchService.searchVerses(
      query: query,
      isExact: isExactNotifier.value,
      // No limit: return all matching results across the Bible
    );

    // Only update if query hasn't changed while searching
    if (_currentQuery.trim() == query.trim()) {
      _allResults = results;

      final counts = <int, int>{};
      for (final res in results) {
        counts[res.reference.bookId] = (counts[res.reference.bookId] ?? 0) + 1;
      }

      final books = counts.entries.map((e) => BookMatch(
        bookId: e.key,
        bookName: bookIdToBookNameMap[e.key] ?? 'Book ${e.key}',
        count: e.value,
      )).toList()..sort((a, b) => a.bookId.compareTo(b.bookId));

      matchingBooksNotifier.value = books;

      if (selectedBookIdNotifier.value != null &&
          !counts.containsKey(selectedBookIdNotifier.value)) {
        selectedBookIdNotifier.value = null;
      }

      _updateFilteredResults();
      isLoadingNotifier.value = false;
    }
  }

  void clearSearch() {
    _currentQuery = '';
    _allResults = [];
    scrollOffset = 0.0;
    bookFilterScrollOffset = 0.0;
    isLoadingNotifier.value = false;
    resultsNotifier.value = [];
    matchingBooksNotifier.value = [];
    selectedBookIdNotifier.value = null;
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
    isExactNotifier.dispose();
    matchingBooksNotifier.dispose();
    selectedBookIdNotifier.dispose();
  }
}
