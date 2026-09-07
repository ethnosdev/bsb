import 'package:bsb/infrastructure/search/search_models.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/search/search_manager.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    this.currentBookId,
  });

  final int? currentBookId;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final SearchManager _manager;
  late final TextEditingController _textController;
  late final ScrollController _scrollController;
  final _tabManager = getIt<TabManager>();
  final _hasTextNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _manager = getIt<SearchManager>();
    _manager.currentBookId = widget.currentBookId;
    _manager.init();

    _textController = TextEditingController(text: _manager.currentQuery);
    _hasTextNotifier.value = _manager.currentQuery.isNotEmpty;
    if (_manager.currentQuery.isNotEmpty) {
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _manager.currentQuery.length),
      );
    }

    _scrollController = ScrollController(
      initialScrollOffset: _manager.scrollOffset,
    );
    _scrollController.addListener(_onScroll);
    _textController.addListener(_onTextChanged);
  }

  void _onScroll() {
    _manager.scrollOffset = _scrollController.offset;
  }

  void _onTextChanged() {
    final text = _textController.text;
    if (_manager.currentQuery == text) return;
    _hasTextNotifier.value = text.isNotEmpty;
    _manager.onQueryChanged(text);
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      _scrollController.jumpTo(0.0);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _hasTextNotifier.dispose();
    // Note: Do NOT dispose _manager as it is an application-level singleton
    // preserving search session state across page navigations.
    super.dispose();
  }

  void _navigateToVerse(int bookId, int chapter, int? verse) {
    if (_scrollController.hasClients) {
      _manager.scrollOffset = _scrollController.offset;
    }
    _manager.recordSearch(_textController.text);
    _tabManager.openTab(bookId, chapter, null, verse);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (_scrollController.hasClients) {
              _manager.scrollOffset = _scrollController.offset;
            }
            Navigator.of(context).pop();
          },
        ),
        title: TextField(
          controller: _textController,
          autofocus: _manager.currentQuery.isEmpty,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search verses or e.g. John 3:16',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withAlpha(120),
            ),
          ),
          onSubmitted: (query) => _manager.recordSearch(query),
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _hasTextNotifier,
            builder: (context, hasText, child) {
              if (!hasText) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear',
                onPressed: () {
                  _textController.clear();
                  _manager.clearSearch();
                },
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              _buildScopeFilterBar(colorScheme),
              ValueListenableBuilder<bool>(
                valueListenable: _manager.isLoadingNotifier,
                builder: (context, isLoading, child) {
                  return isLoading
                      ? const LinearProgressIndicator(minHeight: 2)
                      : const SizedBox(height: 2);
                },
              ),
            ],
          ),
        ),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _hasTextNotifier,
        builder: (context, hasText, child) {
          if (!hasText) {
            return _buildEmptyQueryView();
          }
          return _buildResultsView();
        },
      ),
    );
  }

  Widget _buildScopeFilterBar(ColorScheme colorScheme) {
    return ValueListenableBuilder<SearchScope>(
      valueListenable: _manager.scopeNotifier,
      builder: (context, currentScope, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              _buildFilterChip('All', SearchScope.all, currentScope),
              const SizedBox(width: 8),
              _buildFilterChip('Old Testament', SearchScope.ot, currentScope),
              const SizedBox(width: 8),
              _buildFilterChip('New Testament', SearchScope.nt, currentScope),
              if (widget.currentBookId != null) ...[
                const SizedBox(width: 8),
                _buildFilterChip(
                  bookIdToFullNameMap[widget.currentBookId] ?? 'Current Book',
                  SearchScope.book,
                  currentScope,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    SearchScope scope,
    SearchScope activeScope,
  ) {
    final isSelected = scope == activeScope;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        _manager.setScope(scope);
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0.0);
        }
      },
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyQueryView() {
    return ValueListenableBuilder<List<String>>(
      valueListenable: _manager.recentSearchesNotifier,
      builder: (context, recents, child) {
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (recents.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: _manager.clearRecentSearches,
                    child: const Text('Clear all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: recents.map((query) {
                  return ActionChip(
                    avatar: const Icon(Icons.history, size: 16),
                    label: Text(query),
                    onPressed: () {
                      _textController.text = query;
                      _textController.selection = TextSelection.fromPosition(
                        TextPosition(offset: query.length),
                      );
                    },
                  );
                }).toList(),
              ),
              const Divider(height: 32),
            ],
            Text(
              'Search Tips',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildTipTile(
              icon: Icons.search,
              title: 'Keywords',
              description: 'Search for words like "grace", "faith", or "Jerusalem".',
            ),
            _buildTipTile(
              icon: Icons.format_quote,
              title: 'Exact Phrases',
              description: 'Use quotes for exact phrases like "in the beginning".',
            ),
            _buildTipTile(
              icon: Icons.menu_book,
              title: 'Direct References',
              description: 'Jump directly using "John 3:16", "Jn 3", "Gen 1", or "Ps 23".',
            ),
          ],
        );
      },
    );
  }

  Widget _buildTipTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return ValueListenableBuilder<ParsedReference?>(
      valueListenable: _manager.referenceMatchNotifier,
      builder: (context, refMatch, child) {
        return ValueListenableBuilder<List<SearchResult>>(
          valueListenable: _manager.resultsNotifier,
          builder: (context, results, child) {
            return ValueListenableBuilder<bool>(
              valueListenable: _manager.isLoadingNotifier,
              builder: (context, isLoading, child) {
                final hasRefMatch = refMatch != null;
                final hasResults = results.isNotEmpty;

                if (!isLoading && !hasRefMatch && !hasResults) {
                  return _buildNoResultsView();
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: (hasRefMatch ? 1 : 0) +
                      (hasResults ? results.length + 1 : 0),
                  itemBuilder: (context, index) {
                    // Item 0 is direct reference match card if available
                    if (hasRefMatch && index == 0) {
                      return _buildDirectReferenceCard(refMatch);
                    }

                    final resultIndex = hasRefMatch ? index - 1 : index;

                    // Results count header
                    if (resultIndex == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          '${results.length} ${results.length == 1 ? 'verse' : 'verses'} found',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      );
                    }

                    final item = results[resultIndex - 1];
                    return _buildSearchResultTile(item);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDirectReferenceCard(ParsedReference refMatch) {
    final bookName = bookIdToFullNameMap[refMatch.bookId] ?? '';
    final refString = refMatch.verse != null
        ? '$bookName ${refMatch.chapter}:${refMatch.verse}'
        : '$bookName ${refMatch.chapter}';

    return ValueListenableBuilder<String?>(
      valueListenable: _manager.referencePreviewNotifier,
      builder: (context, preview, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Card(
            elevation: 1.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary.withAlpha(60),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: () => _navigateToVerse(
                refMatch.bookId,
                refMatch.chapter,
                refMatch.verse,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.bookmark_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Go to $refString',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.arrow_forward,
                                size: 16,
                              ),
                            ],
                          ),
                          if (preview != null && preview.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withAlpha(180),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResultTile(SearchResult item) {
    final ref = item.reference;
    final bookName = bookIdToFullNameMap[ref.bookId] ?? '';
    final refTitle = '$bookName ${ref.chapter}:${ref.verse}';

    return ListTile(
      title: Text(
        refTitle,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text.rich(
          _buildHighlightedTextSpan(item.text, item.matchSpans),
          style: const TextStyle(fontSize: 14, height: 1.35),
        ),
      ),
      onTap: () => _navigateToVerse(ref.bookId, ref.chapter, ref.verse),
    );
  }

  TextSpan _buildHighlightedTextSpan(
    String text,
    List<(int, int)> spans,
  ) {
    if (spans.isEmpty) {
      return TextSpan(text: text);
    }

    final children = <TextSpan>[];
    int currentIndex = 0;
    final highlightColor = Theme.of(context).colorScheme.primary;

    for (final (start, end) in spans) {
      if (start > currentIndex && start <= text.length) {
        children.add(TextSpan(text: text.substring(currentIndex, start)));
      }
      if (start < text.length) {
        final actualEnd = end.clamp(0, text.length);
        if (actualEnd > start) {
          children.add(
            TextSpan(
              text: text.substring(start, actualEnd),
              style: TextStyle(
                color: highlightColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          currentIndex = actualEnd;
        }
      }
    }

    if (currentIndex < text.length) {
      children.add(TextSpan(text: text.substring(currentIndex)));
    }

    return TextSpan(children: children);
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 48,
              color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              'No verses found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try checking your spelling, using different keywords, or selecting a broader search scope.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
