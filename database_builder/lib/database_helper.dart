import 'dart:io';

import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';

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
  CREATE TABLE IF NOT EXISTS $tableName (
    $colId INTEGER PRIMARY KEY AUTOINCREMENT,
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

  void init() {
    // final userDirectory =
    // final path = join(userDirectory.path, _databaseName);
    // print('init: $path');
    _database = sqlite3.open(_databaseName);
    _createTable();
  }

  void deleteDatabase() {
    final file = File(_databaseName);
    if (file.existsSync()) {
      print('Deleting database file: $_databaseName');
      file.deleteSync();
    }
  }

  void _createTable() {
    _database.execute(Schema.createTable);
  }

  Future<void> insert({
    required int bookId,
    required int chapter,
    required int verse,
    required int line,
    required String text,
  }) async {
    _database.execute('''
      INSERT INTO ${Schema.tableName} (
        ${Schema.colBookId},
        ${Schema.colChapter},
        ${Schema.colVerse},
        ${Schema.colLine},
        ${Schema.colText}
      ) VALUES (?, ?, ?, ?, ?)
      ''', [bookId, chapter, verse, line, text]);
  }

  Future<List<String>> fetchChapter(int bookId, int chapter) async {
    final verseLines = _database.select('''
      SELECT ${Schema.colText}
      FROM ${Schema.tableName}
      WHERE ${Schema.colBookId} = ? AND ${Schema.colChapter} = ?
      ORDER BY ${Schema.colVerse} ASC, ${Schema.colLine} ASC
      ''', [bookId, chapter]);

    return verseLines.map((row) => row[0] as String).toList();
  }
}
