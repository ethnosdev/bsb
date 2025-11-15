import 'package:bsb/ui/home/chapter_chooser.dart';
import 'package:bsb/ui/shared/snappy_scroll_physics.dart';
import 'package:bsb/ui/text/chapter/chapter_text.dart';
import 'package:flutter/material.dart';

import 'screen_manager.dart';

class TextScreen extends StatefulWidget {
  const TextScreen({
    super.key,
    required this.bookId,
    required this.chapter,
  });

  final int bookId;
  final int chapter;

  @override
  State<TextScreen> createState() => _TextScreenState();
}

class _TextScreenState extends State<TextScreen> {
  final screenManager = TextScreenManager();
  static const _initialPageOffset = 10000;
  late final PageController _pageController;
  final _chapterNotifier = ValueNotifier<(int, int)?>(null);
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageIndex = screenManager.pageIndexForBookAndChapter(
      bookId: widget.bookId,
      chapter: widget.chapter,
    );
    screenManager.updateTitle(index: _pageIndex);
    _pageController = PageController(
      initialPage: _initialPageOffset + _pageIndex,
    );
    _pageController.addListener(() {
      final page = _pageController.page ?? _initialPageOffset;
      final currentIndex = (page - _initialPageOffset).round();
      if (currentIndex != _pageIndex) {
        _pageIndex = currentIndex;
        screenManager.updateTitle(
          index: _pageIndex,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    screenManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<String>(
          valueListenable: screenManager.titleNotifier,
          builder: (context, title, child) {
            return GestureDetector(
              onTap: () {
                final (bookId, chapterCount) =
                    screenManager.currentBookAndChapterCount(_pageIndex);
                _chapterNotifier.value = (bookId, chapterCount);
              },
              child: Text(title),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          _buildChapterTextPageView(),
          _buildChapterChooserOverlay(),
        ],
      ),
    );
  }

  Widget _buildChapterTextPageView() {
    return PageView.builder(
      controller: _pageController,
      physics: const SnappyScrollPhysics(),
      itemBuilder: (context, index) {
        final pageIndex = index - _initialPageOffset;
        final (bookId, chapter) =
            screenManager.bookAndChapterForPageIndex(pageIndex);
        return ChapterText(bookId: bookId, chapter: chapter);
      },
    );
  }

  Widget _buildChapterChooserOverlay() {
    return ValueListenableBuilder<(int, int)?>(
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
            final pageIndex = screenManager.pageIndexForBookAndChapter(
              bookId: bookId,
              chapter: chapter,
            );
            final index = pageIndex + _initialPageOffset;
            _pageController.jumpToPage(index);
          },
        );
      },
    );
  }
}
