import 'package:flutter/material.dart';

class ChapterOverlay extends StatefulWidget {
  const ChapterOverlay({
    super.key,
    required this.bookId,
    required this.chapterCount,
    required this.offset,
    required this.onChapterSelected,
  });

  final int bookId;
  final int chapterCount;
  final Offset offset;
  final void Function(int? chapter) onChapterSelected;

  @override
  State<ChapterOverlay> createState() => _ChapterOverlayState();
}

class _ChapterOverlayState extends State<ChapterOverlay> {
  late bool _isOT;
  // Less than 10 chapters: that means the grid will not have an empty cell
  // at index 0.
  late bool _isShortBook;
  int? _lastSelectedChapter;
  int? _selectedChapter;
  late double _padding;
  late double _gridWidth;
  late int _rowCount;
  late int _columnCount;
  late double _rowHeight;
  late double _cellWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateDimensions();
  }

  void _calculateDimensions() {
    final screenWidth = MediaQuery.of(context).size.width;
    _padding = screenWidth * 0.05;
    _gridWidth = screenWidth - _padding * 2;
    _rowCount = ((widget.chapterCount + 1) / 10).ceil();
    _columnCount = widget.chapterCount < 10 ? widget.chapterCount : 10;
    _rowHeight = _rowCount > 10 ? _gridWidth / 15 : _gridWidth / 10;
    _cellWidth = _gridWidth / _columnCount;
  }

  @override
  void didUpdateWidget(ChapterOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isOT = widget.bookId <= 39;
    _isShortBook = widget.chapterCount < 10;
    _selectedChapter = _findSelectedChapter();
    if (_selectedChapter != _lastSelectedChapter) {
      _lastSelectedChapter = _selectedChapter;
      widget.onChapterSelected(_selectedChapter);
    }
  }

  static const _hebrews = 58;
  static const _revelation = 66;

  int? _findSelectedChapter() {
    var dy = widget.offset.dy;

    // Hebrews and Revelation should start the selection on the bottom row.
    if (widget.bookId == _hebrews) {
      dy += _rowHeight;
    } else if (widget.bookId == _revelation) {
      dy += _rowHeight * 2;
    }

    final gridTop = -_rowHeight / 2;
    final gridBottom = _rowCount * _rowHeight - _rowHeight;
    final clampedY = dy.clamp(gridTop, gridBottom);

    for (int index = 1; index <= widget.chapterCount; index++) {
      // subtract 1 cell width to account for the missing empty cell at index 0.
      final oneCell = _isShortBook ? _cellWidth : 0.0;
      final cellX = (index % 10) * _cellWidth + _padding - oneCell;
      var cellY = (index ~/ 10) * _rowHeight - _rowHeight / 2;

      if (widget.offset.dx >= cellX &&
          widget.offset.dx < cellX + _cellWidth &&
          clampedY >= cellY &&
          clampedY < cellY + _rowHeight) {
        return index;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final offset = _isOT ? 0.7 : -0.7;
    final chapterLabel = (_selectedChapter == null) ? '' : '$_selectedChapter';
    return Stack(
      children: [
        Align(
          alignment: Alignment(0.0, offset),
          child: Text(
            chapterLabel,
            style: const TextStyle(
              fontSize: 100,
              color: Colors.black,
            ),
          ),
        ),
        Center(
          child: Container(
            margin: EdgeInsets.all(_padding),
            width: _gridWidth,
            height: _rowHeight * _rowCount,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _columnCount,
                childAspectRatio: (_gridWidth / _columnCount) / _rowHeight,
              ),
              itemCount: _isShortBook ? widget.chapterCount : widget.chapterCount + 1,
              itemBuilder: (context, index) {
                final chapter = (_isShortBook) ? index + 1 : index;

                if (!_isShortBook && index == 0) {
                  return const SizedBox();
                }
                final isSelected = _selectedChapter == chapter;
                return Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.3) : null,
                  ),
                  child: Center(
                    child: Text(
                      '$chapter',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
