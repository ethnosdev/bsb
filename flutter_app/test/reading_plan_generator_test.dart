import 'package:bsb/infrastructure/reading_plan_generator.dart';
import 'package:bsb/infrastructure/reading_plan_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadingPlanGenerator Tests', () {
    test('canonicalChapters returns 1,189 unique chapters', () {
      final chapters = ReadingPlanGenerator.canonicalChapters();
      expect(chapters.length, equals(1189));
      expect(chapters.toSet().length, equals(1189));
      expect(chapters.first, equals(const ChapterRef(1, 1)));
      expect(chapters.last, equals(const ChapterRef(66, 22)));
    });

    test('oldTestamentChapters returns 929 unique chapters', () {
      final chapters = ReadingPlanGenerator.oldTestamentChapters();
      expect(chapters.length, equals(929));
      expect(chapters.toSet().length, equals(929));
      expect(chapters.first, equals(const ChapterRef(1, 1)));
      expect(chapters.last, equals(const ChapterRef(39, 4)));
    });

    test('newTestamentChapters returns 260 unique chapters', () {
      final chapters = ReadingPlanGenerator.newTestamentChapters();
      expect(chapters.length, equals(260));
      expect(chapters.toSet().length, equals(260));
      expect(chapters.first, equals(const ChapterRef(40, 1)));
      expect(chapters.last, equals(const ChapterRef(66, 22)));
    });

    test('chronologicalChapters returns 1,189 unique chapters covering entire Bible', () {
      final chapters = ReadingPlanGenerator.chronologicalChapters();
      expect(chapters.length, equals(1189));
      expect(chapters.toSet().length, equals(1189));

      final canonical = ReadingPlanGenerator.canonicalChapters().toSet();
      expect(chapters.toSet(), equals(canonical));
    });

    test('Through the Bible - Finish in a Year (OT & NT Daily) covers all 1,189 chapters with individual readings', () {
      final plan = ReadingPlanGenerator.generatePlan(
        PlanTrack.throughTheBible,
        PlanPace.finishInYear,
      );
      expect(plan.days.length, equals(365));

      int totalChapters = 0;
      final seenChapters = <ChapterRef>{};
      for (final day in plan.days) {
        for (final reading in day.readings) {
          expect(reading.chapterCount, equals(1)); // Individual chapter per reading
          expect(reading.startChapter, equals(reading.endChapter));
          totalChapters += reading.chapterCount;
          final added = seenChapters.add(ChapterRef(reading.bookId, reading.startChapter));
          expect(added, isTrue, reason: 'Duplicate chapter in plan: ${reading.bookId}:${reading.startChapter}');
        }
      }
      expect(totalChapters, equals(1189));
      expect(seenChapters.length, equals(1189));
    });

    test('Through the Bible - One Chapter a Day covers 1,189 days', () {
      final plan = ReadingPlanGenerator.generatePlan(
        PlanTrack.throughTheBible,
        PlanPace.oneChapterADay,
      );
      expect(plan.days.length, equals(1189));
      expect(plan.days.first.readings.first.referenceDisplay, equals('Genesis 1'));
      expect(plan.days.last.readings.first.referenceDisplay, equals('Revelation 22'));
    });

    test('Chronological Bible - Finish in a Year covers all 1,189 chapters with individual readings', () {
      final plan = ReadingPlanGenerator.generatePlan(
        PlanTrack.chronological,
        PlanPace.finishInYear,
      );
      expect(plan.days.length, equals(365));

      int totalChapters = 0;
      final seenChapters = <ChapterRef>{};
      for (final day in plan.days) {
        for (final reading in day.readings) {
          expect(reading.chapterCount, equals(1));
          expect(reading.startChapter, equals(reading.endChapter));
          totalChapters += reading.chapterCount;
          final added = seenChapters.add(ChapterRef(reading.bookId, reading.startChapter));
          expect(added, isTrue, reason: 'Duplicate chapter in chronological plan: ${reading.bookId}:${reading.startChapter}');
        }
      }
      expect(totalChapters, equals(1189));
      expect(seenChapters.length, equals(1189));
    });

    test('New Testament - 90 Days covers all 260 chapters with individual readings', () {
      final plan = ReadingPlanGenerator.generatePlan(
        PlanTrack.newTestament,
        PlanPace.finishIn90Days,
      );
      expect(plan.days.length, equals(90));

      int totalChapters = 0;
      final seenChapters = <ChapterRef>{};
      for (final day in plan.days) {
        for (final reading in day.readings) {
          expect(reading.chapterCount, equals(1));
          expect(reading.startChapter, equals(reading.endChapter));
          totalChapters += reading.chapterCount;
          final added = seenChapters.add(ChapterRef(reading.bookId, reading.startChapter));
          expect(added, isTrue, reason: 'Duplicate NT chapter: ${reading.bookId}:${reading.startChapter}');
        }
      }
      expect(totalChapters, equals(260));
      expect(seenChapters.length, equals(260));
    });

    test('New Testament - One Chapter a Day covers 260 days', () {
      final plan = ReadingPlanGenerator.generatePlan(
        PlanTrack.newTestament,
        PlanPace.oneChapterADay,
      );
      expect(plan.days.length, equals(260));
      expect(plan.days.first.readings.first.referenceDisplay, equals('Matthew 1'));
      expect(plan.days.last.readings.first.referenceDisplay, equals('Revelation 22'));
    });

    test('allPlans returns 6 distinct plans', () {
      final plans = ReadingPlanGenerator.allPlans();
      expect(plans.length, equals(6));
      final ids = plans.map((p) => p.id).toSet();
      expect(ids.length, equals(6));
    });
  });
}
