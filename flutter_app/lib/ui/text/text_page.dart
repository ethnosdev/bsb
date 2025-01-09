import 'package:bsb/ui/text/chapter_layout.dart';
// import 'package:database_builder/schema.dart';
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
  final textManager = TextManager();
  static const _initialPageOffset = 1000;
  final _pageController = PageController(initialPage: _initialPageOffset);

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      // print('Current page: ${_pageController.page}');
      if (_pageController.page?.truncateToDouble() == _pageController.page) {
        final index = (_pageController.page?.toInt() ?? _initialPageOffset) - _initialPageOffset;
        // print('Arrived at page: ${index}');
        textManager.requestText(
          initialBookId: widget.bookId,
          initialChapter: widget.chapter,
          index: index,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<String>(
            valueListenable: textManager.titleNotifier,
            builder: (context, title, child) {
              return Text(title);
            }),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, index) {
          final pageIndex = index - _initialPageOffset;
          // print('index: $pageIndex');
          textManager.requestText(
            initialBookId: widget.bookId,
            initialChapter: widget.chapter,
            index: pageIndex,
          );
          return ValueListenableBuilder<TextParagraph>(
            valueListenable: textManager.notifier(pageIndex),
            builder: (context, paragraph, child) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ChapterLayout(
                    paragraphs: paragraph,
                    paragraphSpacing: textManager.paragraphSpacing,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
