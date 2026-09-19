import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/search/scripture_reference_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Reference Cross-Chapter Ranges', () {
    test('constructs and stringifies cross-chapter range', () {
      final ref = Reference(
        bookId: 42, // Luke
        chapter: 23,
        verse: 50,
        endChapter: 24,
        endVerse: 12,
      );

      expect(ref.toString(), 'Luke 23:50–24:12');
      expect(ref.packedVerse, 42023050);
      expect(ref.packedEndVerse, 42024012);
    });

    test('parses cross-chapter range with tryParse', () {
      final ref = Reference.tryParse('Luke 23:50–24:12');
      expect(ref, isNotNull);
      expect(ref!.bookId, 42);
      expect(ref.chapter, 23);
      expect(ref.verse, 50);
      expect(ref.endChapter, 24);
      expect(ref.endVerse, 12);

      final refHyphen = Reference.tryParse('Luke 23:50-24:12');
      expect(refHyphen, equals(ref));
    });

    test('Reference.fromVerseId round-trip with cross-chapter', () {
      final ref = Reference(
        bookId: 42,
        chapter: 23,
        verse: 50,
        endChapter: 24,
        endVerse: 12,
      );
      final fromPacked = Reference.fromVerseId(
        packedInt: ref.packedVerse,
        packedIntEnd: ref.packedEndVerse,
      );
      expect(fromPacked, equals(ref));
    });

    test('ScriptureReferenceParser parses cross-chapter range with abbreviations', () {
      final parsed = ScriptureReferenceParser.tryParse('Lk 23:50-24:12');
      expect(parsed, isNotNull);
      expect(parsed!.bookId, 42);
      expect(parsed.chapter, 23);
      expect(parsed.verse, 50);
      expect(parsed.endChapter, 24);
      expect(parsed.endVerse, 12);

      final asRef = parsed.toReference();
      expect(asRef.toString(), 'Luke 23:50–24:12');
    });

    test('ScriptureReferenceParser parses cross-chapter with full name', () {
      final parsed = ScriptureReferenceParser.tryParse('Luke 23:50–24:12');
      expect(parsed, isNotNull);
      expect(parsed!.bookId, 42);
      expect(parsed.chapter, 23);
      expect(parsed.verse, 50);
      expect(parsed.endChapter, 24);
      expect(parsed.endVerse, 12);
    });
  });
}
