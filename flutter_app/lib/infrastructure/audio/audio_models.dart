import 'package:bsb/infrastructure/reference.dart';
import 'package:database_builder/database_builder.dart';
import 'package:material_ui/material_ui.dart';

enum AudioPlayMode {
  continuous('Continuous', Icons.repeat),
  repeatChapter('Repeat Chapter', Icons.repeat_one),
  stopAfterChapter('1 Chapter', Icons.stop_circle_outlined),
  repeatVerse('Repeat Verse', Icons.replay),
  repeatPassage('Repeat Passage', Icons.repeat_on);

  final String label;
  final IconData icon;

  const AudioPlayMode(this.label, this.icon);

  static AudioPlayMode fromString(String? value) {
    switch (value) {
      case 'repeatChapter':
        return AudioPlayMode.repeatChapter;
      case 'stopAfterChapter':
        return AudioPlayMode.stopAfterChapter;
      case 'repeatVerse':
        return AudioPlayMode.repeatVerse;
      case 'repeatPassage':
        return AudioPlayMode.repeatPassage;
      case 'continuous':
      default:
        return AudioPlayMode.continuous;
    }
  }

  String toStorageString() {
    switch (this) {
      case AudioPlayMode.repeatChapter:
        return 'repeatChapter';
      case AudioPlayMode.stopAfterChapter:
        return 'stopAfterChapter';
      case AudioPlayMode.repeatVerse:
        return 'repeatVerse';
      case AudioPlayMode.repeatPassage:
        return 'repeatPassage';
      case AudioPlayMode.continuous:
        return 'continuous';
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
