import 'dart:math';

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
  final _chapterNotifier = ValueNotifier<String>('');
  bool _isOT = false;

  Offset _startPanPosition = const Offset(0, 0);
  int _lastChapter = -1;

  void _onSelectingChapter(
    String book,
    int chapterCount,
    ChapterSelectionState selectionState,
    Offset? offset,
  ) {
    final bookId = _bookIdFromAbbreviation(book);
    _isOT = bookId <= 39;
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
    _lastChapter = -1;
  }

  void _onSelectionUpdate(Offset offset, int chapterCount) {
    _locationNotifier.value = (chapterCount, offset);
    final currentPosition = offset;
    final relativePosition = currentPosition - _startPanPosition;
    final screenSize = MediaQuery.sizeOf(context);
    final maxPanLength = min(screenSize.width, screenSize.height) / 2 - 20;
    final percentX = (relativePosition.dx / maxPanLength).clamp(-1.0, 1.0).abs();
    final percentY = (relativePosition.dy / maxPanLength).clamp(-1.0, 1.0).abs();

    int units = (9 * percentX).round();
    final maxTens = chapterCount ~/ 10;
    final verticalIncrements = max(maxTens, 10); // 15 for Psalms
    int tens = (verticalIncrements * percentY).round().clamp(0, maxTens);

    final chapter = (10 * tens + units).clamp(1, chapterCount);
    if (chapter == _lastChapter) {
      return;
    }
    _lastChapter = chapter;

    _chapterNotifier.value = '$chapter';
  }

  void _onSelectionEnd(int bookId) {
    _locationNotifier.value = null;
    _chapterNotifier.value = '';
    if (_lastChapter < 1) {
      return;
    }
    widget.onBookSelected(bookId, _lastChapter);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final maxPanLength = min(screenSize.width, screenSize.height) / 2 - 20;
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
        ValueListenableBuilder<String>(
          valueListenable: _chapterNotifier,
          builder: (context, chapter, child) {
            final offset = _isOT ? 0.5 : -0.5;
            return Align(
              alignment: Alignment(0.0, offset),
              child: Text(
                chapter,
                style: const TextStyle(
                  fontSize: 100,
                  color: Colors.black,
                ),
              ),
            );
          },
        ),
        ValueListenableBuilder<(int, Offset)?>(
          valueListenable: _locationNotifier,
          builder: (context, data, child) {
            if (data == null) {
              return const SizedBox();
            }
            final (chapterCount, location) = data;
            // final item = Container(width: 30, height: 30, color: Colors.red);
            return Positioned(
              left: _startPanPosition.dx,
              top: _startPanPosition.dy,
              child: ChapterOverlay(
                chapterCount: chapterCount,
                localOffset: location - _startPanPosition,
                width: maxPanLength,
                onChapterSelected: (chapter) {},
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
            chapterCount: 50,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Exo',
            color: BookChooser.pentateuchColor,
            onTap: widget.onBookSelected,
            chapterCount: 40,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Lev',
            color: BookChooser.pentateuchColor,
            onTap: widget.onBookSelected,
            chapterCount: 27,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Num',
            color: BookChooser.pentateuchColor,
            onTap: widget.onBookSelected,
            chapterCount: 36,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Deu',
            color: BookChooser.pentateuchColor,
            onTap: widget.onBookSelected,
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
            chapterCount: 24,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Jdg',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 21,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Rut',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 4,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '1Sa',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 31,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '2Sa',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
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
            chapterCount: 22,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '2Ki',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 25,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '1Ch',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 29,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '2Ch',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 36,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Ezr',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 10,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Neh',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 13,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Est',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
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
            chapterCount: 42,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Psa',
            color: BookChooser.wisdomColor,
            onTap: widget.onBookSelected,
            chapterCount: 150,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Pro',
            color: BookChooser.wisdomColor,
            onTap: widget.onBookSelected,
            chapterCount: 31,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Ecc',
            color: BookChooser.wisdomColor,
            onTap: widget.onBookSelected,
            chapterCount: 12,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Sng',
            color: BookChooser.wisdomColor,
            onTap: widget.onBookSelected,
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
            chapterCount: 66,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Jer',
            color: BookChooser.majorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 52,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Lam',
            color: BookChooser.majorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 5,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Ezk',
            color: BookChooser.majorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 48,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Dan',
            color: BookChooser.majorProphetsColor,
            onTap: widget.onBookSelected,
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
            chapterCount: 14,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Jol',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 3,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Amo',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 9,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Oba',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 1,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Jon',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 4,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Mic',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
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
            chapterCount: 3,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Hab',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 3,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Zep',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 3,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Hag',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 2,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Zec',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 14,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Mal',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
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
            chapterCount: 28,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Mrk',
            color: BookChooser.gospelsColor,
            onTap: widget.onBookSelected,
            chapterCount: 16,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Luk',
            color: BookChooser.gospelsColor,
            onTap: widget.onBookSelected,
            chapterCount: 24,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Jhn',
            color: BookChooser.gospelsColor,
            onTap: widget.onBookSelected,
            chapterCount: 21,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Act',
            color: BookChooser.gospelsColor,
            onTap: widget.onBookSelected,
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
            chapterCount: 16,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '1Co',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 16,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '2Co',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 13,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Gal',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 6,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Eph',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 6,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Php',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 4,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Col',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
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
            chapterCount: 5,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '2Th',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 3,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '1Ti',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 6,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '2Ti',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 4,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Tit',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 3,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Phm',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
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
            chapterCount: 13,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Jas',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            chapterCount: 5,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '1Pe',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            chapterCount: 5,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '2Pe',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
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
            chapterCount: 5,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '2Jn',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            chapterCount: 1,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: '3Jn',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            chapterCount: 1,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Jud',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            chapterCount: 1,
            onSelectionUpdate: _onSelectingChapter,
          ),
          BookItem(
            title: 'Rev',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
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
    required this.chapterCount,
    required this.onSelectionUpdate,
  });

  final String title;
  final Color color;
  final void Function(int bookId, int chapter) onTap;
  final int chapterCount;
  final void Function(String, int, ChapterSelectionState, Offset) onSelectionUpdate;

  @override
  State<BookItem> createState() => _BookItemState();
}

class _BookItemState extends State<BookItem> {
  Offset _startPanPosition = const Offset(0, 0);
  int _lastChapter = -1;

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
            onTap: () {
              final bookId = _bookIdFromAbbreviation(widget.title);
              widget.onTap(bookId, 1);
            },
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
      widget.title,
      widget.chapterCount,
      ChapterSelectionState.start,
      details.globalPosition,
    );
    // _startPanPosition = details.globalPosition;
    // _lastChapter = -1;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    widget.onSelectionUpdate(
      widget.title,
      widget.chapterCount,
      ChapterSelectionState.selecting,
      details.globalPosition,
    );

    // final currentPosition = details.globalPosition;
    // final relativePosition = currentPosition - _startPanPosition;
    // final screenSize = MediaQuery.sizeOf(context);
    // final maxPanLength = min(screenSize.width, screenSize.height) / 2 - 20;
    // final percentX = (relativePosition.dx / maxPanLength).clamp(-1.0, 1.0).abs();
    // final percentY = (relativePosition.dy / maxPanLength).clamp(-1.0, 1.0).abs();

    // int units = (9 * percentX).round();
    // final maxTens = widget.chapterCount ~/ 10;
    // final verticalIncrements = max(maxTens, 10); // 15 for Psalms
    // int tens = (verticalIncrements * percentY).round().clamp(0, maxTens);

    // final chapter = (10 * tens + units).clamp(1, widget.chapterCount);
    // if (chapter == _lastChapter) {
    //   return;
    // }
    // _lastChapter = chapter;

    // widget.onSelectionUpdate(
    //   widget.title,
    //   chapter,
    //   ChapterSelectionState.selecting,
    // );
  }

  void _onPanEnd(DragEndDetails details) {
    widget.onSelectionUpdate(
      widget.title,
      widget.chapterCount,
      ChapterSelectionState.end,
      details.globalPosition,
    );
    // widget.onSelectionUpdate(
    //   widget.title,
    //   _lastChapter,
    //   ChapterSelectionState.end,
    // );
  }
}

int _bookIdFromAbbreviation(String abbreviation) {
  final caps = abbreviation.toUpperCase();
  return _bookIdMap[caps]!;
}

final _bookIdMap = {
  'GEN': 1,
  'EXO': 2,
  'LEV': 3,
  'NUM': 4,
  'DEU': 5,
  'JOS': 6,
  'JDG': 7,
  'RUT': 8,
  '1SA': 9,
  '2SA': 10,
  '1KI': 11,
  '2KI': 12,
  '1CH': 13,
  '2CH': 14,
  'EZR': 15,
  'NEH': 16,
  'EST': 17,
  'JOB': 18,
  'PSA': 19,
  'PRO': 20,
  'ECC': 21,
  'SNG': 22,
  'ISA': 23,
  'JER': 24,
  'LAM': 25,
  'EZK': 26,
  'DAN': 27,
  'HOS': 28,
  'JOL': 29,
  'AMO': 30,
  'OBA': 31,
  'JON': 32,
  'MIC': 33,
  'NAM': 34,
  'HAB': 35,
  'ZEP': 36,
  'HAG': 37,
  'ZEC': 38,
  'MAL': 39,
  'MAT': 40,
  'MRK': 41,
  'LUK': 42,
  'JHN': 43,
  'ACT': 44,
  'ROM': 45,
  '1CO': 46,
  '2CO': 47,
  'GAL': 48,
  'EPH': 49,
  'PHP': 50,
  'COL': 51,
  '1TH': 52,
  '2TH': 53,
  '1TI': 54,
  '2TI': 55,
  'TIT': 56,
  'PHM': 57,
  'HEB': 58,
  'JAS': 59,
  '1PE': 60,
  '2PE': 61,
  '1JN': 62,
  '2JN': 63,
  '3JN': 64,
  'JUD': 65,
  'REV': 66
};
