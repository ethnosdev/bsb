import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/hebrew_greek/hebrew_greek_page.dart';
import 'package:bsb/ui/home/chapter_chooser.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/text/chapter_layout.dart';
import 'package:flutter/material.dart';

import 'text_manager.dart';

class TextPage extends StatefulWidget {
  const TextPage({
    super.key,
    required this.bookId,
    required this.chapter,
  });

  final int bookId;
  final int chapter;

  @override
  State<TextPage> createState() => _TextPageState();
}

class _TextPageState extends State<TextPage> {
  final manager = TextManager();
  static const _initialPageOffset = 10000;
  late final PageController _pageController;
  final _chapterNotifier = ValueNotifier<(int, int)?>(null);
  int _pageIndex = 0;
  // late int _versesInChapter;

  @override
  void initState() {
    super.initState();
    final index = manager.pageIndexForBookAndChapter(
      bookId: widget.bookId,
      chapter: widget.chapter,
    );
    _pageController = PageController(
      initialPage: _initialPageOffset + index,
    );
    _pageController.addListener(() {
      if (_pageController.page?.truncateToDouble() == _pageController.page) {
        final index = (_pageController.page?.toInt() ?? _initialPageOffset) - _initialPageOffset;
        manager.updateTitle(
          index: index,
        );
      }
    });
    // _findNumberOfVersesInChapter();
  }

  // Future<void> _findNumberOfVersesInChapter() async {
  //   _versesInChapter = await manager.versesInChapter(
  //     bookId: widget.bookId,
  //     chapter: widget.chapter,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<String>(
          valueListenable: manager.titleNotifier,
          builder: (context, title, child) {
            return GestureDetector(
              onTap: () {
                final (bookId, chapterCount) = manager.currentBookAndChapterCount(_pageIndex);
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

  PageView _buildChapterTextPageView() {
    return PageView.builder(
      controller: _pageController,
      itemBuilder: (context, index) {
        _pageIndex = index - _initialPageOffset;
        manager.requestText(
          index: _pageIndex,
          textColor: Theme.of(context).textTheme.bodyMedium!.color!,
          footnoteColor: Theme.of(context).colorScheme.primary,
          onVerseLongPress: (verseNumber) {
            print('Verse $verseNumber');
            _showVerseLongPressDialog(
              verseNumber: verseNumber,
            );
          },
          onFootnoteTap: (note) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                content: SelectableText(
                  note,
                  style: TextStyle(
                    fontSize: getIt<UserSettings>().textSize,
                  ),
                ),
              ),
            );
          },
        );
        return ValueListenableBuilder<TextParagraph>(
          valueListenable: manager.notifier(_pageIndex),
          builder: (context, paragraph, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ChapterLayout(
                  paragraphs: paragraph,
                  paragraphSpacing: manager.paragraphSpacing,
                ),
              ),
            );
          },
        );
      },
    );
  }

  ValueListenableBuilder<(int, int)?> _buildChapterChooserOverlay() {
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
            final pageIndex = manager.pageIndexForBookAndChapter(
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

  Future<String?> _showVerseLongPressDialog({
    required int verseNumber,
  }) async {
    final languageLabel = manager.verseLanguageLabel(_pageIndex, verseNumber);
    return showDialog(
      context: context,
      builder: (BuildContext buildContext) {
        return Dialog(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(languageLabel),
                onTap: () async {
                  Navigator.of(context).pop();
                  final (bookId, chapter) = manager.bookAndChapterForPageIndex(_pageIndex);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => HebrewGreekPage(
                        bookId: bookId,
                        chapter: chapter,
                        verse: verseNumber,
                        // versesInChapter: _versesInChapter,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
