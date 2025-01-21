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
}
