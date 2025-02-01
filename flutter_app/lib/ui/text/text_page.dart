import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/hebrew_greek/hebrew_greek_screen.dart';
import 'package:bsb/ui/home/chapter_chooser.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/text/chapter_layout.dart';
import 'package:bsb/ui/text/text_page_manager.dart';
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
  final screenManager = TextManager();
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
                final (bookId, chapterCount) = screenManager.currentBookAndChapterCount(_pageIndex);
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
        final pageIndex = index - _initialPageOffset;
        final (bookId, chapter) = screenManager.bookAndChapterForPageIndex(pageIndex);
        final pageManager = TextPageManager();
        pageManager.requestText(
          bookId: bookId,
          chapter: chapter,
          textColor: Theme.of(context).textTheme.bodyMedium!.color!,
          footnoteColor: Theme.of(context).colorScheme.primary,
          onVerseLongPress: _showVerseLongPressDialog,
          onFootnoteTap: (note) {
            final details = pageManager.formatFootnote(
              footnote: note,
              highlightColor: Theme.of(context).colorScheme.primary,
              onTapKeyword: (keyword) async {
                final text = await pageManager.lookupFootnoteDetails(keyword);
                if (text == null) return;
                _showDetailsDialog(keyword, text);
              },
            );
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                content: SelectableText.rich(
                  details,
                  style: TextStyle(
                    fontSize: getIt<UserSettings>().textSize,
                  ),
                ),
              ),
            );
          },
        );

        return ValueListenableBuilder<TextParagraph>(
          valueListenable: pageManager.textParagraphNotifier,
          // valueListenable: manager.notifier(_pageIndex),
          builder: (context, paragraph, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ChapterLayout(
                  paragraphs: paragraph,
                  paragraphSpacing: pageManager.paragraphSpacing,
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

  Future<String?> _showVerseLongPressDialog(int verseNumber) async {
    final language = screenManager.verseLanguageLabel(_pageIndex, verseNumber);
    final languageLabel = 'View ${language.displayName} source';
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
                  final (bookId, chapter) = screenManager.bookAndChapterForPageIndex(_pageIndex);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => HebrewGreekScreen(
                        bookId: bookId,
                        chapter: chapter,
                        verse: verseNumber,
                        language: language,
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

  Future<void> _showDetailsDialog(String title, TextParagraph passage) async {
    final fontSize = getIt<UserSettings>().textSize;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            constraints: const BoxConstraints(maxHeight: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: ChapterLayout(paragraphs: passage, paragraphSpacing: 8.0, bottomSpace: 0.0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
