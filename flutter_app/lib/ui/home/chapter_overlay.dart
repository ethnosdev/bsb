import 'package:flutter/material.dart';

class ChapterOverlay extends StatefulWidget {
  const ChapterOverlay({
    super.key,
    required this.chapterCount,
    required this.offset,
    // required this.width,
    required this.onChapterSelected,
  });

  final int chapterCount;
  final Offset offset;
  // final double width;
  final void Function(int chapter) onChapterSelected;

  @override
  State<ChapterOverlay> createState() => _ChapterOverlayState();
}

class _ChapterOverlayState extends State<ChapterOverlay> {
  int? _lastSelectedChapter;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // final percentX = widget.offset.dx / width;
    final padding = screenWidth * 0.05;
    final gridWidth = screenWidth - padding * 2;
    final int rowCount = ((widget.chapterCount + 1) / 10).ceil();
    final int columnCount = widget.chapterCount >= 10 ? 10 : widget.chapterCount;
    final double rowHeight = rowCount > 10 ? gridWidth / 15 : gridWidth / 10;
    return Container(
      margin: EdgeInsets.all(padding),
      width: gridWidth,
      height: rowHeight * rowCount,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: rowCount > 10 ? (gridWidth / 10) / rowHeight : 1.0,
        ),
        itemCount: widget.chapterCount + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const SizedBox();
          }
          final cellWidth = gridWidth / 10;
          final cellX = (index % 10) * cellWidth;
          final cellY = (index ~/ 10) * rowHeight;
          final isSelected = widget.offset.dx >= cellX &&
              widget.offset.dx < cellX + cellWidth &&
              widget.offset.dy >= cellY &&
              widget.offset.dy < cellY + rowHeight;
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
