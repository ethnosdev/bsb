import 'dart:io';

import 'package:database_builder/database_helper.dart';
import 'package:database_builder/utils/utils.dart';

Future<void> createDatabase() async {
  final dbHelper = DatabaseHelper();
  dbHelper.deleteDatabase();
  dbHelper.init();

  final directory = Directory('bsb_usfm');

  if (!await directory.exists()) {
    print('Directory does not exist');
    return;
  }

  int bookId = 0;
  int chapter = 0;
  int verse = 0;
  int line = 0;
  String text = '';

  for (String bookFilename in bibleBooks) {
    print('Processing: $bookFilename');
    final file = File('${directory.path}/$bookFilename');

    if (!file.existsSync()) {
      continue;
    }

    final lines = await file.readAsLines();
    for (String newLine in lines) {
      // text = '';
      final marker = newLine.split(RegExp(r'[ \n]'))[0];
      final remainder = newLine.substring(marker.length).trim();
      // print(marker);
      switch (marker) {
        case '\\id': // book
          bookId = _getBookId(remainder);
          continue;
        case '\\c': // chapter
          chapter = _getChapter(remainder);
          verse = 0;
          line = 0;
          continue;
        case '\\v':
          (verse, text) = _getVerse(remainder);
          line = 1;
        case '\\q1':
        case '\\q2':
          text = remainder;
          line++;
        case '\\b':
          text = '$text\n\n';
        default:
          continue;
      }
      if (text.isEmpty) continue;

      // print('bookId: $bookId, chapter: $chapter, verse: $verse, line: $line, text: $text');

      dbHelper.insert(
        bookId: bookId,
        chapter: chapter,
        verse: verse,
        line: line,
        text: text,
      );
    }

    // testing. Only do first book
    // break;
  }
}

int _getBookId(String textAfterMarker) {
  final index = textAfterMarker.indexOf(' ');
  final bookName = textAfterMarker.substring(0, index);
  return _bookIdMap[bookName]!;
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

final _bookIdMap = {
  'GEN': 1,
  'EXO': 2,
  'LEV': 3,
  'NUM': 4,
  'DEU': 5,
  'JOS': 6,
  'JDG': 7,
  'RUT': 8,
  '1SA': 9,
  '2SA': 10,
  '1KI': 11,
  '2KI': 12,
  '1CH': 13,
  '2CH': 14,
  'EZR': 15,
  'NEH': 16,
  'EST': 17,
  'JOB': 18,
  'PSA': 19,
  'PRO': 20,
  'ECC': 21,
  'SNG': 22,
  'ISA': 23,
  'JER': 24,
  'LAM': 25,
  'EZK': 26,
  'DAN': 27,
  'HOS': 28,
  'JOL': 29,
  'AMO': 30,
  'OBA': 31,
  'JON': 32,
  'MIC': 33,
  'NAM': 34,
  'HAB': 35,
  'ZEP': 36,
  'HAG': 37,
  'ZEC': 38,
  'MAL': 39,
  'MAT': 41,
  'MRK': 42,
  'LUK': 43,
  'JHN': 44,
  'ACT': 45,
  'ROM': 46,
  '1CO': 47,
  '2CO': 48,
  'GAL': 49,
  'EPH': 50,
  'PHP': 51,
  'COL': 52,
  '1TH': 53,
  '2TH': 54,
  '1TI': 55,
  '2TI': 56,
  'TIT': 57,
  'PHM': 58,
  'HEB': 59,
  'JAS': 60,
  '1PE': 61,
  '2PE': 62,
  '1JN': 63,
  '2JN': 64,
  '3JN': 65,
  'JUD': 66,
  'REV': 67
};
