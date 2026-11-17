import 'dart:developer';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'schema.dart';

class DatabaseHelper {
  DatabaseHelper({this.databaseName = 'database.db'});

  final String databaseName;
  late Database _database;

  // Prepared statements
  late PreparedStatement _insertBsbStmt;
  late PreparedStatement _insertOriginalStmt;
  late PreparedStatement _insertEnglishStmt;
  late PreparedStatement _insertPosStmt;
  late PreparedStatement _insertInterlinearStmt;
  late PreparedStatement _insertVerseSearchStmt;
  late PreparedStatement _insertLexiconStmt;
  late PreparedStatement _insertAudioTimingStmt;

  Database get database => _database;

  void init() {
    _database = sqlite3.open(databaseName);
    _createTables();
    _prepareStatements();
  }

  void _createTables() {
    _database.execute(Schema.createBsbTable);
    _database.execute(Schema.createOriginalLanguageTable);
    _database.execute(Schema.createEnglishTable);
    _database.execute(Schema.createPartOfSpeechTable);
    _database.execute(Schema.createInterlinearTable);
    _database.execute(Schema.createVerseSearchTable);
    _database.execute(Schema.createLexiconEntryTable);
    _database.execute(Schema.createAudioTimingsTable);
  }

  void _prepareStatements() {
    _insertBsbStmt = _database.prepare(Schema.insertBsbLine);
    _insertOriginalStmt = _database.prepare(Schema.insertOriginalLanguage);
    _insertEnglishStmt = _database.prepare(Schema.insertEnglish);
    _insertPosStmt = _database.prepare(Schema.insertPartOfSpeech);
    _insertInterlinearStmt = _database.prepare(Schema.insertInterlinear);
    _insertVerseSearchStmt = _database.prepare(Schema.insertVerseSearch);
    _insertLexiconStmt = _database.prepare(Schema.insertLexiconEntry);
    _insertAudioTimingStmt = _database.prepare(Schema.insertAudioTiming);
  }

  void beginTransaction() {
    _database.execute('BEGIN TRANSACTION;');
  }

  void commitTransaction() {
    _database.execute('COMMIT;');
  }

  void deleteDatabase() {
    final file = File(databaseName);
    if (file.existsSync()) {
      print('Deleting database file: $databaseName');
      file.deleteSync();
    }
  }

  void insertBsbLine({
    required int bookId,
    required int chapter,
    required int verse,
    required String text,
    required String format,
  }) {
    if (text.isEmpty && format != 'b') {
      throw Exception('Empty text for $bookId, $chapter, $verse');
    }
    final reference = _packReference(bookId, chapter, verse);
    _insertBsbStmt.execute([reference, text, format]);
  }

  // BBCCCVVV packed int
  int _packReference(int bookId, int chapter, int verse) {
    return bookId * 1000000 + chapter * 1000 + verse;
  }

  int insertOriginalLanguage({required String word}) {
    _insertOriginalStmt.execute([word]);
    return _database.lastInsertRowId;
  }

  int insertEnglish({required String word}) {
    _insertEnglishStmt.execute([word]);
    return _database.lastInsertRowId;
  }

  int insertPartOfSpeech({required String name}) {
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
        word.bsbSort,
      ]);
    }
  }

  void insertLexiconEntry({
    required int language,
    required int strongs,
    required String lemma,
    required String content,
  }) {
    _insertLexiconStmt.execute([
      language,
      strongs,
      lemma,
      content,
    ]);
  }

  void createIndexes() {
    print('Creating SQLite indexes for bible, interlinear, and lexicon...');
    _database.execute(Schema.createBibleIndexes);
    _database.execute(Schema.createInterlinearIndexes);
    _database.execute(Schema.createLexiconIndexes);
    print('Indexes created successfully.');
  }

  void dispose() {
    _insertBsbStmt.close();
    _insertOriginalStmt.close();
    _insertEnglishStmt.close();
    _insertPosStmt.close();
    _insertInterlinearStmt.close();
    _insertVerseSearchStmt.close();
    _insertLexiconStmt.close();
    _insertAudioTimingStmt.close();
    _database.close();
  }

  void insertAudioTiming({
    required int reference,
    required int startMs,
    required int endMs,
  }) {
    _insertAudioTimingStmt.execute([reference, startMs, endMs]);
  }

  void insertVerseSearch({
    required int reference,
    required String text,
  }) {
    _insertVerseSearchStmt.execute([
      reference,
      text,
    ]);
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
    required this.bsbSort,
  });
  final int language;
  final int original;
  final int partOfSpeech;
  final int strongsNumber;
  final int english;
  final String? punctuation;
  final int bsbSort;
}
