import 'package:bsb/ui/home/chapter_chooser.dart';
import 'package:flutter/material.dart';

enum ChapterSelectionState {
  start,
  selecting,
  end,
}

class BookChooser extends StatefulWidget {
  const BookChooser({
    super.key,
    required this.onSelected,
  });

  final void Function(int bookId, int chapter) onSelected;

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
        ValueListenableBuilder<(int, int)?>(
          valueListenable: _chapterNotifier,
          builder: (context, bookChapter, child) {
            if (bookChapter == null) {
              return const SizedBox();
            }
            final (bookId, chapterCount) = bookChapter;
            return ChapterChooser(
              chapterCount: chapterCount,
              onChapterSelected: (chapter) {
                _chapterNotifier.value = null;
                if (chapter == null) return;
                widget.onSelected(bookId, chapter);
              },
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
            color: pentateuchColor,
            onTap: _onBookSelected,
            bookId: 1,
            chapterCount: 50,
          ),
          BookItem(
            title: 'Exo',
            color: pentateuchColor,
            onTap: _onBookSelected,
            bookId: 2,
            chapterCount: 40,
          ),
          BookItem(
            title: 'Lev',
            color: pentateuchColor,
            onTap: _onBookSelected,
            bookId: 3,
            chapterCount: 27,
          ),
          BookItem(
            title: 'Num',
            color: pentateuchColor,
            onTap: _onBookSelected,
            bookId: 4,
            chapterCount: 36,
          ),
          BookItem(
            title: 'Deut',
            color: pentateuchColor,
            onTap: _onBookSelected,
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
            bookId: 6,
            chapterCount: 24,
          ),
          BookItem(
            title: 'Judg',
            color: historicalColor,
            onTap: _onBookSelected,
            bookId: 7,
            chapterCount: 21,
          ),
          BookItem(
            title: 'Ruth',
            color: historicalColor,
            onTap: _onBookSelected,
            bookId: 8,
            chapterCount: 4,
          ),
          BookItem(
            title: '1Sam',
            color: historicalColor,
            onTap: _onBookSelected,
            bookId: 9,
            chapterCount: 31,
          ),
          BookItem(
            title: '2Sam',
            color: historicalColor,
            onTap: _onBookSelected,
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
            bookId: 11,
            chapterCount: 22,
          ),
          BookItem(
            title: '2Ki',
            color: historicalColor,
            onTap: _onBookSelected,
            bookId: 12,
            chapterCount: 25,
          ),
          BookItem(
            title: '1Ch',
            color: historicalColor,
            onTap: _onBookSelected,
            bookId: 13,
            chapterCount: 29,
          ),
          BookItem(
            title: '2Ch',
            color: historicalColor,
            onTap: _onBookSelected,
            bookId: 14,
            chapterCount: 36,
          ),
          BookItem(
            title: 'Ezra',
            color: historicalColor,
            onTap: _onBookSelected,
            bookId: 15,
            chapterCount: 10,
          ),
          BookItem(
            title: 'Neh',
            color: historicalColor,
            onTap: _onBookSelected,
            bookId: 16,
            chapterCount: 13,
          ),
          BookItem(
            title: 'Est',
            color: historicalColor,
            onTap: _onBookSelected,
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
            bookId: 18,
            chapterCount: 42,
          ),
          BookItem(
            title: 'Psa',
            color: wisdomColor,
            onTap: _onBookSelected,
            bookId: 19,
            chapterCount: 150,
          ),
          BookItem(
            title: 'Prov',
            color: wisdomColor,
            onTap: _onBookSelected,
            bookId: 20,
            chapterCount: 31,
          ),
          BookItem(
            title: 'Eccl',
            color: wisdomColor,
            onTap: _onBookSelected,
            bookId: 21,
            chapterCount: 12,
          ),
          BookItem(
            title: 'Song',
            color: wisdomColor,
            onTap: _onBookSelected,
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
            bookId: 23,
            chapterCount: 66,
          ),
          BookItem(
            title: 'Jer',
            color: majorProphetsColor,
            onTap: _onBookSelected,
            bookId: 24,
            chapterCount: 52,
          ),
          BookItem(
            title: 'Lam',
            color: majorProphetsColor,
            onTap: _onBookSelected,
            bookId: 25,
            chapterCount: 5,
          ),
          BookItem(
            title: 'Ezek',
            color: majorProphetsColor,
            onTap: _onBookSelected,
            bookId: 26,
            chapterCount: 48,
          ),
          BookItem(
            title: 'Dan',
            color: majorProphetsColor,
            onTap: _onBookSelected,
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
            bookId: 28,
            chapterCount: 14,
          ),
          BookItem(
            title: 'Joel',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            bookId: 29,
            chapterCount: 3,
          ),
          BookItem(
            title: 'Amos',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            bookId: 30,
            chapterCount: 9,
          ),
          BookItem(
            title: 'Oba',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            bookId: 31,
            chapterCount: 1,
          ),
          BookItem(
            title: 'Jon',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            bookId: 32,
            chapterCount: 4,
          ),
          BookItem(
            title: 'Mic',
            color: minorProphetsColor,
            onTap: _onBookSelected,
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
            bookId: 34,
            chapterCount: 3,
          ),
          BookItem(
            title: 'Hab',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            bookId: 35,
            chapterCount: 3,
          ),
          BookItem(
            title: 'Zeph',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            bookId: 36,
            chapterCount: 3,
          ),
          BookItem(
            title: 'Hag',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            bookId: 37,
            chapterCount: 2,
          ),
          BookItem(
            title: 'Zec',
            color: minorProphetsColor,
            onTap: _onBookSelected,
            bookId: 38,
            chapterCount: 14,
          ),
          BookItem(
            title: 'Mal',
            color: minorProphetsColor,
            onTap: _onBookSelected,
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
            bookId: 40,
            chapterCount: 28,
          ),
          BookItem(
            title: 'Mark',
            color: gospelsColor,
            onTap: _onBookSelected,
            bookId: 41,
            chapterCount: 16,
          ),
          BookItem(
            title: 'Luke',
            color: gospelsColor,
            onTap: _onBookSelected,
            bookId: 42,
            chapterCount: 24,
          ),
          BookItem(
            title: 'John',
            color: gospelsColor,
            onTap: _onBookSelected,
            bookId: 43,
            chapterCount: 21,
          ),
          BookItem(
            title: 'Acts',
            color: gospelsColor,
            onTap: _onBookSelected,
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
            bookId: 45,
            chapterCount: 16,
          ),
          BookItem(
            title: '1Co',
            color: paulineColor,
            onTap: _onBookSelected,
            bookId: 46,
            chapterCount: 16,
          ),
          BookItem(
            title: '2Co',
            color: paulineColor,
            onTap: _onBookSelected,
            bookId: 47,
            chapterCount: 13,
          ),
          BookItem(
            title: 'Gal',
            color: paulineColor,
            onTap: _onBookSelected,
            bookId: 48,
            chapterCount: 6,
          ),
          BookItem(
            title: 'Eph',
            color: paulineColor,
            onTap: _onBookSelected,
            bookId: 49,
            chapterCount: 6,
          ),
          BookItem(
            title: 'Php',
            color: paulineColor,
            onTap: _onBookSelected,
            bookId: 50,
            chapterCount: 4,
          ),
          BookItem(
            title: 'Col',
            color: paulineColor,
            onTap: _onBookSelected,
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
            bookId: 52,
            chapterCount: 5,
          ),
          BookItem(
            title: '2Th',
            color: paulineColor,
            onTap: _onBookSelected,
            bookId: 53,
            chapterCount: 3,
          ),
          BookItem(
            title: '1Ti',
            color: paulineColor,
            onTap: _onBookSelected,
            bookId: 54,
            chapterCount: 6,
          ),
          BookItem(
            title: '2Ti',
            color: paulineColor,
            onTap: _onBookSelected,
            bookId: 55,
            chapterCount: 4,
          ),
          BookItem(
            title: 'Tit',
            color: paulineColor,
            onTap: _onBookSelected,
            bookId: 56,
            chapterCount: 3,
          ),
          BookItem(
            title: 'Phm',
            color: paulineColor,
            onTap: _onBookSelected,
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
            bookId: 58,
            chapterCount: 13,
          ),
          BookItem(
            title: 'James',
            color: generalEpistlesColor,
            onTap: _onBookSelected,
            bookId: 59,
            chapterCount: 5,
          ),
          BookItem(
            title: '1Pet',
            color: generalEpistlesColor,
            onTap: _onBookSelected,
            bookId: 60,
            chapterCount: 5,
          ),
          BookItem(
            title: '2Pet',
            color: generalEpistlesColor,
            onTap: _onBookSelected,
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
            bookId: 62,
            chapterCount: 5,
          ),
          BookItem(
            title: '2Jn',
            color: generalEpistlesColor,
            onTap: _onBookSelected,
            bookId: 63,
            chapterCount: 1,
          ),
          BookItem(
            title: '3Jn',
            color: generalEpistlesColor,
            onTap: _onBookSelected,
            bookId: 64,
            chapterCount: 1,
          ),
          BookItem(
            title: 'Jude',
            color: generalEpistlesColor,
            onTap: _onBookSelected,
            bookId: 65,
            chapterCount: 1,
          ),
          BookItem(
            title: 'Rev',
            color: generalEpistlesColor,
            onTap: _onBookSelected,
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
    required this.color,
    required this.onTap,
    required this.bookId,
    required this.chapterCount,
  });

  final String title;
  final Color color;
  final void Function(int bookId, int chapterCount) onTap;
  final int bookId;
  final int chapterCount;

  @override
  State<BookItem> createState() => _BookItemState();
}

class _BookItemState extends State<BookItem> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: widget.color,
        child: InkWell(
          onTap: () => widget.onTap(widget.bookId, widget.chapterCount),
          // Setting the chapter count to 1 is a hack to go directly to chapter
          // 1 without showing the chapter chooser.
          onDoubleTap: () => widget.onTap(widget.bookId, 1),
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
                    fontSize: 17,
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
