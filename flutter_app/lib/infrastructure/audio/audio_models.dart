import 'package:bsb/infrastructure/reference.dart';
import 'package:database_builder/database_builder.dart';
import 'package:material_ui/material_ui.dart';

enum AudioPlayContext {
  chapter('Chapter', Icons.menu_book_outlined),
  range('Range', Icons.view_stream_outlined),
  verse('Verse', Icons.format_quote_outlined);

  final String label;
  final IconData icon;

  const AudioPlayContext(this.label, this.icon);
}

enum AudioRepeatBehavior {
  continueOn('Continue', Icons.double_arrow),
  stop('Stop', Icons.stop_circle_outlined),
  repeat('Repeat', Icons.repeat);

  final String label;
  final IconData icon;

  const AudioRepeatBehavior(this.label, this.icon);

  static AudioRepeatBehavior fromString(String? value) {
    switch (value) {
      case 'repeat':
      case 'repeatChapter':
        return AudioRepeatBehavior.repeat;
      case 'stop':
      case 'stopAfterChapter':
        return AudioRepeatBehavior.stop;
      case 'continueOn':
      case 'continuous':
      default:
        return AudioRepeatBehavior.continueOn;
    }
  }

  String toStorageString() {
    switch (this) {
      case AudioRepeatBehavior.repeat:
        return 'repeat';
      case AudioRepeatBehavior.stop:
        return 'stop';
      case AudioRepeatBehavior.continueOn:
        return 'continueOn';
    }
  }
}

/// Live countdown state while waiting between verses in pause-between-verses mode.
class VersePauseState {
  final bool isPaused;
  final int remainingSeconds;
  final int totalSeconds;
  final int? nextBookId;
  final int? nextChapter;
  final int? nextVerse;

  const VersePauseState({
    this.isPaused = false,
    this.remainingSeconds = 0,
    this.totalSeconds = kDefaultVersePauseSeconds,
    this.nextBookId,
    this.nextChapter,
    this.nextVerse,
  });

  static const VersePauseState idle = VersePauseState();

  /// Formatted countdown text for display in the player UI and lock screen.
  String? get statusText {
    if (!isPaused) return null;
    return 'Next verse in ${remainingSeconds}s...';
  }
}

/// Formats [reference] concisely with its book abbreviation (e.g. `Rom 8:31–39`).
String formatCompactPassageReference(Reference reference) {
  final abbr =
      bookIdToAbbreviationMap[reference.bookId] ??
      bookIdToFullNameMap[reference.bookId] ??
      'Book ${reference.bookId}';
  final verse = reference.verse;
  final endChapter = reference.endChapter;
  final endVerse = reference.endVerse;
  if (verse == null) {
    if (endChapter != null && endChapter != reference.chapter) {
      return '$abbr ${reference.chapter}–$endChapter';
    }
    return '$abbr ${reference.chapter}';
  }
  if (endChapter != null && endChapter != reference.chapter) {
    if (endVerse != null) {
      return '$abbr ${reference.chapter}:$verse–$endChapter:$endVerse';
    }
    return '$abbr ${reference.chapter}:$verse–$endChapter';
  }
  if (endVerse != null && endVerse != verse) {
    return '$abbr ${reference.chapter}:$verse–$endVerse';
  }
  return '$abbr ${reference.chapter}:$verse';
}

const int kDefaultVersePauseSeconds = 5;
const int kMinVersePauseSeconds = 1;
const int kMaxVersePauseSeconds = 60;
const List<int> kVersePausePresetSeconds = [3, 5, 8, 10, 15];

enum SleepTimerOption {
  off('Off', null),
  endOfChapter('End of chapter', null),
  fifteenMinutes('15 minutes', Duration(minutes: 15)),
  thirtyMinutes('30 minutes', Duration(minutes: 30)),
  fortyFiveMinutes('45 minutes', Duration(minutes: 45)),
  sixtyMinutes('60 minutes', Duration(minutes: 60));

  final String label;
  final Duration? duration;

  const SleepTimerOption(this.label, this.duration);
}

const List<double> kAudioSpeedOptions = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
