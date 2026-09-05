import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChapterChooser extends StatefulWidget {
  const ChapterChooser({
    super.key,
    this.bookName,
    this.bookId,
    required this.chapterCount,
    this.onChapterSelected,
  });

  /// Optional book name to display at the top of the popup.
  /// If not provided and [bookId] is provided, it will be looked up using [bookId].
  final String? bookName;

  /// Optional book ID (1 to 66) used to look up the book name if [bookName] is omitted.
  final int? bookId;

  /// Total number of chapters in the selected book.
  final int chapterCount;

  /// Callback when a chapter is selected or the chooser is dismissed.
  /// A `null` value indicates that selection was canceled.
  final void Function(int? chapter)? onChapterSelected;

  @override
  State<ChapterChooser> createState() => _ChapterChooserState();
}

class _ChapterChooserState extends State<ChapterChooser> {
  String _enteredText = '';

  String get _displayBookName {
    if (widget.bookName != null && widget.bookName!.isNotEmpty) {
      return widget.bookName!;
    }
    if (widget.bookId != null) {
      return bookIdToFullNameMap[widget.bookId] ?? '';
    }
    return '';
  }

  @override
  void didUpdateWidget(covariant ChapterChooser oldWidget) {
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

    return Stack(
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
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        const SizedBox(width: 40), // Balance close button
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
        IconButton(
          key: const ValueKey('keypad_close'),
          icon: const Icon(Icons.close),
          onPressed: () => widget.onChapterSelected?.call(null),
          tooltip: 'Close',
          visualDensity: VisualDensity.compact,
        ),
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
}
