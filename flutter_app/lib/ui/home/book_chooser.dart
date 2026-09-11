import 'package:bsb/ui/home/chapter_chooser.dart';
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

class BookChooser extends StatefulWidget {
  const BookChooser({
    super.key,
    required this.onSelected,
    this.wideScreenBreakpoint = defaultWideScreenBreakpoint,
  });

  /// The width threshold above which full book names are displayed instead of abbreviations.
  static const double defaultWideScreenBreakpoint = 800.0;

  final void Function(int bookId, int chapter, [String? sectionHeading]) onSelected;
  final double wideScreenBreakpoint;

  @override
  State<BookChooser> createState() => _BookChooserState();
}

class _BookChooserState extends State<BookChooser> {
  final _chapterNotifier = ValueNotifier<(int, int)?>(null);

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

  void _onBookSelected(int bookId, int chapterCount) {
    if (chapterCount == 1) {
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final useFullName = width >= widget.wideScreenBreakpoint;

        return _BookChooserScope(
          useFullName: useFullName,
          child: Stack(
            children: [
              Column(
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
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Expanded _buildPentateuch() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BookItem(
            title: 'Gen',
            color: pentateuchColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 1,
            chapterCount: 50,
          ),
          BookItem(
            title: 'Exo',
            color: pentateuchColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 2,
            chapterCount: 40,
          ),
          BookItem(
            title: 'Lev',
            color: pentateuchColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 3,
            chapterCount: 27,
          ),
          BookItem(
            title: 'Num',
            color: pentateuchColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 4,
            chapterCount: 36,
          ),
          BookItem(
            title: 'Deut',
            color: pentateuchColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 5,
            chapterCount: 34,
          ),
        ],
      ),
    );
  }

  Expanded _buildHistorical1() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BookItem(
            title: 'Josh',
            color: historicalColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 6,
            chapterCount: 24,
          ),
          BookItem(
            title: 'Judg',
            color: historicalColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 7,
            chapterCount: 21,
          ),
          BookItem(
            title: 'Ruth',
            color: historicalColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 8,
            chapterCount: 4,
          ),
          BookItem(
            title: '1Sam',
            color: historicalColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 9,
            chapterCount: 31,
          ),
          BookItem(
            title: '2Sam',
            color: historicalColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 10,
            chapterCount: 24,
          ),
        ],
      ),
    );
  }

  Expanded _buildHistorical2() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BookItem(
            title: '1Ki',
            color: historicalColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 11,
            chapterCount: 22,
          ),
          BookItem(
            title: '2Ki',
            color: historicalColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 12,
            chapterCount: 25,
          ),
          BookItem(
            title: '1Ch',
            color: historicalColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 13,
            chapterCount: 29,
          ),
          BookItem(
            title: '2Ch',
            color: historicalColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 14,
            chapterCount: 36,
          ),
          BookItem(
            title: 'Ezra',
            color: historicalColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 15,
            chapterCount: 10,
          ),
          BookItem(
            title: 'Neh',
            color: historicalColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 16,
            chapterCount: 13,
          ),
          BookItem(
            title: 'Est',
            color: historicalColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 17,
            chapterCount: 10,
          ),
        ],
      ),
    );
  }

  Expanded _buildWisdom() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BookItem(
            title: 'Job',
            color: wisdomColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 18,
            chapterCount: 42,
          ),
          BookItem(
            title: 'Psa',
            color: wisdomColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 19,
            chapterCount: 150,
          ),
          BookItem(
            title: 'Prov',
            color: wisdomColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 20,
            chapterCount: 31,
          ),
          BookItem(
            title: 'Eccl',
            color: wisdomColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 21,
            chapterCount: 12,
          ),
          BookItem(
            title: 'Song',
            color: wisdomColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 22,
            chapterCount: 8,
          ),
        ],
      ),
    );
  }

  Expanded _buildMajorProphets() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BookItem(
            title: 'Isa',
            color: majorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 23,
            chapterCount: 66,
          ),
          BookItem(
            title: 'Jer',
            color: majorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 24,
            chapterCount: 52,
          ),
          BookItem(
            title: 'Lam',
            color: majorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 25,
            chapterCount: 5,
          ),
          BookItem(
            title: 'Ezek',
            color: majorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 26,
            chapterCount: 48,
          ),
          BookItem(
            title: 'Dan',
            color: majorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 27,
            chapterCount: 12,
          ),
        ],
      ),
    );
  }

  Expanded _buildMinorProphets1() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BookItem(
            title: 'Hos',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 28,
            chapterCount: 14,
          ),
          BookItem(
            title: 'Joel',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 29,
            chapterCount: 3,
          ),
          BookItem(
            title: 'Amos',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 30,
            chapterCount: 9,
          ),
          BookItem(
            title: 'Oba',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 31,
            chapterCount: 1,
          ),
          BookItem(
            title: 'Jon',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 32,
            chapterCount: 4,
          ),
          BookItem(
            title: 'Mic',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 33,
            chapterCount: 7,
          ),
        ],
      ),
    );
  }

  Expanded _buildMinorProphets2() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BookItem(
            title: 'Nam',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 34,
            chapterCount: 3,
          ),
          BookItem(
            title: 'Hab',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 35,
            chapterCount: 3,
          ),
          BookItem(
            title: 'Zeph',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 36,
            chapterCount: 3,
          ),
          BookItem(
            title: 'Hag',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 37,
            chapterCount: 2,
          ),
          BookItem(
            title: 'Zec',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 38,
            chapterCount: 14,
          ),
          BookItem(
            title: 'Mal',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 39,
            chapterCount: 4,
          ),
        ],
      ),
    );
  }

  Expanded _buildGospels() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BookItem(
            title: 'Matt',
            color: gospelsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 40,
            chapterCount: 28,
          ),
          BookItem(
            title: 'Mark',
            color: gospelsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 41,
            chapterCount: 16,
          ),
          BookItem(
            title: 'Luke',
            color: gospelsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 42,
            chapterCount: 24,
          ),
          BookItem(
            title: 'John',
            color: gospelsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 43,
            chapterCount: 21,
          ),
          BookItem(
            title: 'Acts',
            color: gospelsColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 44,
            chapterCount: 28,
          ),
        ],
      ),
    );
  }

  Expanded _buildPaulineEpistles() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BookItem(
            title: 'Rom',
            color: paulineColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 45,
            chapterCount: 16,
          ),
          BookItem(
            title: '1Co',
            color: paulineColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 46,
            chapterCount: 16,
          ),
          BookItem(
            title: '2Co',
            color: paulineColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 47,
            chapterCount: 13,
          ),
          BookItem(
            title: 'Gal',
            color: paulineColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 48,
            chapterCount: 6,
          ),
          BookItem(
            title: 'Eph',
            color: paulineColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 49,
            chapterCount: 6,
          ),
          BookItem(
            title: 'Php',
            color: paulineColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 50,
            chapterCount: 4,
          ),
          BookItem(
            title: 'Col',
            color: paulineColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 51,
            chapterCount: 4,
          ),
        ],
      ),
    );
  }

  Expanded _buildPastoralEpistles() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BookItem(
            title: '1Th',
            color: paulineColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 52,
            chapterCount: 5,
          ),
          BookItem(
            title: '2Th',
            color: paulineColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 53,
            chapterCount: 3,
          ),
          BookItem(
            title: '1Ti',
            color: paulineColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 54,
            chapterCount: 6,
          ),
          BookItem(
            title: '2Ti',
            color: paulineColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 55,
            chapterCount: 4,
          ),
          BookItem(
            title: 'Tit',
            color: paulineColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 56,
            chapterCount: 3,
          ),
          BookItem(
            title: 'Phm',
            color: paulineColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 57,
            chapterCount: 1,
          ),
        ],
      ),
    );
  }

  Expanded _buildGeneralEpistles1() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BookItem(
            title: 'Heb',
            color: generalEpistlesColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 58,
            chapterCount: 13,
          ),
          BookItem(
            title: 'James',
            color: generalEpistlesColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 59,
            chapterCount: 5,
          ),
          BookItem(
            title: '1Pet',
            color: generalEpistlesColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 60,
            chapterCount: 5,
          ),
          BookItem(
            title: '2Pet',
            color: generalEpistlesColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 61,
            chapterCount: 3,
          ),
        ],
      ),
    );
  }

  Expanded _buildGeneralEpistles2() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BookItem(
            title: '1Jn',
            color: generalEpistlesColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 62,
            chapterCount: 5,
          ),
          BookItem(
            title: '2Jn',
            color: generalEpistlesColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 63,
            chapterCount: 1,
          ),
          BookItem(
            title: '3Jn',
            color: generalEpistlesColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 64,
            chapterCount: 1,
          ),
          BookItem(
            title: 'Jude',
            color: generalEpistlesColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 65,
            chapterCount: 1,
          ),
          BookItem(
            title: 'Rev',
            color: generalEpistlesColor,
            onTap: _onBookSelected,
            onSwipeUp: _goToFirstChapter,
            onSwipeDown: _goToLastChapter,
            bookId: 66,
            chapterCount: 22,
          ),
        ],
      ),
    );
  }
}

class BookItem extends StatefulWidget {
  const BookItem({
    super.key,
    required this.title,
    this.fullName,
    required this.color,
    required this.onTap,
    required this.onSwipeUp,
    required this.onSwipeDown,
    required this.bookId,
    required this.chapterCount,
    this.useFullName,
    this.wideScreenBreakpoint,
  });

  final String title;
  final String? fullName;
  final Color color;
  final void Function(int bookId, int chapterCount) onTap;
  final void Function(int bookId) onSwipeUp;
  final void Function(int bookId, int chapter) onSwipeDown;
  final int bookId;
  final int chapterCount;
  final bool? useFullName;
  final double? wideScreenBreakpoint;

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
          bookIdToFullNameMap[widget.bookId] ??
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

    return Expanded(
      child: Material(
        color: widget.color,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              widget.onSwipeUp(widget.bookId);
            } else if (details.primaryVelocity! > 0) {
              widget.onSwipeDown(widget.bookId, widget.chapterCount);
            }
          },
          child: InkWell(
            onTap: () => widget.onTap(widget.bookId, widget.chapterCount),
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
                    style: const TextStyle(
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
