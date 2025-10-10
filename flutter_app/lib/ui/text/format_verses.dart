import 'package:bsb/infrastructure/verse_line.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

List<(TextSpan, ParagraphFormat)> formatVerses({
  required List<VerseLine> verseLines,
  required double baseFontSize,
  Color? textColor,
  Color? footnoteColor,
  void Function(int)? onVerseLongPress,
  void Function(String)? onFootnoteTap,
  bool showVerseNumbers = true,
  bool showSectionTitles = true,
}) {
  final mrTitleSize = baseFontSize * 1.2;
  final msTitleSize = baseFontSize * 1.5;
  final lightTextColor = textColor?.withAlpha(150);

  final paragraphs = <(TextSpan, ParagraphFormat)>[];
  var verseSpans = <TextSpan>[];
  int oldVerseNumber = 0;
  ParagraphFormat oldFormat = ParagraphFormat.m;

  for (var i = 0; i < verseLines.length; i++) {
    final row = verseLines[i];
    final format = row.format;
    final text = row.text;
    final verseNumber = row.verse;
    final footnote = row.footnote;

    if (!format.isBiblicalText && verseSpans.isNotEmpty) {
      paragraphs.add((TextSpan(children: verseSpans), oldFormat));
      verseSpans = [];
    }

    if (format == ParagraphFormat.b) {
      paragraphs.add((TextSpan(children: verseSpans), oldFormat));
      verseSpans = [];
      break;
    } else if (format.isBiblicalText) {
      // add verse number
      if (showVerseNumbers && oldVerseNumber != verseNumber) {
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
      if (format == ParagraphFormat.qr) {
        _addVerseSpansWithFootnotes(
          verseSpans: verseSpans,
          text: text,
          style: TextStyle(
            fontSize: baseFontSize,
            fontStyle: FontStyle.italic,
          ),
          footnote: footnote,
          footnoteColor: footnoteColor,
          onFootnoteTap: onFootnoteTap,
          verseNumber: verseNumber,
          onVerseLongPress: onVerseLongPress,
        );
      } else {
        _addVerseSpansWithFootnotes(
          verseSpans: verseSpans,
          text: '$text ',
          style: TextStyle(
            fontSize: baseFontSize,
          ),
          footnote: footnote,
          footnoteColor: footnoteColor,
          onFootnoteTap: onFootnoteTap,
          verseNumber: verseNumber,
          onVerseLongPress: onVerseLongPress,
        );
      }

      // handle poetry
      if (format == ParagraphFormat.q1 ||
          format == ParagraphFormat.q2 ||
          format == ParagraphFormat.qr) {
        paragraphs.add((TextSpan(children: verseSpans), format));
        verseSpans = [];
      }
      oldFormat = format;
    } else if (format == ParagraphFormat.d) {
      final spans = <TextSpan>[];
      _addVerseSpansWithFootnotes(
        verseSpans: spans,
        text: text,
        style: TextStyle(
          fontSize: baseFontSize,
          fontStyle: FontStyle.italic,
        ),
        footnote: footnote,
        footnoteColor: footnoteColor,
        onFootnoteTap: onFootnoteTap,
        verseNumber: verseNumber,
        onVerseLongPress: onVerseLongPress,
      );
      paragraphs.add((
        TextSpan(children: spans),
        format,
      ));
    } else if (format == ParagraphFormat.r) {
      // Skip because cross references are now handled in TextType.s1
      break;
    } else if (format == ParagraphFormat.s1) {
      if (!showSectionTitles) break;
      final spans = <TextSpan>[];
      String? reference;
      // Check if next row is a reference
      if (i + 1 < verseLines.length &&
          verseLines[i + 1].format == ParagraphFormat.r) {
        reference = verseLines[i + 1].text;
        i++; // Skip the reference row since we're handling it here
      }
      if (reference != null) {
        // Strip parentheses from reference
        reference = reference.replaceAll(RegExp(r'[()]'), '');
        spans.addAll([
          TextSpan(
            text: text,
            style: TextStyle(
              fontSize: baseFontSize,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                onFootnoteTap?.call(reference!);
              },
          ),
          TextSpan(
            text: '*',
            style: TextStyle(
              fontSize: baseFontSize,
              fontWeight: FontWeight.bold,
              color: footnoteColor,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                onFootnoteTap?.call(reference!);
              },
          ),
        ]);
      } else {
        spans.add(TextSpan(
          text: text,
          style: TextStyle(
            fontSize: baseFontSize,
            fontWeight: FontWeight.bold,
          ),
        ));
      }
      paragraphs.add((
        TextSpan(children: spans),
        format,
      ));
    } else if (format == ParagraphFormat.s2) {
      if (!showSectionTitles) break;
      paragraphs.add((
        TextSpan(
          text: text,
          style: TextStyle(
            fontSize: baseFontSize,
            fontStyle: FontStyle.italic,
          ),
        ),
        format,
      ));
    } else if (format == ParagraphFormat.ms) {
      if (!showSectionTitles) break;
      paragraphs.add((
        TextSpan(
          text: text,
          style: TextStyle(
            fontSize: msTitleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        format,
      ));
    } else if (format == ParagraphFormat.mr) {
      if (!showSectionTitles) break;
      paragraphs.add((
        TextSpan(
          text: text,
          style: TextStyle(
            fontSize: mrTitleSize,
            color: lightTextColor,
            fontStyle: FontStyle.italic,
          ),
        ),
        format,
      ));
    } else if (format == ParagraphFormat.qa) {
      if (!showSectionTitles) break;
      paragraphs.add((
        TextSpan(
          text: text,
          style: TextStyle(
            fontSize: baseFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        format,
      ));
    }
  }

  if (verseSpans.isNotEmpty) {
    paragraphs.add((TextSpan(children: verseSpans), oldFormat));
  }

  return paragraphs;
}

void _addVerseSpansWithFootnotes({
  required List<TextSpan> verseSpans,
  required String text,
  required TextStyle style,
  required String? footnote,
  required Color? footnoteColor,
  required int verseNumber,
  required void Function(int)? onVerseLongPress,
  required void Function(String)? onFootnoteTap,
}) {
  final longPressCallback = (onVerseLongPress == null) //
      ? null
      : LongPressGestureRecognizer()
    ?..onLongPress = () => onVerseLongPress?.call(verseNumber);

  if (footnote == null || onFootnoteTap == null) {
    verseSpans.add(TextSpan(
      text: text,
      style: style,
      recognizer: longPressCallback,
    ));
    return;
  }

  // The text may contain multiple footnotes. Each footnote is separated
  // by a \n newline. The index and the footnote text are separated by a #.
  // The indexes are exclusive, meaning the footnote text should be inserted
  // before the index.
  //
  // Example footnote: 11#Or mist\n36#Or land
  // Example text: "But springs welled up from the earth and watered the whole
  // surface of the ground. "
  //
  // This means there should be a footnote marker at index 11 and 36.
  // Resulting text: "But springs* welled up from the earth* and watered the
  // whole surface of the ground. "
  final List<(int, String)> footnotes = footnote.split('\n').map((f) {
    final parts = f.split('#');
    return (int.parse(parts[0]), parts[1]);
  }).toList();

  int lastIndex = 0;
  for (var i = 0; i < footnotes.length; i++) {
    final (index, note) = footnotes[i];

    // Add text before the word with footnote
    if (index > lastIndex) {
      final beforeText = text.substring(lastIndex, index);
      final lastSpace = beforeText.lastIndexOf(' ');

      if (lastSpace != -1) {
        // Add text up to the last word
        verseSpans.add(TextSpan(
          text: beforeText.substring(0, lastSpace + 1),
          style: style,
          recognizer: longPressCallback,
        ));

        // Add the last word and footnote marker together as tappable
        verseSpans.addAll([
          TextSpan(
            text: beforeText.substring(lastSpace + 1),
            style: style,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                onFootnoteTap(note);
              },
          ),
          TextSpan(
            text: '*',
            style: style.copyWith(color: footnoteColor),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                onFootnoteTap(note);
              },
          )
        ]);
      } else {
        // If no space found, make the entire text tappable
        verseSpans.addAll([
          TextSpan(
            text: beforeText,
            style: style,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                onFootnoteTap(note);
              },
          ),
          TextSpan(
            text: '*',
            style: style.copyWith(color: footnoteColor),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                onFootnoteTap(note);
              },
          )
        ]);
      }
    } else {
      // If at start of text, just add the footnote marker
      verseSpans.add(TextSpan(
        text: '*',
        style: style.copyWith(color: footnoteColor),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            onFootnoteTap(note);
          },
      ));
    }

    lastIndex = index;
  }

  // Add remaining text after last footnote
  if (lastIndex < text.length) {
    verseSpans.add(TextSpan(
      text: text.substring(lastIndex),
      style: style,
      recognizer: longPressCallback,
    ));
  }
}
