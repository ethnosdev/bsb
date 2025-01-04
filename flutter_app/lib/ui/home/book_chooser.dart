import 'package:bsb/ui/home/chapter_overlay.dart';
import 'package:flutter/material.dart';

enum ChapterSelectionState {
  start,
  selecting,
  end,
}

class BookChooser extends StatefulWidget {
  const BookChooser({
    super.key,
    required this.onBookSelected,
  });

  final void Function(int bookId, int chapter) onBookSelected;

  static const Color ot1 = Color(0xFFe9edc9);
  static const Color ot2 = Color(0xFFccd5ae);
  static const Color nt1 = Color(0xFFfefae0);
  static const Color nt2 = Color.fromARGB(255, 248, 228, 180);

  static Color pentateuchColor = ot1;
  static Color historicalColor = ot2;
  static Color wisdomColor = ot1;
  static Color majorProphetsColor = ot2;
  static Color minorProphetsColor = ot1;
  static Color gospelsColor = nt2;
  static Color paulineColor = nt1;
  static Color generalEpistlesColor = nt2;

  @override
  State<BookChooser> createState() => _BookChooserState();
}

class _BookChooserState extends State<BookChooser> {
  final _locationNotifier = ValueNotifier<(int, Offset)?>(null);

  Offset _startPanPosition = const Offset(0, 0);
  int? _lastChapter;

  void _onSelectingChapter(
    int bookId,
    int chapterCount,
    ChapterSelectionState selectionState,
    Offset? offset,
  ) {
    switch (selectionState) {
      case ChapterSelectionState.start:
        _onSelectionStart(offset!, chapterCount);
      case ChapterSelectionState.selecting:
        _onSelectionUpdate(offset!, chapterCount);
      case ChapterSelectionState.end:
        _onSelectionEnd(bookId);
    }
  }

  void _onSelectionStart(Offset offset, int chapterCount) {
    _locationNotifier.value = (chapterCount, offset);
    _startPanPosition = offset;
    _lastChapter = null;
  }

  void _onSelectionUpdate(Offset offset, int chapterCount) {
    _locationNotifier.value = (chapterCount, offset);
  }

  void _onSelectionEnd(int bookId) {
    _locationNotifier.value = null;
    if (_lastChapter == null) {
      return;
    }
    widget.onBookSelected(bookId, _lastChapter!);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
        ValueListenableBuilder<(int, Offset)?>(
          valueListenable: _locationNotifier,
          builder: (context, data, child) {
            if (data == null) {
              return const SizedBox();
            }
            final (chapterCount, location) = data;
            return Center(
              child: ChapterOverlay(
                bookId: 1,
                chapterCount: chapterCount,
                offset: location - Offset(0, _startPanPosition.dy),
                onChapterSelected: (chapter) {
                  if (chapter == null) return;
                  _lastChapter = chapter;
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Expanded _buildPentateuch() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BookItem(
            title: 'Gen',
            color: BookChooser.pentateuchColor,
            onTap: widget.onBookSelected,
            bookId: 1,
            chapterCount: 50,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Exo',
            color: BookChooser.pentateuchColor,
            onTap: widget.onBookSelected,
            bookId: 2,
            chapterCount: 40,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Lev',
            color: BookChooser.pentateuchColor,
            onTap: widget.onBookSelected,
            bookId: 3,
            chapterCount: 27,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Num',
            color: BookChooser.pentateuchColor,
            onTap: widget.onBookSelected,
            bookId: 4,
            chapterCount: 36,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Deu',
            color: BookChooser.pentateuchColor,
            onTap: widget.onBookSelected,
            bookId: 5,
            chapterCount: 34,
            onSelectionUpdate: _onSelectingChapter,
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
            title: 'Jos',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            bookId: 6,
            chapterCount: 24,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Jdg',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            bookId: 7,
            chapterCount: 21,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Rut',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            bookId: 8,
            chapterCount: 4,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '1Sa',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            bookId: 9,
            chapterCount: 31,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '2Sa',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            bookId: 10,
            chapterCount: 24,
            onSelectionUpdate: _onSelectingChapter,
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
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            bookId: 11,
            chapterCount: 22,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '2Ki',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            bookId: 12,
            chapterCount: 25,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '1Ch',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            bookId: 13,
            chapterCount: 29,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '2Ch',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            bookId: 14,
            chapterCount: 36,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Ezr',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            bookId: 15,
            chapterCount: 10,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Neh',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            bookId: 16,
            chapterCount: 13,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Est',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            bookId: 17,
            chapterCount: 10,
            onSelectionUpdate: _onSelectingChapter,
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
            color: BookChooser.wisdomColor,
            onTap: widget.onBookSelected,
            bookId: 18,
            chapterCount: 42,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Psa',
            color: BookChooser.wisdomColor,
            onTap: widget.onBookSelected,
            bookId: 19,
            chapterCount: 150,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Pro',
            color: BookChooser.wisdomColor,
            onTap: widget.onBookSelected,
            bookId: 20,
            chapterCount: 31,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Ecc',
            color: BookChooser.wisdomColor,
            onTap: widget.onBookSelected,
            bookId: 21,
            chapterCount: 12,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Sng',
            color: BookChooser.wisdomColor,
            onTap: widget.onBookSelected,
            bookId: 22,
            chapterCount: 8,
            onSelectionUpdate: _onSelectingChapter,
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
            color: BookChooser.majorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 23,
            chapterCount: 66,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Jer',
            color: BookChooser.majorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 24,
            chapterCount: 52,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Lam',
            color: BookChooser.majorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 25,
            chapterCount: 5,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Ezk',
            color: BookChooser.majorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 26,
            chapterCount: 48,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Dan',
            color: BookChooser.majorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 27,
            chapterCount: 12,
            onSelectionUpdate: _onSelectingChapter,
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
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 28,
            chapterCount: 14,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Jol',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 29,
            chapterCount: 3,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Amo',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 30,
            chapterCount: 9,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Oba',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 31,
            chapterCount: 1,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Jon',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 32,
            chapterCount: 4,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Mic',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 33,
            chapterCount: 7,
            onSelectionUpdate: _onSelectingChapter,
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
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 34,
            chapterCount: 3,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Hab',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 35,
            chapterCount: 3,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Zep',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 36,
            chapterCount: 3,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Hag',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 37,
            chapterCount: 2,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Zec',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 38,
            chapterCount: 14,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Mal',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            bookId: 39,
            chapterCount: 4,
            onSelectionUpdate: _onSelectingChapter,
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
            title: 'Mat',
            color: BookChooser.gospelsColor,
            onTap: widget.onBookSelected,
            bookId: 40,
            chapterCount: 28,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Mrk',
            color: BookChooser.gospelsColor,
            onTap: widget.onBookSelected,
            bookId: 41,
            chapterCount: 16,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Luk',
            color: BookChooser.gospelsColor,
            onTap: widget.onBookSelected,
            bookId: 42,
            chapterCount: 24,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Jhn',
            color: BookChooser.gospelsColor,
            onTap: widget.onBookSelected,
            bookId: 43,
            chapterCount: 21,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Act',
            color: BookChooser.gospelsColor,
            onTap: widget.onBookSelected,
            bookId: 44,
            chapterCount: 28,
            onSelectionUpdate: _onSelectingChapter,
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
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            bookId: 45,
            chapterCount: 16,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '1Co',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            bookId: 46,
            chapterCount: 16,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '2Co',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            bookId: 47,
            chapterCount: 13,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Gal',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            bookId: 48,
            chapterCount: 6,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Eph',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            bookId: 49,
            chapterCount: 6,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Php',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            bookId: 50,
            chapterCount: 4,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Col',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            bookId: 51,
            chapterCount: 4,
            onSelectionUpdate: _onSelectingChapter,
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
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            bookId: 52,
            chapterCount: 5,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '2Th',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            bookId: 53,
            chapterCount: 3,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '1Ti',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            bookId: 54,
            chapterCount: 6,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '2Ti',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            bookId: 55,
            chapterCount: 4,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Tit',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            bookId: 56,
            chapterCount: 3,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Phm',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            bookId: 57,
            chapterCount: 1,
            onSelectionUpdate: _onSelectingChapter,
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
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            bookId: 58,
            chapterCount: 13,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Jas',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            bookId: 59,
            chapterCount: 5,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '1Pe',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            bookId: 60,
            chapterCount: 5,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '2Pe',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            bookId: 61,
            chapterCount: 3,
            onSelectionUpdate: _onSelectingChapter,
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
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            bookId: 62,
            chapterCount: 5,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '2Jn',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            bookId: 63,
            chapterCount: 1,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '3Jn',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            bookId: 64,
            chapterCount: 1,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Jud',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            bookId: 65,
            chapterCount: 1,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Rev',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            bookId: 66,
            chapterCount: 22,
            onSelectionUpdate: _onSelectingChapter,
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
    required this.color,
    required this.onTap,
    required this.bookId,
    required this.chapterCount,
    required this.onSelectionUpdate,
  });

  final String title;
  final Color color;
  final void Function(int bookId, int chapter) onTap;
  final int bookId;
  final int chapterCount;
  final void Function(int, int, ChapterSelectionState, Offset) onSelectionUpdate;

  @override
  State<BookItem> createState() => _BookItemState();
}

class _BookItemState extends State<BookItem> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: widget.color,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: InkWell(
            onTap: () => widget.onTap(widget.bookId, 1),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(width: 0.5),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.black87,
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

  void _onPanStart(DragStartDetails details) {
    widget.onSelectionUpdate(
      widget.bookId,
      widget.chapterCount,
      ChapterSelectionState.start,
      details.globalPosition,
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    widget.onSelectionUpdate(
      widget.bookId,
      widget.chapterCount,
      ChapterSelectionState.selecting,
      details.globalPosition,
    );
  }

  void _onPanEnd(DragEndDetails details) {
    widget.onSelectionUpdate(
      widget.bookId,
      widget.chapterCount,
      ChapterSelectionState.end,
      details.globalPosition,
    );
  }
}
