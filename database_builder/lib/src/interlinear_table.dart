import 'dart:io';

import 'package:database_builder/src/language/language.dart';

import 'book_id.dart';
import 'database_helper.dart';

/// Returns maps of original/pos/english values and their corresponding row IDs
(Map<String, int>, Map<String, int>, Map<String, int>) createForeignTables(
    DatabaseHelper dbHelper) {
  final file = File('bsb_tables/bsb_tables.csv');
  final lines = file.readAsLinesSync();

  final Map<String, int> originalMap = {};
  final Set<String> uniqueOriginal = {};
  int originalColumn = 5;

  final Map<String, int> posMap = {};
  final Set<String> uniquePos = {};
  int posColumn = 9;

  final Map<String, int> englishMap = {};
  final Set<String> uniqueEnglish = {};
  int englishColumn = 18;

  // Collect unique POS values
  for (int i = 1; i < lines.length; i++) {
    if (i % 50000 == 0) {
      print('Processing line $i');
    }
    final line = lines[i];
    final columns = line.split('\t');
    if (columns.length > englishColumn) {
      final original = columns[originalColumn].trim();
      if (original.isNotEmpty) {
        uniqueOriginal.add(original);
      }
      final pos = columns[posColumn].trim();
      if (pos.isNotEmpty) {
        uniquePos.add(pos);
      }
      final english = columns[englishColumn].trim();
      if (english.isNotEmpty) {
        uniqueEnglish.add(english);
      }
    }
  }

  int progress = 0;
  print('Inserting original values into the database');
  dbHelper.beginTransaction();
  for (var original in uniqueOriginal) {
    if (progress % 10000 == 0) {
      print('Inserting original values: $progress');
    }
    final rowId = dbHelper.insertOriginalLanguage(word: original);
    originalMap[original] = rowId;
    progress++;
  }
  dbHelper.commitTransaction();

  print('Inserting POS values into the database');
  dbHelper.beginTransaction();
  for (var pos in uniquePos) {
    final rowId = dbHelper.insertPartOfSpeech(name: pos);
    posMap[pos] = rowId;
  }
  dbHelper.commitTransaction();

  print('Inserting English values into the database');
  dbHelper.beginTransaction();
  progress = 0;
  for (var english in uniqueEnglish) {
    if (progress % 10000 == 0) {
      print('Inserting English values: $progress');
    }
    final rowId = dbHelper.insertEnglish(word: english);
    englishMap[english] = rowId;
    progress++;
  }
  dbHelper.commitTransaction();

  return (originalMap, posMap, englishMap);
}

Future<void> createInterlinearTable(
  DatabaseHelper dbHelper,
  Map<String, int> originalMap,
  Map<String, int> posMap,
  Map<String, int> englishMap,
) async {
  final file = File('bsb_tables/bsb_tables.csv');
  final lines = file.readAsLinesSync();

  int bookId = 0;
  int chapter = 0;
  int verse = 0;

  List<InterlinearWord> verseWords = [];

  dbHelper.beginTransaction();
  for (int i = 1; i < lines.length; i++) {
    if (i % 10000 == 0) {
      print('Processing line $i');
    }
    final line = lines[i];
    final columns = line.split('\t');

    if (columns[5].isEmpty) {
      if (verseWords.isNotEmpty) {
        dbHelper.insertInterlinearVerse(verseWords, bookId, chapter, verse);
        verseWords = [];
        bookId = 0;
        chapter = 0;
        verse = 0;
      }
      continue;
    }
    final original = originalMap[columns[5].trim()]!;

    final reference = columns[12];
    if (reference.isNotEmpty) {
      (bookId, chapter, verse) = _parseReference(reference);
    }

    final language = Language.fromString(columns[4]);
    // final transliteration = columns[7];
    final partOfSpeech = posMap[columns[9].trim()] ?? -1;
    if (partOfSpeech == -1) {
      // print('No POS for $original ($bookId, $chapter, $verse)');
    }
    final strongsCol = (language == Language.greek) ? 11 : 10;
    final strongsNumber = int.tryParse(columns[strongsCol]) ?? -1;
    if (strongsNumber == -1) {
      // print('No strongs number for $original ($bookId, $chapter, $verse)');
    }
    var english = columns[18].trim();
    if (english.isEmpty) {
      english = '-';
    }
    final englishId = englishMap[english]!;

    final punctuation = columns[19];

    verseWords.add(
      InterlinearWord(
        language: language.id,
        original: original,
        partOfSpeech: partOfSpeech,
        strongsNumber: strongsNumber,
        english: englishId,
        punctuation: punctuation.isEmpty ? null : punctuation,
      ),
    );
  }
  if (verseWords.isNotEmpty) {
    dbHelper.insertInterlinearVerse(verseWords, bookId, chapter, verse);
  }
  dbHelper.commitTransaction();
}

(int bookId, int chapter, int verse) _parseReference(String reference) {
  // reference is in the form: "1 Corinthians 1:1"

  final refIndex = reference.lastIndexOf(' ');
  final bookName = reference.substring(0, refIndex);
  final chapterVerse = reference.substring(refIndex + 1).split(':');
  final chapter = int.parse(chapterVerse[0]);
  final verse = int.parse(chapterVerse[1]);

  // Get book ID from the full name
  final bookId = fullNameToBookIdMap[bookName]!;

  return (bookId, chapter, verse);
}
