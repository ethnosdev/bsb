import 'package:bsb/infrastructure/reading_plan_models.dart';
import 'package:database_builder/database_builder.dart';

abstract final class ReadingPlanGenerator {
  /// Returns all 1,189 chapters in canonical order (Genesis to Revelation).
  static List<ChapterRef> canonicalChapters() {
    final list = <ChapterRef>[];
    for (int bookId = 1; bookId <= 66; bookId++) {
      final count = bookIdToChapterCountMap[bookId] ?? 1;
      for (int ch = 1; ch <= count; ch++) {
        list.add(ChapterRef(bookId, ch));
      }
    }
    return list;
  }

  /// Returns 929 Old Testament chapters (Genesis to Malachi).
  static List<ChapterRef> oldTestamentChapters() {
    final list = <ChapterRef>[];
    for (int bookId = 1; bookId <= 39; bookId++) {
      final count = bookIdToChapterCountMap[bookId] ?? 1;
      for (int ch = 1; ch <= count; ch++) {
        list.add(ChapterRef(bookId, ch));
      }
    }
    return list;
  }

  /// Returns 260 New Testament chapters (Matthew to Revelation).
  static List<ChapterRef> newTestamentChapters() {
    final list = <ChapterRef>[];
    for (int bookId = 40; bookId <= 66; bookId++) {
      final count = bookIdToChapterCountMap[bookId] ?? 1;
      for (int ch = 1; ch <= count; ch++) {
        list.add(ChapterRef(bookId, ch));
      }
    }
    return list;
  }

  /// Hardcoded exact chronological reading schedule for 365 days.
  /// Format: "bookId:startChapter-endChapter,..."
  static const List<String> _chronoSchedule = [
    // Era I: Primeval and Patriarchal Eras
    "1:1-3",
    "1:4-7",
    "1:8-11",
    "18:1-5",
    "18:6-9",
    "18:10-13",
    "18:14-16",
    "18:17-20",
    "18:21-23",
    "18:24-28",
    "18:29-31",
    "18:32-34",
    "18:35-37",
    "18:38-39",
    "18:40-42",
    "1:12-15",
    "1:16-18",
    "1:19-21",
    "1:22-24",
    "1:25-26",
    "1:27-29",
    "1:30-31",
    "1:32-34",
    "1:35-37",
    "1:38-40",
    "1:41-42",
    "1:43-45",
    "1:46-47",
    "1:48-50",

    // Era II: Exodus, Wilderness Wanderings, and Settlement
    "2:1-3",
    "2:4-6",
    "2:7-9",
    "2:10-12",
    "2:13-15",
    "2:16-18",
    "2:19-21",
    "2:22-24",
    "2:25-27",
    "2:28-29",
    "2:30-32",
    "2:33-35",
    "2:36-38",
    "2:39-40",
    "3:1-4",
    "3:5-7",
    "3:8-10",
    "3:11-13",
    "3:14-15",
    "3:16-18",
    "3:19-21",
    "3:22-23",
    "3:24-25",
    "3:26-27",
    "4:1-2",
    "4:3-4",
    "4:5-6",
    "4:7-7",
    "4:8-10",
    "4:11-13",
    "4:14-15,19:90-90",
    "4:16-17",
    "4:18-20",
    "4:21-22",
    "4:23-25",
    "4:26-27",
    "4:28-30",
    "4:31-32",
    "4:33-34",
    "4:35-36",
    "5:1-2",
    "5:3-4",
    "5:5-7",
    "5:8-10",
    "5:11-13",
    "5:14-16",
    "5:17-20",
    "5:21-23",
    "5:24-27",
    "5:28-29",
    "5:30-31",
    "5:32-34,19:91-91",
    "6:1-4",
    "6:5-8",
    "6:9-11",
    "6:12-15",
    "6:16-18",
    "6:19-21",
    "6:22-24",

    // Era III: The Judges, United Monarchy, and Wisdom Literature
    "7:1-2",
    "7:3-5",
    "7:6-7",
    "7:8-9",
    "7:10-12",
    "7:13-15",
    "7:16-18",
    "7:19-21",
    "8:1-4",
    "9:1-3",
    "9:4-8",
    "9:9-12",
    "9:13-14",
    "9:15-17",
    "9:18-20,19:11-11,19:59-59",
    "9:21-24",
    "19:7-7,19:27-27,19:31-31,19:34-34,19:52-52",
    "19:56-56,19:120-120,19:140-142",
    "9:25-27",
    "19:17-17,19:35-35,19:54-54,19:63-63",
    "9:28-31,19:18-18",
    "19:121-121,19:123-125,19:128-130",
    "10:1-4",
    "19:6-6,19:8-10,19:14-14,19:16-16,19:19-19,19:21-21",
    "13:1-2",
    "19:43-45,19:49-49,19:84-85,19:87-87",
    "13:3-5",
    "19:73-73,19:77-78",
    "13:6-6",
    "19:81-81,19:88-88,19:92-93",
    "13:7-10",
    "19:102-104",
    "10:5-5,13:11-12",
    "19:133-133",
    "19:106-107",
    "13:13-16",
    "19:1-2,19:15-15,19:22-24,19:47-47,19:68-68",
    "19:89-89,19:96-96,19:100-101,19:105-105,19:132-132",
    "10:6-7,13:17-17",
    "19:25-25,19:29-29,19:33-33,19:36-36,19:39-39",
    "10:8-9,13:18-18",
    "19:50-50,19:53-53,19:60-60,19:75-75",
    "10:10-10,13:19-19,19:20-20",
    "19:65-67,19:69-70",
    "10:11-12,13:20-20",
    "19:32-32,19:51-51,19:86-86,19:122-122",
    "10:13-15",
    "19:3-4,19:12-13,19:28-28,19:55-55",
    "10:16-18",
    "19:26-26,19:40-40,19:58-58,19:61-62,19:64-64",
    "10:19-21",
    "19:5-5,19:38-38,19:41-42",
    "10:22-23,19:57-57",
    "19:95-95,19:97-99",
    "10:24-24,13:21-22,19:30-30",
    "19:108-110",
    "13:23-25",
    "19:131-131,19:138-139,19:143-145",
    "13:26-29,19:127-127",
    "19:111-118",
    "11:1-2,19:37-37,19:71-71,19:94-94",
    "19:119-119",
    "11:3-4",
    "14:1-1,19:72-72",
    "22:1-8",
    "20:1-3",
    "20:4-6",
    "20:7-9",
    "20:10-12",
    "20:13-15",
    "20:16-18",
    "20:19-21",
    "20:22-24",
    "11:5-6,14:2-3",
    "11:7-7,14:4-4",
    "11:8-8,14:5-5",
    "14:6-7,19:136-136",
    "19:134-134,19:146-150",
    "11:9-9,14:8-8",
    "20:25-26",
    "20:27-29", "21:1-6", "21:7-12", "11:10-11,14:9-9", "20:30-31",

    // Era IV: The Divided Monarchy and the Pre-Exilic Prophets
    "11:12-14",
    "14:10-12",
    "11:15-15,14:13-16",
    "11:16-16,14:17-17",
    "11:17-19",
    "11:20-21",
    "11:22-22,14:18-18",
    "14:19-23",
    "31:1-1,29:1-3,19:82-83",
    "12:1-4",
    "12:5-8",
    "12:9-11",
    "12:12-13,14:24-24",
    "12:14-14,14:25-25",
    "32:1-4",
    "12:15-15,14:26-26",
    "23:1-4",
    "23:5-8",
    "30:1-5",
    "30:6-9",
    "14:27-27,23:9-12",
    "33:1-7",
    "14:28-28,12:16-17",
    "23:13-17",
    "23:18-22",
    "23:23-27",
    "12:18-18,14:29-31,19:48-48",
    "28:1-7",
    "28:8-14",
    "23:28-30",
    "23:31-34",
    "23:35-36",
    "23:37-39,19:76-76",
    "23:40-43",
    "23:44-48",
    "12:19-19,19:46-46,19:80-80,19:135-135",
    "23:49-53",
    "23:54-58",
    "23:59-63",
    "23:64-66",
    "12:20-21",
    "14:32-33",
    "34:1-3",
    "12:22-23,14:34-35",
    "36:1-3",
    "24:1-3",
    "24:4-6",
    "24:7-9",
    "24:10-13",
    "24:14-17",
    "24:18-22",
    "24:23-25",
    "24:26-29",
    "24:30-31",
    "24:32-34",
    "24:35-37",
    "24:38-40,19:74-74,19:79-79",
    "12:24-25,14:36-36",
    "35:1-3",
    "24:41-44",
    "24:45-48", "24:49-50", "24:51-52", "25:1-3", "25:4-5",

    // Era V: The Babylonian Exile
    "26:1-4",
    "26:5-8",
    "26:9-12",
    "26:13-15",
    "26:16-17",
    "26:18-20",
    "26:21-23",
    "26:24-27",
    "26:28-30",
    "26:31-33",
    "26:34-36",
    "26:37-39",
    "26:40-42",
    "26:43-45",
    "26:46-48",
    "27:1-3",
    "27:4-6",
    "27:7-9",
    "27:10-12",

    // Era VI: Post-Exilic Restoration and Persian Era
    "15:1-3,19:126-126,19:137-137",
    "15:4-6,37:1-2",
    "38:1-7",
    "38:8-14",
    "17:1-5",
    "17:6-10",
    "15:7-10",
    "16:1-5",
    "16:6-8",
    "16:9-10",
    "16:11-13", "39:1-4",

    // Era VII: The Incarnation and Earthly Ministry of the Messiah
    "42:1-1,43:1-1",
    "40:1-1,42:2-2",
    "40:2-2",
    "40:3-3,41:1-1,42:3-3",
    "40:4-4,42:4-5",
    "43:2-4",
    "40:8-8,41:2-2",
    "40:12-12,41:3-3,42:6-6",
    "40:5-7",
    "40:9-9,42:7-7",
    "40:11-11,42:11-11",
    "40:13-13,42:8-8",
    "41:4-5",
    "40:10-10",
    "40:14-14,41:6-6,42:9-9",
    "43:5-6",
    "40:15-15,41:7-7",
    "40:16-16,41:8-8",
    "40:17-17,41:9-9",
    "40:18-18",
    "43:7-8",
    "43:9-10",
    "42:10-10,42:12-12",
    "42:13-13",
    "42:14-15",
    "42:16-17",
    "43:11-11",
    "42:18-18,40:19-19",
    "41:10-10,40:20-20",
    "42:19-19,40:21-21",
    "41:11-12,43:12-12",
    "40:22-22,42:20-20",
    "40:23-23,42:21-21",
    "41:13-13,40:24-24",
    "40:25-25",
    "40:26-26,41:14-14",
    "42:22-22,43:13-13",
    "43:14-17",
    "40:27-27,41:15-15",
    "42:23-23,43:18-19",
    "40:28-28,41:16-16", "42:24-24,43:20-21",

    // Era VIII: The Apostolic Church, Missionary Journeys, and Epistles
    "44:1-3",
    "44:4-6",
    "44:7-8",
    "44:9-10",
    "44:11-12",
    "59:1-3",
    "59:4-5",
    "44:13-14",
    "48:1-3",
    "48:4-6",
    "44:15-16",
    "52:1-5",
    "53:1-3",
    "44:17-18",
    "46:1-4",
    "46:5-8",
    "46:9-11",
    "46:12-14",
    "46:15-16",
    "47:1-4",
    "47:5-9",
    "47:10-13",
    "44:19-20",
    "45:1-3",
    "45:4-7",
    "45:8-10",
    "45:11-13",
    "45:14-16",
    "44:21-23",
    "44:24-26",
    "44:27-28",
    "51:1-4,57:1-1",
    "49:1-6",
    "50:1-4",
    "54:1-6",
    "56:1-3",
    "60:1-5",
    "58:1-4",
    "58:5-8",
    "58:9-10",
    "58:11-13", "55:1-4", "61:1-3,65:1-1",

    // Era IX: The Late Johannine Writings and the Apocalypse
    "62:1-5",
    "63:1-1,64:1-1",
    "66:1-3",
    "66:4-6",
    "66:7-9",
    "66:10-12",
    "66:13-15",
    "66:16-18",
    "66:19-20",
    "66:21-21",
    "66:22-22",
  ];

  /// Parses the hardcoded 365-day schedule into daily PlanDay records,
  /// breaking ranges down so every chapter is an individual PlanReading.
  static List<PlanDay> _parseChronologicalDays() {
    final days = <PlanDay>[];
    for (int i = 0; i < _chronoSchedule.length; i++) {
      final readings = <PlanReading>[];
      final parts = _chronoSchedule[i].split(',');
      for (final part in parts) {
        final bp = part.split(':');
        final bookId = int.parse(bp[0]);
        final cp = bp[1].split('-');
        final startCh = int.parse(cp[0]);
        final endCh = int.parse(cp[1]);

        // Loop through the range to add each chapter individually
        for (int ch = startCh; ch <= endCh; ch++) {
          readings.add(
            PlanReading(bookId: bookId, startChapter: ch, endChapter: ch),
          );
        }
      }
      days.add(PlanDay(dayNumber: i + 1, readings: readings));
    }
    return days;
  }

  /// Returns all 1,189 chapters arranged in historical chronological order.
  static List<ChapterRef> chronologicalChapters() {
    final days = _parseChronologicalDays();
    final list = <ChapterRef>[];
    for (final day in days) {
      for (final reading in day.readings) {
        for (int ch = reading.startChapter; ch <= reading.endChapter; ch++) {
          list.add(ChapterRef(reading.bookId, ch));
        }
      }
    }
    return list;
  }

  /// Groups consecutive chapters belonging to the same book into single PlanReadings.
  static List<PlanReading> groupContiguousChapters(List<ChapterRef> chapters) {
    if (chapters.isEmpty) return const [];
    final readings = <PlanReading>[];

    int? currentBookId;
    int? startChapter;
    int? lastChapter;

    for (final ch in chapters) {
      if (currentBookId == null) {
        currentBookId = ch.bookId;
        startChapter = ch.chapter;
        lastChapter = ch.chapter;
      } else if (ch.bookId == currentBookId && ch.chapter == lastChapter! + 1) {
        lastChapter = ch.chapter;
      } else {
        readings.add(
          PlanReading(
            bookId: currentBookId,
            startChapter: startChapter!,
            endChapter: lastChapter!,
          ),
        );
        currentBookId = ch.bookId;
        startChapter = ch.chapter;
        lastChapter = ch.chapter;
      }
    }

    if (currentBookId != null) {
      readings.add(
        PlanReading(
          bookId: currentBookId,
          startChapter: startChapter!,
          endChapter: lastChapter!,
        ),
      );
    }

    return readings;
  }

  /// Partitions a list of items across a given number of days.
  static List<List<T>> partition<T>(List<T> items, int numDays) {
    final total = items.length;
    final days = <List<T>>[];
    int start = 0;
    for (int i = 0; i < numDays; i++) {
      final end = ((i + 1) * total / numDays).round();
      days.add(items.sublist(start, end));
      start = end;
    }
    return days;
  }

  /// Converts a list of ChapterRefs into individual PlanReadings (one per chapter).
  static List<PlanReading> _toReadings(List<ChapterRef> chapters) {
    return chapters
        .map(
          (ch) => PlanReading(
            bookId: ch.bookId,
            startChapter: ch.chapter,
            endChapter: ch.chapter,
          ),
        )
        .toList();
  }

  /// Generates the requested ReadingPlan model.
  static ReadingPlan generatePlan(PlanTrack track, PlanPace pace) {
    final planId = ReadingPlan.makePlanId(track, pace);
    final days = <PlanDay>[];

    switch (track) {
      case PlanTrack.throughTheBible:
        if (pace == PlanPace.oneChapterADay) {
          final chapters = canonicalChapters();
          for (int i = 0; i < chapters.length; i++) {
            days.add(
              PlanDay(
                dayNumber: i + 1,
                readings: [
                  PlanReading(
                    bookId: chapters[i].bookId,
                    startChapter: chapters[i].chapter,
                    endChapter: chapters[i].chapter,
                  ),
                ],
              ),
            );
          }
          return ReadingPlan(
            id: planId,
            track: track,
            pace: pace,
            title: 'Through the Bible (One Chapter a Day)',
            description: 'Read through the entire Bible at a relaxed pace of one chapter each day.',
            totalDays: days.length,
            days: days,
          );
        } else {
          // Finish in a year (interleaving OT & NT daily)
          final otChapters = oldTestamentChapters();
          final ntChapters = newTestamentChapters();
          final otDays = partition(otChapters, 365);
          final ntDays = partition(ntChapters, 365);

          for (int i = 0; i < 365; i++) {
            final dayReadings = <PlanReading>[
              ..._toReadings(otDays[i]),
              ..._toReadings(ntDays[i]),
            ];
            days.add(PlanDay(dayNumber: i + 1, readings: dayReadings));
          }

          return ReadingPlan(
            id: planId,
            track: track,
            pace: PlanPace.finishInYear,
            title: 'Through the Bible in a Year',
            description: 'Read through the entire Bible in a year with Old and New Testament passages every day.',
            totalDays: 365,
            days: days,
          );
        }

      case PlanTrack.chronological:
        if (pace == PlanPace.oneChapterADay) {
          final chapters = chronologicalChapters();
          for (int i = 0; i < chapters.length; i++) {
            days.add(
              PlanDay(
                dayNumber: i + 1,
                readings: [
                  PlanReading(
                    bookId: chapters[i].bookId,
                    startChapter: chapters[i].chapter,
                    endChapter: chapters[i].chapter,
                  ),
                ],
              ),
            );
          }
          return ReadingPlan(
            id: planId,
            track: track,
            pace: pace,
            title: 'Chronological Bible (One Chapter a Day)',
            description: 'Read through the entire Bible in historical order at one chapter per day.',
            totalDays: days.length,
            days: days,
          );
        } else {
          // Finish in a year (365 days) perfectly matched to the provided schedule
          final exactDays = _parseChronologicalDays();
          return ReadingPlan(
            id: planId,
            track: track,
            pace: PlanPace.finishInYear,
            title: 'Chronological Bible in a Year',
            description: 'Read through the entire Bible in the historical order in which events occurred in one year.',
            totalDays: exactDays.length,
            days: exactDays,
          );
        }

      case PlanTrack.newTestament:
        final chapters = newTestamentChapters();
        if (pace == PlanPace.oneChapterADay) {
          for (int i = 0; i < chapters.length; i++) {
            days.add(
              PlanDay(
                dayNumber: i + 1,
                readings: [
                  PlanReading(
                    bookId: chapters[i].bookId,
                    startChapter: chapters[i].chapter,
                    endChapter: chapters[i].chapter,
                  ),
                ],
              ),
            );
          }
          return ReadingPlan(
            id: planId,
            track: track,
            pace: pace,
            title: 'New Testament (One Chapter a Day)',
            description: 'Read through the entire New Testament at one chapter per day (260 days).',
            totalDays: days.length,
            days: days,
          );
        } else {
          // Finish in 90 days
          final partitioned = partition(chapters, 90);
          for (int i = 0; i < 90; i++) {
            days.add(
              PlanDay(dayNumber: i + 1, readings: _toReadings(partitioned[i])),
            );
          }
          return ReadingPlan(
            id: planId,
            track: track,
            pace: PlanPace.finishIn90Days,
            title: 'New Testament in 90 Days',
            description: 'Read through the entire New Testament in three months (~3 chapters/day).',
            totalDays: 90,
            days: days,
          );
        }
    }
  }

  /// All available plans in the catalog.
  static List<ReadingPlan> allPlans() {
    return [
      generatePlan(PlanTrack.throughTheBible, PlanPace.finishInYear),
      generatePlan(PlanTrack.throughTheBible, PlanPace.oneChapterADay),
      generatePlan(PlanTrack.chronological, PlanPace.finishInYear),
      generatePlan(PlanTrack.chronological, PlanPace.oneChapterADay),
      generatePlan(PlanTrack.newTestament, PlanPace.finishIn90Days),
      generatePlan(PlanTrack.newTestament, PlanPace.oneChapterADay),
    ];
  }
}
