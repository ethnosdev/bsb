import 'dart:convert';

import 'package:database_builder/database_builder.dart';

enum PlanTrack {
  throughTheBible(
    'through_the_bible',
    'Through the Bible',
    'Read the entire Bible in biblical order from Genesis to Revelation.',
  ),
  chronological(
    'chronological',
    'Chronological Bible',
    'Read the entire Bible in the historical order of events.',
  ),
  newTestament(
    'new_testament',
    'New Testament',
    'Read through the New Testament covering the life of Christ and the early church.',
  );

  final String id;
  final String title;
  final String description;
  const PlanTrack(this.id, this.title, this.description);

  List<PlanPace> get availablePaces {
    switch (this) {
      case PlanTrack.throughTheBible:
        return const [PlanPace.finishInYear, PlanPace.oneChapterADay];
      case PlanTrack.chronological:
        return const [PlanPace.finishInYear, PlanPace.oneChapterADay];
      case PlanTrack.newTestament:
        return const [PlanPace.finishIn90Days, PlanPace.oneChapterADay];
    }
  }

  static PlanTrack fromId(String id) {
    return PlanTrack.values.firstWhere(
      (t) => t.id == id,
      orElse: () => PlanTrack.throughTheBible,
    );
  }
}

enum PlanPace {
  finishInYear(
    'finish_in_year',
    'Finish in a year',
    365,
  ),
  finishIn90Days(
    'finish_in_90_days',
    'Finish in 90 days',
    90,
  ),
  oneChapterADay(
    'one_chapter_a_day',
    'One chapter a day',
    null,
  );

  final String id;
  final String label;
  final int? targetDays;
  const PlanPace(this.id, this.label, this.targetDays);

  String get title => label;

  static PlanPace fromId(String id) {
    return PlanPace.values.firstWhere(
      (p) => p.id == id,
      orElse: () => PlanPace.finishInYear,
    );
  }
}

class ChapterRef {
  final int bookId;
  final int chapter;
  const ChapterRef(this.bookId, this.chapter);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterRef &&
          other.bookId == bookId &&
          other.chapter == chapter;

  @override
  int get hashCode => Object.hash(bookId, chapter);

  @override
  String toString() => '$bookId:$chapter';
}

class PlanReading {
  final int bookId;
  final int startChapter;
  final int endChapter;

  const PlanReading({
    required this.bookId,
    required this.startChapter,
    required this.endChapter,
  });

  String get id => '${bookId}_${startChapter}_$endChapter';

  String get referenceDisplay {
    final bookName = bookIdToFullNameMap[bookId] ??
        (bookIdToBookNameMap[bookId] ?? 'Book $bookId');
    if (startChapter == endChapter) {
      return '$bookName $startChapter';
    }
    return '$bookName $startChapter–$endChapter';
  }

  int get chapterCount => endChapter - startChapter + 1;

  Map<String, dynamic> toMap() => {
        'bookId': bookId,
        'startChapter': startChapter,
        'endChapter': endChapter,
      };

  factory PlanReading.fromMap(Map<String, dynamic> map) => PlanReading(
        bookId: map['bookId'] as int,
        startChapter: map['startChapter'] as int,
        endChapter: map['endChapter'] as int,
      );
}

class PlanDay {
  final int dayNumber;
  final List<PlanReading> readings;

  const PlanDay({
    required this.dayNumber,
    required this.readings,
  });

  int get totalChapters => readings.fold(0, (sum, r) => sum + r.chapterCount);

  String get summaryDisplay =>
      readings.map((r) => r.referenceDisplay).join(', ');

  Map<String, dynamic> toMap() => {
        'dayNumber': dayNumber,
        'readings': readings.map((r) => r.toMap()).toList(),
      };

  factory PlanDay.fromMap(Map<String, dynamic> map) => PlanDay(
        dayNumber: map['dayNumber'] as int,
        readings: (map['readings'] as List<dynamic>)
            .map((r) => PlanReading.fromMap(r as Map<String, dynamic>))
            .toList(),
      );
}

class ReadingPlan {
  final String id;
  final PlanTrack track;
  final PlanPace pace;
  final String title;
  final String description;
  final int totalDays;
  final List<PlanDay> days;

  const ReadingPlan({
    required this.id,
    required this.track,
    required this.pace,
    required this.title,
    required this.description,
    required this.totalDays,
    required this.days,
  });

  static String makePlanId(PlanTrack track, PlanPace pace) =>
      '${track.id}_${pace.id}';
}

class UserPlanProgress {
  final String planId;
  final String trackId;
  final String paceId;
  final int totalDays;
  final DateTime startedAt;
  final DateTime? lastReadAt;
  final Set<int> completedDays;
  final Set<String> completedReadingIds; // "${dayNumber}_${reading.id}"
  final bool isActive;

  const UserPlanProgress({
    required this.planId,
    required this.trackId,
    required this.paceId,
    required this.totalDays,
    required this.startedAt,
    this.lastReadAt,
    this.completedDays = const {},
    this.completedReadingIds = const {},
    this.isActive = true,
  });

  PlanTrack get track => PlanTrack.fromId(trackId);
  PlanPace get pace => PlanPace.fromId(paceId);

  bool isReadingCompleted(int dayNumber, PlanReading reading) {
    return completedReadingIds.contains('${dayNumber}_${reading.id}');
  }

  bool isDayCompleted(PlanDay day) {
    if (completedDays.contains(day.dayNumber)) return true;
    if (day.readings.isEmpty) return false;
    return day.readings.every((r) => isReadingCompleted(day.dayNumber, r));
  }

  double get progressPercentage {
    if (totalDays <= 0) return 0.0;
    return (completedDays.length / totalDays).clamp(0.0, 1.0);
  }

  int get nextUncompletedDayNumber {
    for (int day = 1; day <= totalDays; day++) {
      if (!completedDays.contains(day)) {
        return day;
      }
    }
    return totalDays;
  }

  bool get isPlanFinished => totalDays > 0 && completedDays.length >= totalDays;

  UserPlanProgress copyWith({
    String? planId,
    String? trackId,
    String? paceId,
    int? totalDays,
    DateTime? startedAt,
    DateTime? lastReadAt,
    Set<int>? completedDays,
    Set<String>? completedReadingIds,
    bool? isActive,
  }) {
    return UserPlanProgress(
      planId: planId ?? this.planId,
      trackId: trackId ?? this.trackId,
      paceId: paceId ?? this.paceId,
      totalDays: totalDays ?? this.totalDays,
      startedAt: startedAt ?? this.startedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      completedDays: completedDays ?? this.completedDays,
      completedReadingIds: completedReadingIds ?? this.completedReadingIds,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() => {
        'plan_id': planId,
        'track_id': trackId,
        'pace_id': paceId,
        'total_days': totalDays,
        'started_at': startedAt.millisecondsSinceEpoch,
        'last_read_at': lastReadAt?.millisecondsSinceEpoch,
        'completed_days': jsonEncode(completedDays.toList()..sort()),
        'completed_readings': jsonEncode(completedReadingIds.toList()..sort()),
        'is_active': isActive ? 1 : 0,
      };

  factory UserPlanProgress.fromMap(Map<String, dynamic> map) {
    final completedDaysList = (map['completed_days'] is String)
        ? (jsonDecode(map['completed_days'] as String) as List<dynamic>)
            .map((e) => (e as num).toInt())
            .toSet()
        : <int>{};

    final completedReadingsList = (map['completed_readings'] is String)
        ? (jsonDecode(map['completed_readings'] as String) as List<dynamic>)
            .map((e) => e.toString())
            .toSet()
        : <String>{};

    return UserPlanProgress(
      planId: map['plan_id'] as String,
      trackId: map['track_id'] as String? ?? '',
      paceId: map['pace_id'] as String? ?? '',
      totalDays: (map['total_days'] as num?)?.toInt() ?? 0,
      startedAt: DateTime.fromMillisecondsSinceEpoch(
          (map['started_at'] as num).toInt()),
      lastReadAt: map['last_read_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['last_read_at'] as num).toInt())
          : null,
      completedDays: completedDaysList,
      completedReadingIds: completedReadingsList,
      isActive: (map['is_active'] as num?)?.toInt() == 1,
    );
  }
}
