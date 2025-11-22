import 'package:bsb/ui/text/chapter/chapter_manager.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:scripture/scripture.dart';

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

class _ChapterTextState extends State<ChapterText> {
  final manager = ChapterManager();
  final _selectionController = ScriptureSelectionController();

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
    return ValueListenableBuilder<List<UsfmLine>>(
      valueListenable: manager.textParagraphNotifier,
      builder: (context, verseLines, child) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: UsfmWidget(
              verseLines: verseLines,
              selectionController: _selectionController,
              onFootnoteTapped: _onFootnoteTapped,
              onWordTapped: (id) => print("Tapped word $id"),
              onSelectionRequested: (wordId) {
                ScriptureLogic.highlightVerse(
                    _selectionController, verseLines, wordId);
              },
              styleBuilder: (format) {
                return UsfmParagraphStyle.usfmDefaults(
                  format: format,
                  baseStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium!
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
                    child: UsfmWidget(
                      verseLines: passage,
                      selectionController: ScriptureSelectionController(),
                      styleBuilder: (format) {
                        return UsfmParagraphStyle.usfmDefaults(
                          format: format,
                          baseStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontSize: manager.textSize),
                        );
                      },
                      showHeadings: false,
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
