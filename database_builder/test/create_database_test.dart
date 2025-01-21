import 'package:database_builder/bsb/create_database.dart';
import 'package:test/test.dart';

void main() {
  group('extractFootnote', () {
    test('returns original text when no footnote present', () {
      const text = 'Simple text without footnote';
      final result = extractFootnote(text);
      expect(result.$1, equals(text));
      expect(result.$2, isNull);
    });

    test('extracts single footnote correctly without space', () {
      const text = r'But springs\f + \fr 2:6 \ft Or mist\f* welled up';
      final result = extractFootnote(text);
      expect(result.$1, equals('But springs welled up'));
      expect(result.$2, equals('11#Or mist'));
    });

    test('extracts single footnote correctly after space', () {
      const text = r'But springs \f + \fr 2:6 \ft Or mist\f* welled up';
      final result = extractFootnote(text);
      expect(result.$1, equals('But springs welled up'));
      expect(result.$2, equals('11#Or mist'));
    });

    test('extracts multiple footnotes correctly', () {
      const text =
          'But springs \\f + \\fr 2:6 \\ft Or mist\\f* welled up from the earth \\f + \\fr 2:7 \\ft Or land\\f*';
      final result = extractFootnote(text);
      expect(result.$1, equals('But springs welled up from the earth'));
      expect(result.$2, equals('11#Or mist\n36#Or land'));
    });

    test('throws RangeError for malformed footnote', () {
      const text = 'But springs \\f + \\fr 2:6 \\ft Or mist welled up';
      expect(() => extractFootnote(text), throwsRangeError);
    });
  });
}
