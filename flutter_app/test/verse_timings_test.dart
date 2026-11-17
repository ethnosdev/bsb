import 'package:bsb/infrastructure/audio/verse_timings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleTimings = ChapterTimings(
    bookId: 43,
    chapter: 10,
    verses: [
      VerseTiming(
        verse: 1,
        start: Duration(milliseconds: 4700),
        end: Duration(milliseconds: 12950),
      ),
      VerseTiming(
        verse: 2,
        start: Duration(milliseconds: 12950),
        end: Duration(milliseconds: 16690),
      ),
      VerseTiming(
        verse: 3,
        start: Duration(milliseconds: 16690),
        end: Duration(milliseconds: 24830),
      ),
    ],
  );

  group('ChapterTimings.verseAt', () {
    test('returns null before the first verse start (chapter announcement)', () {
      expect(sampleTimings.verseAt(Duration.zero), isNull);
      expect(
        sampleTimings.verseAt(const Duration(milliseconds: 4699)),
        isNull,
      );
    });

    test('returns the later verse when position is exactly on a boundary', () {
      expect(
        sampleTimings.verseAt(const Duration(milliseconds: 4700)),
        equals(1),
      );
      expect(
        sampleTimings.verseAt(const Duration(milliseconds: 12950)),
        equals(2),
      );
      expect(
        sampleTimings.verseAt(const Duration(milliseconds: 16690)),
        equals(3),
      );
    });

    test('returns the enclosing verse mid-verse', () {
      expect(
        sampleTimings.verseAt(const Duration(milliseconds: 14000)),
        equals(2),
      );
    });

    test('returns the last verse at or past the last verse end', () {
      expect(
        sampleTimings.verseAt(const Duration(milliseconds: 24830)),
        equals(3),
      );
      expect(
        sampleTimings.verseAt(const Duration(seconds: 60)),
        equals(3),
      );
    });

    test('returns null for empty timings', () {
      const empty = ChapterTimings.empty(43, 10);
      expect(empty.isEmpty, isTrue);
      expect(empty.verseAt(const Duration(seconds: 5)), isNull);
    });
  });

  group('ChapterTimings.timingFor', () {
    test('finds existing verses and returns null for missing ones', () {
      expect(sampleTimings.timingFor(2)?.start, const Duration(milliseconds: 12950));
      expect(sampleTimings.timingFor(99), isNull);
    });
  });

  group('ChapterTimings verse navigation targets', () {
    test('nextSeekTarget handles announcement, mid-chapter, and last verse', () {
      expect(
        sampleTimings.nextSeekTarget(const Duration(seconds: 2)),
        const Duration(milliseconds: 4700),
      );
      expect(
        sampleTimings.nextSeekTarget(const Duration(milliseconds: 14000)),
        const Duration(milliseconds: 16690),
      );
      expect(
        sampleTimings.nextSeekTarget(const Duration(milliseconds: 20000)),
        isNull,
      );
    });

    test('previousSeekTarget applies the 2-second rule, verse 1, and announcement', () {
      // Announcement -> 0:00
      expect(
        sampleTimings.previousSeekTarget(const Duration(seconds: 2)),
        Duration.zero,
      );
      // Verse 1 within 2s -> 0:00
      expect(
        sampleTimings.previousSeekTarget(const Duration(milliseconds: 5700)),
        Duration.zero,
      );
      // Verse 1 more than 2s in -> restart verse 1
      expect(
        sampleTimings.previousSeekTarget(const Duration(milliseconds: 8000)),
        const Duration(milliseconds: 4700),
      );
      // Verse 2 within 2s -> go to verse 1
      expect(
        sampleTimings.previousSeekTarget(const Duration(milliseconds: 14000)),
        const Duration(milliseconds: 4700),
      );
      // Verse 2 more than 2s in -> restart verse 2
      expect(
        sampleTimings.previousSeekTarget(const Duration(milliseconds: 15500)),
        const Duration(milliseconds: 12950),
      );
    });
  });
}
