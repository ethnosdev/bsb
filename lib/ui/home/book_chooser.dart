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

  final void Function(String) onBookSelected;

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
  final _chapterNotifier = ValueNotifier<String>('');

  void onSelectingChapter(
    String book,
    int chapter,
    ChapterSelectionState selectionState,
  ) {
    switch (selectionState) {
      case ChapterSelectionState.start:
        print('start');
      case ChapterSelectionState.selecting:
        _chapterNotifier.value = '$chapter';
        break;
      case ChapterSelectionState.end:
        print('end');
        _chapterNotifier.value = '';
    }
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
        ValueListenableBuilder<String>(
          valueListenable: _chapterNotifier,
          builder: (context, chapter, child) {
            return Center(
              child: Text(chapter, style: const TextStyle(fontSize: 100)),
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
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Exo',
            color: BookChooser.pentateuchColor,
            onTap: widget.onBookSelected,
            chapterCount: 40,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Lev',
            color: BookChooser.pentateuchColor,
            onTap: widget.onBookSelected,
            chapterCount: 27,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Num',
            color: BookChooser.pentateuchColor,
            onTap: widget.onBookSelected,
            chapterCount: 36,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Deu',
            color: BookChooser.pentateuchColor,
            onTap: widget.onBookSelected,
            chapterCount: 34,
            onSelectionUpdate: onSelectingChapter,
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
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Jdg',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 21,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Rut',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 4,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: '1Sa',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 31,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: '2Sa',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 24,
            onSelectionUpdate: onSelectingChapter,
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
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: '2Ki',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 25,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: '1Ch',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 29,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: '2Ch',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 36,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Ezr',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 10,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Neh',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 13,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Est',
            color: BookChooser.historicalColor,
            onTap: widget.onBookSelected,
            chapterCount: 10,
            onSelectionUpdate: onSelectingChapter,
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
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Psa',
            color: BookChooser.wisdomColor,
            onTap: widget.onBookSelected,
            chapterCount: 150,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Pro',
            color: BookChooser.wisdomColor,
            onTap: widget.onBookSelected,
            chapterCount: 31,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Ecc',
            color: BookChooser.wisdomColor,
            onTap: widget.onBookSelected,
            chapterCount: 12,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Sng',
            color: BookChooser.wisdomColor,
            onTap: widget.onBookSelected,
            chapterCount: 8,
            onSelectionUpdate: onSelectingChapter,
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
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Jer',
            color: BookChooser.majorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 52,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Lam',
            color: BookChooser.majorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 5,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Ezk',
            color: BookChooser.majorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 48,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Dan',
            color: BookChooser.majorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 12,
            onSelectionUpdate: onSelectingChapter,
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
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Jol',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 3,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Amo',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 9,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Oba',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 1,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Jon',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 4,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Mic',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 7,
            onSelectionUpdate: onSelectingChapter,
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
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Hab',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 3,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Zep',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 3,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Hag',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 2,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Zec',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 14,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Mal',
            color: BookChooser.minorProphetsColor,
            onTap: widget.onBookSelected,
            chapterCount: 4,
            onSelectionUpdate: onSelectingChapter,
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
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Mrk',
            color: BookChooser.gospelsColor,
            onTap: widget.onBookSelected,
            chapterCount: 16,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Luk',
            color: BookChooser.gospelsColor,
            onTap: widget.onBookSelected,
            chapterCount: 24,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Jhn',
            color: BookChooser.gospelsColor,
            onTap: widget.onBookSelected,
            chapterCount: 21,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Act',
            color: BookChooser.gospelsColor,
            onTap: widget.onBookSelected,
            chapterCount: 28,
            onSelectionUpdate: onSelectingChapter,
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
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: '1Co',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 16,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: '2Co',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 13,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Gal',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 6,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Eph',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 6,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Php',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 4,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Col',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 4,
            onSelectionUpdate: onSelectingChapter,
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
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: '2Th',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 3,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: '1Ti',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 6,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: '2Ti',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 4,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Tit',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 3,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Phm',
            color: BookChooser.paulineColor,
            onTap: widget.onBookSelected,
            chapterCount: 1,
            onSelectionUpdate: onSelectingChapter,
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
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Jas',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            chapterCount: 5,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: '1Pe',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            chapterCount: 5,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: '2Pe',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            chapterCount: 3,
            onSelectionUpdate: onSelectingChapter,
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
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: '2Jn',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            chapterCount: 1,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: '3Jn',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            chapterCount: 1,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Jud',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            chapterCount: 1,
            onSelectionUpdate: onSelectingChapter,
          ),
          BookItem(
            title: 'Rev',
            color: BookChooser.generalEpistlesColor,
            onTap: widget.onBookSelected,
            chapterCount: 22,
            onSelectionUpdate: onSelectingChapter,
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
  final void Function(String) onTap;
  final int chapterCount;
  final void Function(String, int, ChapterSelectionState) onSelectionUpdate;

  @override
  State<BookItem> createState() => _BookItemState();
}

class _BookItemState extends State<BookItem> {
  int _currentChapter = 1;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: widget.color,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPressStart: (details) {
            _currentChapter = 1;
            widget.onSelectionUpdate(widget.title, _currentChapter, ChapterSelectionState.start);
          },
          onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
            final distance = details.localOffsetFromOrigin.distance;
            final maxDistance = MediaQuery.of(context).size.width / 2;
            final chapter = ((distance / maxDistance) * widget.chapterCount).clamp(1, widget.chapterCount).round();
            widget.onSelectionUpdate(widget.title, chapter, ChapterSelectionState.selecting);
          },
          onLongPressEnd: (LongPressEndDetails details) {
            widget.onSelectionUpdate(widget.title, _currentChapter, ChapterSelectionState.end);
          },
          child: InkWell(
            onTap: () => widget.onTap(widget.title.toUpperCase()),
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
}
