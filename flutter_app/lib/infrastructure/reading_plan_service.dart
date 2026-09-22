import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/reading_plan_generator.dart';
import 'package:bsb/infrastructure/reading_plan_models.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:flutter/foundation.dart';

class ReadingPlanService {
  final AnnotationDatabaseHelper _dbHelper;
  final ValueNotifier<UserPlanProgress?> activeProgressNotifier =
      ValueNotifier<UserPlanProgress?>(null);

  final Map<String, ReadingPlan> _cachedPlans = {};

  ReadingPlanService({AnnotationDatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? getIt<AnnotationDatabaseHelper>();

  Future<void> init() async {
    final active = await _dbHelper.getActivePlanProgress();
    activeProgressNotifier.value = active;
  }

  ReadingPlan getPlan(PlanTrack track, PlanPace pace) {
    final planId = ReadingPlan.makePlanId(track, pace);
    if (_cachedPlans.containsKey(planId)) {
      return _cachedPlans[planId]!;
    }
    final plan = ReadingPlanGenerator.generatePlan(track, pace);
    _cachedPlans[planId] = plan;
    return plan;
  }

  ReadingPlan? getPlanById(String planId) {
    if (_cachedPlans.containsKey(planId)) {
      return _cachedPlans[planId];
    }
    if (planId == 'through_the_bible_finish_in_year_seq' ||
        planId == 'through_the_bible_finish_in_year_ot_nt') {
      return getPlan(PlanTrack.throughTheBible, PlanPace.finishInYear);
    }
    if (planId == 'chronological_finish_in_year_seq') {
      return getPlan(PlanTrack.chronological, PlanPace.finishInYear);
    }
    for (final plan in ReadingPlanGenerator.allPlans()) {
      _cachedPlans[plan.id] = plan;
      if (plan.id == planId) {
        return plan;
      }
    }
    return null;
  }

  ReadingPlan? getActivePlan() {
    final progress = activeProgressNotifier.value;
    if (progress == null) return null;
    return getPlanById(progress.planId);
  }

  Future<List<UserPlanProgress>> getAllProgress() async {
    return await _dbHelper.getAllPlanProgress();
  }

  Future<UserPlanProgress?> getProgress(String planId) async {
    return await _dbHelper.getPlanProgress(planId);
  }

  Future<void> startOrResumePlan(PlanTrack track, PlanPace pace) async {
    final plan = getPlan(track, pace);
    final existing = await _dbHelper.getPlanProgress(plan.id);

    UserPlanProgress progress;
    if (existing != null) {
      progress = existing.copyWith(isActive: true);
    } else {
      progress = UserPlanProgress(
        planId: plan.id,
        trackId: track.id,
        paceId: pace.id,
        totalDays: plan.totalDays,
        startedAt: DateTime.now(),
        isActive: true,
      );
    }

    await _dbHelper.savePlanProgress(progress);
    await _dbHelper.setActivePlan(plan.id);
    activeProgressNotifier.value = progress;
  }

  Future<void> switchActivePlan(String planId) async {
    final target = await _dbHelper.getPlanProgress(planId);
    if (target != null) {
      await _dbHelper.setActivePlan(planId);
      activeProgressNotifier.value = target.copyWith(isActive: true);
    }
  }

  Future<void> toggleReadingComplete(int dayNumber, PlanReading reading) async {
    final current = activeProgressNotifier.value;
    if (current == null) return;

    final readingKey = '${dayNumber}_${reading.id}';
    final updatedReadings = Set<String>.from(current.completedReadingIds);
    final updatedDays = Set<int>.from(current.completedDays);

    if (updatedReadings.contains(readingKey)) {
      updatedReadings.remove(readingKey);
      updatedDays.remove(dayNumber);
    } else {
      updatedReadings.add(readingKey);
      final activePlan = getActivePlan();
      if (activePlan != null && dayNumber <= activePlan.days.length) {
        final planDay = activePlan.days[dayNumber - 1];
        final allDone = planDay.readings
            .every((r) => updatedReadings.contains('${dayNumber}_${r.id}'));
        if (allDone) {
          updatedDays.add(dayNumber);
        }
      }
    }

    final updated = current.copyWith(
      completedDays: updatedDays,
      completedReadingIds: updatedReadings,
      lastReadAt: DateTime.now(),
    );

    await _dbHelper.savePlanProgress(updated);
    activeProgressNotifier.value = updated;
  }

  Future<void> toggleDayComplete(int dayNumber) async {
    final current = activeProgressNotifier.value;
    if (current == null) return;

    final activePlan = getActivePlan();
    if (activePlan == null || dayNumber > activePlan.days.length) return;

    final planDay = activePlan.days[dayNumber - 1];
    final updatedReadings = Set<String>.from(current.completedReadingIds);
    final updatedDays = Set<int>.from(current.completedDays);

    final isCurrentlyDone = updatedDays.contains(dayNumber);

    if (isCurrentlyDone) {
      updatedDays.remove(dayNumber);
      for (final r in planDay.readings) {
        updatedReadings.remove('${dayNumber}_${r.id}');
      }
    } else {
      updatedDays.add(dayNumber);
      for (final r in planDay.readings) {
        updatedReadings.add('${dayNumber}_${r.id}');
      }
    }

    final updated = current.copyWith(
      completedDays: updatedDays,
      completedReadingIds: updatedReadings,
      lastReadAt: DateTime.now(),
    );

    await _dbHelper.savePlanProgress(updated);
    activeProgressNotifier.value = updated;
  }

  Future<void> resetPlan(String planId) async {
    await _dbHelper.deletePlanProgress(planId);
    if (activeProgressNotifier.value?.planId == planId) {
      final all = await _dbHelper.getAllPlanProgress();
      if (all.isNotEmpty) {
        final next = all.first;
        await _dbHelper.setActivePlan(next.planId);
        activeProgressNotifier.value = next.copyWith(isActive: true);
      } else {
        activeProgressNotifier.value = null;
      }
    }
  }
}
