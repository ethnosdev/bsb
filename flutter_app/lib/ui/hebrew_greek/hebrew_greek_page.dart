import 'package:bsb/infrastructure/verse_element.dart';
import 'package:bsb/ui/hebrew_greek/hebrew_greek_manager.dart';
import 'package:bsb/ui/hebrew_greek/verse_page_manager.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';

class HebrewGreekPage extends StatefulWidget {
  const HebrewGreekPage({
    super.key,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.language,
  });

  final int bookId;
  final int chapter;
  final int verse;
  final Language language;

  @override
  State<HebrewGreekPage> createState() => _HebrewGreekPageState();
}

class _HebrewGreekPageState extends State<HebrewGreekPage> {
  final manager = HebrewGreekManager();
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    manager.init(widget.bookId, widget.chapter, widget.verse);
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
              final verseManager = VersePageManager();
              verseManager.requestVerseContent(
                bookId: widget.bookId,
                chapter: widget.chapter,
                verse: index + 1,
                textColor: Theme.of(context).textTheme.bodyMedium!.color!,
                highlightColor: Theme.of(context).colorScheme.primary,
              );
              return ListenableBuilder(
                listenable: verseManager,
                builder: (context, child) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildInterlinearText(verseManager.interlinearText),
                        if (verseManager.originalWord != null) //
                          ..._buildOriginalWordDetails(verseManager.originalWord!),
                      ],
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

  Widget _buildInterlinearText(TextSpan text) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text.rich(
        text,
        textDirection: (widget.language.isRTL) //
            ? TextDirection.rtl
            : TextDirection.ltr,
      ),
    );
  }

  List<Widget> _buildOriginalWordDetails(OriginalWord word) {
    final fontFamily = (word.language == Language.greek) ? 'Galatia' : 'Ezra';
    return [
      Text(
        word.word,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 50,
        ),
      ),
      Text(word.englishGloss),
      Text(word.partOfSpeech),
      Text(word.strongsNumber.toString()),
    ];
  }
}
