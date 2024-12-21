import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Schema {
  // Bible table
  static const String tableName = "bible";

  // Column names
  static const String colId = '_id';
  static const String colBookId = 'book';
  static const String colChapter = 'chapter';
  static const String colVerse = 'verse';
  static const String colLine = 'line';
  static const String colText = 'text';

  // SQL statements
  static const String createTable = '''
  CREATE TABLE $tableName (
    $colId TEXT PRIMARY KEY,
    $colBookId INTEGER NOT NULL,
    $colChapter INTEGER NOT NULL,
    $colVerse INTEGER NOT NULL,
    $colLine INTEGER NOT NULL,
    $colText TEXT NOT NULL
  )
  ''';
}

class DatabaseHelper {
  final String _databaseName = "database.db";
  static const _databaseVersion = 1;
  late Database _database;

  Future<void> init() async {
    final path = join(await getDatabasesPath(), _databaseName);
    print('init: $path');
    _database = await openDatabase(
      path,
      onCreate: _onCreate,
      version: _databaseVersion,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(Schema.createTable);
  }

  Future<void> insert({
    required int bookId,
    required int chapter,
    required int verse,
    required int line,
    required String text,
  }) async {
    await _database.insert(
      Schema.tableName,
      {
        Schema.colBookId: bookId,
        Schema.colChapter: chapter,
        Schema.colVerse: verse,
        Schema.colLine: line,
        Schema.colText: text,
      },
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<List<String>> fetchChapter(int bookId, int chapter) async {
    final verseLines = await _database.query(
      Schema.tableName,
      columns: [Schema.colText],
      where: '${Schema.colBookId} = ? AND ${Schema.colChapter} = ?',
      whereArgs: [bookId, chapter],
      orderBy: '${Schema.colVerse} ASC, ${Schema.colLine} ASC',
    );

    return List.generate(verseLines.length, (i) {
      final verse = verseLines[i];
      return verse[Schema.colText] as String;
    });
  }
}
