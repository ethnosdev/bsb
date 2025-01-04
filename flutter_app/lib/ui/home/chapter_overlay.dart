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
    _rowCount = ((widget.chapterCount + 1) / 10).ceil();
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
    // _maxGridLength = minLength * 0.9;
    // final screenWidth = screenSize.width;
    // final screenHeight = screenSize.height;
    // if (screenSize.width > screenSize.height) {
    //   _verticalPadding = minLength * 0.05;
    //   _horizontalPadding = (screenSize.width - _maxGridLength) / 2;
    // } else {
    //   _horizontalPadding = minLength * 0.05;
    //   _verticalPadding = (screenSize.height - _maxGridLength) / 2;
    // }
    // _padding = minLength * 0.05;
    // final gridHeight = screenHeight - _padding * 2;

    // if (screenWidth > screenHeight) {
    //   _rowHeight = (screenHeight - _padding * 2) / _columnCount;
    // if (_rowCount > 10) {
    //   if (screenWidth > screenHeight) {
    //     _rowHeight = gridHeight / 16;
    //   } else {
    //     _rowHeight = _gridWidth / 16;
    //   }
    // } else {
    //   _rowHeight = _gridWidth / 10;
    // }
    // _rowHeight = _rowCount > 10 ? _gridWidth / 15 : _gridWidth / 10;
  }

  @override
  void didUpdateWidget(ChapterOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setOffset();
    _isBeforeJob = widget.bookId < 18;
    _isShortBook = widget.chapterCount < 10;
    _selectedChapter = _findSelectedChapter();
    if (_selectedChapter != _lastSelectedChapter) {
      _lastSelectedChapter = _selectedChapter;
      widget.onChapterSelected(_selectedChapter);
    }
  }

  void _setOffset() {
    // if start offset is within the grid, then use that as the offset.
    _offset = widget.currentOffset;

    // Case 1: Above
    if (widget.startOffset.dy < _verticalPadding) {
      _offset = Offset(
        widget.currentOffset.dx,
        widget.currentOffset.dy + _verticalPadding - widget.startOffset.dy + _rowHeight / 2,
      );
    }

    // Case 2: Below
    if (widget.startOffset.dy > _verticalPadding + _rowHeight * _rowCount) {
      _offset = Offset(
        widget.currentOffset.dx,
        widget.currentOffset.dy - (widget.startOffset.dy - _verticalPadding - _rowHeight * _rowCount) - _rowHeight / 2,
      );
    }

    // Case 3: Left
    if (widget.startOffset.dx < _horizontalPadding) {
      _offset = Offset(
        widget.currentOffset.dx + _horizontalPadding - widget.startOffset.dx + _columnWidth / 2,
        widget.currentOffset.dy,
      );
    }

    // Case 4: Right
    if (widget.startOffset.dx > _horizontalPadding + _gridWidth) {
      _offset = Offset(
        widget.currentOffset.dx - (widget.startOffset.dx - _horizontalPadding - _gridWidth) - _columnWidth / 2,
        widget.currentOffset.dy,
      );
    }

    // Case 5: Top-Left
    if (widget.startOffset.dx < _horizontalPadding && widget.startOffset.dy < _verticalPadding) {
      _offset = Offset(
        widget.currentOffset.dx + _horizontalPadding - widget.startOffset.dx + _columnWidth / 2,
        widget.currentOffset.dy + _verticalPadding - widget.startOffset.dy + _rowHeight / 2,
      );
    }

    // Case 6: Top-Right
    if (widget.startOffset.dx > _horizontalPadding + _gridWidth && widget.startOffset.dy < _verticalPadding) {
      _offset = Offset(
        widget.currentOffset.dx - (widget.startOffset.dx - _horizontalPadding - _gridWidth) - _columnWidth / 2,
        widget.currentOffset.dy + _verticalPadding - widget.startOffset.dy + _rowHeight / 2,
      );
    }

    // Case 7: Bottom-Left
    if (widget.startOffset.dx < _horizontalPadding &&
        widget.startOffset.dy > _verticalPadding + _rowHeight * _rowCount) {
      _offset = Offset(
        widget.currentOffset.dx + _horizontalPadding - widget.startOffset.dx + _columnWidth / 2,
        widget.currentOffset.dy - (widget.startOffset.dy - _verticalPadding - _rowHeight * _rowCount) - _rowHeight / 2,
      );
    }

    // Case 8: Bottom-Right
    if (widget.startOffset.dx > _horizontalPadding + _gridWidth &&
        widget.startOffset.dy > _verticalPadding + _rowHeight * _rowCount) {
      _offset = Offset(
        widget.currentOffset.dx - (widget.startOffset.dx - _horizontalPadding - _gridWidth) - _columnWidth / 2,
        widget.currentOffset.dy - (widget.startOffset.dy - _verticalPadding - _rowHeight * _rowCount) - _rowHeight / 2,
      );
    }
  }

  static const _psalms = 19;
  static const _hebrews = 58;
  static const _revelation = 66;

  int? _findSelectedChapter() {
    final offset = _offset;
    if (offset == null) {
      return null;
    }
    // var dy = offset.dy;

    // Hebrews and Revelation should start the selection on the bottom row.
    // if (widget.bookId == _hebrews) {
    //   dy += _rowHeight;
    // } else if (widget.bookId == _revelation) {
    //   dy += _rowHeight * 2;
    // }

    // final gridTop = -_rowHeight / 2;
    // final gridBottom = _rowCount * _rowHeight - _rowHeight;
    // final clampedY = dy.clamp(gridTop, gridBottom);
    final screenSize = MediaQuery.of(context).size;
    print(
        '_horizontal: $_horizontalPadding, _cellWidth: $_columnWidth, screenWidth: ${screenSize.width}, offset.dx: ${offset.dx}');

    for (int index = 0; index <= widget.chapterCount; index++) {
      final cellX = _horizontalPadding + (index % _columnCount) * _columnWidth;
      final cellY = _verticalPadding + (index ~/ 10) * _rowHeight;
      if (offset.dx > cellX && //
          offset.dx < cellX + _columnWidth &&
          offset.dy >= cellY &&
          offset.dy < cellY + _rowHeight) {
        // subtract 1 cell width to account for the missing empty cell at index 0.
        // final oneCell = _isShortBook

        return index;
      }
      // subtract 1 cell width to account for the missing empty cell at index 0.
      // final oneCell = _isShortBook ? _cellWidth : 0.0;
      // final cellX = (index % _columnCount) * _cellWidth + _horizontalPadding;
      // final cellY = (index ~/ 10) * _rowHeight + _verticalPadding;

      // if (offset.dx >= cellX && //
      //     offset.dx < cellX + _cellWidth &&
      //     clampedY >= cellY &&
      //     clampedY < cellY + _rowHeight) {
      //   return index;
      // }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final offset = _isBeforeJob ? 1.0 : -1.0;
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
