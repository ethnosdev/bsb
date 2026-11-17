/// Audio timing bounds for a single verse within a chapter.
class VerseTiming {
  final int verse;
  final Duration start;
  final Duration end;

  const VerseTiming({
    required this.verse,
    required this.start,
    required this.end,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerseTiming &&
          verse == other.verse &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(verse, start, end);
}

/// Ordered per-verse audio timings for a single Bible chapter.
class ChapterTimings {
  final int bookId;
  final int chapter;
  final List<VerseTiming> verses;

  const ChapterTimings({
    required this.bookId,
    required this.chapter,
    required this.verses,
  });

  const ChapterTimings.empty(this.bookId, this.chapter) : verses = const [];

  bool get isEmpty => verses.isEmpty;

  /// Returns the verse number playing at [position], or `null` during the
  /// spoken chapter announcement before the first verse starts.
  /// Positions at or past the last verse's end return the last verse.
  int? verseAt(Duration position) {
    final idx = _indexAt(position);
    if (idx == null) return null;
    return verses[idx].verse;
  }

  /// Returns the timing record for [verse], or `null` if not present.
  VerseTiming? timingFor(int verse) {
    int low = 0;
    int high = verses.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final current = verses[mid].verse;
      if (current == verse) return verses[mid];
      if (current < verse) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return null;
  }

  /// Returns the seek target for advancing to the next verse from [position],
  /// or `null` when already at or past the last verse.
  Duration? nextSeekTarget(Duration position) {
    if (verses.isEmpty) return null;
    final idx = _indexAt(position);
    if (idx == null) {
      return verses.first.start;
    }
    if (idx + 1 < verses.length) {
      return verses[idx + 1].start;
    }
    return null;
  }

  /// Returns the seek target for stepping back a verse from [position].
  /// Restarts the current verse if more than [restartThreshold] past its start;
  /// otherwise moves to the previous verse (or `0:00` from verse 1 / announcement).
  Duration? previousSeekTarget(
    Duration position, {
    Duration restartThreshold = const Duration(seconds: 2),
  }) {
    if (verses.isEmpty) return null;
    final idx = _indexAt(position);
    if (idx == null) {
      return Duration.zero;
    }
    if (position - verses[idx].start > restartThreshold) {
      return verses[idx].start;
    }
    if (idx > 0) {
      return verses[idx - 1].start;
    }
    return Duration.zero;
  }

  int? _indexAt(Duration position) {
    if (verses.isEmpty || position < verses.first.start) {
      return null;
    }

    int low = 0;
    int high = verses.length - 1;
    int result = 0;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (verses[mid].start <= position) {
        result = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return result;
  }
}
