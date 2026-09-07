import 'package:bsb/infrastructure/search/scripture_reference_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScriptureReferenceParser', () {
    test('parses full book name with chapter and verse', () {
      final ref = ScriptureReferenceParser.tryParse('John 3:16');
      expect(ref, isNotNull);
      expect(ref!.bookId, equals(43));
      expect(ref.chapter, equals(3));
      expect(ref.verse, equals(16));
      expect(ref.isExactVerse, isTrue);
    });

    test('parses common abbreviations', () {
      final jn = ScriptureReferenceParser.tryParse('jn 3:16');
      expect(jn, isNotNull);
      expect(jn!.bookId, equals(43));
      expect(jn.chapter, equals(3));
      expect(jn.verse, equals(16));

      final gen = ScriptureReferenceParser.tryParse('Gen 1:1');
      expect(gen, isNotNull);
      expect(gen!.bookId, equals(1));
      expect(gen.chapter, equals(1));
      expect(gen.verse, equals(1));

      final rom = ScriptureReferenceParser.tryParse('Rom 8:28');
      expect(rom, isNotNull);
      expect(rom!.bookId, equals(45));
      expect(rom.chapter, equals(8));
      expect(rom.verse, equals(28));

      final ps = ScriptureReferenceParser.tryParse('Ps 23:1');
      expect(ps, isNotNull);
      expect(ps!.bookId, equals(19));
      expect(ps.chapter, equals(23));
      expect(ps.verse, equals(1));
    });

    test('parses numbered books with flexible spacing', () {
      final firstCor1 = ScriptureReferenceParser.tryParse('1 Cor 13:4');
      expect(firstCor1, isNotNull);
      expect(firstCor1!.bookId, equals(46));
      expect(firstCor1.chapter, equals(13));
      expect(firstCor1.verse, equals(4));

      final firstCor2 = ScriptureReferenceParser.tryParse('1co 13:4');
      expect(firstCor2, isNotNull);
      expect(firstCor2!.bookId, equals(46));
      expect(firstCor2.chapter, equals(13));
      expect(firstCor2.verse, equals(4));

      final secondKgs = ScriptureReferenceParser.tryParse('2 Kings 2:11');
      expect(secondKgs, isNotNull);
      expect(secondKgs!.bookId, equals(12));
      expect(secondKgs.chapter, equals(2));
      expect(secondKgs.verse, equals(11));

      final firstJn = ScriptureReferenceParser.tryParse('1 John 1:9');
      expect(firstJn, isNotNull);
      expect(firstJn!.bookId, equals(62));
      expect(firstJn.chapter, equals(1));
      expect(firstJn.verse, equals(9));
    });

    test('parses chapter-only queries', () {
      final jn3 = ScriptureReferenceParser.tryParse('John 3');
      expect(jn3, isNotNull);
      expect(jn3!.bookId, equals(43));
      expect(jn3.chapter, equals(3));
      expect(jn3.verse, isNull);
      expect(jn3.isExactVerse, isFalse);

      final ps23 = ScriptureReferenceParser.tryParse('Psalm 23');
      expect(ps23, isNotNull);
      expect(ps23!.bookId, equals(19));
      expect(ps23.chapter, equals(23));
      expect(ps23.verse, isNull);
      expect(ps23.isExactVerse, isFalse);
    });

    test('parses single-chapter books', () {
      final jude5 = ScriptureReferenceParser.tryParse('Jude 5');
      expect(jude5, isNotNull);
      expect(jude5!.bookId, equals(65));
      expect(jude5.chapter, equals(1));
      expect(jude5.verse, equals(5));
      expect(jude5.isExactVerse, isTrue);

      final jude15 = ScriptureReferenceParser.tryParse('Jude 1:5');
      expect(jude15, isNotNull);
      expect(jude15!.bookId, equals(65));
      expect(jude15.chapter, equals(1));
      expect(jude15.verse, equals(5));

      final phm3 = ScriptureReferenceParser.tryParse('Philemon 3');
      expect(phm3, isNotNull);
      expect(phm3!.bookId, equals(57));
      expect(phm3.chapter, equals(1));
      expect(phm3.verse, equals(3));
    });

    test('handles verse ranges', () {
      final range = ScriptureReferenceParser.tryParse('John 3:16-18');
      expect(range, isNotNull);
      expect(range!.bookId, equals(43));
      expect(range.chapter, equals(3));
      expect(range.verse, equals(16));
      expect(range.endVerse, equals(18));
      expect(range.isExactVerse, isTrue);
    });

    test('returns null for non-references and regular search text', () {
      expect(ScriptureReferenceParser.tryParse(''), isNull);
      expect(ScriptureReferenceParser.tryParse('faith'), isNull);
      expect(ScriptureReferenceParser.tryParse('grace and truth'), isNull);
      expect(ScriptureReferenceParser.tryParse('in the beginning'), isNull);
      expect(ScriptureReferenceParser.tryParse('John'), isNull); // Book name only without chapter
      expect(ScriptureReferenceParser.tryParse('John 999'), isNull); // Exceeds chapter count
    });
  });
}
