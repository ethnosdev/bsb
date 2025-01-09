import 'package:bsb/infrastructure/verse_line.dart';
import 'package:database_builder/schema.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

List<(TextSpan, TextType, Format?)> formatVerses(List<VerseLine> content, double baseFontSize, Color textColor,
    Color footnoteColor, void Function(String) onFootnoteTap) {
  final referenceSize = baseFontSize * 0.8;
  final mrTitleSize = baseFontSize * 1.2;
  final msTitleSize = baseFontSize * 1.5;
  final lightTextColor = textColor.withAlpha(150);

  final paragraphs = <(TextSpan, TextType, Format?)>[];
  var verseSpans = <TextSpan>[];
  int oldVerseNumber = 0;
  Format oldFormat = Format.m;

  for (final row in content) {
    final type = row.type;
    final format = row.format;
    final text = row.text;
    final verseNumber = row.verse;
    final footnote = row.footnote;

    if (type != TextType.v && verseSpans.isNotEmpty) {
      paragraphs.add((TextSpan(children: verseSpans), TextType.v, oldFormat));
      verseSpans = [];
    }

    switch (type) {
      case TextType.v:
        if (text == '\n') {
          paragraphs.add((TextSpan(children: verseSpans), type, oldFormat));
          verseSpans = [];
          break;
        }
        // add verse number
        if (oldVerseNumber != verseNumber) {
          oldVerseNumber = verseNumber;
          verseSpans.add(
            TextSpan(
              // Use NNBSP so the verse number is not separated from the verse text.
              text: '$verseNumber\u202f',
              style: TextStyle(
                fontSize: baseFontSize,
                color: lightTextColor,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.superscripts()],
              ),
            ),
          );
        }
        // add verse line text
        if (format == Format.qr) {
          _addVerseSpansWithFootnotes(
            verseSpans,
            text,
            TextStyle(
              fontSize: baseFontSize,
              fontStyle: FontStyle.italic,
            ),
            footnote,
            footnoteColor,
            onFootnoteTap,
          );
        } else {
          _addVerseSpansWithFootnotes(
            verseSpans,
            '$text ',
            TextStyle(
              fontSize: baseFontSize,
            ),
            footnote,
            footnoteColor,
            onFootnoteTap,
          );
        }

        // handle poetry
        if (format == Format.q1 || format == Format.q2 || format == Format.qr) {
          paragraphs.add((TextSpan(children: verseSpans), type, format));
          verseSpans = [];
        }
        oldFormat = format ?? Format.m;

      case TextType.d:
        final spans = <TextSpan>[];
        _addVerseSpansWithFootnotes(
          spans,
          text,
          TextStyle(
            fontSize: baseFontSize,
            fontStyle: FontStyle.italic,
          ),
          footnote,
          footnoteColor,
          onFootnoteTap,
        );
        paragraphs.add((
          TextSpan(children: spans),
          type,
          format,
        ));

      case TextType.r:
        paragraphs.add((
          TextSpan(
            text: text,
            style: TextStyle(
              fontSize: referenceSize,
              color: lightTextColor,
              fontStyle: FontStyle.italic,
            ),
          ),
          type,
          format,
        ));

      case TextType.s1:
        paragraphs.add((
          TextSpan(
            text: text,
            style: TextStyle(
              fontSize: baseFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          type,
          format,
        ));

      case TextType.s2:
        paragraphs.add((
          TextSpan(
            text: text,
            style: TextStyle(
              fontSize: baseFontSize,
              fontStyle: FontStyle.italic,
            ),
          ),
          type,
          format,
        ));

      case TextType.ms:
        paragraphs.add((
          TextSpan(
            text: text,
            style: TextStyle(
              fontSize: msTitleSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          type,
          format,
        ));

      case TextType.mr:
        paragraphs.add((
          TextSpan(
            text: text,
            style: TextStyle(
              fontSize: mrTitleSize,
              color: lightTextColor,
              fontStyle: FontStyle.italic,
            ),
          ),
          type,
          format,
        ));

      case TextType.qa:
        paragraphs.add((
          TextSpan(
            text: text,
            style: TextStyle(
              fontSize: baseFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          type,
          format,
        ));
    }
  }

  if (verseSpans.isNotEmpty) {
    paragraphs.add((TextSpan(children: verseSpans), TextType.v, oldFormat));
  }

  return paragraphs;
}

void _addVerseSpansWithFootnotes(
  List<InlineSpan> verseSpans,
  String text,
  TextStyle style,
  String? footnote,
  Color footnoteColor,
  void Function(String) onFootnoteTap,
) {
  if (footnote == null) {
    verseSpans.add(TextSpan(
      text: text,
      style: style,
    ));
    return;
  }

  /// The text may contain multiple footnotes. Each footnote is separated
  /// by a \n newline. The index and the footnote text are separated by a #.
  /// The indexes are exclusive, meaning the footnote text should be inserted before the index.
  ///
  /// Example footnote: 11#Or mist\n36#Or land
  /// Example text: "But springs welled up from the earth and watered the whole surface of the ground. "
  ///
  /// This means there should be a footnote marker at index 11 and 36.
  /// Resulting text: "But springs* welled up from the earth* and watered the whole surface of the ground. "
  final List<(int, String)> footnotes = footnote.split('\n').map((f) {
    final parts = f.split('#');
    return (int.parse(parts[0]), parts[1]);
  }).toList();

  int lastIndex = 0;
  for (var i = 0; i < footnotes.length; i++) {
    final (index, note) = footnotes[i];

    // Add text before footnote
    if (index > lastIndex) {
      verseSpans.add(TextSpan(
        text: text.substring(lastIndex, index),
        style: style,
      ));
    }

    // Add footnote marker
    verseSpans.add(TextSpan(
      text: '*',
      style: style.copyWith(color: footnoteColor),
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          onFootnoteTap(note);
        },
    ));

    lastIndex = index;
  }

  // Add remaining text after last footnote
  if (lastIndex < text.length) {
    verseSpans.add(TextSpan(
      text: text.substring(lastIndex),
      style: style,
    ));
  }
}
