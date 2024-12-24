import 'dart:io';

import 'package:database_builder/database_helper.dart';
import 'package:database_builder/schema.dart';
import 'package:database_builder/utils/utils.dart';

import 'book_id.dart';

Future<void> createDatabase() async {
  final dbHelper = DatabaseHelper();
  dbHelper.deleteDatabase();
  dbHelper.init();

  final directory = Directory('bsb_usfm');

  if (!await directory.exists()) {
    print('Directory does not exist');
    return;
  }

  int bookId = -1;
  int chapter = -1;
  int verse = -1;
  int line = -1;
  String? text;
  Format? format;
  String? footnote;
  TextType? type;

  for (String bookFilename in bibleBooks) {
    print('Processing: $bookFilename');
    final file = File('${directory.path}/$bookFilename');

    if (!file.existsSync()) {
      continue;
    }

    final lines = await file.readAsLines();
    for (String newLine in lines) {
      var marker = newLine.split(RegExp(r'[ \n]'))[0];
      final remainder = newLine.substring(marker.length).trim();
      marker = marker.replaceAll(r'\', '');
      switch (marker) {
        case 'id': // book
          bookId = _getBookId(remainder);
          type = null;
          continue;
        case 'h': // book title
        case 'toc1': // book title
        case 'toc2': // book title
        case 'mt1': // book title
          // ignore
          continue;
        case 'c': // chapter
          chapter = _getChapter(remainder);
          verse = -1;
          line = -1;
          continue;
        case 's1': // section heading level 1
          type = TextType.s1;
          text = remainder;
        case 's2': // section heading level 2
          type = TextType.s2;
          text = remainder;
        case 'r': // cross reference
          type = TextType.r;
          text = remainder;
        case 'ms': // major section (Psalms)
          type = TextType.ms;
          text = remainder;
        case 'mr': // major section range (Psalms)
          type = TextType.mr;
          text = remainder;
        case 'qa': // Acrostic heading (Psalm 119)
          type = TextType.qa;
          text = remainder;
        case 'm': // margin
          format = Format.m;
          if (remainder.isEmpty) {
            continue;
          }
          text = remainder;
          line++;
        case 'pmo': // indented paragraph margin opening
          format = Format.pmo;
          if (remainder.isEmpty) {
            continue;
          }
          text = remainder;
          line++;
        case 'li1': // list item level 1
          format = Format.li1;
          if (remainder.isEmpty) {
            continue;
          }
          text = remainder;
          line++;
        case 'li2': // list item level 2
          format = Format.li2;
          if (remainder.isEmpty) {
            continue;
          }
          text = remainder;
          line++;
        case 'v': // verse
          type = TextType.v;
          (verse, text) = _getVerse(remainder);
          line = 1;
        case 'd': // descriptive title
          type = TextType.d;
          if (remainder.isEmpty) {
            continue;
          }
          text = remainder;
          verse = 0;
          line = 1;
        case 'b': // break
          if (verse == -1) {
            continue;
          }
          if (format == null) {
            print('Missing format for break, book: $bookId, chapter $chapter, verse $verse');
            continue;
          }
          text = '\n';
          line++;
          format = null;
        case 'q1': // poetry indentation level 1
          format = Format.q1;
          if (remainder.isEmpty) {
            continue;
          }
          text = remainder;
          line++;
        case 'q2': // poetry indentation level 2
          format = Format.q2;
          if (remainder.isEmpty) {
            continue;
          }
          text = remainder;
          line++;
        case 'pc': // centered
          format = Format.pc;
          if (remainder.isEmpty) {
            continue;
          }
          text = remainder;
          line++;
        // TODO: there is a centered itallic line in Habakkuk. Need to figure out what to do with it.
        case 'qr': // right aligned
          format = Format.qr;
          if (remainder.isEmpty) {
            continue;
          }
          text = remainder;
          line++;
        default:
          throw Exception('Unknown marker: $marker (chapter: $chapter, verse: $verse)');
      }

      (text, footnote) = extractFootnote(text);

      if (type == null) {
        print('Type null at: $marker (chapter: $chapter, verse: $verse)');
        return;
      }

      dbHelper.insert(
        bookId: bookId,
        type: type.id,
        chapter: chapter,
        verse: verse,
        line: line,
        text: text,
        format: format?.id,
        footnote: footnote,
      );

      footnote = null;
      text = null;
    }

    // testing. Only do first book
    // break;
  }
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
    final footnoteText = footnote.substring(ftIndex + 4, footnote.length - 3).trim();
    footnotes.add('$footnoteIndex#$footnoteText');
    // Remove footnote from text
    modifiedText = modifiedText.replaceRange(startIndex, endIndex, '').replaceAll('  ', ' ');
  }

  return (modifiedText.trim(), footnotes.join('\n'));
}
