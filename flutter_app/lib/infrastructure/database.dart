import 'dart:io';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:bsb/infrastructure/verse_line.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:database_builder/database_builder.dart';

class DatabaseHelper {
  static const _databaseName = "database.db";
  static const _databaseVersion = 8;
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

  Future<int> getVerseCount(int bookId, int chapter) async {
    final result = await _database.rawQuery(
      'SELECT MAX(${Schema.colVerse}) as max_verse '
      'FROM ${Schema.bibleTextTable} '
      'WHERE ${Schema.colBookId} = ? AND ${Schema.colChapter} = ?',
      [bookId, chapter],
    );
    return result.first['max_verse'] as int;
  }

  Future<List<VerseElement>> getOriginalLanguageData(
    Reference reference,
  ) async {
    final result = await _database.rawQuery(
      'SELECT o.${Schema.olColWord} as ${Schema.ilColOriginal}, '
      'e.${Schema.engColWord} as ${Schema.ilColEnglish}, '
      'i.${Schema.ilColStrongsNumber}, '
      'p.${Schema.posColName} as ${Schema.ilColPartOfSpeech}, '
      'i.${Schema.ilColLanguage}, '
      'i.${Schema.ilColPunctuation} '
      'FROM ${Schema.interlinearTable} i '
      'JOIN ${Schema.englishTable} e ON i.${Schema.ilColEnglish} = e.${Schema.engColId} '
      'JOIN ${Schema.partOfSpeechTable} p ON i.${Schema.ilColPartOfSpeech} = p.${Schema.posColId} '
      'JOIN ${Schema.originalLanguageTable} o ON i.${Schema.ilColOriginal} = o.${Schema.olColId} '
      'WHERE i.${Schema.ilColBookId} = ? AND i.${Schema.ilColChapter} = ? AND i.${Schema.ilColVerse} = ? '
      'ORDER BY i.${Schema.ilColId}',
      [reference.bookId, reference.chapter, reference.verse],
    );
    return result.map((row) {
      final text = row[Schema.ilColOriginal] as String;
      if (row[Schema.ilColPunctuation] == 1) {
        return Punctuation(punctuation: text);
      } else {
        return OriginalWord(
          language: Language.fromInt(row[Schema.ilColLanguage] as int),
          word: text,
          englishGloss: row[Schema.ilColEnglish] as String,
          strongsNumber: row[Schema.ilColStrongsNumber] as int,
          partOfSpeech: row[Schema.ilColPartOfSpeech] as String,
        );
      }
    }).toList();
  }

  Future<List<Reference>> getVersesWithStrongNumber(
    Language language,
    int strongsNumber,
  ) async {
    final result = await _database.rawQuery(
      'SELECT DISTINCT ${Schema.ilColBookId}, ${Schema.ilColChapter}, ${Schema.ilColVerse} '
      'FROM ${Schema.interlinearTable} '
      'WHERE ${Schema.ilColStrongsNumber} = ? AND ${Schema.ilColLanguage} = ? '
      'ORDER BY ${Schema.ilColBookId}, ${Schema.ilColChapter}, ${Schema.ilColVerse}',
      [strongsNumber, language.id],
    );

    return result
        .map((row) => Reference(
              bookId: row[Schema.ilColBookId] as int,
              chapter: row[Schema.ilColChapter] as int,
              verse: row[Schema.ilColVerse] as int,
            ))
        .toList();
  }
}
