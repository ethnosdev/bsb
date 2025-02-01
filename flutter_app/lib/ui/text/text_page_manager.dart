import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/source_texts.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/text/format_verses.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef TextParagraph = List<(TextSpan, TextType, Format?)>;

class TextPageManager {
  final _dbHelper = getIt<DatabaseHelper>();
  final textParagraphNotifier = ValueNotifier<TextParagraph>([]);

  double _normalTextSize = 14.0;
  double get paragraphSpacing => _normalTextSize * 0.6;

  Future<void> requestText({
    required int bookId,
    required int chapter,
    required Color textColor,
    required Color footnoteColor,
    required void Function(int) onVerseLongPress,
    required void Function(String) onFootnoteTap,
  }) async {
    final content = await _dbHelper.getChapter(bookId, chapter);
    _normalTextSize = getIt<UserSettings>().textSize;
    final formattedContent = formatVerses(
      verseLines: content,
      baseFontSize: _normalTextSize,
      textColor: textColor,
      footnoteColor: footnoteColor,
      onVerseLongPress: onVerseLongPress,
      onFootnoteTap: onFootnoteTap,
    );
    textParagraphNotifier.value = formattedContent;
  }

  TextSpan formatFootnote({
    required String footnote,
    required Color highlightColor,
    required void Function(String tappedKeyword) onTapKeyword,
  }) {
    // Make semicolon-separated content display on new lines
    final note = footnote.replaceAll('; ', ';\n');

    final patterns = [
      Reference.regex.pattern,
      ...sourceTexts.keys.map((kw) => RegExp.escape(kw)),
    ].join('|');
    final regex = RegExp('($patterns)');

    final List<TextSpan> spans = [];
    int start = 0;

    for (final match in regex.allMatches(note)) {
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
              onTapKeyword(matchedText);
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

  // Returns the title and text body for a given tapped keyword.
  // They keyword can either be a cross reference or a source text name.
  // If a cross reference, then show the source text.
  // If a source text abbreviation, then show the full name.
  Future<TextParagraph?> lookupFootnoteDetails(String keyword) async {
    if (Reference.isValid(keyword)) {
      final reference = Reference.tryParse(keyword)!;
      final content = await _dbHelper.getRange(reference);
      return formatVerses(
        verseLines: content,
        baseFontSize: _normalTextSize,
        showSectionTitles: false,
        showVerseNumbers: false,
      );
    } else if (sourceTexts.containsKey(keyword)) {
      final source = sourceTexts[keyword]!;
      final withNewLine = source.replaceAll('; ', '\n');
      final formattedSource = TextSpan(
        text: withNewLine,
        style: TextStyle(
          fontSize: _normalTextSize,
        ),
      );
      return [(formattedSource, TextType.v, null)];
    }
    return null;
  }
}
