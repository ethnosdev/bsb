import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'schema.dart';

class DatabaseHelper {
  final String _databaseName = "database.db";
  late Database _database;

  void init() {
    _database = sqlite3.open(_databaseName);
    _createBsbTable();
    _createPartOfSpeechTable();
    _createInterlinearTable();
  }

  void deleteDatabase() {
    final file = File(_databaseName);
    if (file.existsSync()) {
      print('Deleting database file: $_databaseName');
      file.deleteSync();
    }
  }

  void _createBsbTable() {
    _database.execute(Schema.createBsbTable);
  }

  void _createPartOfSpeechTable() {
    _database.execute(Schema.createPartOfSpeechTable);
  }

  void _createInterlinearTable() {
    _database.execute(Schema.createInterlinearTable);
  }

  Future<void> insertBsbLine({
    required int bookId,
    required int chapter,
    required int verse,
    required String text,
    required int type,
    required int? format,
    required String? footnote,
  }) async {
    if (text.isEmpty) {
      throw Exception('Empty text for $bookId, $chapter, $verse');
    }
    _database.execute('''
      INSERT INTO ${Schema.bibleTextTable} (
        ${Schema.colBookId},
        ${Schema.colChapter},
        ${Schema.colVerse},
        ${Schema.colText},
        ${Schema.colType},
        ${Schema.colFormat},
        ${Schema.colFootnote}
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''', [bookId, chapter, verse, text, type, format, footnote]);
  }

  int insertPartOfSpeech({
    required String name,
  }) {
    _database.execute('''
      INSERT INTO ${Schema.partOfSpeechTable} (
        ${Schema.posColName}
      ) VALUES (?)
      ''', [name]);
    return _database.lastInsertRowId;
  }

  Future<void> insertInterlinearLine({
    required int bookId,
    required int chapter,
    required int verse,
    required int language,
    required String original,
    required String transliteration,
    required int partOfSpeech,
    required int strongsNumber,
    required String english,
    String? punctuation,
  }) async {
    _database.execute('''
        INSERT INTO ${Schema.interlinearTable} (
          ${Schema.ilColBookId},
          ${Schema.ilColChapter},
          ${Schema.ilColVerse},
          ${Schema.ilColLanguage},
          ${Schema.ilColOriginal},
          ${Schema.ilColTransliteration},
          ${Schema.ilColPartOfSpeech},
          ${Schema.ilColStrongsNumber},
          ${Schema.ilColEnglish},
          ${Schema.ilColPunctuation}
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
      bookId,
      chapter,
      verse,
      language,
      original,
      transliteration,
      partOfSpeech,
      strongsNumber,
      english,
      punctuation
    ]);
  }
}
