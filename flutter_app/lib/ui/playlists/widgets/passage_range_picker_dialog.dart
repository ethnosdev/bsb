import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/verse_counts.dart';
import 'package:bsb/ui/home/book_chooser.dart';
import 'package:bsb/ui/home/chapter_chooser.dart';
import 'package:bsb/ui/home/list_book_chooser.dart';
import 'package:bsb/ui/playlists/widgets/passage_trim_dialog.dart';
import 'package:bsb/ui/playlists/widgets/passage_trim_helper.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

class PassageRangePickerResult {
  final Reference reference;
  final int? startWordId;
  final int? endWordId;

  const PassageRangePickerResult({
    required this.reference,
    this.startWordId,
    this.endWordId,
  });

  bool get isTrimmed => startWordId != null || endWordId != null;
}

class PassageRangePickerDialog extends StatefulWidget {
  final Reference? initialReference;
  final int? initialStartWordId;
  final int? initialEndWordId;
  final DatabaseHelper? dbHelper;
  final VoidCallback? onDelete;

  const PassageRangePickerDialog({
    super.key,
    this.initialReference,
    this.initialStartWordId,
    this.initialEndWordId,
    this.dbHelper,
    this.onDelete,
  });

  static Future<PassageRangePickerResult?> show(
    BuildContext context, {
    Reference? initialReference,
    int? initialStartWordId,
    int? initialEndWordId,
    DatabaseHelper? dbHelper,
    VoidCallback? onDelete,
  }) {
    return showDialog<PassageRangePickerResult>(
      context: context,
      builder: (ctx) => PassageRangePickerDialog(
        initialReference: initialReference,
        initialStartWordId: initialStartWordId,
        initialEndWordId: initialEndWordId,
        dbHelper: dbHelper,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<PassageRangePickerDialog> createState() => _PassageRangePickerDialogState();
}

class _PassageRangePickerDialogState extends State<PassageRangePickerDialog> {
  int? _bookId;
  int? _startChapter;
  int? _startVerse;
  int? _endChapter;
  int? _endVerse;
  int? _startWordId;
  int? _endWordId;
  List<UsfmLine> _rawLines = [];

  String? _previewText;
  bool _isLoadingPreview = false;

  late final DatabaseHelper _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.dbHelper ??
        (getIt.isRegistered<DatabaseHelper>()
            ? getIt<DatabaseHelper>()
            : DatabaseHelper());

    final init = widget.initialReference;
    _startWordId = widget.initialStartWordId;
    _endWordId = widget.initialEndWordId;
    if (init != null) {
      _bookId = init.bookId;
      _startChapter = init.chapter;
      _startVerse = init.verse ?? 1;
      _endChapter = init.endChapter ?? init.chapter;
      _endVerse = init.endVerse ?? init.verse ?? 1;
      _loadPreview();
    }
  }

  int _compareReference(int ch1, int vs1, int ch2, int vs2) {
    if (ch1 != ch2) {
      return ch1.compareTo(ch2);
    }
    return vs1.compareTo(vs2);
  }

  Reference? _buildCurrentReference() {
    if (_bookId == null || _startChapter == null || _startVerse == null) {
      return null;
    }

    final endChapter = _endChapter ?? _startChapter!;
    final endVerse = _endVerse ?? _startVerse!;

    final isSameVerse = _startChapter == endChapter && _startVerse == endVerse;
    if (isSameVerse) {
      return Reference(
        bookId: _bookId!,
        chapter: _startChapter!,
        verse: _startVerse!,
      );
    }

    final isCrossChapter = endChapter != _startChapter;
    return Reference(
      bookId: _bookId!,
      chapter: _startChapter!,
      verse: _startVerse!,
      endChapter: isCrossChapter ? endChapter : null,
      endVerse: endVerse,
    );
  }

  void _loadPreview() async {
    final ref = _buildCurrentReference();
    if (ref == null) {
      if (mounted) {
        setState(() {
          _rawLines = [];
          _previewText = null;
          _isLoadingPreview = false;
        });
      }
      return;
    }

    setState(() => _isLoadingPreview = true);
    try {
      final lines = await _dbHelper.getRange(ref);
      if (mounted) {
        _rawLines = lines;
        final trimmed = trimPassageLines(lines, _startWordId, _endWordId);
        final text = cleanPassagePreview(trimmed);
        setState(() {
          _previewText = text.isEmpty ? null : text;
          _isLoadingPreview = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingPreview = false);
      }
    }
  }

  Future<void> _openTrimDialog() async {
    final ref = _buildCurrentReference();
    if (ref == null) return;

    List<UsfmLine> lines = _rawLines;
    if (lines.isEmpty) {
      lines = await _dbHelper.getRange(ref);
      _rawLines = lines;
    }
    if (lines.isEmpty || !mounted) return;

    final result = await PassageTrimDialog.show(
      context: context,
      reference: ref,
      lines: lines,
      initialStartWordId: _startWordId,
      initialEndWordId: _endWordId,
    );

    if (result != null && mounted) {
      setState(() {
        _startWordId = result.startWordId;
        _endWordId = result.endWordId;
      });
      _loadPreview();
    }
  }

  Future<void> _openBookPicker() async {
    final userSettings =
        getIt.isRegistered<UserSettings>() ? getIt<UserSettings>() : null;
    final appState = getIt.isRegistered<AppState>() ? getIt<AppState>() : null;
    final bookStyle = appState?.bookChooserStyleNotifier.value ??
        userSettings?.bookChooserStyle ??
        BookChooserStyle.grid;

    final chosenBookId = await showDialog<int>(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
            child: bookStyle == BookChooserStyle.list
                ? ListBookChooser(
                    key: const ValueKey('popup_list_book_chooser'),
                    onBookSelected: (bookId) {
                      Navigator.of(dialogCtx).pop(bookId);
                    },
                    onSelected: (bookId, chapter, [section]) {
                      Navigator.of(dialogCtx).pop(bookId);
                    },
                  )
                : BookChooser(
                    key: const ValueKey('popup_grid_book_chooser'),
                    onBookSelected: (bookId) {
                      Navigator.of(dialogCtx).pop(bookId);
                    },
                    onSelected: (bookId, chapter, [section]) {
                      Navigator.of(dialogCtx).pop(bookId);
                    },
                  ),
          ),
        );
      },
    );

    if (chosenBookId != null && mounted) {
      setState(() {
        if (_bookId != chosenBookId) {
          _bookId = chosenBookId;
          // As soon as the book is selected, start chapter defaults to 1 and start verse defaults to 1.
          // End chapter and verse match start chapter and verse on first setting.
          _startChapter = 1;
          _startVerse = 1;
          _endChapter = 1;
          _endVerse = 1;
          _startWordId = null;
          _endWordId = null;
        }
      });
      _loadPreview();
    }
  }

  Future<void> _openChapterPicker({required bool isStart}) async {
    if (_bookId == null) return;

    final userSettings =
        getIt.isRegistered<UserSettings>() ? getIt<UserSettings>() : null;
    final appState = getIt.isRegistered<AppState>() ? getIt<AppState>() : null;
    final chapterStyle = appState?.chapterChooserStyleNotifier.value ??
        userSettings?.chapterChooserStyle ??
        ChapterChooserStyle.keypad;

    final maxChapters = bookIdToChapterCountMap[_bookId!] ?? 1;
    final bookName = bookIdToBookNameMap[_bookId!] ?? '';
    final initialChapter = isStart ? _startChapter : _endChapter;

    final chosenChapter = await showDialog<int>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogCtx) {
        return chapterStyle == ChapterChooserStyle.grid
            ? GridChapterChooser(
                bookId: _bookId,
                bookName: bookName,
                chapterCount: maxChapters,
                onChapterSelected: (chapter) {
                  Navigator.of(dialogCtx).pop(chapter);
                },
              )
            : NumericKeypadChooser(
                title: bookName,
                label: isStart ? 'Start Chapter' : 'End Chapter',
                maxCount: maxChapters,
                initialValue: initialChapter,
                onSelected: (chapter) {
                  Navigator.of(dialogCtx).pop(chapter);
                },
                onDismiss: () {
                  Navigator.of(dialogCtx).pop();
                },
              );
      },
    );

    if (chosenChapter != null && mounted) {
      setState(() {
        _startWordId = null;
        _endWordId = null;
        if (isStart) {
          _startChapter = chosenChapter;
          final maxVerses = getVerseCountForBookAndChapter(_bookId!, chosenChapter);
          if (_startVerse != null && _startVerse! > maxVerses) {
            _startVerse = 1;
          }
          _startVerse ??= 1;
          _endChapter ??= _startChapter;
          _endVerse ??= _startVerse;

          // If start range is changed to be greater than end range:
          // make end range match start range
          if (_compareReference(_startChapter!, _startVerse!, _endChapter!, _endVerse!) > 0) {
            _endChapter = _startChapter;
            _endVerse = _startVerse;
          }
        } else {
          _endChapter = chosenChapter;
          final maxVerses = getVerseCountForBookAndChapter(_bookId!, chosenChapter);
          if (_endVerse != null && _endVerse! > maxVerses) {
            _endVerse = maxVerses;
          }
          _endVerse ??= 1;
          _startChapter ??= _endChapter;
          _startVerse ??= _endVerse;

          // If end range is changed to be before current start range:
          // make start range match end range
          if (_compareReference(_endChapter!, _endVerse!, _startChapter!, _startVerse!) < 0) {
            _startChapter = _endChapter;
            _startVerse = _endVerse;
          }
        }
      });
      _loadPreview();
    }
  }

  Future<void> _openVersePicker({required bool isStart}) async {
    if (_bookId == null) return;
    final targetChapter = isStart ? _startChapter : _endChapter;
    if (targetChapter == null) return;

    final userSettings =
        getIt.isRegistered<UserSettings>() ? getIt<UserSettings>() : null;
    final appState = getIt.isRegistered<AppState>() ? getIt<AppState>() : null;
    final verseStyle = appState?.verseChooserStyleNotifier.value ??
        userSettings?.verseChooserStyle ??
        VerseChooserStyle.sidebar;

    final maxVerses = getVerseCountForBookAndChapter(_bookId!, targetChapter);
    final bookName = bookIdToBookNameMap[_bookId!] ?? '';

    final chosenVerse = await showDialog<int>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogCtx) {
        return verseStyle == VerseChooserStyle.grid
            ? GridVerseChooser(
                bookId: _bookId,
                bookName: bookName,
                chapter: targetChapter,
                verseCount: maxVerses,
                onVerseSelected: (verse) {
                  Navigator.of(dialogCtx).pop(verse);
                },
              )
            : KeypadVerseChooser(
                bookId: _bookId,
                bookName: bookName,
                chapter: targetChapter,
                verseCount: maxVerses,
                onVerseSelected: (verse) {
                  Navigator.of(dialogCtx).pop(verse);
                },
                onBackPressed: () {
                  Navigator.of(dialogCtx).pop();
                },
              );
      },
    );

    if (chosenVerse != null && mounted) {
      setState(() {
        _startWordId = null;
        _endWordId = null;
        if (isStart) {
          _startVerse = chosenVerse;
          _endChapter ??= _startChapter;
          _endVerse ??= _startVerse;

          // If start range is changed to be greater than end range:
          // make end range match start range
          if (_compareReference(_startChapter!, _startVerse!, _endChapter!, _endVerse!) > 0) {
            _endChapter = _startChapter;
            _endVerse = _startVerse;
          }
        } else {
          _endVerse = chosenVerse;
          _startChapter ??= _endChapter;
          _startVerse ??= _endVerse;

          // If end range is changed to be before current start range:
          // make start range match end range
          if (_compareReference(_endChapter!, _endVerse!, _startChapter!, _startVerse!) < 0) {
            _startChapter = _endChapter;
            _startVerse = _endVerse;
          }
        }
      });
      _loadPreview();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Passage'),
        content: const Text('Are you sure you want to remove this passage from the playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.onDelete?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentRef = _buildCurrentReference();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Title, Delete (if edit mode). No close X button.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.initialReference == null
                          ? 'Select Scripture Passage'
                          : 'Edit Scripture Passage',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete Passage',
                      onPressed: _confirmDelete,
                    ),
                ],
              ),
              const Divider(height: 16),
              const SizedBox(height: 12),

              // Verse Range Selector Row
              _buildSelectorRow(theme),
              const SizedBox(height: 16),

              // Preview Area
              Flexible(
                child: _buildPreviewArea(theme, currentRef),
              ),
              const SizedBox(height: 16),

              // Action Buttons (Cancel / Add to Playlist)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('add_to_playlist_button'),
                    onPressed: currentRef == null
                        ? null
                        : () {
                            final adjustedRef = computeAdjustedReference(
                              originalReference: currentRef,
                              startWordId: _startWordId,
                              endWordId: _endWordId,
                            );
                            Navigator.of(context).pop(
                              PassageRangePickerResult(
                                reference: adjustedRef,
                                startWordId: _startWordId,
                                endWordId: _endWordId,
                              ),
                            );
                          },
                    child: Text(
                      widget.initialReference == null
                          ? 'Add to Playlist'
                          : 'Save Reference',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorRow(ThemeData theme) {
    final bookLabel = _bookId == null ? 'Book' : (bookIdToBookNameMap[_bookId] ?? 'Book');
    final startChLabel = _startChapter == null ? 'Ch' : '$_startChapter';
    final startVsLabel = _startVerse == null ? 'Vs' : '$_startVerse';
    final endChLabel = _endChapter == null ? 'Ch' : '$_endChapter';
    final endVsLabel = _endVerse == null ? 'Vs' : '$_endVerse';

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Button that says "Book"
            _buildBtn(
              key: const ValueKey('passage_book_button'),
              label: bookLabel,
              onPressed: _openBookPicker,
              isWide: true,
            ),
            // 2. followed by a space
            const SizedBox(width: 8),

            // 3. button for the start chapter
            _buildBtn(
              key: const ValueKey('passage_start_chapter_button'),
              label: startChLabel,
              onPressed: _bookId == null ? null : () => _openChapterPicker(isStart: true),
            ),
            // 4. followed by a colon
            _buildColon(theme),

            // 5. button for the start verse
            _buildBtn(
              key: const ValueKey('passage_start_verse_button'),
              label: startVsLabel,
              onPressed: (_bookId == null || _startChapter == null)
                  ? null
                  : () => _openVersePicker(isStart: true),
            ),

            // Separator between start and end
            _buildDash(theme),

            // 6. button for the end chapter
            _buildBtn(
              key: const ValueKey('passage_end_chapter_button'),
              label: endChLabel,
              onPressed: (_bookId == null || _startChapter == null || _startVerse == null)
                  ? null
                  : () => _openChapterPicker(isStart: false),
            ),
            // 7. followed by a colon
            _buildColon(theme),

            // 8. button for the end verse
            _buildBtn(
              key: const ValueKey('passage_end_verse_button'),
              label: endVsLabel,
              onPressed: (_bookId == null || _startChapter == null || _startVerse == null)
                  ? null
                  : () => _openVersePicker(isStart: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn({
    required Key key,
    required String label,
    required VoidCallback? onPressed,
    bool isWide = false,
  }) {
    return OutlinedButton(
      key: key,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: isWide ? 14 : 10, vertical: 8),
        minimumSize: Size(isWide ? 76 : 44, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildColon(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDash(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '–',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildPreviewArea(ThemeData theme, Reference? currentRef) {
    if (currentRef == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a book to begin',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        computeAdjustedReference(
                          originalReference: currentRef,
                          startWordId: _startWordId,
                          endWordId: _endWordId,
                        ).toString(),
                        key: const ValueKey('preview_ref_header'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    if (_startWordId != null || _endWordId != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Trimmed',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              OutlinedButton.icon(
                key: const ValueKey('passage_trim_button'),
                icon: const Icon(Icons.content_cut, size: 16),
                label: const Text('Trim'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _isLoadingPreview ? null : _openTrimDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingPreview)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_previewText != null)
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  _previewText!,
                  key: const ValueKey('preview_text'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Strips USFM markup, footnotes, and Words of Jesus tags for display in preview snippets.
String cleanPassagePreview(List<UsfmLine> lines) {
  const headingFormats = {
    ParagraphFormat.s1,
    ParagraphFormat.s2,
    ParagraphFormat.ms,
    ParagraphFormat.ms1,
    ParagraphFormat.ms2,
    ParagraphFormat.mr,
    ParagraphFormat.qa,
    ParagraphFormat.sp,
    ParagraphFormat.r,
    ParagraphFormat.b,
  };

  return lines
      .where((l) => !headingFormats.contains(l.format))
      .map((l) => cleanVerseText(l.text))
      .where((t) => t.isNotEmpty)
      .join(' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
