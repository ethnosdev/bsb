import 'package:flutter/material.dart';

class ChapterDialog extends StatelessWidget {
  final int chapters;
  final Function(int)? onChapterSelected;

  const ChapterDialog({super.key, required this.chapters, this.onChapterSelected});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                childAspectRatio: 1,
              ),
              itemCount: chapters,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onPanUpdate: (details) {
                    final RenderBox box = context.findRenderObject() as RenderBox;
                    final Offset localPosition = box.globalToLocal(details.globalPosition);
                    final int hoveredIndex = _getHoveredIndex(localPosition, box.size, 10);
                    if (hoveredIndex >= 0 && hoveredIndex < chapters) {
                      _showOverlay(context, details.globalPosition, hoveredIndex + 1);
                    }
                  },
                  onTapUp: (_) {
                    Navigator.of(context).pop();
                    onChapterSelected?.call(index + 1);
                  },
                  child: Center(
                    child: Text(
                      (index + 1).toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  int _getHoveredIndex(Offset localPosition, Size size, int crossCount) {
    if (localPosition.dx < 0 ||
        localPosition.dy < 0 ||
        localPosition.dx > size.width ||
        localPosition.dy > size.height) {
      return -1;
    }
    final double itemWidth = size.width / crossCount;
    final double itemHeight = itemWidth;
    final int row = localPosition.dy ~/ itemHeight;
    final int col = localPosition.dx ~/ itemWidth;
    return row * crossCount + col;
  }

  void _showOverlay(BuildContext context, Offset position, int number) {
    OverlayEntry? existingEntry;
    final overlay = Overlay.of(context);

    existingEntry?.remove();

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 20,
        top: position.dy - 40,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    existingEntry = entry;
  }
}
