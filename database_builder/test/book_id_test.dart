import 'package:database_builder/src/book_id.dart';
import 'package:database_builder/src/utils/bsb_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Book ID Mappings', () {
    test('bookAbbreviationToIdMap has all 66 canonical books', () {
      expect(bookAbbreviationToIdMap.length, equals(66));

      // Keys must be 3-character uppercase abbreviations
      for (final abbrev in bookAbbreviationToIdMap.keys) {
        expect(abbrev.length, equals(3));
        expect(abbrev, equals(abbrev.toUpperCase()));
      }

      // Values must span 1 to 66
      final ids = bookAbbreviationToIdMap.values.toList()..sort();
      expect(ids, equals(List.generate(66, (i) => i + 1)));
    });

    test('bookIdToFullNameMap has all 66 canonical books', () {
      expect(bookIdToFullNameMap.length, equals(66));

      for (int id = 1; id <= 66; id++) {
        expect(bookIdToFullNameMap.containsKey(id), isTrue);
        expect(bookIdToFullNameMap[id], isNotEmpty);
      }

      expect(bookIdToFullNameMap[1], equals('Genesis'));
      expect(bookIdToFullNameMap[19], equals('Psalm'));
      expect(bookIdToFullNameMap[40], equals('Matthew'));
      expect(bookIdToFullNameMap[66], equals('Revelation'));
    });

    test('fullNameToBookIdMap contains all canonical names plus Psalms alias', () {
      // 66 canonical names + 'Psalms' alias for 'Psalm'
      expect(fullNameToBookIdMap.length, equals(67));
      expect(fullNameToBookIdMap['Psalm'], equals(19));
      expect(fullNameToBookIdMap['Psalms'], equals(19));

      for (final entry in bookIdToFullNameMap.entries) {
        expect(fullNameToBookIdMap[entry.value], equals(entry.key));
      }
    });

    test('bibleBookFilenames contains 66 files in order matching abbreviations', () {
      expect(bibleBookFilenames.length, equals(66));

      for (int i = 0; i < bibleBookFilenames.length; i++) {
        final filename = bibleBookFilenames[i];
        expect(filename.endsWith('.usfm'), isTrue);

        final abbrev = filename.replaceAll('.usfm', '');
        final expectedId = i + 1;
        expect(
          bookAbbreviationToIdMap[abbrev],
          equals(expectedId),
          reason: '$filename abbreviation does not map to expected ID $expectedId',
        );
      }
    });
  });
}
