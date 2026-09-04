import 'package:database_builder/database_builder.dart';
import 'package:scripture/scripture_core.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  late Database db;

  setUpAll(() {
    db = openTestDatabase();
  });

  tearDownAll(() {
    db.close();
  });

  group('Schema & Table Integrity', () {
    test('all required tables exist', () {
      final tables = db
          .select("SELECT name FROM sqlite_master WHERE type = 'table';")
          .map((row) => row['name'] as String)
          .toSet();

      expect(
        tables,
        containsAll([
          Schema.bibleTextTable,
          Schema.interlinearTable,
          Schema.originalLanguageTable,
          Schema.englishTable,
          Schema.partOfSpeechTable,
        ]),
      );
    });

    test('all tables have expected row counts', () {
      int count(String table) =>
          db.select('SELECT count(*) as c FROM $table;').first['c'] as int;

      expect(count(Schema.bibleTextTable), greaterThan(68000));
      expect(count(Schema.interlinearTable), greaterThan(440000));
      expect(count(Schema.originalLanguageTable), greaterThan(130000));
      expect(count(Schema.englishTable), greaterThan(100000));
      expect(count(Schema.partOfSpeechTable), greaterThan(3800));
    });
  });

  group('Canonical Structure & Verse Completeness', () {
    test('contains all 66 canonical books', () {
      final books = db
          .select(
            'SELECT DISTINCT ${Schema.colReference} / 1000000 as book '
            'FROM ${Schema.bibleTextTable} ORDER BY book;',
          )
          .map((row) => row['book'] as int)
          .toList();

      expect(books.length, equals(kTotalBooks));
      expect(books, equals(List.generate(66, (i) => i + 1)));
    });

    test('contains exactly 1,189 canonical chapters (929 OT, 260 NT)', () {
      final totalChapters = db
          .select(
            'SELECT count(DISTINCT ${Schema.colReference} / 1000) as c '
            'FROM ${Schema.bibleTextTable};',
          )
          .first['c'] as int;
      expect(totalChapters, equals(kTotalChapters));

      final otChapters = db
          .select(
            'SELECT count(DISTINCT ${Schema.colReference} / 1000) as c '
            'FROM ${Schema.bibleTextTable} '
            'WHERE ${Schema.colReference} / 1000000 <= $kOldTestamentBooks;',
          )
          .first['c'] as int;
      expect(otChapters, equals(kOldTestamentChapters));

      final ntChapters = db
          .select(
            'SELECT count(DISTINCT ${Schema.colReference} / 1000) as c '
            'FROM ${Schema.bibleTextTable} '
            'WHERE ${Schema.colReference} / 1000000 > $kOldTestamentBooks;',
          )
          .first['c'] as int;
      expect(ntChapters, equals(kNewTestamentChapters));
    });

    test(
      'contains exactly 31,086 distinct canonical verses (23,145 OT, 7,941 NT)',
      () {
        final totalVerses = db
            .select(
              'SELECT count(DISTINCT ${Schema.colReference}) as c '
              'FROM ${Schema.bibleTextTable} '
              'WHERE ${Schema.colReference} % 1000 > 0;',
            )
            .first['c'] as int;
        expect(totalVerses, equals(kTotalCanonicalVerses));

        final otVerses = db
            .select(
              'SELECT count(DISTINCT ${Schema.colReference}) as c '
              'FROM ${Schema.bibleTextTable} '
              'WHERE ${Schema.colReference} % 1000 > 0 '
              '  AND ${Schema.colReference} / 1000000 <= $kOldTestamentBooks;',
            )
            .first['c'] as int;
        expect(otVerses, equals(kOldTestamentVerses));

        final ntVerses = db
            .select(
              'SELECT count(DISTINCT ${Schema.colReference}) as c '
              'FROM ${Schema.bibleTextTable} '
              'WHERE ${Schema.colReference} % 1000 > 0 '
              '  AND ${Schema.colReference} / 1000000 > $kOldTestamentBooks;',
            )
            .first['c'] as int;
        expect(ntVerses, equals(kNewTestamentVerses));
      },
    );

    test('every chapter in every book contains verse 1', () {
      final missingVerse1 = db.select('''
        SELECT ch.book, ch.chapter FROM (
          SELECT DISTINCT ${Schema.colReference} / 1000000 as book,
                          (${Schema.colReference} % 1000000) / 1000 as chapter
          FROM ${Schema.bibleTextTable}
        ) ch
        WHERE NOT EXISTS (
          SELECT 1 FROM ${Schema.bibleTextTable} b
          WHERE b.${Schema.colReference} / 1000000 = ch.book
            AND (b.${Schema.colReference} % 1000000) / 1000 = ch.chapter
            AND b.${Schema.colReference} % 1000 = 1
        );
      ''');

      expect(missingVerse1, isEmpty);
    });

    test('every book has the exact expected number of chapters', () {
      final rows = db.select('''
        SELECT ${Schema.colReference} / 1000000 as book,
               count(DISTINCT (${Schema.colReference} % 1000000) / 1000) as chapters
        FROM ${Schema.bibleTextTable}
        GROUP BY book
        ORDER BY book;
      ''');

      for (var row in rows) {
        final book = row['book'] as int;
        final chapters = row['chapters'] as int;
        expect(
          chapters,
          equals(kExpectedChaptersPerBook[book]),
          reason: 'Book $book chapter count mismatch',
        );
      }
    });

    test('every book has the exact expected number of canonical verses', () {
      final rows = db.select('''
        SELECT ${Schema.colReference} / 1000000 as book,
               count(DISTINCT ${Schema.colReference}) as verses
        FROM ${Schema.bibleTextTable}
        WHERE ${Schema.colReference} % 1000 > 0
        GROUP BY book
        ORDER BY book;
      ''');

      for (var row in rows) {
        final book = row['book'] as int;
        final verses = row['verses'] as int;
        expect(
          verses,
          equals(kExpectedVersesPerBook[book]),
          reason: 'Book $book verse count mismatch',
        );
      }
    });

    test('benchmark chapters have correct verse counts', () {
      int countVerses(int book, int ch) {
        return db
            .select(
              'SELECT count(DISTINCT ${Schema.colReference}) as c '
              'FROM ${Schema.bibleTextTable} '
              'WHERE ${Schema.colReference} / 1000000 = ? '
              '  AND (${Schema.colReference} % 1000000) / 1000 = ? '
              '  AND ${Schema.colReference} % 1000 > 0;',
              [book, ch],
            )
            .first['c'] as int;
      }

      expect(countVerses(1, 1), equals(31)); // Genesis 1
      expect(countVerses(19, 117), equals(2)); // Psalm 117 (shortest chapter)
      expect(countVerses(19, 119), equals(176)); // Psalm 119 (longest chapter)
      expect(countVerses(31, 1), equals(21)); // Obadiah (single chapter)
      expect(countVerses(40, 1), equals(25)); // Matthew 1
      expect(countVerses(57, 1), equals(25)); // Philemon
      expect(countVerses(63, 1), equals(13)); // 2 John
      expect(countVerses(64, 1), equals(14)); // 3 John
      expect(countVerses(65, 1), equals(25)); // Jude
      expect(countVerses(66, 22), equals(21)); // Revelation 22
    });

    test('references are strictly monotonic (non-decreasing) in bible table', () {
      final outOfOrder = db.select('''
        SELECT count(*) as c FROM (
          SELECT ${Schema.colReference} as ref,
                 LAG(${Schema.colReference}) OVER (ORDER BY ${Schema.colId}) as prev_ref
          FROM ${Schema.bibleTextTable}
        ) WHERE prev_ref IS NOT NULL AND ref < prev_ref;
      ''').first['c'] as int;

      expect(outOfOrder, equals(0));
    });

    test('all references are valid packed integers', () {
      final invalidRefs = db.select('''
        SELECT count(*) as c FROM ${Schema.bibleTextTable}
        WHERE ${Schema.colReference} / 1000000 < 1
           OR ${Schema.colReference} / 1000000 > 66
           OR (${Schema.colReference} % 1000000) / 1000 < 1
           OR ${Schema.colReference} % 1000 < 0;
      ''').first['c'] as int;

      expect(invalidRefs, equals(0));
    });

    test(
      'verse 0 is only used for headings, titles, cross-references, or breaks',
      () {
        final regularTextOnVerse0 = db.select('''
        SELECT count(*) as c FROM ${Schema.bibleTextTable}
        WHERE ${Schema.colReference} % 1000 = 0
          AND ${Schema.colFormat} NOT IN ('s1', 's2', 'r', 'd', 'ms', 'qa', 'b');
      ''').first['c'] as int;

        expect(regularTextOnVerse0, equals(0));
      },
    );
  });

  group('Text Hygiene & USFM Parsing Quality', () {
    test('zero occurrences of Words of Jesus tags (\\wj or \\wj*) in bible text', () {
      final wjCount = db.select('''
        SELECT count(*) as c FROM ${Schema.bibleTextTable}
        WHERE ${Schema.colText} LIKE '%\\wj%'
           OR ${Schema.colText} LIKE '%\\wj*%';
      ''').first['c'] as int;

      expect(wjCount, equals(0));
    });

    test('zero phantom rows with text = "\\wj"', () {
      final phantomWj = db.select('''
        SELECT count(*) as c FROM ${Schema.bibleTextTable}
        WHERE trim(${Schema.colText}) = '\\wj';
      ''').first['c'] as int;

      expect(phantomWj, equals(0));
    });

    test('zero unstripped \\ref* in cross-reference rows (format = "r")', () {
      final unstrippedRef = db.select('''
        SELECT count(*) as c FROM ${Schema.bibleTextTable}
        WHERE ${Schema.colFormat} = 'r'
          AND ${Schema.colText} LIKE '%\\ref*%';
      ''').first['c'] as int;

      expect(unstrippedRef, equals(0));
    });

    test('cross-references (format = "r") do not contain raw parentheses', () {
      final parensInCrossRefs = db.select('''
        SELECT count(*) as c FROM ${Schema.bibleTextTable}
        WHERE ${Schema.colFormat} = 'r'
          AND (${Schema.colText} LIKE '%(%' OR ${Schema.colText} LIKE '%)%');
      ''').first['c'] as int;

      expect(parensInCrossRefs, equals(0));
    });

    test('zero rows where text starts with a backslash marker', () {
      final startsWithBackslash = db.select('''
        SELECT count(*) as c FROM ${Schema.bibleTextTable}
        WHERE ${Schema.colText} LIKE '\\%';
      ''').first['c'] as int;

      expect(startsWithBackslash, equals(0));
    });

    test('zero stray inline \\v or \\c markers in bible text', () {
      final strayInlineMarkers = db.select('''
        SELECT count(*) as c FROM ${Schema.bibleTextTable}
        WHERE ${Schema.colText} LIKE '%\\v %'
           OR ${Schema.colText} LIKE '%\\c %';
      ''').first['c'] as int;

      expect(strayInlineMarkers, equals(0));
    });

    test('all footnotes (\\f) are properly closed with (\\f*)', () {
      final unclosedFootnotes = db.select('''
        SELECT count(*) as c FROM ${Schema.bibleTextTable}
        WHERE (LENGTH(${Schema.colText}) - LENGTH(REPLACE(${Schema.colText}, '\\f ', ''))) / 3 !=
              (LENGTH(${Schema.colText}) - LENGTH(REPLACE(${Schema.colText}, '\\f*', ''))) / 3;
      ''').first['c'] as int;

      expect(unclosedFootnotes, equals(0));
    });

    test('Matthew 5:15 has clean text starting without \\wj', () {
      final rows = db.select('''
        SELECT ${Schema.colText} as text FROM ${Schema.bibleTextTable}
        WHERE ${Schema.colReference} = 40005015;
      ''');

      expect(rows, isNotEmpty);
      final text = rows.first['text'] as String;
      expect(text, startsWith('Neither do people light a lamp'));
      expect(text, isNot(contains(r'\wj')));
    });

    test('Psalm 112:1 contains expected footnote with \\fqa markup', () {
      final rows = db.select('''
        SELECT ${Schema.colText} as text FROM ${Schema.bibleTextTable}
        WHERE ${Schema.colReference} = 19112001 AND ${Schema.colFormat} = 'q1';
      ''');

      expect(rows, isNotEmpty);
      final text = rows.first['text'] as String;
      expect(text, startsWith('Hallelujah!'));
      expect(text, contains(r'\fqa Hallelu YAH\ft'));
    });
  });

  group('Paragraph Format Invariants', () {
    test('every format value in bible table deserializes to ParagraphFormat', () {
      final formats = db
          .select(
            'SELECT DISTINCT ${Schema.colFormat} as format '
            'FROM ${Schema.bibleTextTable};',
          )
          .map((row) => row['format'] as String);

      for (var format in formats) {
        expect(
          () => ParagraphFormat.fromJson(format),
          returnsNormally,
          reason: 'Unknown format: "$format"',
        );
      }
    });

    test('empty text rows are strictly and exclusively format = "b"', () {
      final emptyNonBreak = db.select('''
        SELECT count(*) as c FROM ${Schema.bibleTextTable}
        WHERE trim(${Schema.colText}) = '' AND ${Schema.colFormat} != 'b';
      ''').first['c'] as int;
      expect(emptyNonBreak, equals(0));

      final nonEmptyBreak = db.select('''
        SELECT count(*) as c FROM ${Schema.bibleTextTable}
        WHERE trim(${Schema.colText}) != '' AND ${Schema.colFormat} = 'b';
      ''').first['c'] as int;
      expect(nonEmptyBreak, equals(0));
    });

    test('no consecutive break rows (format = "b")', () {
      final consecutiveBreaks = db.select('''
        SELECT count(*) as c FROM (
          SELECT ${Schema.colFormat} as format,
                 LAG(${Schema.colFormat}) OVER (ORDER BY ${Schema.colId}) as prev_format
          FROM ${Schema.bibleTextTable}
        ) WHERE format = 'b' AND prev_format = 'b';
      ''').first['c'] as int;

      expect(consecutiveBreaks, equals(0));
    });

    test('section headings (s1, s2) have non-empty text', () {
      final emptyHeadings = db.select('''
        SELECT count(*) as c FROM ${Schema.bibleTextTable}
        WHERE ${Schema.colFormat} IN ('s1', 's2')
          AND trim(${Schema.colText}) = '';
      ''').first['c'] as int;

      expect(emptyHeadings, equals(0));
    });
  });

  group('Interlinear Table Integrity', () {
    test('interlinear table has expected word count (>440,000 words)', () {
      final count = db
          .select(
            'SELECT count(*) as c FROM ${Schema.interlinearTable};',
          )
          .first['c'] as int;
      expect(count, greaterThan(440000));
    });

    test('interlinear references are strictly monotonic (non-decreasing)', () {
      final outOfOrder = db.select('''
        SELECT count(*) as c FROM (
          SELECT ${Schema.ilColReference} as ref,
                 LAG(${Schema.ilColReference}) OVER (ORDER BY ${Schema.ilColId}) as prev_ref
          FROM ${Schema.interlinearTable}
        ) WHERE prev_ref IS NOT NULL AND ref < prev_ref;
      ''').first['c'] as int;

      expect(outOfOrder, equals(0));
    });

    test('interlinear does not contain verse 0 references', () {
      final verse0Count = db.select('''
        SELECT count(*) as c FROM ${Schema.interlinearTable}
        WHERE ${Schema.ilColReference} % 1000 = 0;
      ''').first['c'] as int;

      expect(verse0Count, equals(0));
    });

    test(
      'interlinear covers all 31,085 canonical verses (only Neh 7:68 omitted)',
      () {
        final distinctVerses = db.select('''
        SELECT count(DISTINCT ${Schema.ilColReference}) as c
        FROM ${Schema.interlinearTable};
      ''').first['c'] as int;

        expect(distinctVerses, equals(kInterlinearCanonicalVerses));

        final missingFromInterlinear = db.select('''
        SELECT DISTINCT b.${Schema.colReference} as ref
        FROM ${Schema.bibleTextTable} b
        LEFT JOIN ${Schema.interlinearTable} i
          ON b.${Schema.colReference} = i.${Schema.ilColReference}
        WHERE b.${Schema.colReference} % 1000 > 0
          AND i.${Schema.ilColReference} IS NULL;
      ''');

        expect(missingFromInterlinear.length, equals(1));
        expect(missingFromInterlinear.first['ref'], equals(kNehemiah7Verse68));
      },
    );

    test('every reference in interlinear exists in the bible table', () {
      final orphans = db.select('''
        SELECT count(DISTINCT i.${Schema.ilColReference}) as c
        FROM ${Schema.interlinearTable} i
        LEFT JOIN ${Schema.bibleTextTable} b
          ON i.${Schema.ilColReference} = b.${Schema.colReference}
        WHERE b.${Schema.colReference} IS NULL;
      ''').first['c'] as int;

      expect(orphans, equals(0));
    });

    test('language column matches testaments (OT: Hebrew/Aramaic, NT: Greek)', () {
      final invalidLanguages = db.select('''
        SELECT count(*) as c FROM ${Schema.interlinearTable}
        WHERE (${Schema.ilColReference} / 1000000 <= $kOldTestamentBooks AND ${Schema.ilColLanguage} NOT IN (0, 1))
           OR (${Schema.ilColReference} / 1000000 > $kOldTestamentBooks AND ${Schema.ilColLanguage} != 2);
      ''').first['c'] as int;

      expect(invalidLanguages, equals(0));
    });

    test('foreign keys to original table are all valid', () {
      final missingOriginal = db.select('''
        SELECT count(*) as c
        FROM ${Schema.interlinearTable} i
        LEFT JOIN ${Schema.originalLanguageTable} o
          ON i.${Schema.ilColOriginal} = o.${Schema.olColId}
        WHERE o.${Schema.olColId} IS NULL;
      ''').first['c'] as int;

      expect(missingOriginal, equals(0));
    });

    test('foreign keys to english table are all valid', () {
      final missingEnglish = db.select('''
        SELECT count(*) as c
        FROM ${Schema.interlinearTable} i
        LEFT JOIN ${Schema.englishTable} e
          ON i.${Schema.ilColEnglish} = e.${Schema.engColId}
        WHERE e.${Schema.engColId} IS NULL;
      ''').first['c'] as int;

      expect(missingEnglish, equals(0));
    });

    test('foreign keys to pos table are valid (or -1 when untagged)', () {
      final invalidPos = db.select('''
        SELECT count(*) as c
        FROM ${Schema.interlinearTable} i
        LEFT JOIN ${Schema.partOfSpeechTable} p
          ON i.${Schema.ilColPartOfSpeech} = p.${Schema.posColId}
        WHERE i.${Schema.ilColPartOfSpeech} != -1
          AND p.${Schema.posColId} IS NULL;
      ''').first['c'] as int;

      expect(invalidPos, equals(0));
    });

    test('strongs numbers are either -1 (untagged) or positive integers <= 8674', () {
      final invalidStrongs = db.select('''
        SELECT count(*) as c FROM ${Schema.interlinearTable}
        WHERE ${Schema.ilColStrongsNumber} != -1
          AND (${Schema.ilColStrongsNumber} < 1 OR ${Schema.ilColStrongsNumber} > 8674);
      ''').first['c'] as int;

      expect(invalidStrongs, equals(0));
    });

    test('Genesis 1:1 in interlinear has 7 Hebrew words', () {
      final rows = db.select('''
        SELECT o.${Schema.olColWord} as original,
               e.${Schema.engColWord} as english,
               i.${Schema.ilColLanguage} as lang
        FROM ${Schema.interlinearTable} i
        JOIN ${Schema.originalLanguageTable} o ON i.${Schema.ilColOriginal} = o.${Schema.olColId}
        JOIN ${Schema.englishTable} e ON i.${Schema.ilColEnglish} = e.${Schema.engColId}
        WHERE i.${Schema.ilColReference} = 1001001
        ORDER BY i.${Schema.ilColId};
      ''');

      expect(rows.length, equals(7));
      expect(rows.first['lang'], equals(0)); // Hebrew
      expect(rows.first['original'], equals('בְּרֵאשִׁ֖ית'));
      expect(rows.first['english'], equals('In the beginning'));
    });

    test('John 1:1 in interlinear has 17 Greek words', () {
      final rows = db.select('''
        SELECT o.${Schema.olColWord} as original,
               e.${Schema.engColWord} as english,
               i.${Schema.ilColLanguage} as lang
        FROM ${Schema.interlinearTable} i
        JOIN ${Schema.originalLanguageTable} o ON i.${Schema.ilColOriginal} = o.${Schema.olColId}
        JOIN ${Schema.englishTable} e ON i.${Schema.ilColEnglish} = e.${Schema.engColId}
        WHERE i.${Schema.ilColReference} = 43001001
        ORDER BY i.${Schema.ilColId};
      ''');

      expect(rows.length, equals(17));
      expect(rows.first['lang'], equals(2)); // Greek
      expect(rows.first['original'], equals('Ἐν'));
      expect(rows.first['english'], equals('In'));
    });
  });

  group('Foreign Tables Integrity (original, english, pos)', () {
    test('original table words are all non-empty strings', () {
      final emptyOriginal = db.select('''
        SELECT count(*) as c FROM ${Schema.originalLanguageTable}
        WHERE trim(${Schema.olColWord}) = '';
      ''').first['c'] as int;

      expect(emptyOriginal, equals(0));
    });

    test('english table words are all non-empty strings', () {
      final emptyEnglish = db.select('''
        SELECT count(*) as c FROM ${Schema.englishTable}
        WHERE trim(${Schema.engColWord}) = '';
      ''').first['c'] as int;

      expect(emptyEnglish, equals(0));
    });

    test('pos table names are all non-empty strings', () {
      final emptyPos = db.select('''
        SELECT count(*) as c FROM ${Schema.partOfSpeechTable}
        WHERE trim(${Schema.posColName}) = '';
      ''').first['c'] as int;

      expect(emptyPos, equals(0));
    });

    test('foreign table IDs start at 1 and match total row count', () {
      void checkIds(String table, String colId) {
        final row = db.select('''
          SELECT min($colId) as min_id,
                 max($colId) as max_id,
                 count(*) as count
          FROM $table;
        ''').first;

        expect(row['min_id'], equals(1));
        expect(row['max_id'], equals(row['count']));
      }

      checkIds(Schema.originalLanguageTable, Schema.olColId);
      checkIds(Schema.englishTable, Schema.engColId);
      checkIds(Schema.partOfSpeechTable, Schema.posColId);
    });
  });
}
