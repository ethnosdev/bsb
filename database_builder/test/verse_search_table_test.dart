import 'package:database_builder/src/verse_search_table.dart';
import 'package:test/test.dart';

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
  });
}
