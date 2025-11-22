import 'dart:developer';
import 'dart:io';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';
import 'package:sqflite/sqflite.dart';
import 'package:database_builder/database_builder.dart';

class DatabaseHelper {
  static const _databaseName = "database.db";
  static const _databaseVersion = 14;
  late Database _database;

  Future<void> init() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, _databaseName);
    var exists = await databaseExists(path);

    if (!exists) {
      log("Creating new copy from asset");
      await _copyDatabaseFromAssets(path);
    } else {
      // Check if database needs update
      var currentVersion = await getDatabaseVersion(path);
      if (currentVersion != _databaseVersion) {
        log("Updating database from version $currentVersion to $_databaseVersion");
        await deleteDatabase(path);
        await _copyDatabaseFromAssets(path);
      } else {
        log("Opening existing database");
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
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes, flush: true);
  }

  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async {
    final (lowerBound, upperBound) = _chapterBounds(bookId, chapter);

    final verses = await _database.query(
      Schema.bibleTextTable,
      columns: [
        Schema.colReference,
        Schema.colText,
        Schema.colFormat,
      ],
      where: '${Schema.colReference} >= ? AND ${Schema.colReference} < ?',
      whereArgs: [lowerBound, upperBound],
      orderBy: '${Schema.colId} ASC',
    );

    return verses.map(
      (verse) {
        final format = verse[Schema.colFormat] as String;
        return UsfmLine(
          bookChapterVerse: verse[Schema.colReference] as int,
          text: verse[Schema.colText] as String,
          format: ParagraphFormat.fromJson(format),
        );
      },
    ).toList();
  }

  (int, int) _chapterBounds(int bookId, int chapter) {
    const int bookMultiplier = 1000000;
    const int chapterMultiplier = 1000;
    final int lowerBound =
        bookId * bookMultiplier + chapter * chapterMultiplier;
    final int upperBound =
        bookId * bookMultiplier + (chapter + 1) * chapterMultiplier;
    return (lowerBound, upperBound);
  }

  Future<int> getVerseCount(int bookId, int chapter) async {
    final (lowerBound, upperBound) = _chapterBounds(bookId, chapter);
    final result = await _database.rawQuery(
      'SELECT MAX(${Schema.colReference}) as max_ref '
      'FROM ${Schema.bibleTextTable} '
      'WHERE ${Schema.colReference} >= ? AND ${Schema.colReference} < ?',
      [lowerBound, upperBound],
    );

    final maxRef = result.first['max_ref'];
    if (maxRef == null) {
      return 0;
    }
    return (maxRef as int) % 1000;
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
      'WHERE i.${Schema.ilColReference} = ? '
      'ORDER BY i.${Schema.ilColId}',
      [reference.packedVerse],
    );
    return result.map((row) {
      final text = row[Schema.ilColOriginal] as String;
      if (row[Schema.ilColPunctuation] == 1) {
        return Punctuation(punctuation: text);
      } else {
        final language = Language.fromInt(row[Schema.ilColLanguage] as int);
        final transliteration =
            (language == Language.greek) ? transliterateGreek(text) : '';
        return OriginalWord(
          language: language,
          word: text,
          transliteration: transliteration,
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
      'SELECT DISTINCT ${Schema.ilColReference} '
      'FROM ${Schema.interlinearTable} '
      'WHERE ${Schema.ilColStrongsNumber} = ? AND ${Schema.ilColLanguage} = ? '
      'ORDER BY ${Schema.ilColReference}',
      [strongsNumber, language.id],
    );

    return result
        .map((row) => Reference.fromVerseId(
              packedInt: row[Schema.ilColReference] as int,
            ))
        .toList();
  }

  Future<List<UsfmLine>> getRange(Reference reference) async {
    final verses = await _database.query(
      Schema.bibleTextTable,
      columns: [
        Schema.colReference,
        Schema.colText,
        Schema.colFormat,
      ],
      where: '${Schema.colReference} >= ? '
          'AND ${Schema.colReference} <= ?',
      whereArgs: [
        reference.packedVerse,
        reference.packedEndVerse ?? reference.packedVerse,
      ],
      orderBy: '${Schema.colId} ASC',
    );

    return verses.map(
      (verse) {
        final format = verse[Schema.colFormat] as String;
        return UsfmLine(
          bookChapterVerse: verse[Schema.colReference] as int,
          text: verse[Schema.colText] as String,
          format: ParagraphFormat.fromJson(format),
        );
      },
    ).toList();
  }
}
