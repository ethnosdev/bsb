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

  final parentheses = RegExp(r'[()]');

  for (String bookFilename in bibleBookFilenames) {
    print('Processing: $bookFilename');
    final file = File('${directory.path}/$bookFilename');

    if (!file.existsSync()) {
      throw Exception('${file.path} does not exist');
    }

    final lines = await file.readAsLines();
    String oldMarker = '';
    for (String newLine in lines) {
      if (newLine.trim().isEmpty) continue;

      // split at a space or a newline and take the text before it
      String marker = newLine.split(RegExp(r'[ \n]'))[0];
      final remainder = newLine.substring(marker.length).trim();
      marker = marker.replaceAll(r'\', '');

      // We will flag if the insert happens normally at the bottom,
      // or if we handle multiple inserts inside the switch case.
      bool insertAtBottom = true;

      switch (marker) {
        case 'id': // book
          bookId = _getBookId(remainder);
          format = null;
          continue;
        case 'usfm': // format identifier
        case 'h': // book title
        case 'toc1': // book title
        case 'toc2': // book title
        case 'toc3': // book abbreviation
        case 'mt1': // book title
        case 'mt2': // book title
          // ignore
          continue;
        case 'c': // chapter
          chapter = _getChapter(remainder);
          verse = 0;
          continue;
        case 'r': // cross reference
          format = ParagraphFormat.r;
          if (remainder.isEmpty) continue;

          text = remainder
              .replaceAll(parentheses, '')
              .replaceAll(RegExp(r'\\ref\s+'), '') // removes "\ref "
              .replaceAll(
                RegExp(r'\|.*?\\ref\*'),
                '',
              ); // removes "|JHN 1:1-5\ref*"
          break; // Let it insert at the bottom
        case 'p': // standard paragraph marker
        case 's1': // section heading level 1
        case 's2': // section heading level 2
        case 'ms': // major section (Psalms)
        case 'mr': // major section range (Psalms)
        case 'qa': // Acrostic heading (Psalm 119)
        case 'm': // margin
        case 'pmo': // indented paragraph margin opening
        case 'li1': // list item level 1
        case 'li2': // list item level 2
        case 'q1': // poetry indentation level 1
        case 'q2': // poetry indentation level 2
        case 'qr': // right aligned
          format = ParagraphFormat.fromJson(marker);
          if (remainder.isEmpty) continue;

          insertAtBottom = false; // We will handle multiple inserts here

          // Auto-insert paragraph break for standard text blocks
          if (_shouldInsertBreak(oldMarker, marker)) {
            dbHelper.insertBsbLine(
              bookId: bookId,
              chapter: chapter,
              verse: verse,
              text: '',
              format: ParagraphFormat.b.id,
            );
          }

          // Split the text by "\v " to separate multiple verses on the same line
          List<String> chunks = remainder.split(r'\v ');
          for (int i = 0; i < chunks.length; i++) {
            String chunk = chunks[i].trim();
            if (chunk.isEmpty) continue;

            if (i > 0 || remainder.startsWith(r'\v ')) {
              // This chunk starts with a verse number
              final verseData = _getVerse(chunk);
              verse = verseData.$1;
              text = verseData.$2;
            } else {
              // This chunk is text before any \v marker (belongs to the current verse)
              text = chunk;
            }

            dbHelper.insertBsbLine(
              bookId: bookId,
              chapter: chapter,
              verse: verse,
              text: text!,
              format: format!.id,
            );
          }
          break;
        case 'v': // verse (if it still appears on its own line)
          insertAtBottom = false; // We will handle multiple inserts here

          if (format == null) {
            print('Format null at: $marker (chapter: $chapter, verse: $verse)');
            return;
          }

          // A line starting with \v might also contain subsequent \v markers
          List<String> chunks = remainder.split(r'\v ');
          for (int i = 0; i < chunks.length; i++) {
            String chunk = chunks[i].trim();
            if (chunk.isEmpty) continue;

            final verseData = _getVerse(chunk);
            verse = verseData.$1;
            text = verseData.$2;

            dbHelper.insertBsbLine(
              bookId: bookId,
              chapter: chapter,
              verse: verse,
              text: text!,
              format: format!.id,
            );
          }
          break;
        case 'd': // descriptive title
          format = ParagraphFormat.d;
          if (remainder.isEmpty) continue;

          insertAtBottom = false;

          List<String> chunks = remainder.split(r'\v ');
          for (int i = 0; i < chunks.length; i++) {
            String chunk = chunks[i].trim();
            if (chunk.isEmpty) continue;

            if (i > 0 || remainder.startsWith(r'\v ')) {
              // Extract the inline verse number
              final verseData = _getVerse(chunk);
              verse = verseData.$1;
              text = verseData.$2;
            } else {
              text = chunk;
              // If \d has no \v marker, it is historically verse 0.
              verse = 0;
            }

            dbHelper.insertBsbLine(
              bookId: bookId,
              chapter: chapter,
              verse: verse,
              text: text!,
              format: format!.id,
            );
          }
          break;

        case 'b': // break
          // ignore unnecessary breaks after section headings
          if (oldMarker == 's1' || oldMarker == 's2') continue;
          format = ParagraphFormat.b;
          text = '';
          break; // Let it insert at the bottom

        case 'pc': // centered
          format = ParagraphFormat.pc;
          if (remainder.isEmpty) continue;

          insertAtBottom = false;

          // Auto-insert paragraph break for centered text blocks
          if (_shouldInsertBreak(oldMarker, marker)) {
            dbHelper.insertBsbLine(
              bookId: bookId,
              chapter: chapter,
              verse: verse,
              text: '',
              format: ParagraphFormat.b.id,
            );
          }

          List<String> chunks = remainder.split(r'\v ');
          for (int i = 0; i < chunks.length; i++) {
            String chunk = chunks[i].trim();
            if (chunk.isEmpty) continue;

            if (i > 0 || remainder.startsWith(r'\v ')) {
              final verseData = _getVerse(chunk);
              verse = verseData.$1;
              text = verseData.$2;
            } else {
              text = chunk;
            }

            dbHelper.insertBsbLine(
              bookId: bookId,
              chapter: chapter,
              verse: verse,
              text: text!,
              format: format!.id,
            );
          }
          break;
        default:
          throw Exception(
            'Unknown marker: $marker (chapter: $chapter, verse: $verse)',
          );
      }

      // If it wasn't handled inside the switch case, insert it now
      if (insertAtBottom) {
        if (format == null) {
          print('Format null at: $marker (chapter: $chapter, verse: $verse)');
          return;
        }

        dbHelper.insertBsbLine(
          bookId: bookId,
          chapter: chapter,
          verse: verse,
          text: text!,
          format: format!.id,
        );
      }

      text = null;
      oldMarker = marker;
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

bool _shouldInsertBreak(String oldMarker, String currentMarker) {
  // Markers that represent the end of a previous line of text
  final previousTextBlocks = {
    'p',
    'm',
    'pmo',
    'li1',
    'li2',
    'q1',
    'q2',
    'qr',
    'pc',
    'v',
  };

  // Markers that force a new structural block to begin
  final newStructuralBlocks = {
    'p',
    'm',
    'pmo',
    'li1',
    'li2',
    'q1',
    'q2',
    'qr',
    'pc',
  };

  // If the previous line wasn't text (e.g. it was a heading or an existing '\b'), no break needed.
  if (!previousTextBlocks.contains(oldMarker)) return false;

  // If the current line is just a loose '\v' (continuing a paragraph), no break needed.
  if (!newStructuralBlocks.contains(currentMarker)) return false;

  // If we are transitioning between poetry lines (e.g., q1 -> q2, q2 -> q1, q1 -> q1),
  // we want them grouped together tightly as a stanza without breaks.
  if ({'q1', 'q2'}.contains(oldMarker) &&
      {'q1', 'q2'}.contains(currentMarker)) {
    return false;
  }

  // Otherwise, this is a new block element and it gets a break!
  return true;
}
