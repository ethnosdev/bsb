import 'dart:io';
import 'package:bsb/infrastructure/verse_line.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:database_builder/bsb/database_builder.dart';

class DatabaseHelper {
  static const _databaseName = "database.db";
  static const _databaseVersion = 6;
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

  Future<List<VerseLine>> getChapter(int bookId, int chapter) async {
    print('bookId: $bookId, chapter: $chapter');
    final verses = await _database.query(
      Schema.bibleTextTable,
      columns: [
        Schema.colVerse,
        Schema.colText,
        Schema.colFootnote,
        Schema.colType,
        Schema.colFormat,
      ],
      where: '${Schema.colBookId} = ? AND ${Schema.colChapter} = ?',
      whereArgs: [bookId, chapter],
      orderBy: '${Schema.colId} ASC',
    );

    return verses.map(
      (verse) {
        final format = verse[Schema.colFormat] as int?;
        return VerseLine(
          bookId: bookId,
          chapter: chapter,
          verse: verse[Schema.colVerse] as int,
          text: verse[Schema.colText] as String,
          footnote: verse[Schema.colFootnote] as String?,
          format: (format == null) ? null : Format.fromInt(format),
          type: TextType.fromInt(verse[Schema.colType] as int),
        );
      },
    ).toList();
  }
}
