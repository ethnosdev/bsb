import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('Reference Packing and Unpacking', () {
    test('packs references into BBCCCVVV integer format', () {
      expect(packReference(1, 1, 0), equals(1001000));
      expect(packReference(1, 1, 1), equals(1001001));
      expect(packReference(1, 50, 26), equals(1050026));
      expect(packReference(19, 119, 176), equals(19119176));
      expect(packReference(40, 1, 1), equals(40001001));
      expect(packReference(66, 22, 21), equals(66022021));
    });

    test('unpacks references accurately into components', () {
      expect(unpackBook(1001000), equals(1));
      expect(unpackChapter(1001000), equals(1));
      expect(unpackVerse(1001000), equals(0));

      expect(unpackBook(1001001), equals(1));
      expect(unpackChapter(1001001), equals(1));
      expect(unpackVerse(1001001), equals(1));

      expect(unpackBook(19119176), equals(19));
      expect(unpackChapter(19119176), equals(119));
      expect(unpackVerse(19119176), equals(176));

      expect(unpackBook(66022021), equals(66));
      expect(unpackChapter(66022021), equals(22));
      expect(unpackVerse(66022021), equals(21));
    });

    test('round-trip packing and unpacking preserves all values', () {
      final cases = [
        (1, 1, 0),
        (1, 1, 1),
        (2, 40, 38),
        (19, 119, 176),
        (40, 28, 20),
        (66, 22, 21),
      ];

      for (final (book, chapter, verse) in cases) {
        final packed = packReference(book, chapter, verse);
        expect(unpackBook(packed), equals(book));
        expect(unpackChapter(packed), equals(chapter));
        expect(unpackVerse(packed), equals(verse));
      }
    });
  });
}
