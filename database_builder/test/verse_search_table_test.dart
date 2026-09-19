import 'package:database_builder/src/verse_search_table.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

void main() {
  group('cleanVerseText', () {
    test('strips standard footnotes', () {
      const raw =
          r'And God said, “Let there be light,”\f + \fr 1:3 \ft Cited in \ref 2 Corinthians 4:6|2CO 4:6\ref*\f* and there was light.';
      final cleaned = cleanVerseText(raw);
      expect(cleaned, equals('And God said, “Let there be light,” and there was light.'));
    });

    test('strips complex footnotes with fqa and multiple tags', () {
      const raw =
          r'With loving devotion\f + \fr 15:13 \ft Forms of the Hebrew \fqa chesed \ft are translated here\f* You will lead';
      final cleaned = cleanVerseText(raw);
      expect(cleaned, equals('With loving devotion You will lead'));
    });

    test('normalizes extra whitespace', () {
      const raw = '   In   the    beginning   ';
      final cleaned = cleanVerseText(raw);
      expect(cleaned, equals('In the beginning'));
    });

    test('strips words of Jesus markers while preserving spoken text', () {
      const raw = r'\wj “What do you want?”\wj* He asked.';
      final cleaned = cleanVerseText(raw);
      expect(cleaned, equals('“What do you want?” He asked.'));
    });

    test('strips footnote and words of jesus combined', () {
      const raw =
          r'\wj  “Come and see,”\wj* He replied. So they went and saw where He was staying, and spent that day with Him. It was about the tenth hour.\f + \fr 1:39 \ft That is, about four in the afternoon\f*';
      final cleaned = cleanVerseText(raw);
      expect(
        cleaned,
        equals(
          '“Come and see,” He replied. So they went and saw where He was staying, and spent that day with Him. It was about the tenth hour.',
        ),
      );
    });

    test('handles footnote directly followed by word without space', () {
      const raw =
          r'She named him Samuel,\f + \fr 1:20 \fqa Samuel \ft sounds like Hebrew\f*saying, “Because...”';
      final cleaned = cleanVerseText(raw);
      expect(cleaned, equals('She named him Samuel, saying, “Because...”'));
    });
  });

  group('verses_search FTS4 table', () {
    late Database db;

    setUpAll(() {
      db = openTestDatabase();
    });

    tearDownAll(() {
      db.close();
    });

    test('verses_search table uses FTS4', () {
      final rows = db.select(
        "SELECT sql FROM sqlite_master WHERE name = 'verses_search';",
      );
      expect(rows, isNotEmpty);
      final sql = (rows.first['sql'] as String).toLowerCase();
      expect(sql, contains('fts4'));
      expect(sql, isNot(contains('fts5')));
    });

    test('contains all 31,086 canonical verses', () {
      final count = db.select(
        'SELECT count(*) as c FROM verses_search_docsize;',
      ).first['c'] as int;
      expect(count, equals(kTotalCanonicalVerses));
    });

    test('matches prefix queries ordered canonically', () {
      final results = db.select('''
        SELECT docid FROM verses_search
        WHERE verses_search MATCH ?
        ORDER BY docid ASC;
      ''', ['love*']);
      expect(results.length, greaterThan(200));
      // First canonical match is in Genesis
      final firstRef = results.first['docid'] as int;
      expect(firstRef ~/ 1000000, equals(1)); // Genesis
    });

    test('matches exact phrase queries', () {
      final results = db.select('''
        SELECT docid FROM verses_search
        WHERE verses_search MATCH ?
        ORDER BY docid ASC;
      ''', ['"in the beginning"']);
      expect(results.length, greaterThanOrEqualTo(2));
      expect(results.first['docid'], equals(1001001)); // Gen 1:1
      final refs = results.map((r) => r['docid'] as int).toList();
      expect(refs, contains(43001001)); // John 1:1
    });
  });
}
