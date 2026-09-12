import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/annotations/annotation_file_handler.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:bsb/ui/text/note_editor_sheet.dart';
import 'package:flutter/material.dart';

enum AnnotationSortOrder {
  biblical('Biblical order'),
  newest('Newest first'),
  oldest('Oldest first');

  final String label;
  const AnnotationSortOrder(this.label);

  String get sqlOrder {
    switch (this) {
      case AnnotationSortOrder.biblical:
        return 'book_id ASC, chapter ASC, start_word_id ASC';
      case AnnotationSortOrder.newest:
        return 'updated_at DESC';
      case AnnotationSortOrder.oldest:
        return 'updated_at ASC';
    }
  }
}

enum _AnnotationMenuAction {
  exportJson,
  exportMarkdown,
  importJson,
}

class HighlightsAndNotesPage extends StatefulWidget {
  final int initialTabIndex;

  const HighlightsAndNotesPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<HighlightsAndNotesPage> createState() => _HighlightsAndNotesPageState();
}

class _HighlightsAndNotesPageState extends State<HighlightsAndNotesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _annotationService = getIt<AnnotationService>();
  final _dbHelper = getIt<DatabaseHelper>();
  final _tabManager = getIt<TabManager>();
  final _userSettings = getIt<UserSettings>();

  final Map<String, String> _snippetCache = {};
  List<Highlight> _highlights = [];
  List<Note> _notes = [];
  bool _isLoading = true;
  late AnnotationSortOrder _sortOrder;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static String _snippetKey(int startWordId, int endWordId) =>
      '${startWordId}_$endWordId';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _sortOrder = _loadInitialSortOrder();
    _searchController.addListener(_onSearchChanged);
    _annotationService.changeNotifier.addListener(_loadData);
    _loadData();
  }

  AnnotationSortOrder _loadInitialSortOrder() {
    final saved = _userSettings.annotationSortOrder;
    if (saved != null) {
      for (final order in AnnotationSortOrder.values) {
        if (order.name == saved) {
          return order;
        }
      }
    }
    return AnnotationSortOrder.biblical;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _annotationService.changeNotifier.removeListener(_loadData);
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final highlights = await _annotationService.getAllHighlights(
        orderBy: _sortOrder.sqlOrder,
      );
      final notes = await _annotationService.getAllNotes(
        orderBy: _sortOrder.sqlOrder,
      );

      if (!mounted) return;

      for (final h in highlights) {
        if (h.text != null && h.text!.isNotEmpty) {
          _snippetCache[_snippetKey(h.startWordId, h.endWordId)] = h.text!;
        }
      }
      for (final n in notes) {
        if (n.passageText != null && n.passageText!.isNotEmpty) {
          _snippetCache[_snippetKey(n.startWordId, n.endWordId)] = n.passageText!;
        }
      }

      setState(() {
        _highlights = highlights;
        _notes = notes;
        _isLoading = false;
      });

      await _fetchSnippets(highlights, notes);
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchSnippets(
    List<Highlight> highlights,
    List<Note> notes,
  ) async {
    bool hasNew = false;

    for (final h in highlights) {
      final key = _snippetKey(h.startWordId, h.endWordId);
      if (!_snippetCache.containsKey(key)) {
        String? text = await _dbHelper.getTextForRange(
          bookId: h.bookId,
          chapter: h.chapter,
          startWordId: h.startWordId,
          endWordId: h.endWordId,
        );
        if (text == null || text.isEmpty) {
          final ref = Reference.fromWordId(
            packedInt: h.startWordId,
            packedIntEnd: h.endWordId,
          );
          text = await _dbHelper.getVerseText(ref.packedVerse);
        }
        if (text != null) {
          _snippetCache[key] = text;
          _annotationService.updateHighlight(h.copyWith(text: text));
          hasNew = true;
        }
      }
    }

    for (final n in notes) {
      final key = _snippetKey(n.startWordId, n.endWordId);
      if (!_snippetCache.containsKey(key)) {
        String? text = await _dbHelper.getTextForRange(
          bookId: n.bookId,
          chapter: n.chapter,
          startWordId: n.startWordId,
          endWordId: n.endWordId,
        );
        if (text == null || text.isEmpty) {
          final ref = Reference.fromWordId(
            packedInt: n.startWordId,
            packedIntEnd: n.endWordId,
          );
          text = await _dbHelper.getVerseText(ref.packedVerse);
        }
        if (text != null) {
          _snippetCache[key] = text;
          _annotationService.saveNote(
            bookId: n.bookId,
            chapter: n.chapter,
            startWordId: n.startWordId,
            endWordId: n.endWordId,
            content: n.content,
            passageText: text,
            existingNoteId: n.id,
          );
          hasNew = true;
        }
      }
    }

    if (hasNew && mounted) {
      setState(() {});
    }
  }

  void _navigateToVerse(int bookId, int chapter, int? verse) {
    _tabManager.openTab(bookId, chapter, null, verse);
    Navigator.of(context).pop();
  }

  void _confirmDeleteHighlight(Highlight highlight) async {
    final ref = Reference.fromWordId(
      packedInt: highlight.startWordId,
      packedIntEnd: highlight.endWordId,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Highlight'),
        content: Text('Delete highlight in $ref?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _annotationService.deleteHighlight(highlight.id);
    }
  }

  void _confirmDeleteNote(Note note) async {
    final ref = Reference.fromWordId(
      packedInt: note.startWordId,
      packedIntEnd: note.endWordId,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Delete note for $ref?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _annotationService.deleteNote(note.id);
    }
  }

  void _editNote(Note note) async {
    final ref = Reference.fromWordId(
      packedInt: note.startWordId,
      packedIntEnd: note.endWordId,
    );
    final passageText = note.passageText ??
        _snippetCache[_snippetKey(note.startWordId, note.endWordId)];

    await NoteEditorSheet.show(
      context: context,
      title: ref.toString(),
      passageText: passageText,
      initialContent: note.content,
      isExisting: true,
      onSave: (content) async {
        await _annotationService.saveNote(
          bookId: note.bookId,
          chapter: note.chapter,
          startWordId: note.startWordId,
          endWordId: note.endWordId,
          content: content,
          passageText: passageText,
          existingNoteId: note.id,
        );
      },
      onDelete: () async {
        await _annotationService.deleteNote(note.id);
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    if (diff.inDays == 0 && now.day == dt.day) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return 'Today at $hour:$minute $period';
    } else if (diff.inDays <= 1 && now.day - dt.day == 1) {
      return 'Yesterday';
    } else if (now.year == dt.year) {
      return '${months[dt.month - 1]} ${dt.day}';
    } else {
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    }
  }

  List<Highlight> get _filteredHighlights {
    if (_searchQuery.isEmpty) return _highlights;
    return _highlights.where((h) {
      final ref = Reference.fromWordId(
        packedInt: h.startWordId,
        packedIntEnd: h.endWordId,
      ).toString().toLowerCase();
      final snippet =
          (_snippetCache[_snippetKey(h.startWordId, h.endWordId)] ?? '')
              .toLowerCase();
      return ref.contains(_searchQuery) || snippet.contains(_searchQuery);
    }).toList();
  }

  List<Note> get _filteredNotes {
    if (_searchQuery.isEmpty) return _notes;
    return _notes.where((n) {
      final ref = Reference.fromWordId(
        packedInt: n.startWordId,
        packedIntEnd: n.endWordId,
      ).toString().toLowerCase();
      final content = n.content.toLowerCase();
      final snippet =
          (_snippetCache[_snippetKey(n.startWordId, n.endWordId)] ?? '')
              .toLowerCase();
      return ref.contains(_searchQuery) ||
          content.contains(_searchQuery) ||
          snippet.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Filter highlights & notes...',
                  border: InputBorder.none,
                ),
                style: theme.textTheme.titleMedium,
              )
            : const Text('Highlights & Notes'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Close search' : 'Search',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _isSearching = false;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          PopupMenuButton<AnnotationSortOrder>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            initialValue: _sortOrder,
            onSelected: (order) {
              setState(() => _sortOrder = order);
              _userSettings.setAnnotationSortOrder(order.name);
              _loadData();
            },
            itemBuilder: (context) => AnnotationSortOrder.values.map((order) {
              return PopupMenuItem(
                value: order,
                child: Row(
                  children: [
                    if (_sortOrder == order)
                      Icon(Icons.check, size: 18, color: colorScheme.primary)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(order.label),
                  ],
                ),
              );
            }).toList(),
          ),
          PopupMenuButton<_AnnotationMenuAction>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (action) {
              final handler = AnnotationFileHandler();
              switch (action) {
                case _AnnotationMenuAction.exportJson:
                  handler.exportJson(context);
                  break;
                case _AnnotationMenuAction.exportMarkdown:
                  handler.exportMarkdown(context);
                  break;
                case _AnnotationMenuAction.importJson:
                  handler.importJson(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _AnnotationMenuAction.exportJson,
                child: Row(
                  children: [
                    Icon(Icons.backup_outlined, size: 20),
                    SizedBox(width: 12),
                    Expanded(child: Text('Export backup (JSON)')),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: _AnnotationMenuAction.exportMarkdown,
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, size: 20),
                    SizedBox(width: 12),
                    Expanded(child: Text('Export as Markdown (.md)')),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _AnnotationMenuAction.importJson,
                child: Row(
                  children: [
                    Icon(Icons.restore_outlined, size: 20),
                    SizedBox(width: 12),
                    Expanded(child: Text('Import backup (JSON)')),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: _highlights.isNotEmpty
                  ? 'Highlights (${_highlights.length})'
                  : 'Highlights',
            ),
            Tab(
              text: _notes.isNotEmpty ? 'Notes (${_notes.length})' : 'Notes',
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildHighlightsTab(),
                  _buildNotesTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildHighlightsTab() {
    final list = _filteredHighlights;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.highlight_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No matching highlights'
                    : 'No highlights yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try a different search term.'
                    : 'Long press a verse in the Bible reader to select and highlight text.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final highlight = list[index];
        final ref = Reference.fromWordId(
          packedInt: highlight.startWordId,
          packedIntEnd: highlight.endWordId,
        );
        final snippet = _snippetCache[
            _snippetKey(highlight.startWordId, highlight.endWordId)];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _navigateToVerse(
              highlight.bookId,
              highlight.chapter,
              ref.verse,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Color swatch bar
                  Container(
                    width: 6,
                    height: 52,
                    decoration: BoxDecoration(
                      color: highlight.color.previewColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ref.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              tooltip: 'Delete highlight',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _confirmDeleteHighlight(highlight),
                            ),
                          ],
                        ),
                        if (snippet != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            snippet,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(highlight.updatedAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesTab() {
    final list = _filteredNotes;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_note,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty ? 'No matching notes' : 'No notes yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try a different search term.'
                    : 'Select a verse and tap the Note option to write notes.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final note = list[index];
        final ref = Reference.fromWordId(
          packedInt: note.startWordId,
          packedIntEnd: note.endWordId,
        );
        final snippet =
            _snippetCache[_snippetKey(note.startWordId, note.endWordId)];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _navigateToVerse(
              note.bookId,
              note.chapter,
              ref.verse,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.edit_note,
                            size: 22,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ref.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: 'Edit note',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _editNote(note),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            tooltip: 'Delete note',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _confirmDeleteNote(note),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Note content
                  Text(
                    note.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (snippet != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(note.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
