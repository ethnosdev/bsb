import 'package:bsb/ui/hebrew_greek/hebrew_greek_manager.dart';
import 'package:flutter/material.dart';

class HebrewGreekPage extends StatefulWidget {
  const HebrewGreekPage({
    super.key,
    required this.bookId,
    required this.chapter,
    required this.verse,
  });

  final int bookId;
  final int chapter;
  final int verse;

  @override
  State<HebrewGreekPage> createState() => _HebrewGreekPageState();
}

class _HebrewGreekPageState extends State<HebrewGreekPage> {
  final manager = HebrewGreekManager();
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    manager.init(widget.bookId, widget.chapter);
    _pageController = PageController(
      initialPage: widget.verse - 1,
    );
    _pageController.addListener(() {
      if (_pageController.page?.truncateToDouble() == _pageController.page) {
        final index = _pageController.page?.toInt() ?? 0;
        manager.updateTitle(
          bookId: widget.bookId,
          chapter: widget.chapter,
          verse: index + 1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<String>(
          valueListenable: manager.titleNotifier,
          builder: (context, title, child) {
            return Text(title);
          },
        ),
      ),
      body: ValueListenableBuilder<int?>(
        valueListenable: manager.verseCountNotifier,
        builder: (context, verseCount, child) {
          if (verseCount == null) {
            return const SizedBox();
          }
          return PageView.builder(
            controller: _pageController,
            itemCount: verseCount,
            itemBuilder: (context, index) {
              manager.requestVerseContent(
                verse: index + 1,
              );
              return ValueListenableBuilder<OriginalLanguageData?>(
                valueListenable: manager.notifier(index),
                builder: (context, data, child) {
                  if (data == null) {
                    return const SizedBox();
                  }
                  return const SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
