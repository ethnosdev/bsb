import 'dart:developer';
import 'dart:io';

import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/search/search_models.dart';
import 'package:bsb/infrastructure/section_heading.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:bsb/infrastructure/word_cluster.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';
import 'package:sqflite/sqflite.dart';
import 'package:database_builder/database_builder.dart';

class DatabaseHelper {
  static const _databaseName = "database.db";
  static const _databaseVersion = 28;
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
        log(
          "Updating database from version $currentVersion to $_databaseVersion",
        );
        await deleteDatabase(path);
        await _copyDatabaseFromAssets(path);
      } else {
        log("Opening existing database");
      }
    }
    _database = await openDatabase(path, version: _databaseVersion);
    await ensureSearchTableExists();
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
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    await File(path).writeAsBytes(bytes, flush: true);
  }

  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async {
    final (lowerBound, upperBound) = _chapterBounds(bookId, chapter);

    final verses = await _database.query(
      Schema.bibleTextTable,
      columns: [Schema.colReference, Schema.colText, Schema.colFormat],
      where: '${Schema.colReference} >= ? AND ${Schema.colReference} < ?',
      whereArgs: [lowerBound, upperBound],
      orderBy: '${Schema.colId} ASC',
    );

    return verses.map((verse) {
      final format = verse[Schema.colFormat] as String;
      return UsfmLine(
        bookChapterVerse: verse[Schema.colReference] as int,
        text: verse[Schema.colText] as String,
        format: ParagraphFormat.fromJson(format),
      );
    }).toList();
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
      'SELECT i.${Schema.ilColId} as token_id, '
      'o.${Schema.olColId} as original_id, '
      'o.${Schema.olColWord} as ${Schema.ilColOriginal}, '
      'e.${Schema.engColWord} as ${Schema.ilColEnglish}, '
      'i.${Schema.ilColStrongsNumber}, '
      'p.${Schema.posColName} as ${Schema.ilColPartOfSpeech}, '
      'i.${Schema.ilColLanguage}, '
      'i.${Schema.ilColPunctuation}, '
      'i.${Schema.ilColBsbSort} '
      'FROM ${Schema.interlinearTable} i '
      'JOIN ${Schema.englishTable} e ON i.${Schema.ilColEnglish} = e.${Schema.engColId} '
      'JOIN ${Schema.partOfSpeechTable} p ON i.${Schema.ilColPartOfSpeech} = p.${Schema.posColId} '
      'JOIN ${Schema.originalLanguageTable} o ON i.${Schema.ilColOriginal} = o.${Schema.olColId} '
      'WHERE i.${Schema.ilColReference} = ? '
      'ORDER BY i.${Schema.ilColId}',
      [reference.packedVerse],
    );
    final htmlTagRegex = RegExp(r'<[^>]+>');
    final words = result.map((row) {
      final text = row[Schema.ilColOriginal] as String;
      final language = Language.fromInt(row[Schema.ilColLanguage] as int);
      final transliteration = (language == Language.greek)
          ? transliterateGreek(text)
          : '';
      final rawPunctuation = row[Schema.ilColPunctuation] as String?;
      final punctuation = rawPunctuation?.replaceAll(htmlTagRegex, '');
      final bsbSort = (row[Schema.ilColBsbSort] as int?) ?? 0;
      final tokenId = (row['token_id'] as int?) ?? 0;
      final originalId = (row['original_id'] as int?) ?? 0;
      final rawEnglish = row[Schema.ilColEnglish] as String;
      final englishGloss = rawEnglish
          .replaceAll(htmlTagRegex, ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      return OriginalWord(
        id: tokenId,
        originalId: originalId,
        language: language,
        word: text,
        transliteration: transliteration,
        englishGloss: englishGloss,
        strongsNumber: row[Schema.ilColStrongsNumber] as int,
        partOfSpeech: row[Schema.ilColPartOfSpeech] as String,
        punctuation: (punctuation != null && punctuation.trim().isEmpty)
            ? null
            : punctuation,
        bsbSort: bsbSort,
      );
    }).toList();
    return resolveWordClusters(words);
  }

  Future<String?> getLexiconContent(
    Language language,
    int strongsNumber,
  ) async {
    final results = await _database.query(
      Schema.lexiconEntryTable,
      columns: [Schema.lexColContent],
      where: '${Schema.lexColLanguage} = ? AND ${Schema.lexColStrongs} = ?',
      whereArgs: [language.id, strongsNumber],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first[Schema.lexColContent] as String?;
    }
    return null;
  }

  Future<String?> getLexiconContentByLemma(
    Language? language,
    String lemma,
  ) async {
    final cleanLemma = lemma.trim();
    if (cleanLemma.isEmpty) return null;

    final whereClause = language != null
        ? '(${Schema.lexColLanguage} = ? OR ${Schema.lexColLanguage} = ?) AND (${Schema.lexColLemma} = ? OR ${Schema.lexColLemma} LIKE ?)'
        : '(${Schema.lexColLemma} = ? OR ${Schema.lexColLemma} LIKE ?)';
    final whereArgs = language != null
        ? [
            language.id,
            language == Language.hebrew ? Language.aramaic.id : language.id,
            cleanLemma,
            '%$cleanLemma%',
          ]
        : [cleanLemma, '%$cleanLemma%'];

    final results = await _database.query(
      Schema.lexiconEntryTable,
      columns: [Schema.lexColContent],
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first[Schema.lexColContent] as String?;
    }
    return null;
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
        .map(
          (row) => Reference.fromVerseId(
            packedInt: row[Schema.ilColReference] as int,
          ),
        )
        .toList();
  }

  Future<List<Reference>> getVersesWithExactWord(int originalId) async {
    final result = await _database.rawQuery(
      'SELECT DISTINCT ${Schema.ilColReference} '
      'FROM ${Schema.interlinearTable} '
      'WHERE ${Schema.ilColOriginal} = ? '
      'ORDER BY ${Schema.ilColReference}',
      [originalId],
    );

    return result
        .map(
          (row) => Reference.fromVerseId(
            packedInt: row[Schema.ilColReference] as int,
          ),
        )
        .toList();
  }

  Future<int> getExactWordCount(int originalId) async {
    final result = await _database.rawQuery(
      'SELECT count(DISTINCT ${Schema.ilColReference}) as c '
      'FROM ${Schema.interlinearTable} '
      'WHERE ${Schema.ilColOriginal} = ?',
      [originalId],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<int> getStrongNumberCount(Language language, int strongsNumber) async {
    final result = await _database.rawQuery(
      'SELECT count(DISTINCT ${Schema.ilColReference}) as c '
      'FROM ${Schema.interlinearTable} '
      'WHERE ${Schema.ilColStrongsNumber} = ? AND ${Schema.ilColLanguage} = ?',
      [strongsNumber, language.id],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<List<UsfmLine>> getRange(Reference reference) async {
    final verses = await _database.query(
      Schema.bibleTextTable,
      columns: [Schema.colReference, Schema.colText, Schema.colFormat],
      where:
          '${Schema.colReference} >= ? '
          'AND ${Schema.colReference} <= ?',
      whereArgs: [
        reference.packedVerse,
        reference.packedEndVerse ?? reference.packedVerse,
      ],
      orderBy: '${Schema.colId} ASC',
    );

    return verses.map((verse) {
      final format = verse[Schema.colFormat] as String;
      return UsfmLine(
        bookChapterVerse: verse[Schema.colReference] as int,
        text: verse[Schema.colText] as String,
        format: ParagraphFormat.fromJson(format),
      );
    }).toList();
  }

  Future<List<SectionHeading>> getSectionHeadings(int bookId) async {
    const int bookMultiplier = 1000000;
    final int lowerBound = bookId * bookMultiplier;
    final int upperBound = (bookId + 1) * bookMultiplier;

    final results = await _database.rawQuery(
      '''
      SELECT s.${Schema.colReference} as ref,
             s.${Schema.colText} as heading_text,
             s.${Schema.colFormat} as heading_format,
             (SELECT v.${Schema.colReference} FROM ${Schema.bibleTextTable} v
              WHERE v.${Schema.colId} > s.${Schema.colId}
                AND v.${Schema.colFormat} NOT IN ('s1', 's2', 'r', 'd', 'ms', 'b')
              LIMIT 1) as next_ref
      FROM ${Schema.bibleTextTable} s
      WHERE s.${Schema.colReference} >= ? AND s.${Schema.colReference} < ?
        AND s.${Schema.colFormat} IN ('s1', 's2')
      ORDER BY s.${Schema.colId} ASC
      ''',
      [lowerBound, upperBound],
    );

    return results.map((row) {
      final headingText = row['heading_text'] as String;
      final format = row['heading_format'] as String;
      final nextRef = row['next_ref'] as int?;
      final ref = row['ref'] as int;

      final int chapter;
      final int verse;

      if (nextRef != null) {
        chapter = (nextRef % 1000000) ~/ 1000;
        verse = nextRef % 1000;
      } else {
        chapter = (ref % 1000000) ~/ 1000;
        final rawVerse = ref % 1000;
        verse = rawVerse == 0 ? 1 : rawVerse;
      }

      return SectionHeading(
        bookId: bookId,
        chapter: chapter,
        verse: verse,
        text: headingText,
        format: format,
      );
    }).toList();
  }

  Future<void> ensureSearchTableExists() async {
    final tables = await _database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [Schema.verseSearchTable],
    );
    if (tables.isEmpty) {
      log("Creating and populating verse search table");
      await _populateSearchTable();
    }
  }

  Future<void> _populateSearchTable() async {
    await _database.execute(Schema.createVerseSearchTable);
    final rows = await _database.rawQuery('''
      SELECT ${Schema.colReference}, ${Schema.colText}
      FROM ${Schema.bibleTextTable}
      WHERE ${Schema.colFormat} NOT IN ('s1', 's2', 'r', 'd', 'ms', 'mr', 'b', 'qa')
        AND ${Schema.colReference} % 1000 != 0
      ORDER BY ${Schema.colId} ASC
    ''');

    final verses = <int, List<String>>{};
    for (final row in rows) {
      final ref = row[Schema.colReference] as int;
      final text = row[Schema.colText] as String;
      final clean = cleanVerseText(text);
      if (clean.isEmpty) continue;
      verses.putIfAbsent(ref, () => []).add(clean);
    }

    final batch = _database.batch();
    for (final entry in verses.entries) {
      final ref = entry.key;
      final bookId = ref ~/ 1000000;
      final chapter = (ref % 1000000) ~/ 1000;
      final verse = ref % 1000;
      final fullText = entry.value.join(' ');

      batch.rawInsert(Schema.insertVerseSearch, [
        ref,
        bookId,
        chapter,
        verse,
        fullText,
      ]);
    }
    await batch.commit(noResult: true);
    log("Verse search table populated with ${verses.length} verses");
  }

  static String _sanitizeFtsQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return '';

    final tokens = <String>[];
    final tokenRegex = RegExp(r'"([^"]+)"|(\S+)');
    for (final match in tokenRegex.allMatches(trimmed)) {
      final quoted = match.group(1);
      final unquoted = match.group(2);

      if (quoted != null && quoted.trim().isNotEmpty) {
        final clean = quoted.replaceAll('"', '""').trim();
        tokens.add('"$clean"');
      } else if (unquoted != null) {
        final clean = unquoted.replaceAll(RegExp(r'[^\w]'), '');
        if (clean.isNotEmpty) {
          tokens.add('$clean*');
        }
      }
    }

    if (tokens.isEmpty) return '';
    return tokens.join(' AND ');
  }

  Future<List<SearchResult>> searchVerses({
    required String query,
    SearchScope scope = SearchScope.all,
    int? specificBookId,
    int? limit,
  }) async {
    await ensureSearchTableExists();
    final cleanQuery = _sanitizeFtsQuery(query);
    if (cleanQuery.isEmpty) return [];

    String scopeClause = '';
    final List<Object?> args = [cleanQuery];

    switch (scope) {
      case SearchScope.all:
        break;
      case SearchScope.ot:
        scopeClause = 'AND ${Schema.colBookId} <= 39';
      case SearchScope.nt:
        scopeClause = 'AND ${Schema.colBookId} >= 40';
      case SearchScope.book:
        if (specificBookId != null) {
          scopeClause = 'AND ${Schema.colBookId} = ?';
          args.add(specificBookId);
        }
    }

    String limitClause = '';
    if (limit != null && limit > 0) {
      limitClause = 'LIMIT ?';
      args.add(limit);
    }

    try {
      final results = await _database.rawQuery('''
        SELECT ${Schema.colReference}, ${Schema.colText}
        FROM ${Schema.verseSearchTable}
        WHERE ${Schema.verseSearchTable} MATCH ? $scopeClause
        ORDER BY ${Schema.colReference} ASC
        $limitClause
        ''', args);

      return results.map((row) {
        final refInt = row[Schema.colReference] as int;
        final text = row[Schema.colText] as String;
        final ref = Reference.fromVerseId(packedInt: refInt);
        return SearchResult(reference: ref, text: text);
      }).toList();
    } catch (e) {
      log('Error during search: $e');
      return [];
    }
  }

  Future<String?> getVerseText(int reference) async {
    await ensureSearchTableExists();
    final results = await _database.query(
      Schema.verseSearchTable,
      columns: [Schema.colText],
      where: '${Schema.colReference} = ?',
      whereArgs: [reference],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first[Schema.colText] as String?;
    }
    return null;
  }
}
