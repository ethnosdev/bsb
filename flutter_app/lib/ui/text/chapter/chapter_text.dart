import 'package:bsb/infrastructure/verse_line.dart';
import 'package:bsb/ui/text/chapter/chapter_manager.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

class ChapterText extends StatefulWidget {
  const ChapterText({super.key, required this.bookId, required this.chapter});

  final int bookId;
  final int chapter;

  @override
  State<ChapterText> createState() => _ChapterTextState();
}

class _ChapterTextState extends State<ChapterText> {
  final manager = ChapterManager();

  @override
  void initState() {
    super.initState();
    manager.requestText(bookId: widget.bookId, chapter: widget.chapter);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<UsfmLine>>(
      valueListenable: manager.textParagraphNotifier,
      builder: (context, verseLines, child) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildPassage(verseLines),
          ),
        );
      },
    );
  }

  PassageWidget _buildPassage(List<UsfmLine> verseLines,
      {bool showHeadings = true}) {
    UsfmPassage passage = UsfmPassage([]);
    int verseNumber = 0;
    for (final line in verseLines) {
      switch (line.format) {
        case ParagraphFormat.b:
          passage.commit([], ParagraphFormat.b);
        case ParagraphFormat.r:
          if (passage.paragraphs.isNotEmpty &&
              passage.paragraphs.last.content.isNotEmpty) {
            final footnote = Footnote(line.text);
            passage.paragraphs.last.content.add(footnote);
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
          final words = _getWords(line.text, line.bookChapterVerse);
          passage.commit(words, line.format);
        case ParagraphFormat.s1:
        case ParagraphFormat.s2:
        case ParagraphFormat.ms:
        case ParagraphFormat.mr:
        case ParagraphFormat.qa:
          if (!showHeadings) {
            passage.commit();
            continue;
          }
          final words = _getWords(line.text, line.bookChapterVerse);
          passage.commit(words, line.format);
      }
    }
    passage.commit();
    return _buildPassageWidget(passage.paragraphs, manager);
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

  PassageWidget _buildPassageWidget(
      List<UsfmParagraph> paragraphs, ChapterManager manager) {
    final passageChildren = <Widget>[];
    for (final paragraph in paragraphs) {
      final paragraphChildren =
          _getParagraphChildren(paragraph, _onFootnoteTapped);
      switch (paragraph.format) {
        case ParagraphFormat.b:
          _addParagraphSpacing(passageChildren, paragraph.format);
        case ParagraphFormat.m:
        case ParagraphFormat.pc:
        case ParagraphFormat.qr:
          passageChildren.add(ParagraphWidget(
            children: paragraphChildren,
          ));
        case ParagraphFormat.q1:
        case ParagraphFormat.li1:
          passageChildren.add(ParagraphWidget(
            firstLineIndent: 20,
            subsequentLinesIndent: 100,
            children: paragraphChildren,
          ));
        case ParagraphFormat.q2:
        case ParagraphFormat.li2:
          passageChildren.add(ParagraphWidget(
            firstLineIndent: 60,
            subsequentLinesIndent: 100,
            children: paragraphChildren,
          ));
        case ParagraphFormat.pmo:
          passageChildren.add(ParagraphWidget(
            firstLineIndent: 20,
            subsequentLinesIndent: 20,
            children: paragraphChildren,
          ));
        case ParagraphFormat.d:
        case ParagraphFormat.r:
        case ParagraphFormat.mr:
          passageChildren.add(ParagraphWidget(
            children: paragraphChildren,
          ));
          _addParagraphSpacing(passageChildren, paragraph.format);
        case ParagraphFormat.s1:
        case ParagraphFormat.s2:
          _addParagraphSpacing(passageChildren, paragraph.format);
          passageChildren.add(ParagraphWidget(
            children: paragraphChildren,
          ));
          _addParagraphSpacing(passageChildren, paragraph.format);
        case ParagraphFormat.ms:
        case ParagraphFormat.qa:
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

  void _addParagraphSpacing(List<Widget> paragraphs, ParagraphFormat format) {
    const spacing = 16.0;
    if (paragraphs.isEmpty || paragraphs.last is SizedBox) {
      return;
    }
    paragraphs.add(const SizedBox(height: spacing));
  }

  List<Widget> _getParagraphChildren(
    UsfmParagraph paragraph,
    void Function(String) onFootnoteTapped,
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
        atom = TextAtomWidget(
          children: [
            WordWidget(
              text: currentElement.text,
              id: currentElement.id,
              style: style,
              // Assign the callback to the preceding Word.
              // We adapt our new callback to the WordWidget's expected signature.
              onTap: (wordText, wordId) => onFootnoteTapped(nextFootnote.text),
            ),
            FootnoteWidget(
              marker: '*',
              text: nextFootnote.text,
              style:
                  style.copyWith(color: Theme.of(context).colorScheme.primary),
              onTap: onFootnoteTapped,
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

  TextStyle _getStyleForParagraphType(
    ParagraphFormat format,
  ) {
    double normalTextSize = manager.textSize;
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

  void _onFootnoteTapped(String footnoteText) {
    // print(footnoteText);
    // footnoteText = footnoteText.replaceAll('; ', ';\n');
    final details = formatFootnote(
      footnote: footnoteText,
      highlightColor: Theme.of(context).colorScheme.primary,
      onTapKeyword: (keyword, count) async {
        if (count == 1) {
          Navigator.of(context).pop();
        }
        final text = await manager.lookupFootnoteDetails(keyword);
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
            fontSize: manager.textSize,
          ),
        ),
      ),
    );
  }

  TextSpan formatFootnote({
    required String footnote,
    required Color highlightColor,
    required void Function(String tappedKeyword, int keywordCount) onTapKeyword,
  }) {
    // Make semicolon-separated content display on new lines
    final note = footnote.replaceAll('; ', ';\n');

    final List<TextSpan> spans = [];
    int start = 0;

    final keywords = manager.footnoteKeywords();
    final matches = keywords.allMatches(note);

    for (final match in matches) {
      // Add text before the match
      if (match.start > start) {
        spans.add(TextSpan(text: note.substring(start, match.start)));
      }

      // Add the matched keyword as a tappable span
      final matchedText = match.group(0)!;
      spans.add(
        TextSpan(
          text: matchedText,
          style: TextStyle(color: highlightColor),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              onTapKeyword(matchedText, matches.length);
            },
        ),
      );

      start = match.end;
    }

    // Add remaining text after the last match
    if (start < note.length) {
      spans.add(TextSpan(text: note.substring(start)));
    }

    return TextSpan(children: spans);
  }

  Future<void> _showDetailsDialog(String title, List<UsfmLine> passage) async {
    final fontSize = manager.textSize;
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
                    child: _buildPassage(passage, showHeadings: false),
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
