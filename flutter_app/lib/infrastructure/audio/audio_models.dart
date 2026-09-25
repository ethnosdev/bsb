import 'package:flutter/material.dart';

enum AudioPlayMode {
  continuous('Continuous', Icons.repeat),
  repeatChapter('Repeat Chapter', Icons.repeat_one),
  stopAfterChapter('1 Chapter', Icons.stop_circle_outlined);

  final String label;
  final IconData icon;

  const AudioPlayMode(this.label, this.icon);

  static AudioPlayMode fromString(String? value) {
    switch (value) {
      case 'repeatChapter':
        return AudioPlayMode.repeatChapter;
      case 'stopAfterChapter':
        return AudioPlayMode.stopAfterChapter;
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
      case AudioPlayMode.continuous:
        return 'continuous';
    }
  }
}

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
