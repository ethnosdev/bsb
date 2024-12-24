import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'schema.dart';

class DatabaseHelper {
  final String _databaseName = "database.db";
  late Database _database;

  void init() {
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
    required int type,
    required int chapter,
    required int verse,
    required int line,
    required String text,
    required int? format,
    required String? footnote,
  }) async {
    if (text.isEmpty) {
      throw Exception('Empty text for $bookId, $chapter, $verse');
    }
    _database.execute('''
      INSERT INTO ${Schema.bibleTextTable} (
        ${Schema.colBookId},
        ${Schema.colType},
        ${Schema.colChapter},
        ${Schema.colVerse},
        ${Schema.colLine},
        ${Schema.colText},
        ${Schema.colFormat},
        ${Schema.colFootnote}
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''', [bookId, type, chapter, verse, line, text, format, footnote]);
  }

  Future<List<String>> fetchChapter(int bookId, int chapter) async {
    final verseLines = _database.select('''
      SELECT ${Schema.colText}
      FROM ${Schema.bibleTextTable}
      WHERE ${Schema.colBookId} = ? AND ${Schema.colChapter} = ?
      ORDER BY ${Schema.colVerse} ASC, ${Schema.colLine} ASC
      ''', [bookId, chapter]);

    return verseLines.map((row) => row[0] as String).toList();
  }
}
