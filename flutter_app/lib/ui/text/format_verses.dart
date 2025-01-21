import 'package:bsb/infrastructure/verse_line.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

List<(TextSpan, TextType, Format?)> formatVerses(
  List<VerseLine> content,
  double baseFontSize,
  Color textColor,
  Color footnoteColor,
  void Function(String) onFootnoteTap,
) {
  final mrTitleSize = baseFontSize * 1.2;
  final msTitleSize = baseFontSize * 1.5;
  final lightTextColor = textColor.withAlpha(150);

  final paragraphs = <(TextSpan, TextType, Format?)>[];
  var verseSpans = <TextSpan>[];
  int oldVerseNumber = 0;
  Format oldFormat = Format.m;

  for (var i = 0; i < content.length; i++) {
    final row = content[i];
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
        // Skip as references are now handled in TextType.s1
        break;

      case TextType.s1:
        final spans = <TextSpan>[];
        String? reference;
        // Check if next row is a reference
        if (i + 1 < content.length && content[i + 1].type == TextType.r) {
          reference = content[i + 1].text;
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
                  onFootnoteTap(reference!);
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
                  onFootnoteTap(reference!);
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
  List<TextSpan> verseSpans,
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
    ));
  }
}
