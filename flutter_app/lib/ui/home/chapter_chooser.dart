import 'dart:math';

import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/section_heading.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/verse_counts.dart';
import 'package:bsb/ui/home/section_headings_dialog.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

export 'package:bsb/ui/settings/user_settings.dart' show ChapterChooserStyle;

/// Generic chapter chooser widget that displays either a keypad or a grid
/// of chapter numbers based on user settings or an explicit [style] override.
///
/// If [showVerseGrid] (or the corresponding user setting) is enabled, selecting
/// a chapter transitions to a grid of verses for that chapter.
class ChapterChooser extends StatefulWidget {
  const ChapterChooser({
    super.key,
    this.bookName,
    this.bookId,
    required this.chapterCount,
    this.initialChapter,
    this.style,
    this.showVerseGrid,
    this.headingsLoader,
    this.verseCountLoader,
    this.onChapterSelected,
    this.onSectionSelected,
    this.onVerseSelected,
  });

  /// Optional book name to display at the top of the popup.
  /// If not provided and [bookId] is provided, it will be looked up using [bookId].
  final String? bookName;

  /// Optional book ID (1 to 66) used to look up the book name if [bookName] is omitted.
  final int? bookId;

  /// Total number of chapters in the selected book.
  final int chapterCount;

  /// Optional initial chapter to display directly in the verse grid if [showVerseGrid] is enabled.
  final int? initialChapter;

  /// Optional style override. If null, the style configured in settings is used.
  final ChapterChooserStyle? style;

  /// Optional override for showing the verse grid after chapter selection.
  /// If null, the setting configured in [UserSettings.showVerseGrid] is used.
  final bool? showVerseGrid;

  /// Optional custom loader for section headings (used primarily in tests).
  final Future<List<SectionHeading>> Function(int bookId)? headingsLoader;

  /// Optional custom loader for verse count (used primarily in tests).
  final int Function(int bookId, int chapter)? verseCountLoader;

  /// Callback when a chapter is selected or the chooser is dismissed.
  /// A `null` value indicates that selection was canceled.
  final void Function(int? chapter)? onChapterSelected;

  /// Optional callback when a section heading is selected.
  final void Function(int chapter, String sectionHeading)? onSectionSelected;

  /// Optional callback when a verse is selected.
  final void Function(int chapter, int verse)? onVerseSelected;

  @override
  State<ChapterChooser> createState() => _ChapterChooserState();
}

class _ChapterChooserState extends State<ChapterChooser> {
  int? _chosenChapter;

  @override
  void initState() {
    super.initState();
    if (_resolveShowVerseGrid()) {
      if (widget.initialChapter != null) {
        _chosenChapter = widget.initialChapter;
      } else if (widget.chapterCount == 1) {
        _chosenChapter = 1;
      }
    }
  }

  @override
  void didUpdateWidget(covariant ChapterChooser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialChapter != oldWidget.initialChapter &&
        widget.initialChapter != null &&
        _resolveShowVerseGrid()) {
      setState(() {
        _chosenChapter = widget.initialChapter;
      });
    }
  }

  bool _resolveShowVerseGrid() {
    if (widget.showVerseGrid != null) {
      return widget.showVerseGrid!;
    }
    final appState = getIt.isRegistered<AppState>() ? getIt<AppState>() : null;
    if (appState != null) {
      return appState.showVerseGridNotifier.value;
    }
    final userSettings =
        getIt.isRegistered<UserSettings>() ? getIt<UserSettings>() : null;
    return userSettings?.showVerseGrid ?? false;
  }

  int _getVerseCount(int chapter) {
    final bookId = widget.bookId ??
        (widget.bookName != null
            ? fullNameToBookIdMap[widget.bookName] ?? 1
            : 1);
    if (widget.verseCountLoader != null) {
      return widget.verseCountLoader!(bookId, chapter);
    }
    return getVerseCountForBookAndChapter(bookId, chapter);
  }

  void _onChapterChosen(int? chapter) {
    if (chapter == null) {
      widget.onChapterSelected?.call(null);
      return;
    }

    final showVerseGrid = _resolveShowVerseGrid();
    if (!showVerseGrid) {
      widget.onChapterSelected?.call(chapter);
      return;
    }

    setState(() {
      _chosenChapter = chapter;
    });
  }

  void _onVerseChosen(int? verse) {
    if (verse == null) {
      widget.onChapterSelected?.call(null);
      return;
    }

    final chapter = _chosenChapter!;
    if (widget.onVerseSelected != null) {
      widget.onVerseSelected!(chapter, verse);
    } else {
      widget.onChapterSelected?.call(chapter);
    }
  }

  void _onBackPressedFromVerse() {
    if (widget.chapterCount == 1) {
      widget.onChapterSelected?.call(null);
      return;
    }
    setState(() {
      _chosenChapter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_chosenChapter != null) {
      return GridVerseChooser(
        bookName: widget.bookName,
        bookId: widget.bookId,
        chapter: _chosenChapter!,
        verseCount: _getVerseCount(_chosenChapter!),
        onVerseSelected: _onVerseChosen,
        onBackPressed: _onBackPressedFromVerse,
      );
    }

    if (widget.style != null) {
      return _buildChooser(widget.style!);
    }

    final appState = getIt.isRegistered<AppState>() ? getIt<AppState>() : null;
    if (appState != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: appState.showVerseGridNotifier,
        builder: (context, showGrid, child) {
          return ValueListenableBuilder<ChapterChooserStyle>(
            valueListenable: appState.chapterChooserStyleNotifier,
            builder: (context, currentStyle, child) {
              return _buildChooser(widget.style ?? currentStyle);
            },
          );
        },
      );
    }

    final userSettings =
        getIt.isRegistered<UserSettings>() ? getIt<UserSettings>() : null;
    final currentStyle = widget.style ??
        userSettings?.chapterChooserStyle ??
        ChapterChooserStyle.keypad;
    return _buildChooser(currentStyle);
  }

  Widget _buildChooser(ChapterChooserStyle currentStyle) {
    switch (currentStyle) {
      case ChapterChooserStyle.grid:
        return GridChapterChooser(
          bookName: widget.bookName,
          bookId: widget.bookId,
          chapterCount: widget.chapterCount,
          headingsLoader: widget.headingsLoader,
          onChapterSelected: _onChapterChosen,
          onSectionSelected: widget.onSectionSelected,
        );
      case ChapterChooserStyle.keypad:
        return KeypadChapterChooser(
          bookName: widget.bookName,
          bookId: widget.bookId,
          chapterCount: widget.chapterCount,
          headingsLoader: widget.headingsLoader,
          onChapterSelected: _onChapterChosen,
          onSectionSelected: widget.onSectionSelected,
        );
    }
  }
}

/// A chapter chooser that uses a numeric keypad layout.
class KeypadChapterChooser extends StatefulWidget {
  const KeypadChapterChooser({
    super.key,
    this.bookName,
    this.bookId,
    required this.chapterCount,
    this.headingsLoader,
    this.onChapterSelected,
    this.onSectionSelected,
  });

  final String? bookName;
  final int? bookId;
  final int chapterCount;
  final Future<List<SectionHeading>> Function(int bookId)? headingsLoader;
  final void Function(int? chapter)? onChapterSelected;
  final void Function(int chapter, String sectionHeading)? onSectionSelected;

  @override
  State<KeypadChapterChooser> createState() => _KeypadChapterChooserState();
}

class _KeypadChapterChooserState extends State<KeypadChapterChooser> {
  String _enteredText = '';

  String get _displayBookName {
    final resolvedBookId = widget.bookId ??
        (widget.bookName != null ? fullNameToBookIdMap[widget.bookName] : null);
    if (resolvedBookId != null &&
        bookIdToBookNameMap.containsKey(resolvedBookId)) {
      return bookIdToBookNameMap[resolvedBookId]!;
    }
    if (widget.bookName != null && widget.bookName!.isNotEmpty) {
      return widget.bookName!;
    }
    return '';
  }

  @override
  void didUpdateWidget(covariant KeypadChapterChooser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapterCount != widget.chapterCount) {
      if (_enteredText.isNotEmpty && _matchingChapters(_enteredText).isEmpty) {
        _enteredText = '';
      }
    }
  }

  /// Returns all valid chapters (1..chapterCount) whose string representation
  /// starts with [prefix].
  List<int> _matchingChapters(String prefix) {
    if (prefix.isEmpty || prefix.startsWith('0')) {
      return const [];
    }
    final matches = <int>[];
    for (var c = 1; c <= widget.chapterCount; c++) {
      if (c.toString().startsWith(prefix)) {
        matches.add(c);
      }
    }
    return matches;
  }

  /// Returns true if typing [digit] after [_enteredText] leads to at least
  /// one valid chapter.
  bool _isDigitValid(int digit) {
    final candidate = '$_enteredText$digit';
    return _matchingChapters(candidate).isNotEmpty;
  }

  bool get _canGo {
    final chapter = int.tryParse(_enteredText);
    return chapter != null && chapter >= 1 && chapter <= widget.chapterCount;
  }

  void _handleDigit(int digit) {
    final newText = '$_enteredText$digit';
    final matches = _matchingChapters(newText);
    if (matches.length == 1) {
      setState(() {
        _enteredText = newText;
      });
      widget.onChapterSelected?.call(matches.first);
    } else {
      setState(() {
        _enteredText = newText;
      });
    }
  }

  void _handleBackspace() {
    if (_enteredText.isNotEmpty) {
      setState(() {
        _enteredText = _enteredText.substring(0, _enteredText.length - 1);
      });
    }
  }

  void _handleGo() {
    final chapter = int.tryParse(_enteredText);
    if (chapter != null && chapter >= 1 && chapter <= widget.chapterCount) {
      widget.onChapterSelected?.call(chapter);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final char = event.character;
    int? digit;
    if (char != null && RegExp(r'^[0-9]$').hasMatch(char)) {
      digit = int.parse(char);
    } else if (event.logicalKey == LogicalKeyboardKey.digit0 ||
        event.logicalKey == LogicalKeyboardKey.numpad0) {
      digit = 0;
    } else if (event.logicalKey == LogicalKeyboardKey.digit1 ||
        event.logicalKey == LogicalKeyboardKey.numpad1) {
      digit = 1;
    } else if (event.logicalKey == LogicalKeyboardKey.digit2 ||
        event.logicalKey == LogicalKeyboardKey.numpad2) {
      digit = 2;
    } else if (event.logicalKey == LogicalKeyboardKey.digit3 ||
        event.logicalKey == LogicalKeyboardKey.numpad3) {
      digit = 3;
    } else if (event.logicalKey == LogicalKeyboardKey.digit4 ||
        event.logicalKey == LogicalKeyboardKey.numpad4) {
      digit = 4;
    } else if (event.logicalKey == LogicalKeyboardKey.digit5 ||
        event.logicalKey == LogicalKeyboardKey.numpad5) {
      digit = 5;
    } else if (event.logicalKey == LogicalKeyboardKey.digit6 ||
        event.logicalKey == LogicalKeyboardKey.numpad6) {
      digit = 6;
    } else if (event.logicalKey == LogicalKeyboardKey.digit7 ||
        event.logicalKey == LogicalKeyboardKey.numpad7) {
      digit = 7;
    } else if (event.logicalKey == LogicalKeyboardKey.digit8 ||
        event.logicalKey == LogicalKeyboardKey.numpad8) {
      digit = 8;
    } else if (event.logicalKey == LogicalKeyboardKey.digit9 ||
        event.logicalKey == LogicalKeyboardKey.numpad9) {
      digit = 9;
    }

    if (digit != null) {
      if (_isDigitValid(digit)) {
        _handleDigit(digit);
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      if (_enteredText.isNotEmpty) {
        _handleBackspace();
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_canGo) {
        _handleGo();
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onChapterSelected?.call(null);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          widget.onChapterSelected?.call(null);
        }
      },
      child: Stack(
        children: [
          // Barrier / Scrim
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onChapterSelected?.call(null),
              child: Container(
                color: theme.colorScheme.scrim.withValues(alpha: 0.5),
              ),
            ),
          ),
          // Keypad Popup
          Center(
            child: Focus(
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // Prevent taps inside dialog from closing it
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(24),
                  color: theme.colorScheme.surfaceContainerHigh,
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(theme),
                        const SizedBox(height: 12),
                        _buildDisplay(theme),
                        const SizedBox(height: 16),
                        _buildKeypadRow(['1', '2', '3']),
                        const SizedBox(height: 8),
                        _buildKeypadRow(['4', '5', '6']),
                        const SizedBox(height: 8),
                        _buildKeypadRow(['7', '8', '9']),
                        const SizedBox(height: 8),
                        _buildBottomRow(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            key: const ValueKey('keypad_sections'),
            icon: const Icon(Icons.format_list_bulleted, size: 22),
            padding: EdgeInsets.zero,
            onPressed: _openSectionHeadings,
            tooltip: 'Section Headings',
          ),
        ),
        Expanded(
          child: Text(
            _displayBookName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildDisplay(ThemeData theme) {
    final displayText = _enteredText.isNotEmpty
        ? 'Chapter $_enteredText'
        : 'Chapter (1–${widget.chapterCount})';

    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        displayText,
        style: _enteredText.isNotEmpty
            ? theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              )
            : theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _buildDigitButton(int.parse(keys[i])),
          ),
        ],
      ],
    );
  }

  Widget _buildDigitButton(int digit) {
    final isValid = _isDigitValid(digit);
    return SizedBox(
      height: 52,
      child: FilledButton.tonal(
        key: ValueKey('keypad_$digit'),
        onPressed: isValid ? () => _handleDigit(digit) : null,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          '$digit',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomRow(ThemeData theme) {
    return Row(
      children: [
        // Delete button
        Expanded(
          child: SizedBox(
            height: 52,
            child: FilledButton.tonal(
              key: const ValueKey('keypad_delete'),
              onPressed: _enteredText.isNotEmpty ? _handleBackspace : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(
                Icons.backspace_outlined,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 0 digit
        Expanded(
          child: _buildDigitButton(0),
        ),
        const SizedBox(width: 8),
        // Go button
        Expanded(
          child: SizedBox(
            height: 52,
            child: FilledButton(
              key: const ValueKey('keypad_go'),
              onPressed: _canGo ? _handleGo : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Go',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openSectionHeadings() async {
    final heading = await showDialog<SectionHeading>(
      context: context,
      builder: (context) => SectionHeadingsDialog(
        bookId: widget.bookId ?? 1,
        bookName: _displayBookName,
        headingsLoader: widget.headingsLoader,
      ),
    );
    if (heading != null) {
      if (widget.onSectionSelected != null) {
        widget.onSectionSelected!(heading.chapter, heading.text);
      } else {
        widget.onChapterSelected?.call(heading.chapter);
      }
    }
  }
}

/// A chapter chooser that displays a compact grid of all chapter numbers.
class GridChapterChooser extends StatefulWidget {
  const GridChapterChooser({
    super.key,
    this.bookName,
    this.bookId,
    required this.chapterCount,
    this.headingsLoader,
    this.onChapterSelected,
    this.onSectionSelected,
  });

  final String? bookName;
  final int? bookId;
  final int chapterCount;
  final Future<List<SectionHeading>> Function(int bookId)? headingsLoader;
  final void Function(int? chapter)? onChapterSelected;
  final void Function(int chapter, String sectionHeading)? onSectionSelected;

  @override
  State<GridChapterChooser> createState() => _GridChapterChooserState();
}

class _GridChapterChooserState extends State<GridChapterChooser> {
  String get _displayBookName {
    final resolvedBookId = widget.bookId ??
        (widget.bookName != null ? fullNameToBookIdMap[widget.bookName] : null);
    if (resolvedBookId != null &&
        bookIdToBookNameMap.containsKey(resolvedBookId)) {
      return bookIdToBookNameMap[resolvedBookId]!;
    }
    if (widget.bookName != null && widget.bookName!.isNotEmpty) {
      return widget.bookName!;
    }
    return '';
  }

  Future<void> _openSectionHeadings() async {
    final heading = await showDialog<SectionHeading>(
      context: context,
      builder: (context) => SectionHeadingsDialog(
        bookId: widget.bookId ?? 1,
        bookName: _displayBookName,
        headingsLoader: widget.headingsLoader,
      ),
    );
    if (heading != null) {
      if (widget.onSectionSelected != null) {
        widget.onSectionSelected!(heading.chapter, heading.text);
      } else {
        widget.onChapterSelected?.call(heading.chapter);
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onChapterSelected?.call(null);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.sizeOf(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          widget.onChapterSelected?.call(null);
        }
      },
      child: Stack(
        children: [
          // Barrier / Scrim
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onChapterSelected?.call(null),
              child: Container(
                color: theme.colorScheme.scrim.withValues(alpha: 0.5),
              ),
            ),
          ),
          // Grid Dialog
          Center(
            child: Focus(
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // Prevent taps inside dialog from closing it
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(24),
                  color: theme.colorScheme.surfaceContainerHigh,
                  clipBehavior: Clip.none,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: 280,
                      maxWidth: min(screenSize.width * 0.95, 420.0),
                      maxHeight: screenSize.height * 0.9,
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(theme),
                        const SizedBox(height: 12),
                        Flexible(
                          child: _ChapterGridWidget(
                            itemCount: widget.chapterCount,
                            onItemSelected: widget.onChapterSelected,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            key: const ValueKey('keypad_sections'),
            icon: const Icon(Icons.format_list_bulleted, size: 22),
            padding: EdgeInsets.zero,
            onPressed: _openSectionHeadings,
            tooltip: 'Section Headings',
          ),
        ),
        Expanded(
          child: Text(
            _displayBookName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }
}

/// A verse chooser that displays a grid of verse numbers for a selected chapter.
class GridVerseChooser extends StatefulWidget {
  const GridVerseChooser({
    super.key,
    this.bookName,
    this.bookId,
    required this.chapter,
    required this.verseCount,
    this.onVerseSelected,
    this.onBackPressed,
  });

  final String? bookName;
  final int? bookId;
  final int chapter;
  final int verseCount;
  final void Function(int? verse)? onVerseSelected;
  final VoidCallback? onBackPressed;

  @override
  State<GridVerseChooser> createState() => _GridVerseChooserState();
}

class _GridVerseChooserState extends State<GridVerseChooser> {
  String get _displayBookName {
    final resolvedBookId = widget.bookId ??
        (widget.bookName != null ? fullNameToBookIdMap[widget.bookName] : null);
    if (resolvedBookId != null &&
        bookIdToFullNameMap.containsKey(resolvedBookId)) {
      return bookIdToFullNameMap[resolvedBookId]!;
    }
    if (widget.bookName != null && widget.bookName!.isNotEmpty) {
      if (widget.bookName == 'Psalms') {
        return 'Psalm';
      }
      return widget.bookName!;
    }
    return '';
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onVerseSelected?.call(null);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.sizeOf(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (widget.onBackPressed != null) {
            widget.onBackPressed!();
          } else {
            widget.onVerseSelected?.call(null);
          }
        }
      },
      child: Stack(
        children: [
          // Barrier / Scrim
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onVerseSelected?.call(null),
              child: Container(
                color: theme.colorScheme.scrim.withValues(alpha: 0.5),
              ),
            ),
          ),
          // Grid Dialog
          Center(
            child: Focus(
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // Prevent taps inside dialog from closing it
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(24),
                  color: theme.colorScheme.surfaceContainerHigh,
                  clipBehavior: Clip.none,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: 280,
                      maxWidth: min(screenSize.width * 0.95, 420.0),
                      maxHeight: screenSize.height * 0.9,
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(theme),
                        const SizedBox(height: 12),
                        Flexible(
                          child: _VerseGridWidget(
                            itemCount: widget.verseCount,
                            onItemSelected: widget.onVerseSelected,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        if (widget.onBackPressed != null)
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              key: const ValueKey('verse_grid_back'),
              icon: const Icon(Icons.arrow_back, size: 22),
              padding: EdgeInsets.zero,
              onPressed: widget.onBackPressed,
              tooltip: 'Back to chapters',
            ),
          )
        else
          const SizedBox(width: 40),
        Expanded(
          child: Text(
            '$_displayBookName ${widget.chapter}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }
}

class _NumberGridWidget extends LeafRenderObjectWidget {
  const _NumberGridWidget({
    required this.itemCount,
    this.onItemSelected,
  });

  final int itemCount;
  final void Function(int? item)? onItemSelected;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final theme = Theme.of(context);
    return _RenderNumberGrid(
      itemCount: itemCount,
      onItemSelected: onItemSelected,
      textStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
      gridColor: theme.colorScheme.surfaceContainerHighest,
      gridHighlightColor: theme.colorScheme.primary,
      textColor: theme.colorScheme.onSurface,
      highlightTextColor: theme.colorScheme.onPrimary,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderNumberGrid renderObject) {
    final theme = Theme.of(context);
    renderObject
      ..itemCount = itemCount
      ..onItemSelected = onItemSelected
      ..textStyle = theme.textTheme.bodyMedium ?? const TextStyle()
      ..gridColor = theme.colorScheme.surfaceContainerHighest
      ..gridHighlightColor = theme.colorScheme.primary
      ..textColor = theme.colorScheme.onSurface
      ..highlightTextColor = theme.colorScheme.onPrimary;
  }
}

class _ChapterGridWidget extends _NumberGridWidget {
  const _ChapterGridWidget({
    required super.itemCount,
    super.onItemSelected,
  });
}

class _VerseGridWidget extends _NumberGridWidget {
  const _VerseGridWidget({
    required super.itemCount,
    super.onItemSelected,
  });
}

class _RenderNumberGrid extends RenderBox {
  _RenderNumberGrid({
    required this._itemCount,
    this._onItemSelected,
    required this._textStyle,
    required this._gridColor,
    required this._gridHighlightColor,
    required this._textColor,
    required this._highlightTextColor,
  }) {
    _gridPaint.color = _gridColor;
    _highlightPaint.color = _gridHighlightColor;
  }

  final _gridPaint = Paint();
  final _highlightPaint = Paint();

  int? _highlightedItem;
  bool _showOffsetTile = false;

  int get itemCount => _itemCount;
  int _itemCount;
  set itemCount(int value) {
    if (_itemCount == value) return;
    _itemCount = value;
    markNeedsLayout();
  }

  void Function(int? item)? get onItemSelected => _onItemSelected;
  void Function(int? item)? _onItemSelected;
  set onItemSelected(void Function(int? item)? value) {
    if (_onItemSelected == value) return;
    _onItemSelected = value;
  }

  TextStyle get textStyle => _textStyle;
  TextStyle _textStyle;
  set textStyle(TextStyle value) {
    if (_textStyle == value) return;
    _textStyle = value;
    markNeedsLayout();
  }

  Color get gridColor => _gridColor;
  Color _gridColor;
  set gridColor(Color value) {
    if (_gridColor == value) return;
    _gridColor = value;
    _gridPaint.color = value;
    markNeedsPaint();
  }

  Color get gridHighlightColor => _gridHighlightColor;
  Color _gridHighlightColor;
  set gridHighlightColor(Color value) {
    if (_gridHighlightColor == value) return;
    _gridHighlightColor = value;
    _highlightPaint.color = value;
    markNeedsPaint();
  }

  Color get textColor => _textColor;
  Color _textColor;
  set textColor(Color value) {
    if (_textColor == value) return;
    _textColor = value;
    markNeedsPaint();
  }

  Color get highlightTextColor => _highlightTextColor;
  Color _highlightTextColor;
  set highlightTextColor(Color value) {
    if (_highlightTextColor == value) return;
    _highlightTextColor = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  Size _gridSize = Size.zero;
  Size _tileSize = Size.zero;
  int _rows = 0;
  int _columns = 0;
  double _scaledFontSize = 14.0;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    _rows = (itemCount / 10).ceil();
    _columns = itemCount < 10 ? itemCount : 10;
    const desiredTileWidth = 36.0;
    final desiredTileHeight = (itemCount > 100) ? 24.0 : 36.0;

    final maxGridWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : _columns * desiredTileWidth;
    final gridWidth = min(maxGridWidth, _columns * desiredTileWidth);
    final tileWidth = gridWidth / _columns;

    final maxGridHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : _rows * desiredTileHeight;
    final gridHeight = min(maxGridHeight, _rows * desiredTileHeight);
    final tileHeight = gridHeight / _rows;

    _gridSize = Size(tileWidth * _columns, tileHeight * _rows);
    _tileSize = Size(tileWidth, tileHeight);

    _scaledFontSize = _calculateOptimalFontSize(itemCount.toString());

    return _gridSize;
  }

  double _calculateOptimalFontSize(String sampleText) {
    final initialFontSize = textStyle.fontSize ?? 14.0;
    if (_tileSize.width <= 0 || _tileSize.height <= 0) return initialFontSize;

    double scaleFactor = 1.0;
    TextPainter textPainter;
    do {
      textPainter = TextPainter(
        text: TextSpan(
          text: sampleText,
          style: textStyle.copyWith(fontSize: initialFontSize * scaleFactor),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      if (textPainter.width <= _tileSize.width * 0.85 &&
          textPainter.height <= _tileSize.height * 0.85) {
        break;
      }

      scaleFactor *= 0.9;
    } while (scaleFactor > 0.3);

    return initialFontSize * scaleFactor;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  int? _getItemAtPosition(Offset position) {
    if (!(Offset.zero & _gridSize).contains(position)) {
      return null;
    }

    final col = (position.dx / _tileSize.width).floor();
    final row = (position.dy / _tileSize.height).floor();
    final item = row * _columns + col + 1;

    if (item <= itemCount && item > 0) {
      return item;
    }
    return null;
  }

  void _updateHighlightedItem(Offset position, bool isMove) {
    final newHighlight = _getItemAtPosition(position);
    if (newHighlight != _highlightedItem || _showOffsetTile != isMove) {
      _highlightedItem = newHighlight;
      _showOffsetTile = isMove;
      markNeedsPaint();
    }
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      _updateHighlightedItem(event.localPosition, false);
    } else if (event is PointerHoverEvent) {
      _updateHighlightedItem(event.localPosition, false);
    } else if (event is PointerMoveEvent) {
      _updateHighlightedItem(event.localPosition, true);
    } else if (event is PointerUpEvent) {
      final item = _getItemAtPosition(event.localPosition);
      if (item != null) {
        onItemSelected?.call(item);
      }
      _highlightedItem = null;
      _showOffsetTile = false;
      markNeedsPaint();
    } else if (event is PointerCancelEvent) {
      _highlightedItem = null;
      _showOffsetTile = false;
      markNeedsPaint();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final cols = itemCount < 10 ? itemCount : 10;
    return cols * 24.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final cols = itemCount < 10 ? itemCount : 10;
    return cols * 40.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final rows = (itemCount / 10).ceil();
    return rows * 20.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final rows = (itemCount / 10).ceil();
    final desiredH = (itemCount > 100) ? 24.0 : 36.0;
    return rows * desiredH;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    _paintGrid(canvas);
    _paintItems(context);

    canvas.restore();
  }

  void _paintGrid(Canvas canvas) {
    final gridRect = Offset.zero & _gridSize;
    canvas.drawRRect(
      RRect.fromRectAndRadius(gridRect, const Radius.circular(8)),
      _gridPaint,
    );
  }

  void _paintItems(PaintingContext context) {
    for (var row = 0; row < _rows; row++) {
      for (var col = 0; col < _columns; col++) {
        final index = row * _columns + col + 1;
        if (index <= itemCount) {
          _paintItem(context, row, col, index);
        }
      }
    }
  }

  void _paintItem(PaintingContext context, int row, int col, int index) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(
      col * _tileSize.width,
      row * _tileSize.height,
    );

    if (_highlightedItem == index) {
      _paintHighlight(context, index);
    }

    _paintItemNumber(context, index);
    canvas.restore();
  }

  void _paintHighlight(PaintingContext context, int index) {
    final canvas = context.canvas;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Offset.zero & _tileSize, const Radius.circular(4)),
      _highlightPaint,
    );

    if (_showOffsetTile) {
      _paintOffsetTile(context, index);
    }
  }

  void _paintOffsetTile(PaintingContext context, int index) {
    const verticalOffset = 60.0;
    final canvas = context.canvas;
    final offsetTileSize = Size(_tileSize.width * 2, _tileSize.height * 2);
    final offsetPosition = Offset(
      -_tileSize.width / 2,
      -verticalOffset - _tileSize.height / 2,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        offsetPosition & offsetTileSize,
        const Radius.circular(8),
      ),
      _highlightPaint,
    );

    final textPainter = _createTextPainter(
      index.toString(),
      fontSize: _scaledFontSize * 2,
      color: highlightTextColor,
    );

    textPainter.paint(
      context.canvas,
      Offset(
        (-_tileSize.width / 2) + (offsetTileSize.width - textPainter.width) / 2,
        -verticalOffset -
            _tileSize.height / 2 +
            (offsetTileSize.height - textPainter.height) / 2,
      ),
    );
  }

  void _paintItemNumber(PaintingContext context, int index) {
    final textPainter = _createTextPainter(
      index.toString(),
      color: _highlightedItem == index ? highlightTextColor : textColor,
    );

    textPainter.paint(
      context.canvas,
      Offset(
        (_tileSize.width - textPainter.width) / 2,
        (_tileSize.height - textPainter.height) / 2,
      ),
    );
  }

  TextPainter _createTextPainter(String text,
      {Color? color, double? fontSize}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(
          color: color,
          fontSize: fontSize ?? _scaledFontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter;
  }
}
