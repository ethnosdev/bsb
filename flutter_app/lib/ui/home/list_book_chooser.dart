import 'package:bsb/ui/home/chapter_chooser.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';

class ListBookChooser extends StatefulWidget {
  const ListBookChooser({
    super.key,
    required this.onSelected,
  });

  final void Function(int bookId, int chapter, [String? sectionHeading]) onSelected;

  @override
  State<ListBookChooser> createState() => _ListBookChooserState();
}

class _ListBookChooserState extends State<ListBookChooser> {
  final _chapterNotifier = ValueNotifier<(int, int)?>(null);

  static final List<int> _oldTestamentBooks =
      List.generate(39, (index) => index + 1); // 1..39
  static final List<int> _newTestamentBooks =
      List.generate(27, (index) => index + 40); // 40..66

  @override
  void dispose() {
    _chapterNotifier.dispose();
    super.dispose();
  }

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
        Row(
          children: [
            Expanded(
              child: _buildList(
                storageKey: 'old_testament',
                bookIds: _oldTestamentBooks,
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: _buildList(
                storageKey: 'new_testament',
                bookIds: _newTestamentBooks,
              ),
            ),
          ],
        ),
        ValueListenableBuilder<(int, int)?>(
          valueListenable: _chapterNotifier,
          builder: (context, bookChapter, child) {
            if (bookChapter == null) {
              return const SizedBox.shrink();
            }
            final (bookId, chapterCount) = bookChapter;
            return ChapterChooser(
              bookId: bookId,
              chapterCount: chapterCount,
              onChapterSelected: (chapter) {
                _chapterNotifier.value = null;
                if (chapter == null) return;
                widget.onSelected(bookId, chapter);
              },
              onSectionSelected: (chapter, sectionHeading) {
                _chapterNotifier.value = null;
                widget.onSelected(bookId, chapter, sectionHeading);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildList({
    required String storageKey,
    required List<int> bookIds,
  }) {
    return ListView.separated(
      key: PageStorageKey('list_book_chooser_$storageKey'),
      itemCount: bookIds.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, thickness: 0.5),
      itemBuilder: (context, index) {
        final bookId = bookIds[index];
        final bookName = bookIdToFullNameMap[bookId] ?? '';
        final chapterCount = bookIdToChapterCountMap[bookId] ?? 1;

        return ListTile(
          dense: true,
          title: Text(
            bookName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15),
          ),
          onTap: () => _onBookSelected(bookId, chapterCount),
        );
      },
    );
  }
}
