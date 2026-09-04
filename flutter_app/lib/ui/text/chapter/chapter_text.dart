import 'package:bsb/ui/text/chapter/chapter_manager.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

class ChapterText extends StatefulWidget {
  const ChapterText({
    super.key,
    required this.bookId,
    required this.chapter,
    this.onSelectionChanged,
  });

  final int bookId;
  final int chapter;
  final void Function(ScriptureSelectionController controller)?
  onSelectionChanged;

  @override
  State<ChapterText> createState() => _ChapterTextState();
}

class _ChapterTextState extends State<ChapterText>
    with AutomaticKeepAliveClientMixin {
  final manager = ChapterManager();
  final _selectionController = ScriptureSelectionController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    manager.requestText(bookId: widget.bookId, chapter: widget.chapter);
    _selectionController.addListener(_handleSelectionChange);
  }

  @override
  void dispose() {
    _selectionController.removeListener(_handleSelectionChange);
    _selectionController.dispose();
    super.dispose();
  }

  void _handleSelectionChange() {
    if (mounted && widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(_selectionController);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    return ValueListenableBuilder<List<UsfmLine>>(
      valueListenable: manager.textParagraphNotifier,
      builder: (context, verseLines, child) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              top: 16.0,
              right: 16.0,
              bottom: screenHeight * 0.8,
            ),
            child: UsfmWidget(
              verseLines: verseLines,
              selectionController: _selectionController,
              onFootnoteTapped: _onFootnoteTapped,
              onWordTapped: (id) => print("Tapped word $id"),
              onSelectionRequested: (wordId) {
                ScriptureLogic.highlightVerse(
                  _selectionController,
                  verseLines,
                  wordId,
                );
              },
              styleBuilder: (format) {
                return UsfmParagraphStyle.usfmDefaults(
                  format: format == ParagraphFormat.p
                      ? ParagraphFormat.m
                      : format,
                  baseStyle: Theme.of(context).textTheme.bodyMedium!
                      .copyWith(fontSize: manager.textSize),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _onFootnoteTapped(String footnoteText) {
    final details = formatFootnote(
      footnote: footnoteText,
      highlightColor: Theme.of(context).colorScheme.primary,
      keywords: manager.footnoteKeywords(),
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
          style: TextStyle(fontSize: manager.textSize),
        ),
      ),
    );
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
                    child: UsfmWidget(
                      verseLines: passage,
                      selectionController: ScriptureSelectionController(),
                      selectionColor: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.3),
                      onFootnoteTapped: _onFootnoteTapped,
                      styleBuilder: (format) {
                        return UsfmParagraphStyle.usfmDefaults(
                          format: format == ParagraphFormat.p
                              ? ParagraphFormat.m
                              : format,
                          baseStyle: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(fontSize: manager.textSize),
                        );
                      },
                      showHeadings: false,
                      showVerseNumbers: false,
                    ),
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

TextSpan formatFootnote({
  required String footnote,
  required Color highlightColor,
  required RegExp keywords,
  required void Function(String tappedKeyword, int keywordCount) onTapKeyword,
}) {
  // Make semicolon-separated content display on new lines
  final note = footnote.replaceAll('; ', ';\n');

  final List<TextSpan> spans = [];
  int start = 0;
  bool isItalic = false;

  // Match \fqa* first (without trailing spaces), then \fqa (with trailing space separator), then keywords
  final tagOrKeywordPattern =
      RegExp(r'(\\fqa\*)|(\\fqa)\s*|' + keywords.pattern);
  final matches = tagOrKeywordPattern.allMatches(note);

  for (final match in matches) {
    // Add text before the match
    if (match.start > start) {
      final text = note.substring(start, match.start);
      if (text.isNotEmpty) {
        spans.add(
          TextSpan(
            text: text,
            style: isItalic
                ? const TextStyle(fontStyle: FontStyle.italic)
                : null,
          ),
        );
      }
    }

    final isFqaClose = match.group(1) != null;
    final isFqaOpen = match.group(2) != null;
    final matchedText = match.group(0)!;

    if (isFqaClose) {
      isItalic = false;
    } else if (isFqaOpen) {
      isItalic = true;
    } else {
      // Add the matched keyword as a tappable span
      spans.add(
        TextSpan(
          text: matchedText,
          style: TextStyle(
            color: highlightColor,
            fontStyle: isItalic ? FontStyle.italic : null,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              onTapKeyword(matchedText, matches.length);
            },
        ),
      );
    }

    start = match.end;
  }

  // Add remaining text after the last match
  if (start < note.length) {
    final text = note.substring(start);
    if (text.isNotEmpty) {
      spans.add(
        TextSpan(
          text: text,
          style: isItalic
              ? const TextStyle(fontStyle: FontStyle.italic)
              : null,
        ),
      );
    }
  }

  return TextSpan(children: spans);
}
