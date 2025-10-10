import 'dart:developer';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'schema.dart';

class DatabaseHelper {
  final String _databaseName = "database.db";
  late Database _database;

  // Prepared statements
  late PreparedStatement _insertBsbStmt;
  late PreparedStatement _insertOriginalStmt;
  late PreparedStatement _insertEnglishStmt;
  late PreparedStatement _insertPosStmt;
  late PreparedStatement _insertInterlinearStmt;

  void init() {
    _database = sqlite3.open(_databaseName);
    _createTables();
    _prepareStatements();
  }

  void _createTables() {
    _database.execute(Schema.createBsbTable);
    _database.execute(Schema.createOriginalLanguageTable);
    _database.execute(Schema.createEnglishTable);
    _database.execute(Schema.createPartOfSpeechTable);
    _database.execute(Schema.createInterlinearTable);
  }

  void _prepareStatements() {
    _insertBsbStmt = _database.prepare(Schema.insertBsbLine);
    _insertOriginalStmt = _database.prepare(Schema.insertOriginalLanguage);
    _insertEnglishStmt = _database.prepare(Schema.insertEnglish);
    _insertPosStmt = _database.prepare(Schema.insertPartOfSpeech);
    _insertInterlinearStmt = _database.prepare(Schema.insertInterlinear);
  }

  void beginTransaction() {
    _database.execute('BEGIN TRANSACTION;');
  }

  void commitTransaction() {
    _database.execute('COMMIT;');
  }

  void deleteDatabase() {
    final file = File(_databaseName);
    if (file.existsSync()) {
      print('Deleting database file: $_databaseName');
      file.deleteSync();
    }
  }

  void insertBsbLine({
    required int bookId,
    required int chapter,
    required int verse,
    required String text,
    required int format,
    required String? footnote,
  }) {
    if (text.isEmpty) {
      throw Exception('Empty text for $bookId, $chapter, $verse');
    }
    final reference = _packReference(bookId, chapter, verse);
    _insertBsbStmt.execute([reference, text, format, footnote]);
  }

  // BBCCCVVV packed int
  int _packReference(int bookId, int chapter, int verse) {
    return bookId * 1000000 + chapter * 1000 + verse;
  }

  int insertOriginalLanguage({
    required String word,
  }) {
    _insertOriginalStmt.execute([word]);
    return _database.lastInsertRowId;
  }

  int insertEnglish({
    required String word,
  }) {
    _insertEnglishStmt.execute([word]);
    return _database.lastInsertRowId;
  }

  int insertPartOfSpeech({
    required String name,
  }) {
    _insertPosStmt.execute([name]);
    return _database.lastInsertRowId;
  }

  void insertInterlinearVerse(
    List<InterlinearWord> words,
    int bookId,
    int chapter,
    int verse,
  ) {
    if (bookId <= 0 || chapter <= 0 || verse <= 0) {
      log('Invalid bookId, chapter, or verse: $bookId, $chapter, $verse');
    }
    final reference = _packReference(bookId, chapter, verse);
    for (var word in words) {
      _insertInterlinearStmt.execute([
        reference,
        word.language,
        word.original,
        word.partOfSpeech,
        word.strongsNumber,
        word.english,
        word.punctuation,
      ]);
    }
  }

  void dispose() {
    _insertBsbStmt.dispose();
    _insertOriginalStmt.dispose();
    _insertEnglishStmt.dispose();
    _insertPosStmt.dispose();
    _insertInterlinearStmt.dispose();
    _database.dispose();
  }
}

class InterlinearWord {
  InterlinearWord({
    required this.language,
    required this.original,
    required this.partOfSpeech,
    required this.strongsNumber,
    required this.english,
    required this.punctuation,
  });
  final int language;
  final int original;
  final int partOfSpeech;
  final int strongsNumber;
  final int english;
  final String? punctuation;
}
