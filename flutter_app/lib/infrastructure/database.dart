import 'dart:developer';
import 'dart:io';
import 'package:bsb/infrastructure/extrabiblical_texts.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/source_texts.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:bsb/infrastructure/verse_line.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:database_builder/database_builder.dart';

class DatabaseHelper {
  static const _databaseName = "database.db";
  static const _databaseVersion = 9;
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
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes, flush: true);
  }

  Future<List<VerseLine>> getChapter(int bookId, int chapter) async {
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

  Future<List<VerseLine>> getRange(Reference reference) async {
    final verses = await _database.query(
      Schema.bibleTextTable,
      columns: [
        Schema.colVerse,
        Schema.colText,
        Schema.colType,
        Schema.colFormat,
      ],
      where: '${Schema.colBookId} = ? '
          'AND ${Schema.colChapter} = ? '
          'AND ${Schema.colVerse} >= ? '
          'AND ${Schema.colVerse} <= ?',
      whereArgs: [
        reference.bookId,
        reference.chapter,
        reference.verse,
        reference.endVerse ?? reference.verse,
      ],
      orderBy: '${Schema.colId} ASC',
    );

    return verses.map(
      (verse) {
        final format = verse[Schema.colFormat] as int?;
        return VerseLine(
          bookId: reference.bookId,
          chapter: reference.chapter,
          verse: verse[Schema.colVerse] as int,
          text: verse[Schema.colText] as String,
          footnote: null,
          format: (format == null) ? null : Format.fromInt(format),
          type: TextType.fromInt(verse[Schema.colType] as int),
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
        Schema.colBookId,
        Schema.colChapter,
        Schema.colVerse,
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
      final bookId = footnote[Schema.colBookId] as int;
      final chapter = footnote[Schema.colChapter] as int;
      final verse = footnote[Schema.colVerse] as int;
      final reference = Reference(bookId: bookId, chapter: chapter, verse: verse);
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
      if (referenced.contains('Jasher') || referenced.contains('Enoch') || referenced.contains('Esdras')) {
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
