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
    UsfmPassage passage = UsfmPassage([]);
    int verseNumber = 0;
    for (final line in verseLines) {
      print('format: ${line.format}, verse: ${line.verse}, text: ${line.text}');
      switch (line.format) {
        case ParagraphFormat.b:
          passage.commit([], ParagraphFormat.b);
        case ParagraphFormat.r:
          // A cross-reference should not be its own paragraph.
          // Instead, we will attach it as a footnote to the previous paragraph.
          if (passage.paragraphs.isNotEmpty &&
              passage.paragraphs.last.content.isNotEmpty) {
            // 1. Create a Footnote element from the cross-reference text.
            //    We'll prepend a conventional footnote marker like a star (*)
            //    so the FootnoteWidget has something to render.
            final footnote = Footnote(line.text);

            // 2. Add this footnote to the content list of the PREVIOUS paragraph.
            passage.paragraphs.last.content.add(footnote);

            // 3. Do NOT create a new paragraph. The work for this line is done.
          }
        case ParagraphFormat.m:
        case ParagraphFormat.pmo:
          if (line.verse != verseNumber) {
            passage.append([VerseNumber(line.verse.toString())], line.format);
            verseNumber = line.verse;
          }
          final words = _getWords(line.text, line.bookChapterVerse);
          passage.append(words, line.format);
        case ParagraphFormat.q1:
        case ParagraphFormat.q2:
        case ParagraphFormat.li1:
        case ParagraphFormat.li2:
        case ParagraphFormat.qr:
        case ParagraphFormat.pc:
          if (line.verse != verseNumber) {
            passage.append([VerseNumber(line.verse.toString())], line.format);
            verseNumber = line.verse;
          }
          final words = _getWords(line.text, line.bookChapterVerse);
          passage.append(words, line.format);
          passage.commit();
        case ParagraphFormat.d:
        case ParagraphFormat.s1:
        case ParagraphFormat.s2:
        case ParagraphFormat.ms:
        case ParagraphFormat.mr:
        case ParagraphFormat.qa:
          final words = _getWords(line.text, line.bookChapterVerse);
          passage.commit(words, line.format);
      }
    }
    passage.commit();
    return _buildPassageWidget(
      passage.paragraphs,
    );
  }

  List<ParagraphElement> _getWords(String text, int id) {
    final list = <ParagraphElement>[];

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
    final passageChildren = <Widget>[];
    for (final paragraph in paragraphs) {
      switch (paragraph.format) {
        case ParagraphFormat.b:
          _addParagraphSpacing(passageChildren, paragraph.format);
        case ParagraphFormat.m:
        case ParagraphFormat.pc:
        case ParagraphFormat.qr:
          final paragraphChildren = _getParagraphChildren(paragraph);
          passageChildren.add(ParagraphWidget(
            children: paragraphChildren,
          ));
        case ParagraphFormat.q1:
        case ParagraphFormat.li1:
          final paragraphChildren = _getParagraphChildren(paragraph);
          passageChildren.add(ParagraphWidget(
            firstLineIndent: 20,
            subsequentLinesIndent: 100,
            children: paragraphChildren,
          ));
        case ParagraphFormat.q2:
        case ParagraphFormat.li2:
          final paragraphChildren = _getParagraphChildren(paragraph);
          passageChildren.add(ParagraphWidget(
            firstLineIndent: 60,
            subsequentLinesIndent: 100,
            children: paragraphChildren,
          ));
        case ParagraphFormat.pmo:
          final paragraphChildren = _getParagraphChildren(paragraph);
          passageChildren.add(ParagraphWidget(
            firstLineIndent: 20,
            subsequentLinesIndent: 20,
            children: paragraphChildren,
          ));
        case ParagraphFormat.d:
        case ParagraphFormat.r:
        case ParagraphFormat.mr:
          final paragraphChildren = _getParagraphChildren(paragraph);
          passageChildren.add(ParagraphWidget(
            children: paragraphChildren,
          ));
          _addParagraphSpacing(passageChildren, paragraph.format);
        case ParagraphFormat.s1:
        case ParagraphFormat.s2:
          final paragraphChildren = _getParagraphChildren(paragraph);
          _addParagraphSpacing(passageChildren, paragraph.format);
          passageChildren.add(ParagraphWidget(
            children: paragraphChildren,
          ));
          _addParagraphSpacing(passageChildren, paragraph.format);
        case ParagraphFormat.ms:
        case ParagraphFormat.qa:
          final paragraphChildren = _getParagraphChildren(paragraph);
          passageChildren.add(ParagraphWidget(
            children: paragraphChildren,
          ));
      }
    }

    // remove last paragraph space
    if (passageChildren.isNotEmpty && passageChildren.last is SizedBox) {
      passageChildren.removeLast();
    }

    return PassageWidget(
      children: passageChildren,
    );
  }

  List<Widget> _getParagraphChildren(
    UsfmParagraph paragraph,
  ) {
    final style = _getStyleForParagraphType(paragraph.format);
    final paragraphChildren = <Widget>[];
    final List<ParagraphElement> elements = paragraph.content;

    // Use an index-based loop to allow for look-ahead.
    for (int i = 0; i < elements.length; i++) {
      final currentElement = elements[i];
      Widget? atom;

      // --- 1. ATOM CREATION LOGIC ---
      // This logic groups elements that must stick together.

      if (currentElement is VerseNumber &&
          i + 1 < elements.length &&
          elements[i + 1] is Word) {
        // Case: Verse number followed by a word. Bundle them.
        final nextWord = elements[i + 1] as Word;
        atom = TextAtomWidget(
          children: [
            VerseNumberWidget(
              number: currentElement.number,
              style: style,
              padding: const EdgeInsets.only(right: 4.0),
            ),
            WordWidget(text: nextWord.text, id: nextWord.id, style: style),
          ],
        );
        i++; // CRITICAL: Skip the next element as it's now in the atom.
      } else if (currentElement is Word &&
          i + 1 < elements.length &&
          elements[i + 1] is Footnote) {
        // Case: Word followed by a footnote. Bundle them.
        final nextFootnote = elements[i + 1] as Footnote;

        // --- NEW LOGIC: Define the shared callback ---
        // This callback captures the full text of the footnote.
        final footnoteCallback = (String footnoteText) {
          print('Tapped footnote: $footnoteText');
          // Here is where you would show a dialog, bottom sheet, etc.
        };

        atom = TextAtomWidget(
          children: [
            WordWidget(
              text: currentElement.text,
              id: currentElement.id,
              style: style,
              // Assign the callback to the preceding Word.
              // We adapt our new callback to the WordWidget's expected signature.
              onTap: (wordText, wordId) => footnoteCallback(nextFootnote.text),
            ),
            FootnoteWidget(
              marker: '*', // Or use another marker like '¹', '²', etc.
              text: nextFootnote.text,
              style:
                  style, // The RenderFootnote will apply its own modifications
              // Assign the SAME callback to the FootnoteWidget.
              onTap: footnoteCallback,
            ),
          ],
        );
        i++; // CRITICAL: Skip the next element.
      } else if (currentElement is Word) {
        // Case: A standalone word becomes an atom of one.
        atom = TextAtomWidget(children: [
          WordWidget(
              text: currentElement.text, id: currentElement.id, style: style),
        ]);
      } else if (currentElement is VerseNumber) {
        // Case: A standalone verse number (edge case).
        atom = TextAtomWidget(children: [
          VerseNumberWidget(number: currentElement.number, style: style),
        ]);
      }
      // Note: You might add other elements like cross-references here later.

      if (atom != null) {
        paragraphChildren.add(atom);
      }

      // --- 2. SPACING LOGIC ---
      // After adding an atom, decide if a space is needed BEFORE the *next* one.
      if (i + 1 < elements.length) {
        if (_shouldInsertSpace(currentElement, elements[i + 1])) {
          paragraphChildren.add(const SpaceWidget(width: 4.0));
        }
      }
    }

    return paragraphChildren;
  }

  /// Helper function to encapsulate spacing rules.
  bool _shouldInsertSpace(ParagraphElement current, ParagraphElement next) {
    // Rule 1: Never insert a space before a footnote.
    if (next is Footnote) {
      return false;
    }

    // Rule 2 (for CJK etc.): You could add a language check here.
    // if (isCJK(current.text)) {
    //   return false;
    // }

    // Default Rule: Add a space.
    return true;
  }

  void _addParagraphSpacing(List<Widget> paragraphs, ParagraphFormat format) {
    const spacing = 16.0;
    if (paragraphs.isEmpty || paragraphs.last is SizedBox) {
      return;
    }
    paragraphs.add(const SizedBox(height: spacing));

    // switch (format) {
    //   case ParagraphFormat.m:
    //   case ParagraphFormat.q1:
    //   case ParagraphFormat.q2:
    //   case ParagraphFormat.pmo:
    //   case ParagraphFormat.li1:
    //   case ParagraphFormat.li2:
    //   case ParagraphFormat.pc:
    //     break;
    //   case ParagraphFormat.b:
    //   case ParagraphFormat.qr:
    //   case ParagraphFormat.d:
    //   case ParagraphFormat.r:
    //   case ParagraphFormat.s1:
    //   case ParagraphFormat.s2:
    //   case ParagraphFormat.ms:
    //   case ParagraphFormat.mr:
    //   case ParagraphFormat.qa:
    //     paragraphs.add(const SizedBox(height: spacing));
    // }
    // if ((lastFormat == ParagraphFormat.q1 ||
    //         lastFormat == ParagraphFormat.q2) &&
    //     (currentFormat == ParagraphFormat.q1 ||
    //         currentFormat == ParagraphFormat.q2)) {
    //   return;
    // }
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

  // (double, double) _getIndentsForFormat(ParagraphFormat format) {
  //   switch (format) {
  //     case ParagraphFormat.b:
  //     case ParagraphFormat.m:
  //       return (0, 0);
  //     case ParagraphFormat.q1:
  //     case ParagraphFormat.li1:
  //       return (20, 100);
  //     case ParagraphFormat.pmo:
  //       return (20, 20);
  //     case ParagraphFormat.q2:
  //     case ParagraphFormat.li2:
  //       return (60, 100);
  //     case ParagraphFormat.pc:
  //     case ParagraphFormat.qr:
  //     case ParagraphFormat.d:
  //     case ParagraphFormat.r:
  //     case ParagraphFormat.s1:
  //     case ParagraphFormat.s2:
  //     case ParagraphFormat.ms:
  //     case ParagraphFormat.mr:
  //     case ParagraphFormat.qa:
  //       return (0, 0);
  //   }
  // }

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
