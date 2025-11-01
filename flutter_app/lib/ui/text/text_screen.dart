import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/verse_line.dart';
import 'package:bsb/ui/hebrew_greek/hebrew_greek_screen.dart';
import 'package:bsb/ui/home/chapter_chooser.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/shared/snappy_scroll_physics.dart';
import 'package:bsb/ui/text/text_page_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';
import 'package:url_launcher/url_launcher.dart';

import 'text_screen_manager.dart';

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
  final _showBottomBarNotifier = ValueNotifier<bool>(false);

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
    _showBottomBarNotifier.dispose();
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
          ValueListenableBuilder<bool>(
            valueListenable: _showBottomBarNotifier,
            builder: (context, showBar, child) {
              if (!showBar) return const SizedBox();
              return _buildBottomMenuBar();
            },
          ),
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
        final pageManager = TextPageManager();
        pageManager.requestText(
          bookId: bookId,
          chapter: chapter,
          // textColor: Theme.of(context).textTheme.bodyMedium!.color!,
          // footnoteColor: Theme.of(context).colorScheme.primary,
          // onVerseLongPress: (verse) {
          //   // _showBottomBarNotifier.value = true;
          //   // _showBottomMenuBar(verse, pageManager);
          //   _showVerseLongPressDialog(verse, pageManager);
          // },
          // onFootnoteTap: (note) {
          //   final details = pageManager.formatFootnote(
          //     footnote: note,
          //     highlightColor: Theme.of(context).colorScheme.primary,
          //     onTapKeyword: (keyword, count) async {
          //       if (count == 1) {
          //         Navigator.of(context).pop();
          //       }
          //       final text = await pageManager.lookupFootnoteDetails(keyword);
          //       if (text == null) return;
          //       _showDetailsDialog(keyword, text);
          //     },
          //   );
          //   showDialog(
          //     context: context,
          //     builder: (context) => AlertDialog(
          //       content: SelectableText.rich(
          //         details,
          //         style: TextStyle(
          //           fontSize: getIt<UserSettings>().textSize,
          //         ),
          //       ),
          //     ),
          //   );
          // },
        );

        return ValueListenableBuilder<List<UsfmLine>>(
          valueListenable: pageManager.textParagraphNotifier,
          builder: (context, verseLines, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildPassage(verseLines),
              ),
            );
          },
        );
      },
    );
  }

  PassageWidget _buildPassage(List<UsfmLine> verseLines) {
    final paragraphs = <UsfmParagraph>[];
    UsfmParagraph? biblicalParagraph;
    int verseNumber = 0;
    for (final line in verseLines) {
      // new line marker breaks a paragraph
      if (line.format == ParagraphFormat.b && biblicalParagraph != null) {
        paragraphs.add(biblicalParagraph);
        biblicalParagraph = null;
      }
      // add words for biblical text
      else if (line.format.isBiblicalText) {
        biblicalParagraph ??= UsfmParagraph(content: [], format: line.format);
        if (line.verse != verseNumber) {
          biblicalParagraph.content.add(VerseNumber(line.verse.toString()));
          verseNumber = line.verse;
        }
        biblicalParagraph.content
            .addAll(_getWords(line.text, line.bookChapterVerse));
      }
      // add headings, etc.
      else {
        if (biblicalParagraph != null) {
          paragraphs.add(biblicalParagraph);
          biblicalParagraph = null;
        }
        final content = _getWords(line.text, line.bookChapterVerse);
        paragraphs.add(UsfmParagraph(content: content, format: line.format));
      }
    }
    if (biblicalParagraph != null) {
      paragraphs.add(biblicalParagraph);
      biblicalParagraph = null;
    }
    return _buildPassageWidget(
      paragraphs,
    );
  }

  List<Word> _getWords(String text, int id) {
    final list = <Word>[];

    // 1. Use a regular expression to split by one or more whitespace characters.
    // 2. Use .where() to filter out any empty strings that might result.
    final words = text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty);

    int wordId = id * 1000;
    for (final word in words) {
      list.add(Word(text: word, id: wordId.toString()));
      wordId++;
    }
    return list;
  }

  PassageWidget _buildPassageWidget(List<UsfmParagraph> paragraphs) {
    final passageChildren = <ParagraphWidget>[];
    for (final paragraph in paragraphs) {
      final style = _getStyleForParagraphType(paragraph.format);
      final paragraphChildren = <Widget>[];
      for (final element in paragraph.content) {
        if (element is Word) {
          final word = WordWidget(
            text: element.text,
            id: element.id,
            style: style,
            onTap: (text, id) {
              print('Tapped word: "$text" (id: $id)');
            },
          );
          paragraphChildren.add(word);
        } else if (element is VerseNumber) {
          final verse = VerseNumberWidget(
            number: element.number,
            style: style,
            scale: 0.7,
            padding: const EdgeInsets.only(right: 4.0),
          );
          paragraphChildren.add(verse);
        } else if (element is Footnote) {
          print('Footnote: ${element.text}');
        } else {
          // do nothing for now.
        }
      }
      final (level1, level2) = _getIndentsForFormat(paragraph.format);

      final paragraphWidget = ParagraphWidget(
        firstLineIndent: level1,
        subsequentLinesIndent: level2,
        children: paragraphChildren,
      );
      passageChildren.add(paragraphWidget);
    }

    return PassageWidget(children: passageChildren);
  }

  TextStyle _getStyleForParagraphType(
    ParagraphFormat format,
  ) {
    double normalTextSize = getIt<UserSettings>().textSize;
    final defaultStyle = Theme.of(context)
        .textTheme
        .bodyMedium!
        .copyWith(fontSize: normalTextSize);
    switch (format) {
      case ParagraphFormat.b:
      case ParagraphFormat.m:
      case ParagraphFormat.q1:
      case ParagraphFormat.q2:
      case ParagraphFormat.li1:
      case ParagraphFormat.li2:
      case ParagraphFormat.pmo:
        return defaultStyle;
      case ParagraphFormat.pc:
        print('pc');
        return defaultStyle;
      case ParagraphFormat.qr:
        print('qr');
        return defaultStyle;
      case ParagraphFormat.d:
        print('d');
        return defaultStyle;
      case ParagraphFormat.r:
      case ParagraphFormat.s2:
        return defaultStyle.copyWith(fontStyle: FontStyle.italic);
      case ParagraphFormat.s1:
        return defaultStyle.copyWith(fontWeight: FontWeight.bold);
      case ParagraphFormat.ms:
        print('ms');
        return defaultStyle;
      case ParagraphFormat.mr:
        print('mr');
        return defaultStyle;
      case ParagraphFormat.qa:
        print('qa');
        return defaultStyle;
    }
  }

  (double, double) _getIndentsForFormat(ParagraphFormat format) {
    switch (format) {
      case ParagraphFormat.b:
      case ParagraphFormat.m:
        return (0, 0);
      case ParagraphFormat.q1:
      case ParagraphFormat.li1:
      case ParagraphFormat.pmo:
        return (20, 100);
      case ParagraphFormat.q2:
      case ParagraphFormat.li2:
        return (60, 100);
      case ParagraphFormat.pc:
      case ParagraphFormat.qr:
      case ParagraphFormat.d:
      case ParagraphFormat.r:
      case ParagraphFormat.s1:
      case ParagraphFormat.s2:
      case ParagraphFormat.ms:
      case ParagraphFormat.mr:
      case ParagraphFormat.qa:
        return (0, 0);
    }
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

  Widget _buildBottomMenuBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.content_copy),
            label: 'Copy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.highlight),
            label: 'Highlight',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.language),
            label: 'Greek',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare),
            label: 'Compare',
          ),
        ],
        onTap: (index) {
          // Handle taps for each menu item
          _showBottomBarNotifier.value = false;
        },
      ),
    );
  }

  // Future<void> _showBottomMenuBar(int verseNumber, TextPageManager manager) async {
  //   final (bookId, chapter) = screenManager.bookAndChapterForPageIndex(_pageIndex);
  // }

  Future<String?> _showVerseLongPressDialog(
      int verseNumber, TextPageManager manager) async {
    final language = screenManager.verseLanguageLabel(_pageIndex, verseNumber);
    final languageLabel = 'View ${language.displayName} source';
    final (bookId, chapter) =
        screenManager.bookAndChapterForPageIndex(_pageIndex);
    return showDialog(
      context: context,
      builder: (BuildContext buildContext) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text(
                  'Copy',
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final verse = await manager.verseTextForClipboard(
                    bookId,
                    chapter,
                    verseNumber,
                  );
                  await Clipboard.setData(ClipboardData(text: verse));
                },
              ),
              ListTile(
                title: Text(
                  languageLabel,
                ),
                onTap: () async {
                  Navigator.of(context).pop();
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
              ListTile(
                title: const Text(
                  'Compare translations',
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final url = screenManager.bibleHubUrl(
                    bookId: bookId,
                    chapter: chapter,
                    verse: verseNumber,
                  );
                  _launch(url);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Future<void> _showDetailsDialog(String title, TextParagraph passage) async {
  //   final fontSize = getIt<UserSettings>().textSize;
  //   await showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Dialog(
  //         child: Container(
  //           padding: const EdgeInsets.all(16.0),
  //           constraints: const BoxConstraints(maxHeight: 400),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text(
  //                 title,
  //                 style: TextStyle(
  //                   fontSize: fontSize,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //               const SizedBox(height: 16),
  //               Flexible(
  //                 child: SingleChildScrollView(
  //                   child: ChapterLayout(
  //                       paragraphs: passage,
  //                       paragraphSpacing: 8.0,
  //                       bottomSpace: 0.0),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Future<void> _launch(String webpage) async {
    final url = Uri.parse(webpage);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
