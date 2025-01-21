import 'dart:io';

import 'package:database_builder/src/schema.dart';

import 'book_id.dart';
import 'database_helper.dart';

/// Returns a map of POS values and their corresponding row IDs
Future<Map<String, int>> createPosTable(DatabaseHelper dbHelper) async {
  final file = File('bsb_tables/bsb_tables.csv');
  final lines = file.readAsLinesSync();

  final Map<String, int> posMap = {};
  final Set<String> uniquePos = {};
  int posColumn = 9;

  // Collect unique POS values
  for (var line in lines) {
    final columns = line.split('\t');
    if (columns.length > posColumn) {
      final pos = columns[posColumn].trim();
      if (pos.isNotEmpty) {
        uniquePos.add(pos);
      }
    }
  }

  // Insert unique POS values into the database and build the mapping
  for (var pos in uniquePos) {
    final rowId = dbHelper.insertPartOfSpeech(name: pos);
    posMap[pos] = rowId;
  }

  return posMap;
}

Future<void> createInterlinearTable(DatabaseHelper dbHelper, Map<String, int> posMap) async {
  final file = File('bsb_tables/bsb_tables.csv');
  final lines = file.readAsLinesSync();

  int bookId = -1;
  int chapter = -1;
  int verse = -1;

  for (int i = 1; i < lines.length; i++) {
    final line = lines[i];
    final columns = line.split('\t');

    final language = Language.fromString(columns[4]);
    final original = columns[5];
    final transliteration = columns[7];
    final partOfSpeech = posMap[columns[9]];
    final strongsCol = (language == Language.greek) ? 11 : 10;
    final strongsNumber = int.parse(columns[strongsCol]);
    final reference = columns[12];
    if (reference.isNotEmpty) {
      (bookId, chapter, verse) = _parseReference(reference);
    }
    final english = columns[18];
    final punctuation = columns[19];

    await dbHelper.insertInterlinearLine(
      bookId: bookId,
      chapter: chapter,
      verse: verse,
      language: language.id,
      original: original,
      transliteration: transliteration,
      partOfSpeech: partOfSpeech!,
      strongsNumber: strongsNumber,
      english: english,
      punctuation: punctuation.isEmpty ? null : punctuation,
    );
  }
}

(int bookId, int chapter, int verse) _parseReference(String reference) {
  // reference is in the form: "1 Corinthians 1:1"

  final parts = reference.split(' ');
  final chapterVerse = parts.last.split(':');
  final chapter = int.parse(chapterVerse[0]);
  final verse = int.parse(chapterVerse[1]);

  // Remove the chapter:verse part and join the book name
  parts.removeLast();
  final bookName = parts.join(' ');

  // Get book ID from the full name
  final bookId = fullNameToBookIdMap[bookName]!;

  return (bookId, chapter, verse);
}
