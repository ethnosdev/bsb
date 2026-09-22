import 'package:bsb/infrastructure/reading_plan_models.dart';
import 'package:bsb/infrastructure/reading_plan_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'annotation_service_test.dart';

void main() {
  group('ReadingPlanService', () {
    late FakeAnnotationDbHelper fakeDb;
    late ReadingPlanService service;

    setUp(() {
      fakeDb = FakeAnnotationDbHelper();
      service = ReadingPlanService(dbHelper: fakeDb);
    });

    test('init sets activeProgressNotifier to null when no active plan', () async {
      await service.init();
      expect(service.activeProgressNotifier.value, isNull);
      expect(service.getActivePlan(), isNull);
    });

    test('startOrResumePlan creates new progress and activates it', () async {
      await service.startOrResumePlan(PlanTrack.throughTheBible, PlanPace.finishInYear);

      final active = service.activeProgressNotifier.value;
      expect(active, isNotNull);
      expect(active!.planId, 'through_the_bible_finish_in_year');
      expect(active.totalDays, 365);
      expect(active.isActive, isTrue);
      expect(active.completedDays, isEmpty);
      expect(active.completedReadingIds, isEmpty);

      final plan = service.getActivePlan();
      expect(plan, isNotNull);
      expect(plan!.days.length, 365);

      // Verify in DB
      final dbProgress = await fakeDb.getActivePlanProgress();
      expect(dbProgress, isNotNull);
      expect(dbProgress!.planId, active.planId);
    });

    test('switchActivePlan switches active plan between existing progress records', () async {
      // Start Plan A (Through the Bible)
      await service.startOrResumePlan(PlanTrack.throughTheBible, PlanPace.finishInYear);
      // Toggle day 1 in Plan A
      await service.toggleDayComplete(1);

      // Start Plan B (New Testament)
      await service.startOrResumePlan(PlanTrack.newTestament, PlanPace.finishIn90Days);
      expect(service.activeProgressNotifier.value!.planId, 'new_testament_finish_in_90_days');
      expect(service.activeProgressNotifier.value!.completedDays, isEmpty);

      // Switch back to Plan A
      await service.switchActivePlan('through_the_bible_finish_in_year');
      expect(service.activeProgressNotifier.value!.planId, 'through_the_bible_finish_in_year');
      expect(service.activeProgressNotifier.value!.completedDays, contains(1));

      // Check DB persistence
      final all = await fakeDb.getAllPlanProgress();
      expect(all.length, 2);
    });

    test('toggleReadingComplete and toggleDayComplete correctly track sub-day and full-day', () async {
      // Start Through the Bible Finish in a Year (interleaves OT + NT)
      await service.startOrResumePlan(PlanTrack.throughTheBible, PlanPace.finishInYear);
      final plan = service.getActivePlan()!;
      final day1 = plan.days[0];
      expect(day1.readings.length, greaterThanOrEqualTo(2));

      final firstReading = day1.readings[0];
      final secondReading = day1.readings[1];

      // Mark first reading complete
      await service.toggleReadingComplete(1, firstReading);
      var progress = service.activeProgressNotifier.value!;
      expect(progress.isReadingCompleted(1, firstReading), isTrue);
      expect(progress.isReadingCompleted(1, secondReading), isFalse);
      expect(progress.completedDays.contains(1), isFalse);

      // Mark all remaining readings in day 1 complete
      for (int i = 1; i < day1.readings.length; i++) {
        await service.toggleReadingComplete(1, day1.readings[i]);
      }
      progress = service.activeProgressNotifier.value!;
      for (final r in day1.readings) {
        expect(progress.isReadingCompleted(1, r), isTrue);
      }
      expect(progress.completedDays.contains(1), isTrue);

      // Unmark first reading
      await service.toggleReadingComplete(1, firstReading);
      progress = service.activeProgressNotifier.value!;
      expect(progress.isReadingCompleted(1, firstReading), isFalse);
      expect(progress.completedDays.contains(1), isFalse);

      // Toggle entire day on
      await service.toggleDayComplete(1);
      progress = service.activeProgressNotifier.value!;
      expect(progress.completedDays.contains(1), isTrue);
      expect(progress.isReadingCompleted(1, firstReading), isTrue);
      expect(progress.isReadingCompleted(1, secondReading), isTrue);

      // Toggle entire day off
      await service.toggleDayComplete(1);
      progress = service.activeProgressNotifier.value!;
      expect(progress.completedDays.contains(1), isFalse);
      expect(progress.isReadingCompleted(1, firstReading), isFalse);
      expect(progress.isReadingCompleted(1, secondReading), isFalse);
    });

    test('resetPlan deletes progress and clears or updates active plan', () async {
      await service.startOrResumePlan(PlanTrack.newTestament, PlanPace.oneChapterADay);
      expect(service.activeProgressNotifier.value, isNotNull);

      await service.resetPlan('new_testament_one_chapter_a_day');
      expect(service.activeProgressNotifier.value, isNull);

      final dbRecord = await fakeDb.getPlanProgress('new_testament_one_chapter_a_day');
      expect(dbRecord, isNull);
    });
  });
}
