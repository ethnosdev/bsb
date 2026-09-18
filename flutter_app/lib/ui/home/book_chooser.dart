import 'dart:math' as math;

import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/home/chapter_chooser.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';

enum ChapterSelectionState {
  start,
  selecting,
  end,
}

class _BookChooserScope extends InheritedWidget {
  const _BookChooserScope({
    required this.useFullName,
    required super.child,
  });

  final bool useFullName;

  static _BookChooserScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_BookChooserScope>();
  }

  @override
  bool updateShouldNotify(_BookChooserScope oldWidget) {
    return useFullName != oldWidget.useFullName;
  }
}

class _BookData {
  const _BookData({
    required this.title,
    required this.bookId,
    required this.chapterCount,
  });

  final String title;
  final int bookId;
  final int chapterCount;
}

const List<List<_BookData>> _bookRows = [
  // Pentateuch (5)
  [
    _BookData(title: 'Gen', bookId: 1, chapterCount: 50),
    _BookData(title: 'Exo', bookId: 2, chapterCount: 40),
    _BookData(title: 'Lev', bookId: 3, chapterCount: 27),
    _BookData(title: 'Num', bookId: 4, chapterCount: 36),
    _BookData(title: 'Deut', bookId: 5, chapterCount: 34),
  ],
  // Historical 1 (5)
  [
    _BookData(title: 'Josh', bookId: 6, chapterCount: 24),
    _BookData(title: 'Judg', bookId: 7, chapterCount: 21),
    _BookData(title: 'Ruth', bookId: 8, chapterCount: 4),
    _BookData(title: '1Sam', bookId: 9, chapterCount: 31),
    _BookData(title: '2Sam', bookId: 10, chapterCount: 24),
  ],
  // Historical 2 (7)
  [
    _BookData(title: '1Ki', bookId: 11, chapterCount: 22),
    _BookData(title: '2Ki', bookId: 12, chapterCount: 25),
    _BookData(title: '1Ch', bookId: 13, chapterCount: 29),
    _BookData(title: '2Ch', bookId: 14, chapterCount: 36),
    _BookData(title: 'Ezra', bookId: 15, chapterCount: 10),
    _BookData(title: 'Neh', bookId: 16, chapterCount: 13),
    _BookData(title: 'Est', bookId: 17, chapterCount: 10),
  ],
  // Wisdom (5)
  [
    _BookData(title: 'Job', bookId: 18, chapterCount: 42),
    _BookData(title: 'Psa', bookId: 19, chapterCount: 150),
    _BookData(title: 'Prov', bookId: 20, chapterCount: 31),
    _BookData(title: 'Eccl', bookId: 21, chapterCount: 12),
    _BookData(title: 'Song', bookId: 22, chapterCount: 8),
  ],
  // Major Prophets (5)
  [
    _BookData(title: 'Isa', bookId: 23, chapterCount: 66),
    _BookData(title: 'Jer', bookId: 24, chapterCount: 52),
    _BookData(title: 'Lam', bookId: 25, chapterCount: 5),
    _BookData(title: 'Ezek', bookId: 26, chapterCount: 48),
    _BookData(title: 'Dan', bookId: 27, chapterCount: 12),
  ],
  // Minor Prophets 1 (6)
  [
    _BookData(title: 'Hos', bookId: 28, chapterCount: 14),
    _BookData(title: 'Joel', bookId: 29, chapterCount: 3),
    _BookData(title: 'Amos', bookId: 30, chapterCount: 9),
    _BookData(title: 'Oba', bookId: 31, chapterCount: 1),
    _BookData(title: 'Jon', bookId: 32, chapterCount: 4),
    _BookData(title: 'Mic', bookId: 33, chapterCount: 7),
  ],
  // Minor Prophets 2 (6)
  [
    _BookData(title: 'Nam', bookId: 34, chapterCount: 3),
    _BookData(title: 'Hab', bookId: 35, chapterCount: 3),
    _BookData(title: 'Zeph', bookId: 36, chapterCount: 3),
    _BookData(title: 'Hag', bookId: 37, chapterCount: 2),
    _BookData(title: 'Zec', bookId: 38, chapterCount: 14),
    _BookData(title: 'Mal', bookId: 39, chapterCount: 4),
  ],
  // Gospels (5)
  [
    _BookData(title: 'Matt', bookId: 40, chapterCount: 28),
    _BookData(title: 'Mark', bookId: 41, chapterCount: 16),
    _BookData(title: 'Luke', bookId: 42, chapterCount: 24),
    _BookData(title: 'John', bookId: 43, chapterCount: 21),
    _BookData(title: 'Acts', bookId: 44, chapterCount: 28),
  ],
  // Pauline Epistles (7)
  [
    _BookData(title: 'Rom', bookId: 45, chapterCount: 16),
    _BookData(title: '1Co', bookId: 46, chapterCount: 16),
    _BookData(title: '2Co', bookId: 47, chapterCount: 13),
    _BookData(title: 'Gal', bookId: 48, chapterCount: 6),
    _BookData(title: 'Eph', bookId: 49, chapterCount: 6),
    _BookData(title: 'Php', bookId: 50, chapterCount: 4),
    _BookData(title: 'Col', bookId: 51, chapterCount: 4),
  ],
  // Pastoral Epistles (6)
  [
    _BookData(title: '1Th', bookId: 52, chapterCount: 5),
    _BookData(title: '2Th', bookId: 53, chapterCount: 3),
    _BookData(title: '1Ti', bookId: 54, chapterCount: 6),
    _BookData(title: '2Ti', bookId: 55, chapterCount: 4),
    _BookData(title: 'Tit', bookId: 56, chapterCount: 3),
    _BookData(title: 'Phm', bookId: 57, chapterCount: 1),
  ],
  // General Epistles 1 (4)
  [
    _BookData(title: 'Heb', bookId: 58, chapterCount: 13),
    _BookData(title: 'James', bookId: 59, chapterCount: 5),
    _BookData(title: '1Pet', bookId: 60, chapterCount: 5),
    _BookData(title: '2Pet', bookId: 61, chapterCount: 3),
  ],
  // General Epistles 2 (5)
  [
    _BookData(title: '1Jn', bookId: 62, chapterCount: 5),
    _BookData(title: '2Jn', bookId: 63, chapterCount: 1),
    _BookData(title: '3Jn', bookId: 64, chapterCount: 1),
    _BookData(title: 'Jude', bookId: 65, chapterCount: 1),
    _BookData(title: 'Rev', bookId: 66, chapterCount: 22),
  ],
];

class BookChooser extends StatefulWidget {
  const BookChooser({
    super.key,
    required this.onSelected,
    this.onVerseSelected,
    this.wideScreenBreakpoint = defaultWideScreenBreakpoint,
  });

  /// The width threshold above which full book names are displayed instead of abbreviations.
  static const double defaultWideScreenBreakpoint = 800.0;

  final void Function(int bookId, int chapter, [String? sectionHeading]) onSelected;
  final void Function(int bookId, int chapter, int verse)? onVerseSelected;
  final double wideScreenBreakpoint;

  @override
  State<BookChooser> createState() => _BookChooserState();
}

class _BookChooserState extends State<BookChooser> {
  final _chapterNotifier = ValueNotifier<(int, int)?>(null);
  final _overlayController = OverlayPortalController();
  final _gridKey = GlobalKey();

  _BookData? _activeBook;
  Rect? _activeBookRect;
  Offset? _pointerDownPosition;
  Duration? _pointerDownTime;
  _BookData? _startBook;

  int? get _highlightedBookId => _activeBook?.bookId;

  Color get ot1 => Theme.of(context).colorScheme.surfaceContainerLow;
  Color get ot2 => Theme.of(context).colorScheme.surfaceContainerHigh;
  Color get nt1 => Theme.of(context).colorScheme.surfaceContainerLow;
  Color get nt2 => Theme.of(context).colorScheme.surfaceContainerHigh;

  Color get pentateuchColor => ot1;
  Color get historicalColor => ot2;
  Color get wisdomColor => ot1;
  Color get majorProphetsColor => ot2;
  Color get minorProphetsColor => ot1;
  Color get gospelsColor => nt2;
  Color get paulineColor => nt1;
  Color get generalEpistlesColor => nt2;

  Color _getRowColor(int rowIndex) {
    switch (rowIndex) {
      case 0:
        return pentateuchColor;
      case 1:
      case 2:
        return historicalColor;
      case 3:
        return wisdomColor;
      case 4:
        return majorProphetsColor;
      case 5:
      case 6:
        return minorProphetsColor;
      case 7:
        return gospelsColor;
      case 8:
      case 9:
        return paulineColor;
      case 10:
      case 11:
        return generalEpistlesColor;
      default:
        return ot1;
    }
  }

  void _onBookSelected(int bookId, int chapterCount) {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
    final appState = getIt.isRegistered<AppState>() ? getIt<AppState>() : null;
    final userSettings =
        getIt.isRegistered<UserSettings>() ? getIt<UserSettings>() : null;
    final showVerseGrid =
        appState?.showVerseGridNotifier.value ?? userSettings?.showVerseGrid ?? false;

    if (chapterCount == 1 && !showVerseGrid) {
      widget.onSelected(bookId, 1);
      return;
    }
    _chapterNotifier.value = (bookId, chapterCount);
  }

  void _goToFirstChapter(int bookId) {
    widget.onSelected(bookId, 1);
  }

  void _goToLastChapter(int bookId, int lastChapter) {
    widget.onSelected(bookId, lastChapter);
  }

  (double, double) _getGridSize(double fallbackWidth, double fallbackHeight) {
    final renderBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      return (renderBox.size.width, renderBox.size.height);
    }
    return (fallbackWidth, fallbackHeight);
  }

  Offset _getLocalPosition(Offset globalPosition, Offset fallbackLocal) {
    final renderBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      return renderBox.globalToLocal(globalPosition);
    }
    return fallbackLocal;
  }

  ( _BookData?, Rect? ) _getBookAndRectAt(
      Offset position, double totalWidth, double totalHeight) {
    if (position.dx < 0 ||
        position.dx > totalWidth ||
        position.dy < 0 ||
        position.dy > totalHeight) {
      return (null, null);
    }
    const rowCount = 12;
    final rowHeight = totalHeight / rowCount;
    final rowIndex = (position.dy / rowHeight).floor().clamp(0, rowCount - 1);
    final row = _bookRows[rowIndex];
    final colWidth = totalWidth / row.length;
    final colIndex = (position.dx / colWidth).floor().clamp(0, row.length - 1);
    final book = row[colIndex];
    final rect = Rect.fromLTWH(
      colIndex * colWidth,
      rowIndex * rowHeight,
      colWidth,
      rowHeight,
    );
    return (book, rect);
  }

  void _handlePointerDown(
      PointerDownEvent event, double fallbackWidth, double fallbackHeight) {
    if (_chapterNotifier.value != null) return;
    final (totalWidth, totalHeight) = _getGridSize(fallbackWidth, fallbackHeight);
    final localPos = _getLocalPosition(event.position, event.localPosition);

    _pointerDownPosition = localPos;
    _pointerDownTime = event.timeStamp;

    final (book, rect) = _getBookAndRectAt(localPos, totalWidth, totalHeight);
    _startBook = book;
    if (book != null && !_overlayController.isShowing) {
      _overlayController.show();
    }
    setState(() {
      _activeBook = book;
      _activeBookRect = rect;
    });
  }

  void _handlePointerMove(
      PointerMoveEvent event, double fallbackWidth, double fallbackHeight) {
    if (_chapterNotifier.value != null || _startBook == null) return;
    final (totalWidth, totalHeight) = _getGridSize(fallbackWidth, fallbackHeight);
    final localPos = _getLocalPosition(event.position, event.localPosition);

    if (localPos.dx < -50 ||
        localPos.dx > totalWidth + 50 ||
        localPos.dy < -50 ||
        localPos.dy > totalHeight + 50) {
      if (_activeBook != null) {
        if (_overlayController.isShowing) {
          _overlayController.hide();
        }
        setState(() {
          _activeBook = null;
          _activeBookRect = null;
        });
      }
      return;
    }

    final (book, rect) = _getBookAndRectAt(localPos, totalWidth, totalHeight);
    if (book != _activeBook || rect != _activeBookRect) {
      if (book != null) {
        if (!_overlayController.isShowing) {
          _overlayController.show();
        }
      } else {
        if (_overlayController.isShowing) {
          _overlayController.hide();
        }
      }
      setState(() {
        _activeBook = book;
        _activeBookRect = rect;
      });
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
    if (_chapterNotifier.value != null) return;
    final localPos = _getLocalPosition(event.position, event.localPosition);

    final startBook = _startBook;
    final activeBook = _activeBook;
    final downPos = _pointerDownPosition;
    final downTime = _pointerDownTime;

    _pointerDownPosition = null;
    _pointerDownTime = null;
    _startBook = null;
    setState(() {
      _activeBook = null;
      _activeBookRect = null;
    });

    if (startBook == null || downPos == null || downTime == null) return;

    final delta = localPos - downPos;
    final duration = event.timeStamp - downTime;
    final velocityY = duration.inMilliseconds > 0
        ? delta.dy / (duration.inMilliseconds / 1000.0)
        : 0.0;

    final isVerticalSwipe = delta.dy.abs() >= 25.0 &&
        delta.dy.abs() > delta.dx.abs() * 1.5 &&
        duration.inMilliseconds <= 500 &&
        velocityY.abs() >= 250.0;

    if (isVerticalSwipe) {
      if (delta.dy < 0) {
        _goToFirstChapter(startBook.bookId);
      } else {
        _goToLastChapter(startBook.bookId, startBook.chapterCount);
      }
    } else if (activeBook != null) {
      _onBookSelected(activeBook.bookId, activeBook.chapterCount);
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
    _pointerDownPosition = null;
    _pointerDownTime = null;
    _startBook = null;
    if (_activeBook != null) {
      setState(() {
        _activeBook = null;
        _activeBookRect = null;
      });
    }
  }

  Widget _buildPopup(BuildContext context) {
    if (_activeBook == null || _activeBookRect == null) {
      return const SizedBox.shrink();
    }
    final renderBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize || !renderBox.attached) {
      return const SizedBox.shrink();
    }

    final overlayState = Overlay.maybeOf(context);
    final overlayRenderBox =
        overlayState?.context.findRenderObject() as RenderBox?;

    final Offset tileTopLeft;
    final Offset tileCenter;
    final double overlayWidth;

    if (overlayRenderBox != null &&
        overlayRenderBox.hasSize &&
        overlayRenderBox.attached) {
      tileTopLeft = renderBox.localToGlobal(
        _activeBookRect!.topLeft,
        ancestor: overlayRenderBox,
      );
      tileCenter = renderBox.localToGlobal(
        _activeBookRect!.center,
        ancestor: overlayRenderBox,
      );
      overlayWidth = overlayRenderBox.size.width;
    } else {
      tileTopLeft = renderBox.localToGlobal(_activeBookRect!.topLeft);
      tileCenter = renderBox.localToGlobal(_activeBookRect!.center);
      overlayWidth = MediaQuery.sizeOf(context).width;
    }

    final theme = Theme.of(context);
    final book = _activeBook!;
    final fullName =
        bookIdToBookNameMap[book.bookId] ?? book.title;

    final textStyle = theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ) ??
        TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        );

    final textPainter = TextPainter(
      text: TextSpan(text: fullName, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    const paddingH = 16.0;
    const paddingV = 10.0;
    final popupWidth = textPainter.width + paddingH * 2;
    final popupHeight = textPainter.height + paddingV * 2;

    var left = tileCenter.dx - popupWidth / 2;
    left = left.clamp(8.0, math.max(8.0, overlayWidth - popupWidth - 8.0));

    const verticalGap = 12.0;
    var top = tileTopLeft.dy - popupHeight - verticalGap;
    final topPadding = MediaQuery.paddingOf(context).top;
    if (top < topPadding + 4.0) {
      top = topPadding + 4.0;
    }

    return Positioned(
      key: const ValueKey('book_chooser_popup'),
      left: left,
      top: top,
      child: IgnorePointer(
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.primary,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: paddingH,
              vertical: paddingV,
            ),
            child: Text(
              fullName,
              style: textStyle,
            ),
          ),
        ),
      ),
    );
  }

  Expanded _buildRow(int rowIndex) {
    final row = _bookRows[rowIndex];
    final color = _getRowColor(rowIndex);
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final book in row)
            BookItem(
              title: book.title,
              fullName: bookIdToBookNameMap[book.bookId],
              color: color,
              onTap: _onBookSelected,
              onSwipeUp: _goToFirstChapter,
              onSwipeDown: _goToLastChapter,
              bookId: book.bookId,
              chapterCount: book.chapterCount,
              isHighlighted: _highlightedBookId == book.bookId,
            ),
        ],
      ),
    );
  }

  Expanded _buildPentateuch() => _buildRow(0);
  Expanded _buildHistorical1() => _buildRow(1);
  Expanded _buildHistorical2() => _buildRow(2);
  Expanded _buildWisdom() => _buildRow(3);
  Expanded _buildMajorProphets() => _buildRow(4);
  Expanded _buildMinorProphets1() => _buildRow(5);
  Expanded _buildMinorProphets2() => _buildRow(6);
  Expanded _buildGospels() => _buildRow(7);
  Expanded _buildPaulineEpistles() => _buildRow(8);
  Expanded _buildPastoralEpistles() => _buildRow(9);
  Expanded _buildGeneralEpistles1() => _buildRow(10);
  Expanded _buildGeneralEpistles2() => _buildRow(11);

  @override
  void dispose() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
    _chapterNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final useFullName = width >= widget.wideScreenBreakpoint;

        return _BookChooserScope(
          useFullName: useFullName,
          child: OverlayPortal(
            controller: _overlayController,
            overlayChildBuilder: _buildPopup,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Listener(
                  key: _gridKey,
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) => _handlePointerDown(e, width, height),
                  onPointerMove: (e) => _handlePointerMove(e, width, height),
                  onPointerUp: _handlePointerUp,
                  onPointerCancel: _handlePointerCancel,
                  child: Column(
                    children: [
                      _buildPentateuch(),
                      _buildHistorical1(),
                      _buildHistorical2(),
                      _buildWisdom(),
                      _buildMajorProphets(),
                      _buildMinorProphets1(),
                      _buildMinorProphets2(),
                      _buildGospels(),
                      _buildPaulineEpistles(),
                      _buildPastoralEpistles(),
                      _buildGeneralEpistles1(),
                      _buildGeneralEpistles2(),
                    ],
                  ),
                ),
                ValueListenableBuilder<(int, int)?>(
                  valueListenable: _chapterNotifier,
                  builder: (context, bookChapter, child) {
                    if (bookChapter == null) {
                      return const SizedBox();
                    }
                    final (bookId, chapterCount) = bookChapter;
                    return ChapterChooser(
                      bookId: bookId,
                      chapterCount: chapterCount,
                      onChapterSelected: (chapter) {
                        _chapterNotifier.value = null;
                        if (chapter == null) return;
                        widget.onSelected(bookId, chapter);
                      },
                      onSectionSelected: (chapter, sectionHeading) {
                        _chapterNotifier.value = null;
                        widget.onSelected(bookId, chapter, sectionHeading);
                      },
                      onVerseSelected: (chapter, verse) {
                        _chapterNotifier.value = null;
                        if (widget.onVerseSelected != null) {
                          widget.onVerseSelected!(bookId, chapter, verse);
                        } else {
                          widget.onSelected(bookId, chapter);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BookItem extends StatefulWidget {
  const BookItem({
    super.key,
    required this.title,
    this.fullName,
    required this.color,
    this.onTap,
    this.onSwipeUp,
    this.onSwipeDown,
    required this.bookId,
    required this.chapterCount,
    this.useFullName,
    this.wideScreenBreakpoint,
    this.isHighlighted = false,
  });

  final String title;
  final String? fullName;
  final Color color;
  final void Function(int bookId, int chapterCount)? onTap;
  final void Function(int bookId)? onSwipeUp;
  final void Function(int bookId, int chapter)? onSwipeDown;
  final int bookId;
  final int chapterCount;
  final bool? useFullName;
  final double? wideScreenBreakpoint;
  final bool isHighlighted;

  @override
  State<BookItem> createState() => _BookItemState();
}

class _BookItemState extends State<BookItem> {
  bool _shouldUseFullName(BuildContext context) {
    if (widget.useFullName != null) {
      return widget.useFullName!;
    }
    final scope = _BookChooserScope.of(context);
    if (scope != null) {
      return scope.useFullName;
    }
    final breakpoint =
        widget.wideScreenBreakpoint ?? BookChooser.defaultWideScreenBreakpoint;
    return MediaQuery.sizeOf(context).width >= breakpoint;
  }

  String _getDisplayTitle(BuildContext context) {
    if (_shouldUseFullName(context)) {
      return widget.fullName ??
          bookIdToBookNameMap[widget.bookId] ??
          widget.title;
    }
    return widget.title;
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = _getDisplayTitle(context);
    final theme = Theme.of(context);
    final borderColor = theme.brightness == Brightness.light
        ? theme.colorScheme.outlineVariant
        : Colors.black;

    final backgroundColor = widget.isHighlighted
        ? theme.colorScheme.primary
        : widget.color;
    final textColor = widget.isHighlighted
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Expanded(
      child: Material(
        color: backgroundColor,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: 0.5,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                displayTitle,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 17,
                  color: textColor,
                  fontWeight: widget.isHighlighted
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
