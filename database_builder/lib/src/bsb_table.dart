import 'dart:io';

import 'package:scripture/scripture_core.dart';

import 'book_id.dart';
import 'database_helper.dart';
import 'utils/bsb_utils.dart';

Future<void> createBsbTable(DatabaseHelper dbHelper) async {
  final directory = Directory('bsb_usfm');

  if (!await directory.exists()) {
    print('Directory does not exist');
    return;
  }

  dbHelper.beginTransaction();

  int bookId = 0;
  int chapter = 0;
  int verse = 0;
  String? text;
  ParagraphFormat? format;
  String? footnote;

  for (String bookFilename in bibleBookFilenames) {
    print('Processing: $bookFilename');
    final file = File('${directory.path}/$bookFilename');

    if (!file.existsSync()) {
      throw Exception('${file.path} does not exist');
    }

    final lines = await file.readAsLines();
    for (String newLine in lines) {
      // split at a space or a newline and take the text before it
      String marker = newLine.split(RegExp(r'[ \n]'))[0];
      final remainder = newLine.substring(marker.length).trim();
      marker = marker.replaceAll(r'\', '');
      switch (marker) {
        case 'id': // book
          bookId = _getBookId(remainder);
          format = null;
          continue;
        case 'h': // book title
        case 'toc1': // book title
        case 'toc2': // book title
        case 'mt1': // book title
          // ignore
          continue;
        case 'c': // chapter
          chapter = _getChapter(remainder);
          verse = 0;
          continue;
        case 's1': // section heading level 1
        case 's2': // section heading level 2
        case 'r': // cross reference
        case 'ms': // major section (Psalms)
        case 'mr': // major section range (Psalms)
        case 'qa': // Acrostic heading (Psalm 119)
        case 'm': // margin
        case 'pmo': // indented paragraph margin opening
        case 'li1': // list item level 1
        case 'li2': // list item level 2
          format = ParagraphFormat.fromJson(marker);
          if (remainder.isEmpty) {
            continue;
          }
          text = remainder;
        case 'v': // verse
          (verse, text) = _getVerse(remainder);
        case 'd': // descriptive title
          format = ParagraphFormat.d;
          if (remainder.isEmpty) {
            continue;
          }
          text = remainder;
          verse = 0;
        case 'b': // break
          format = ParagraphFormat.b;
          text = '\n';
        case 'q1': // poetry indentation level 1
          format = ParagraphFormat.q1;
          if (remainder.isEmpty) {
            continue;
          }
          text = remainder;
        case 'q2': // poetry indentation level 2
          format = ParagraphFormat.q2;
          if (remainder.isEmpty) {
            continue;
          }
          text = remainder;
        case 'pc': // centered
          const habakkuk = 35;
          if (bookId == habakkuk && chapter == 3 && verse == 19) {
            // This should really be fixed in the original USFM file,
            // but we need to make it centered and italic like TextType.d.
            format = ParagraphFormat.d;
            text = _removeItalicMarkers(remainder);
          } else {
            format = ParagraphFormat.pc;
            if (remainder.isEmpty) {
              continue;
            }
            text = remainder;
          }
        case 'qr': // right aligned
          format = ParagraphFormat.qr;
          if (remainder.isEmpty) {
            continue;
          }
          text = remainder;
        default:
          throw Exception(
              'Unknown marker: $marker (chapter: $chapter, verse: $verse)');
      }

      (text, footnote) = extractFootnote(text);

      if (format == null) {
        print('Format null at: $marker (chapter: $chapter, verse: $verse)');
        return;
      }

      dbHelper.insertBsbLine(
        bookId: bookId,
        chapter: chapter,
        verse: verse,
        text: text,
        // type: type.id,
        format: format.id,
        footnote: footnote,
      );

      footnote = null;
      text = null;
    }

    // Uncomment this for testing the first book only:
    // break;
  }

  dbHelper.commitTransaction();
}

int _getBookId(String textAfterMarker) {
  final index = textAfterMarker.indexOf(' ');
  final bookName = textAfterMarker.substring(0, index);
  return bookAbbreviationToIdMap[bookName]!;
}

int _getChapter(String textAfterMarker) {
  return int.parse(textAfterMarker);
}

(int, String) _getVerse(String textAfterMarker) {
  final index = textAfterMarker.indexOf(' ');
  final verseNumber = int.parse(textAfterMarker.substring(0, index));
  final remainder = textAfterMarker.substring(index).trim();
  return (verseNumber, remainder);
}

/// Extracts the footnote from the text.
///
/// The text may contain multiple footnotes. Each footnote is separated
/// by a \n newline. The index and the footnote text are separated by a #.
/// Example: "But springs \f + \fr 2:6 \ft Or mist\f* welled up from the earth \f + \fr 2:6 \ft Or land\f* and watered the whole surface of the ground. "
/// New text: "But springs welled up from the earth and watered the whole surface of the ground. "
/// The output will be:
/// footnote: 11#Or mist\n36#Or land
/// The indexes are exclusive, meaning the footnote text should be inserted before the index.
(String outputText, String? footnote) extractFootnote(String text) {
  if (!text.contains('\\f')) {
    return (text, null);
  }

  final footnotes = <String>[];
  var modifiedText = text;

  while (modifiedText.contains('\\f')) {
    final startIndex = modifiedText.indexOf('\\f');
    final endIndex = modifiedText.indexOf('\\f*', startIndex) + 3;

    if (endIndex == -1) {
      throw Exception('Malformed footnote: missing closing tag');
    }

    final footnote = modifiedText.substring(startIndex, endIndex);
    final ftIndex = footnote.indexOf('\\ft');
    var footnoteIndex = modifiedText.indexOf('\\f', startIndex);
    // if a footnote comes after a space, the index is shifted by one to the left.
    // This is so that footnote markers may be inserted directly after a word.
    if (footnoteIndex > 0 && modifiedText[footnoteIndex - 1] == ' ') {
      footnoteIndex--;
    }
    final footnoteText =
        footnote.substring(ftIndex + 4, footnote.length - 3).trim();
    footnotes.add('$footnoteIndex#$footnoteText');
    // Remove footnote from text
    modifiedText = modifiedText
        .replaceRange(startIndex, endIndex, '')
        .replaceAll('  ', ' ');
  }

  return (modifiedText.trim(), footnotes.join('\n'));
}

String _removeItalicMarkers(String text) {
  // Original: \it For the choirmaster. With stringed instruments. \it*
  // Desired: For the choirmaster. With stringed instruments.
  final modifiedText = text.replaceAll(r'\it*', '').replaceAll(r'\it', '');
  return modifiedText.trim();
}
