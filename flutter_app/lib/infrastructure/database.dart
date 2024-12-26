import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:database_builder/database_builder.dart';

// TODO: add this as a monorepo import
// class Schema {
//   // Bible table
//   static const String tableName = "bible";

//   // Column names
//   static const String colId = '_id';
//   static const String colBookId = 'book';
//   static const String colChapter = 'chapter';
//   static const String colVerse = 'verse';
//   static const String colLine = 'line';
//   static const String colText = 'text';

//   // SQL statements
//   static const String createTable = '''
//   CREATE TABLE IF NOT EXISTS $tableName (
//     $colId INTEGER PRIMARY KEY AUTOINCREMENT,
//     $colBookId INTEGER NOT NULL,
//     $colChapter INTEGER NOT NULL,
//     $colVerse INTEGER NOT NULL,
//     $colLine INTEGER NOT NULL,
//     $colText TEXT NOT NULL
//   )
//   ''';
// }

class DatabaseHelper {
  static const _databaseName = "database.db";
  static const _databaseVersion = 5;
  late Database _database;

  Future<void> init() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, _databaseName);
    var exists = await databaseExists(path);

    if (!exists) {
      print("Creating new copy from asset");
      await _copyDatabaseFromAssets(path);
    } else {
      // Check if database needs update
      var currentVersion = await getDatabaseVersion(path);
      if (currentVersion != _databaseVersion) {
        print("Updating database from version $currentVersion to $_databaseVersion");
        await deleteDatabase(path);
        await _copyDatabaseFromAssets(path);
      } else {
        print("Opening existing database");
      }
    }
    _database = await openDatabase(path, version: _databaseVersion);
  }

  Future<int> getDatabaseVersion(String path) async {
    var db = await openDatabase(path);
    var version = await db.getVersion();
    await db.close();
    return version;
  }

  Future<void> _copyDatabaseFromAssets(String path) async {
    await Directory(dirname(path)).create(recursive: true);
    final data = await rootBundle.load(join("assets/database", _databaseName));
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes, flush: true);
  }

  Future<List<Map<String, Object?>>> getChapter(int bookId, int chapter) async {
    print('bookId: $bookId, chapter: $chapter');
    final verses = await _database.query(
      Schema.bibleTextTable,
      columns: [
        Schema.colVerse,
        Schema.colLine,
        Schema.colText,
        Schema.colFootnote,
        Schema.colFormat,
        Schema.colType,
      ],
      where: '${Schema.colBookId} = ? AND ${Schema.colChapter} = ?',
      whereArgs: [bookId, chapter],
      orderBy: '${Schema.colId} ASC',
    );

    return verses;
  }
}
