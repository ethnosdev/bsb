import 'dart:developer';
import 'dart:io';
import 'package:bsb/infrastructure/extrabiblical_texts.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/source_texts.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:bsb/infrastructure/verse_line.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:scripture/scripture_core.dart';
import 'package:sqflite/sqflite.dart';
import 'package:database_builder/database_builder.dart';

class DatabaseHelper {
  static const _databaseName = "database.db";
  static const _databaseVersion = 12;
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
        Schema.colFootnote,
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
          footnote: verse[Schema.colFootnote] as String?,
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
        final translit =
            (language == Language.greek) ? transliterateGreek(text) : '';
        return OriginalWord(
          language: language,
          word: text,
          transliteration: translit,
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
        .map((row) => Reference.from(
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
          footnote: null,
          format: ParagraphFormat.fromJson(format),
        );
      },
    ).toList();
  }

  // This method is for checking footnote references. Make sure that we have
  // footnote links for extra biblical texts.
  Future<void> analyzeFootnotes() async {
    final footnotes = await _database.query(
      Schema.bibleTextTable,
      columns: [
        Schema.colReference,
        Schema.colFootnote,
      ],
      where: '${Schema.colFootnote} IS NOT NULL',
      orderBy: '${Schema.colId} ASC',
    );

    const verseRange = '\\d+:\\d+(?:–\\d+)?';
    final patterns = [
      ...validBookNames.map((kw) => '$kw $verseRange'),
      ...sourceTexts.keys.map((kw) => RegExp.escape(kw)),
      ...validExtraBiblicalTexts.keys,
    ].join('|');
    final regex = RegExp('($patterns)');

    final Set<(String, Reference)> references = {};

    for (final footnote in footnotes) {
      final note = footnote[Schema.colFootnote] as String;
      final packedReference = footnote[Schema.colReference] as int;
      final reference = Reference.from(packedInt: packedReference);
      final matches = regex.allMatches(note);
      for (final match in matches) {
        final start = match.start;
        final end = match.end;
        references.add((note.substring(start, end), reference));
      }
    }

    final Set<String> bookNames = {};
    for (final ref in references) {
      final (referenced, source) = ref;
      if (referenced.contains('Jasher') ||
          referenced.contains('Enoch') ||
          referenced.contains('Esdras')) {
        log('$referenced: $source');
      }
      final index = referenced.lastIndexOf(' ');
      if (index > 0) {
        final bookName = referenced.substring(0, index);
        bookNames.add(bookName);
      }
    }

    final sortedBooks = bookNames.toList()..sort();
    for (final book in sortedBooks) {
      log(book);
    }
  }
}
