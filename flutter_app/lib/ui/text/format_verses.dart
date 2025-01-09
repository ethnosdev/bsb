import 'package:bsb/infrastructure/verse_line.dart';
import 'package:database_builder/schema.dart';
import 'package:flutter/widgets.dart';

List<(InlineSpan, TextType, Format?)> formatVerses(
  List<VerseLine> content,
  double baseFontSize,
  Color textColor,
) {
  final referenceSize = baseFontSize * 0.8;
  final mrTitleSize = baseFontSize * 1.2;
  final msTitleSize = baseFontSize * 1.5;
  final lightTextColor = textColor.withAlpha(150);

  final paragraphs = <(InlineSpan, TextType, Format?)>[];
  var verseSpans = <InlineSpan>[];
  int oldVerseNumber = 0;
  Format oldFormat = Format.m;

  for (final row in content) {
    final type = row.type;
    final format = row.format;
    final text = row.text;
    final verseNumber = row.verse;

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
          verseSpans.add(TextSpan(
            text: text,
            style: TextStyle(
              fontSize: baseFontSize,
              fontStyle: FontStyle.italic,
            ),
          ));
        } else {
          verseSpans.add(TextSpan(
            text: '$text ',
            style: TextStyle(
              fontSize: baseFontSize,
            ),
          ));
        }

        // handle poetry
        if (format == Format.q1 || format == Format.q2 || format == Format.qr) {
          paragraphs.add((TextSpan(children: verseSpans), type, format));
          verseSpans = [];
        }
        oldFormat = format ?? Format.m;

      case TextType.d:
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
