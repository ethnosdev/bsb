import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/extrabiblical_texts.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/source_texts.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/text/format_verses.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef TextParagraph = List<(TextSpan, TextType, Format?)>;

/// This class manages one PageView page while TextScreenManager manages
/// the entire screen.
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
    required void Function(String tappedKeyword, int keywordCount) onTapKeyword,
  }) {
    // Make semicolon-separated content display on new lines
    final note = footnote.replaceAll('; ', ';\n');

    const verseRange = '\\d+:\\d+(?:–\\d+)?';
    final patterns = [
      ...validBookNames.map((kw) => '$kw $verseRange'),
      ...sourceTexts.keys.map((kw) => '\\b$kw\\b'),
      ...validExtraBiblicalTexts.keys,
    ].join('|');
    final regex = RegExp('($patterns)');

    final List<TextSpan> spans = [];
    int start = 0;

    final matches = regex.allMatches(note);

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

  // Returns the title and text body for a given tapped keyword.
  // If a cross reference, then show the source text.
  // If a source text abbreviation, then show the full name.
  // If extrabiblical text, then show the source text.
  Future<TextParagraph?> lookupFootnoteDetails(String keyword) async {
    final reference = Reference.tryParse(keyword);
    if (reference != null) {
      final content = await _dbHelper.getRange(reference);
      return formatVerses(
        verseLines: content,
        baseFontSize: _normalTextSize,
        showSectionTitles: false,
        showVerseNumbers: false,
      );
    }

    if (sourceTexts.containsKey(keyword)) {
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

    return _extrabiblicalContent(keyword);
  }

  TextParagraph? _extrabiblicalContent(String keyword) {
    String? content;
    switch (keyword) {
      case 'Jasher 79:27':
        content = jasher7927;
      case 'Jasher 88:63':
        content = jasher8863;
      case 'Jasher 88:64':
        content = jasher8864;
      case '1 Esdras 8:32':
        content = esdras832;
      case '1 Esdras 8:36':
        content = esdras836;
      case '1 Enoch 1:9':
        content = enoch1;
      case '1 Enoch 13:1–11':
        content = enoch13;
      case '1 Enoch 20:1–4':
        content = enoch20;
      default:
        content = null;
    }
    if (content == null) return null;
    final formattedSource = TextSpan(
      text: content,
      style: TextStyle(
        fontSize: _normalTextSize,
      ),
    );
    return [(formattedSource, TextType.v, null)];
  }

  Future<String> verseTextForClipboard(
    int bookId,
    int chapter,
    int verseNumber,
  ) async {
    final reference = Reference(
      bookId: bookId,
      chapter: chapter,
      verse: verseNumber,
    );
    final verse = await _dbHelper.getRange(reference);
    final verseString = StringBuffer();
    for (final line in verse) {
      if (line.text == '\n') continue;
      verseString.write(line.text);
      verseString.write(' ');
    }
    verseString.write('($reference)');
    return verseString.toString();
  }
}
