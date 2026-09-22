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

  /// Returns all 1,189 chapters arranged in historical chronological order.
  /// Designed from public-domain historical biblical timeline events.
  static List<ChapterRef> chronologicalChapters() {
    List<ChapterRef> range(int bookId, int start, int end) {
      return List.generate(
        end - start + 1,
        (i) => ChapterRef(bookId, start + i),
      );
    }

    final seq = <ChapterRef>[];

    // Creation & Patriarchal Era
    seq.addAll(range(1, 1, 11)); // Genesis 1–11
    seq.addAll(range(18, 1, 42)); // Job 1–42 (contemporary with patriarchs)
    seq.addAll(range(1, 12, 50)); // Genesis 12–50

    // Exodus, Wilderness, & Law
    seq.addAll(range(2, 1, 40)); // Exodus 1–40
    seq.addAll(range(3, 1, 27)); // Leviticus 1–27
    seq.addAll(range(4, 1, 36)); // Numbers 1–36
    seq.addAll(range(5, 1, 34)); // Deuteronomy 1–34
    seq.add(const ChapterRef(19, 90)); // Psalm 90 (Prayer of Moses)

    // Conquest & Judges
    seq.addAll(range(6, 1, 24)); // Joshua 1–24
    seq.addAll(range(7, 1, 21)); // Judges 1–21
    seq.addAll(range(8, 1, 4)); // Ruth 1–4

    // Kingdom Era: Samuel, David, & Psalms
    seq.addAll(range(9, 1, 31)); // 1 Samuel 1–31
    seq.addAll(range(10, 1, 24)); // 2 Samuel 1–24
    seq.addAll(range(13, 1, 29)); // 1 Chronicles 1–29
    // Davidic & Temple Psalms (1-89, 91-150)
    for (int c = 1; c <= 89; c++) {
      seq.add(ChapterRef(19, c));
    }
    for (int c = 91; c <= 150; c++) {
      seq.add(ChapterRef(19, c));
    }

    // Solomon: Reign & Wisdom
    seq.addAll(range(11, 1, 11)); // 1 Kings 1–11
    seq.addAll(range(14, 1, 9)); // 2 Chronicles 1–9
    seq.addAll(range(20, 1, 31)); // Proverbs 1–31
    seq.addAll(range(21, 1, 12)); // Ecclesiastes 1–12
    seq.addAll(range(22, 1, 8)); // Song of Solomon 1–8

    // Divided Kingdom & Contemporary Prophets
    seq.addAll(range(11, 12, 22)); // 1 Kings 12–22
    seq.addAll(range(14, 10, 20)); // 2 Chronicles 10–20
    seq.addAll(range(31, 1, 1)); // Obadiah 1
    seq.addAll(range(29, 1, 3)); // Joel 1–3
    seq.addAll(range(32, 1, 4)); // Jonah 1–4
    seq.addAll(range(30, 1, 9)); // Amos 1–9
    seq.addAll(range(28, 1, 14)); // Hosea 1–14
    seq.addAll(range(12, 1, 17)); // 2 Kings 1–17
    seq.addAll(range(14, 21, 28)); // 2 Chronicles 21–28
    seq.addAll(range(33, 1, 7)); // Micah 1–7
    seq.addAll(range(23, 1, 39)); // Isaiah 1–39
    seq.addAll(range(12, 18, 20)); // 2 Kings 18–20
    seq.addAll(range(14, 29, 32)); // 2 Chronicles 29–32
    seq.addAll(range(23, 40, 66)); // Isaiah 40–66
    seq.addAll(range(34, 1, 3)); // Nahum 1–3
    seq.addAll(range(36, 1, 3)); // Zephaniah 1–3
    seq.addAll(range(35, 1, 3)); // Habakkuk 1–3
    seq.addAll(range(12, 21, 25)); // 2 Kings 21–25
    seq.addAll(range(14, 33, 36)); // 2 Chronicles 33–36
    seq.addAll(range(24, 1, 52)); // Jeremiah 1–52
    seq.addAll(range(25, 1, 5)); // Lamentations 1–5

    // Babylonian Exile
    seq.addAll(range(26, 1, 48)); // Ezekiel 1–48
    seq.addAll(range(27, 1, 12)); // Daniel 1–12

    // Return & Restoration
    seq.addAll(range(15, 1, 6)); // Ezra 1–6
    seq.addAll(range(37, 1, 2)); // Haggai 1–2
    seq.addAll(range(38, 1, 14)); // Zechariah 1–14
    seq.addAll(range(17, 1, 10)); // Esther 1–10
    seq.addAll(range(15, 7, 10)); // Ezra 7–10
    seq.addAll(range(16, 1, 13)); // Nehemiah 1–13
    seq.addAll(range(39, 1, 4)); // Malachi 1–4

    // New Testament: Gospels
    seq.addAll(range(40, 1, 28)); // Matthew 1–28
    seq.addAll(range(41, 1, 16)); // Mark 1–16
    seq.addAll(range(42, 1, 24)); // Luke 1–24
    seq.addAll(range(43, 1, 21)); // John 1–21

    // Early Church, Missionary Journeys, & Epistles
    seq.addAll(range(44, 1, 14)); // Acts 1–14
    seq.addAll(range(59, 1, 5)); // James 1–5
    seq.addAll(range(48, 1, 6)); // Galatians 1–6
    seq.addAll(range(44, 15, 18)); // Acts 15–18
    seq.addAll(range(52, 1, 5)); // 1 Thessalonians 1–5
    seq.addAll(range(53, 1, 3)); // 2 Thessalonians 1–3
    seq.addAll(range(44, 19, 20)); // Acts 19–20
    seq.addAll(range(46, 1, 16)); // 1 Corinthians 1–16
    seq.addAll(range(47, 1, 13)); // 2 Corinthians 1–13
    seq.addAll(range(45, 1, 16)); // Romans 1–16
    seq.addAll(range(44, 21, 28)); // Acts 21–28

    // Prison, Pastoral, General Epistles, & Revelation
    seq.addAll(range(49, 1, 6)); // Ephesians 1–6
    seq.addAll(range(51, 1, 4)); // Colossians 1–4
    seq.addAll(range(57, 1, 1)); // Philemon 1
    seq.addAll(range(50, 1, 4)); // Philippians 1–4
    seq.addAll(range(58, 1, 13)); // Hebrews 1–13
    seq.addAll(range(54, 1, 6)); // 1 Timothy 1–6
    seq.addAll(range(56, 1, 3)); // Titus 1–3
    seq.addAll(range(55, 1, 4)); // 2 Timothy 1–4
    seq.addAll(range(60, 1, 5)); // 1 Peter 1–5
    seq.addAll(range(61, 1, 3)); // 2 Peter 1–3
    seq.addAll(range(65, 1, 1)); // Jude 1
    seq.addAll(range(62, 1, 5)); // 1 John 1–5
    seq.addAll(range(63, 1, 1)); // 2 John 1
    seq.addAll(range(64, 1, 1)); // 3 John 1
    seq.addAll(range(66, 1, 22)); // Revelation 1–22

    return seq;
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
        readings.add(PlanReading(
          bookId: currentBookId,
          startChapter: startChapter!,
          endChapter: lastChapter!,
        ));
        currentBookId = ch.bookId;
        startChapter = ch.chapter;
        lastChapter = ch.chapter;
      }
    }

    if (currentBookId != null) {
      readings.add(PlanReading(
        bookId: currentBookId,
        startChapter: startChapter!,
        endChapter: lastChapter!,
      ));
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
        .map((ch) => PlanReading(
              bookId: ch.bookId,
              startChapter: ch.chapter,
              endChapter: ch.chapter,
            ))
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
            days.add(PlanDay(
              dayNumber: i + 1,
              readings: [
                PlanReading(
                  bookId: chapters[i].bookId,
                  startChapter: chapters[i].chapter,
                  endChapter: chapters[i].chapter,
                ),
              ],
            ));
          }
          return ReadingPlan(
            id: planId,
            track: track,
            pace: pace,
            title: 'Through the Bible (One Chapter a Day)',
            description:
                'Read through the entire Bible at a relaxed pace of one chapter each day.',
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
            description:
                'Read through the entire Bible in a year with Old and New Testament passages every day.',
            totalDays: 365,
            days: days,
          );
        }

      case PlanTrack.chronological:
        final chapters = chronologicalChapters();
        if (pace == PlanPace.oneChapterADay) {
          for (int i = 0; i < chapters.length; i++) {
            days.add(PlanDay(
              dayNumber: i + 1,
              readings: [
                PlanReading(
                  bookId: chapters[i].bookId,
                  startChapter: chapters[i].chapter,
                  endChapter: chapters[i].chapter,
                ),
              ],
            ));
          }
          return ReadingPlan(
            id: planId,
            track: track,
            pace: pace,
            title: 'Chronological Bible (One Chapter a Day)',
            description:
                'Read through the entire Bible in historical order at one chapter per day.',
            totalDays: days.length,
            days: days,
          );
        } else {
          // Finish in a year (365 days)
          final partitioned = partition(chapters, 365);
          for (int i = 0; i < 365; i++) {
            days.add(PlanDay(
              dayNumber: i + 1,
              readings: _toReadings(partitioned[i]),
            ));
          }
          return ReadingPlan(
            id: planId,
            track: track,
            pace: PlanPace.finishInYear,
            title: 'Chronological Bible in a Year',
            description:
                'Read through the entire Bible in the historical order in which events occurred in one year.',
            totalDays: 365,
            days: days,
          );
        }

      case PlanTrack.newTestament:
        final chapters = newTestamentChapters();
        if (pace == PlanPace.oneChapterADay) {
          for (int i = 0; i < chapters.length; i++) {
            days.add(PlanDay(
              dayNumber: i + 1,
              readings: [
                PlanReading(
                  bookId: chapters[i].bookId,
                  startChapter: chapters[i].chapter,
                  endChapter: chapters[i].chapter,
                ),
              ],
            ));
          }
          return ReadingPlan(
            id: planId,
            track: track,
            pace: pace,
            title: 'New Testament (One Chapter a Day)',
            description:
                'Read through the entire New Testament at one chapter per day (260 days).',
            totalDays: days.length,
            days: days,
          );
        } else {
          // Finish in 90 days
          final partitioned = partition(chapters, 90);
          for (int i = 0; i < 90; i++) {
            days.add(PlanDay(
              dayNumber: i + 1,
              readings: _toReadings(partitioned[i]),
            ));
          }
          return ReadingPlan(
            id: planId,
            track: track,
            pace: PlanPace.finishIn90Days,
            title: 'New Testament in 90 Days',
            description:
                'Read through the entire New Testament in three months (~3 chapters/day).',
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
