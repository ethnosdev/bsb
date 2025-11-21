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
  final _selectionController = ScriptureSelectionController();
  static const lightTextOpacity = 0.6;

  @override
  void initState() {
    super.initState();
    manager.requestText(bookId: widget.bookId, chapter: widget.chapter);
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
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

  Widget _buildPassage(List<UsfmLine> verseLines, {bool showHeadings = true}) {
    UsfmPassage passage = UsfmPassage([]);
    int currentVerseNum = -1;
    int currentWordOffset = 0;

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
          if (line.verse != currentVerseNum) {
            passage.append([VerseNumber(line.verse.toString())], line.format);
            currentVerseNum = line.verse;
            currentWordOffset = 0;
          }
          final words = _getWords(line, currentWordOffset);
          currentWordOffset += words.whereType<Word>().length;
          passage.append(words, line.format);
        case ParagraphFormat.q1:
        case ParagraphFormat.q2:
        case ParagraphFormat.li1:
        case ParagraphFormat.li2:
        case ParagraphFormat.qr:
        case ParagraphFormat.pc:
          if (line.verse != currentVerseNum) {
            passage.append([VerseNumber(line.verse.toString())], line.format);
            currentVerseNum = line.verse;
            currentWordOffset = 0;
          }
          final words = _getWords(line, currentWordOffset);
          currentWordOffset += words.whereType<Word>().length;
          passage.append(words, line.format);
          passage.commit();
        case ParagraphFormat.d:
          // Titles usually don't change verse numbers, but we should still
          // respect the offset logic if they share a verse ID.
          final words = _getWords(line, currentWordOffset);
          currentWordOffset += words.whereType<Word>().length;
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
          // Increment offset in case a heading technically shares a verse ID
          final words = _getWords(line, currentWordOffset);
          currentWordOffset += words.whereType<Word>().length;
          passage.commit(words, line.format);
      }
    }
    passage.commit();
    return _buildPassageWidget(passage.paragraphs, manager);
  }

  List<ParagraphElement> _getWords(UsfmLine line, int startOffset) {
    final text = line.text;
    final id = line.bookChapterVerse;
    final list = <ParagraphElement>[];
    int wordId = (id * 1000) + startOffset;

    // Regex Breakdown:
    // 1. (\\f.+?\\f\*) -> Matches USFM footnote blocks like \f ... \f*
    // 2. (\s+)         -> Matches whitespace (separators)
    // 3. ([^\s\\]+)    -> Matches words (non-space, non-backslash)
    // Note: We use dotAll check or [\s\S] if footnotes span newlines,
    // but typically UsfmLine is single-line.
    final tokenizer = RegExp(r'(\\f.+?\\f\*)|(\s+)|([^\s\\]+)');

    final matches = tokenizer.allMatches(text);

    for (final match in matches) {
      final fullMatch = match.group(0)!;

      if (match.group(1) != null) {
        // --- IT IS A FOOTNOTE ---
        // Raw: \f + \fr 1:3 \ft Cited in 2 Corinthians 4:6\f*
        final cleanText = _extractUsfmFootnoteText(fullMatch);
        if (cleanText.isNotEmpty) {
          list.add(Footnote(cleanText));
        }
      } else if (match.group(3) != null) {
        // --- IT IS A WORD ---
        // We trim to be safe, though regex usually handles it
        list.add(Word(text: fullMatch, id: wordId.toString()));
        wordId++;
      }
      // If group(2) matches, it's whitespace; we loop to the next item.
    }

    return list;
  }

  /// Helper to clean USFM tags out of the footnote string.
  /// Turns: "\f + \fr 1:3 \ft Cited in 2 Cor 4:6\f*"
  /// Into:  "Cited in 2 Cor 4:6"
  String _extractUsfmFootnoteText(String rawUsfm) {
    // 1. Remove opening \f, closing \f*, and the caller + or -
    var content = rawUsfm.replaceAll(RegExp(r'^\\f\s*[+-]?\s*|\\f\*$'), '');

    // 2. Remove the Reference tag (\fr) AND its content entirely.
    content = content.replaceAll(RegExp(r'\\fr\s*[^\\\\]*'), '');

    // 3. Remove other tag markers (like \ft, \fq) but KEEP their content.
    // This removes "\ft " but leaves "Cited in..."
    content = content.replaceAll(RegExp(r'\\[a-z0-9]+\s*'), '');

    // 4. Clean up double spaces and trim
    return content.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Widget _buildPassageWidget(
      List<UsfmParagraph> paragraphs, ChapterManager manager) {
    final passageChildren = <Widget>[];

    for (final paragraph in paragraphs) {
      // final isSelectable = _isFormatSelectable(paragraph.format);
      final paragraphChildren =
          _getParagraphChildren(paragraph, _onFootnoteTapped);
      switch (paragraph.format) {
        case ParagraphFormat.b:
          _addParagraphSpacing(passageChildren, paragraph.format);
        case ParagraphFormat.m:
          passageChildren.add(ParagraphWidget(
            selectionController: _selectionController,
            children: paragraphChildren,
          ));
        case ParagraphFormat.pc:
          passageChildren.add(ParagraphWidget(
            selectionController: _selectionController,
            textAlign: TextAlign.center,
            children: paragraphChildren,
          ));
        case ParagraphFormat.qr:
          passageChildren.add(ParagraphWidget(
            selectionController: _selectionController,
            textAlign: TextAlign.right,
            children: paragraphChildren,
          ));
          _addParagraphSpacing(passageChildren, paragraph.format);
        case ParagraphFormat.q1:
        case ParagraphFormat.li1:
          passageChildren.add(ParagraphWidget(
            selectionController: _selectionController,
            firstLineIndent: 20,
            subsequentLinesIndent: 100,
            children: paragraphChildren,
          ));
        case ParagraphFormat.q2:
        case ParagraphFormat.li2:
          passageChildren.add(ParagraphWidget(
            selectionController: _selectionController,
            firstLineIndent: 60,
            subsequentLinesIndent: 100,
            children: paragraphChildren,
          ));
        case ParagraphFormat.pmo:
          passageChildren.add(ParagraphWidget(
            selectionController: _selectionController,
            firstLineIndent: 20,
            subsequentLinesIndent: 20,
            children: paragraphChildren,
          ));
        case ParagraphFormat.d:
          passageChildren.add(ParagraphWidget(
            selectionController: _selectionController,
            textAlign: TextAlign.center,
            children: paragraphChildren,
          ));
          _addParagraphSpacing(passageChildren, paragraph.format);
        case ParagraphFormat.r:
        case ParagraphFormat.mr:
          passageChildren.add(ParagraphWidget(
            selectionController: _selectionController,
            selectable: false,
            textAlign: TextAlign.center,
            children: paragraphChildren,
          ));
          _addParagraphSpacing(passageChildren, paragraph.format);
        case ParagraphFormat.s1:
        case ParagraphFormat.s2:
          _addParagraphSpacing(passageChildren, paragraph.format);
          passageChildren.add(ParagraphWidget(
            selectionController: _selectionController,
            selectable: false,
            children: paragraphChildren,
          ));
          _addParagraphSpacing(passageChildren, paragraph.format);
        case ParagraphFormat.ms:
          passageChildren.add(ParagraphWidget(
            selectionController: _selectionController,
            selectable: false,
            textAlign: TextAlign.center,
            children: paragraphChildren,
          ));
        case ParagraphFormat.qa:
          passageChildren.add(ParagraphWidget(
            selectionController: _selectionController,
            selectable: false,
            children: paragraphChildren,
          ));
      }
    }

    // remove last paragraph space
    if (passageChildren.isNotEmpty && passageChildren.last is SizedBox) {
      passageChildren.removeLast();
    }

    return SelectableScripture(
      controller: _selectionController,
      child: PassageWidget(
        children: passageChildren,
      ),
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
    final verseNumberStyle =
        style.copyWith(color: style.color!.withValues(alpha: lightTextOpacity));
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
              style: verseNumberStyle,
              padding: const EdgeInsets.only(right: 4.0),
            ),
            WordWidget(
              text: nextWord.text,
              id: nextWord.id,
              style: style,
              onLongPress: _handleWordLongPress,
              selectionController: _selectionController,
            ),
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
              onLongPress: _handleWordLongPress,
              selectionController: _selectionController,
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
            text: currentElement.text,
            id: currentElement.id,
            style: style,
            onLongPress: _handleWordLongPress,
            selectionController: _selectionController,
          ),
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

  void _handleWordLongPress(String unusedText, String wordIdText) {
    final wordId = int.tryParse(wordIdText);
    if (wordId == null) return;

    final targetVerseRef = wordId ~/ 1000;

    String? startId;
    String? endId;

    final lines = manager.textParagraphNotifier.value;

    // 1. Tracking State (Must mirror _buildPassage exactly)
    int currentVerseNum = -1;
    int currentWordOffset = 0;

    for (final line in lines) {
      // 2. SKIP formats that _buildPassage skips (b, r)
      // If we don't skip these, we might try to process them and mess up IDs
      if (line.format == ParagraphFormat.b ||
          line.format == ParagraphFormat.r) {
        continue;
      }

      // 3. Handle State Resets based on Format
      // In _buildPassage, 'm', 'q1', etc update the verse counter.
      // 'd', 's1', etc DO NOT update the verse counter.

      bool isBiblicalText = false;
      switch (line.format) {
        case ParagraphFormat.m:
        case ParagraphFormat.pmo:
        case ParagraphFormat.q1:
        case ParagraphFormat.q2:
        case ParagraphFormat.li1:
        case ParagraphFormat.li2:
        case ParagraphFormat.qr:
        case ParagraphFormat.pc:
          isBiblicalText = true;
        default:
          isBiblicalText = false;
      }

      if (isBiblicalText) {
        // Only these formats trigger a check for verse change
        if (line.verse != currentVerseNum) {
          currentVerseNum = line.verse;
          currentWordOffset = 0;
        }
      }
      // Note: If format is 'd' or 's1', we DO NOT update currentVerseNum
      // This ensures that if a title is inserted in the middle of a verse,
      // the offset continues accumulating correctly for the next part of the verse.

      // 4. Check if this line matches our Target Verse
      // We check line.bookChapterVerse directly.
      if (line.bookChapterVerse == targetVerseRef) {
        final words = _getWords(line, currentWordOffset);

        for (final w in words) {
          if (w is Word) {
            startId ??= w.id; // First matching word
            endId = w.id; // Continuously update to capture the very last one
          }
        }
      }

      // 5. Increment Offset for the next iteration
      // We calculate the word count exactly as _getWords does
      final wordCount = _getWords(line, 0).whereType<Word>().length;
      currentWordOffset += wordCount;
    }

    // 6. Apply Selection
    if (startId != null && endId != null) {
      _selectionController.selectRange(startId, endId);
    }
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
      case ParagraphFormat.pc:
        return defaultStyle;
      case ParagraphFormat.qr:
      case ParagraphFormat.d:
      case ParagraphFormat.r:
      case ParagraphFormat.s2:
        return defaultStyle.copyWith(fontStyle: FontStyle.italic);
      case ParagraphFormat.qa:
      case ParagraphFormat.s1:
        return defaultStyle.copyWith(fontWeight: FontWeight.bold);
      case ParagraphFormat.ms:
        return defaultStyle.copyWith(
          fontSize: 1.5 * normalTextSize,
          fontWeight: FontWeight.bold,
        );
      case ParagraphFormat.mr:
        return defaultStyle.copyWith(
          fontSize: 1.2 * normalTextSize,
          fontStyle: FontStyle.italic,
          color: defaultStyle.color!.withValues(alpha: lightTextOpacity),
        );
    }
  }

  void _onFootnoteTapped(String footnoteText) {
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
