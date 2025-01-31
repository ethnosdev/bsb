import 'package:bsb/core/font_family.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:bsb/ui/hebrew_greek/hebrew_greek_manager.dart';
import 'package:bsb/ui/hebrew_greek/similar_verses/similar_verses_page.dart';
import 'package:bsb/ui/hebrew_greek/verse_page_manager.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HebrewGreekScreen extends StatefulWidget {
  const HebrewGreekScreen({
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
  State<HebrewGreekScreen> createState() => _HebrewGreekScreenState();
}

class _HebrewGreekScreenState extends State<HebrewGreekScreen> {
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.abc,
              color: manager.showInterlinearEnglish //
                  ? null
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              manager.toggleShowInterlinearEnglish();
              setState(() {});
            },
          ),
        ],
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
              final verseManager = VersePageManager(widget.language);
              verseManager.requestVerseContent(
                bookId: widget.bookId,
                chapter: widget.chapter,
                verse: index + 1,
                textColor: Theme.of(context).textTheme.bodyMedium!.color!,
                highlightColor: Theme.of(context).colorScheme.primary,
                showEnglish: manager.showInterlinearEnglish,
              );
              return ListenableBuilder(
                listenable: verseManager,
                builder: (context, child) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildInterlinearText(
                            verseManager.interlinearText,
                            verseManager.textDirection,
                          ),
                          if (verseManager.originalWord != null) //
                            ..._buildOriginalWordDetails(verseManager.originalWord!),
                        ],
                      ),
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

  Widget _buildInterlinearText(TextSpan text, TextDirection direction) {
    return SelectableText.rich(
      text,
      textAlign: TextAlign.start,
      textDirection: direction,
    );
  }

  List<Widget> _buildOriginalWordDetails(OriginalWord word) {
    final fontFamily = fontFamilyForLanguage(word.language);
    return [
      const SizedBox(height: 16),
      Center(
        child: SelectableText(
          word.word,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 50,
          ),
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: SelectableText(
          word.englishGloss,
          style: const TextStyle(
            fontSize: 20,
          ),
        ),
      ),
      const SizedBox(height: 16),
      SelectableText(
        word.partOfSpeech,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontStyle: FontStyle.italic,
        ),
      ),
      Text.rich(TextSpan(children: [
        const TextSpan(
          text: "Strong's number: ",
        ),
        TextSpan(
          text: "${word.strongsNumber}",
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              final language = (word.language == Language.greek) ? 'greek' : 'hebrew';
              _launch('https://biblehub.com/$language/${word.strongsNumber}.htm');
            },
        ),
      ])),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SimilarVersesPage(
                word: word,
                showEnglish: manager.showInterlinearEnglish,
              ),
            ),
          );
        },
        child: const Text(
          'See use in other verses',
        ),
      ),
    ];
  }

  Future<void> _launch(String webpage) async {
    final url = Uri.parse(webpage);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
