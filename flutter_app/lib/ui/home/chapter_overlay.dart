import 'dart:math';

import 'package:flutter/material.dart';

class ChapterOverlay extends StatefulWidget {
  const ChapterOverlay({
    super.key,
    required this.bookId,
    required this.chapterCount,
    required this.startOffset,
    required this.currentOffset,
    required this.onChapterSelected,
  });

  final int bookId;
  final int chapterCount;
  final Offset startOffset;
  final Offset currentOffset;
  final void Function(int? chapter) onChapterSelected;

  @override
  State<ChapterOverlay> createState() => _ChapterOverlayState();
}

class _ChapterOverlayState extends State<ChapterOverlay> {
  bool _isBeforeJob = false;
  // Less than 10 chapters: that means the grid will not have an empty cell
  // at index 0.
  bool _isShortBook = false;
  int? _lastSelectedChapter;
  int? _selectedChapter;
  Offset? _offset;
  late double _verticalPadding;
  late double _horizontalPadding;
  late double _gridWidth;
  late int _rowCount;
  late int _columnCount;
  late double _rowHeight;
  late double _columnWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateDimensions();
  }

  void _calculateDimensions() {
    _isBeforeJob = widget.bookId < 18;
    _rowCount = ((widget.chapterCount + 1) / 10).ceil();
    _isShortBook = widget.chapterCount < 10;
    _columnCount = _isShortBook ? widget.chapterCount : 10;

    final screenSize = MediaQuery.of(context).size;
    _gridWidth = min(screenSize.width, screenSize.height) * 0.9;
    _rowHeight = (widget.bookId == _psalms) //
        ? _gridWidth / _rowCount
        : _gridWidth / 10;
    _columnWidth = _gridWidth / _columnCount;
    final gridHeight = _rowHeight * _rowCount;
    _verticalPadding = (screenSize.height - gridHeight) / 2;
    _horizontalPadding = (screenSize.width - _gridWidth) / 2;
  }

  @override
  void didUpdateWidget(ChapterOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setOffset();
    _selectedChapter = _findSelectedChapter();
    if (_selectedChapter != _lastSelectedChapter) {
      _lastSelectedChapter = _selectedChapter;
      if (_isValidChapter(_selectedChapter)) {
        widget.onChapterSelected(_selectedChapter);
      } else {
        widget.onChapterSelected(null);
      }
    }
  }

  bool _isValidChapter(int? chapter) {
    return chapter != null && chapter > 0 && chapter <= widget.chapterCount;
  }

  void _setOffset() {
    _offset = widget.currentOffset;

    final dx = widget.startOffset.dx;
    final dy = widget.startOffset.dy;
    final gridRight = _horizontalPadding + _gridWidth;
    final gridBottom = _verticalPadding + _rowHeight * _rowCount;

    double offsetX = widget.currentOffset.dx;
    double offsetY = widget.currentOffset.dy;

    // Handle X axis
    if (dx < _horizontalPadding) {
      offsetX += _horizontalPadding - dx + _columnWidth / 2;
    } else if (dx > gridRight) {
      offsetX -= dx - gridRight + _columnWidth / 2;
    }

    // Handle Y axis
    if (dy < _verticalPadding) {
      offsetY += _verticalPadding - dy + _rowHeight / 2;
    } else if (dy > gridBottom) {
      offsetY -= dy - gridBottom + _rowHeight / 2;
    }

    if (offsetX != widget.currentOffset.dx || offsetY != widget.currentOffset.dy) {
      _offset = Offset(offsetX, offsetY);
    }
    print('offset: $_offset');
  }

  static const _psalms = 19;

  int? _findSelectedChapter() {
    final offset = _offset;
    if (offset == null) {
      return null;
    }
    final max = _rowCount * _columnCount;
    final start = _isShortBook ? 1 : 0;
    for (int index = start; index <= max; index++) {
      // for (int index = 1; index <= widget.chapterCount; index++) {
      final adjustedIndex = _isShortBook ? index - 1 : index;
      final cellX = _horizontalPadding + (adjustedIndex % _columnCount) * _columnWidth;
      final cellY = _verticalPadding + (index ~/ 10) * _rowHeight;
      final row = index ~/ 10;

      final isInXBounds = offset.dx > cellX && offset.dx < cellX + _columnWidth;

      bool isInYBounds;
      if (row == 0) {
        isInYBounds = offset.dy <= cellY + _rowHeight;
      } else if (row == (_rowCount - 1)) {
        isInYBounds = offset.dy >= cellY;
      } else {
        isInYBounds = offset.dy >= cellY && offset.dy < cellY + _rowHeight;
      }

      if (isInXBounds && isInYBounds) {
        return index;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final offset = _isBeforeJob ? 1.0 : -1.0;
    final chapterLabel = _isValidChapter(_selectedChapter) ? '$_selectedChapter' : '';
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
            margin: EdgeInsets.all(min(_horizontalPadding, _verticalPadding)),
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
              // itemCount: _isShortBook ? widget.chapterCount : widget.chapterCount + 1,
              itemCount: _isShortBook ? widget.chapterCount : _rowCount * _columnCount,
              itemBuilder: (context, index) {
                final chapter = (_isShortBook) ? index + 1 : index;

                // if (!_isShortBook && index == 0) {
                //   return const SizedBox();
                // }
                final isSelected = _selectedChapter == chapter;
                final label = chapter == 0 || chapter > widget.chapterCount ? '' : '$chapter';

                return Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.3) : null,
                  ),
                  child: Center(
                    child: Text(
                      label,
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
