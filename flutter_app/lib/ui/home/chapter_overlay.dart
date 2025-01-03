import 'package:flutter/material.dart';

class ChapterOverlay extends StatefulWidget {
  const ChapterOverlay({
    super.key,
    required this.chapterCount,
    required this.localOffset,
    required this.width,
    required this.onChapterSelected,
  });

  final int chapterCount;
  final Offset localOffset;
  final double width;
  final void Function(int chapter) onChapterSelected;

  @override
  State<ChapterOverlay> createState() => _ChapterOverlayState();
}

class _ChapterOverlayState extends State<ChapterOverlay> {
  int? _lastSelectedChapter;

  @override
  Widget build(BuildContext context) {
    final int rowCount = ((widget.chapterCount + 1) / 10).ceil();
    final double rowHeight = rowCount > 10 ? widget.width / 15 : widget.width / 10;
    return Container(
      width: widget.width,
      height: rowHeight * rowCount,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: rowCount > 10 ? (widget.width / 10) / rowHeight : 1.0,
        ),
        itemCount: widget.chapterCount + 1,
        itemBuilder: (context, index) {
          final cellWidth = widget.width / 10;
          final cellX = (index % 10) * cellWidth;
          final cellY = (index ~/ 10) * rowHeight;
          final isSelected = widget.localOffset.dx >= cellX &&
              widget.localOffset.dx < cellX + cellWidth &&
              widget.localOffset.dy >= cellY &&
              widget.localOffset.dy < cellY + rowHeight;
          if (isSelected) {
            if (_lastSelectedChapter != index) {
              print('$index, $_lastSelectedChapter');
              _lastSelectedChapter = index;
              widget.onChapterSelected(index);
            }
          }
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
    );
  }
}
