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
  bool _isOT = false;
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
    _columnCount = widget.chapterCount >= 10 ? 10 : widget.chapterCount;
    _rowHeight = _rowCount > 10 ? _gridWidth / 15 : _gridWidth / 10;
    _cellWidth = _gridWidth / 10;
  }

  @override
  void didUpdateWidget(ChapterOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isOT = widget.bookId <= 39;
    _selectedChapter = _findSelectedChapter();
    if (_selectedChapter != _lastSelectedChapter) {
      _lastSelectedChapter = _selectedChapter;
      widget.onChapterSelected(_selectedChapter);
    }
  }

  int? _findSelectedChapter() {
    for (int index = 1; index <= widget.chapterCount; index++) {
      final cellX = (index % 10) * _cellWidth + _padding;
      final cellY = (index ~/ 10) * _rowHeight - _rowHeight / 2;

      if (widget.offset.dx >= cellX &&
          widget.offset.dx < cellX + _cellWidth &&
          widget.offset.dy >= cellY &&
          widget.offset.dy < cellY + _rowHeight) {
        return index;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // final screenWidth = MediaQuery.of(context).size.width;
    // final padding = screenWidth * 0.05;
    // final gridWidth = screenWidth - padding * 2;
    // final int rowCount = ((widget.chapterCount + 1) / 10).ceil();
    // final int columnCount = widget.chapterCount >= 10 ? 10 : widget.chapterCount;
    // final double rowHeight = rowCount > 10 ? gridWidth / 15 : gridWidth / 10;
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
                childAspectRatio: _rowCount > 10 //
                    ? (_gridWidth / 10) / _rowHeight
                    : 1.0,
              ),
              itemCount: widget.chapterCount + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const SizedBox();
                }
                final isSelected = _selectedChapter == index;
                return Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.3) : null,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
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
        // (_isOT) ? chapterWidget : const Spacer(),
      ],
    );
  }
}
