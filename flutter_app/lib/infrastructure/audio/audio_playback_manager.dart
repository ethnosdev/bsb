import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:bsb/infrastructure/audio/audio_models.dart';
import 'package:bsb/infrastructure/audio/audio_url_resolver.dart';
import 'package:bsb/infrastructure/audio/bsb_audio_handler.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  const PositionData(this.position, this.bufferedPosition, this.duration);
}

class AudioPlaybackManager {
  final BsbAudioHandler audioHandler;
  final UserSettings? userSettings;

  final ValueNotifier<bool> isPlayerVisible = ValueNotifier<bool>(false);
  final ValueNotifier<String?> playbackErrorNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<double> speedNotifier;
  final ValueNotifier<AudioPlayMode> playModeNotifier;
  final ValueNotifier<SleepTimerOption> sleepTimerOptionNotifier =
      ValueNotifier<SleepTimerOption>(SleepTimerOption.off);
  final ValueNotifier<Duration?> sleepTimerRemainingNotifier =
      ValueNotifier<Duration?>(null);
  final ValueNotifier<bool> syncTextNotifier;

  Timer? _sleepCountdownTimer;
  StreamSubscription<MediaItem?>? _mediaItemSub;
  StreamSubscription<Duration>? _positionSaveSub;

  void Function(int bookId, int chapter)? onChapterChanged;

  UserSettings? get _effectiveSettings {
    if (userSettings != null) return userSettings;
    if (getIt.isRegistered<UserSettings>()) {
      return getIt<UserSettings>();
    }
    return null;
  }

  AudioPlaybackManager({
    required this.audioHandler,
    this.userSettings,
  })  : speedNotifier = ValueNotifier<double>(
          (userSettings ??
                  (getIt.isRegistered<UserSettings>()
                      ? getIt<UserSettings>()
                      : null))
              ?.audioSpeed ??
              1.0,
        ),
        playModeNotifier = ValueNotifier<AudioPlayMode>(
          AudioPlayMode.fromString(
            (userSettings ??
                    (getIt.isRegistered<UserSettings>()
                        ? getIt<UserSettings>()
                        : null))
                ?.audioPlayMode,
          ),
        ),
        syncTextNotifier = ValueNotifier<bool>(
          (userSettings ??
                  (getIt.isRegistered<UserSettings>()
                      ? getIt<UserSettings>()
                      : null))
              ?.audioSyncText ??
              true,
        ) {
    audioHandler.setSpeed(speedNotifier.value);
    audioHandler.playMode = playModeNotifier.value;

    audioHandler.onSleepTimerFired = () {
      sleepTimerOptionNotifier.value = SleepTimerOption.off;
      sleepTimerRemainingNotifier.value = null;
    };

    _mediaItemSub = audioHandler.mediaItem.listen((item) {
      if (item != null) {
        final bookId = item.extras?['bookId'] as int?;
        final chapter = item.extras?['chapter'] as int?;
        if (bookId != null && chapter != null) {
          if (syncTextNotifier.value) {
            onChapterChanged?.call(bookId, chapter);
          }
        }
      }
    });

    _positionSaveSub = audioHandler.player.positionStream
        .throttleTime(const Duration(seconds: 5))
        .listen((pos) {
      _saveCurrentState(pos);
    });
  }

  void _saveCurrentState([Duration? pos]) {
    final settings = _effectiveSettings;
    final bookId = audioHandler.currentBookId;
    final chap = audioHandler.currentChapter;
    if (settings != null && bookId != null && chap != null) {
      final currentPos = pos ?? audioHandler.player.position;
      settings.saveLastAudioState(bookId, chap, currentPos.inMilliseconds);
    }
  }

  Stream<PlaybackState> get playbackStateStream => audioHandler.playbackState;

  Stream<MediaItem?> get mediaItemStream => audioHandler.mediaItem;

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        audioHandler.player.positionStream,
        audioHandler.player.bufferedPositionStream,
        audioHandler.player.durationStream,
        (position, buffered, duration) => PositionData(
          position,
          buffered,
          duration ?? Duration.zero,
        ),
      );

  /// Starts or resumes playing the given chapter and ensures player bar is visible.
  Future<void> playOrToggleChapter(int bookId, int chapter) async {
    isPlayerVisible.value = true;
    playbackErrorNotifier.value = null;

    final currentBook = audioHandler.currentBookId;
    final currentChap = audioHandler.currentChapter;

    try {
      if (currentBook == bookId && currentChap == chapter) {
        if (audioHandler.player.playing) {
          return;
        } else {
          await audioHandler.play();
          return;
        }
      }

      // Check if resuming saved position on the same chapter
      final settings = _effectiveSettings;
      Duration? resumePos;
      if (settings != null &&
          settings.lastAudioBookId == bookId &&
          settings.lastAudioChapter == chapter) {
        final ms = settings.lastAudioPositionMs ?? 0;
        if (ms > 3000) {
          resumePos = Duration(milliseconds: ms);
        }
      }

      await audioHandler.playChapter(bookId, chapter, initialPosition: resumePos);
    } catch (e) {
      playbackErrorNotifier.value =
          'Unable to play audio. Check internet connection.';
    }
  }

  Future<void> play() async {
    isPlayerVisible.value = true;
    await audioHandler.play();
  }

  Future<void> pause() async {
    _saveCurrentState();
    await audioHandler.pause();
  }

  Future<void> seek(Duration position) async {
    await audioHandler.seek(position);
  }

  Future<void> seekForward10() async {
    await audioHandler.fastForward();
  }

  Future<void> seekBackward10() async {
    await audioHandler.rewind();
  }

  Future<void> skipToNext() async {
    await audioHandler.skipToNext();
  }

  Future<void> skipToPrevious() async {
    await audioHandler.skipToPrevious();
  }

  Future<void> closePlayer() async {
    isPlayerVisible.value = false;
    _saveCurrentState();
    await audioHandler.stop();
  }

  Future<void> setSpeed(double speed) async {
    speedNotifier.value = speed;
    await audioHandler.setSpeed(speed);
    await _effectiveSettings?.setAudioSpeed(speed);
  }

  void setPlayMode(AudioPlayMode mode) {
    playModeNotifier.value = mode;
    audioHandler.playMode = mode;
    _effectiveSettings?.setAudioPlayMode(mode.toStorageString());
  }

  void cyclePlayMode() {
    final nextMode = switch (playModeNotifier.value) {
      AudioPlayMode.continuous => AudioPlayMode.repeatChapter,
      AudioPlayMode.repeatChapter => AudioPlayMode.stopAfterChapter,
      AudioPlayMode.stopAfterChapter => AudioPlayMode.continuous,
    };
    setPlayMode(nextMode);
  }

  void setSleepTimer(SleepTimerOption option) {
    _sleepCountdownTimer?.cancel();
    _sleepCountdownTimer = null;

    if (option == SleepTimerOption.off) {
      audioHandler.stopAtEndOfChapter = false;
      sleepTimerOptionNotifier.value = SleepTimerOption.off;
      sleepTimerRemainingNotifier.value = null;
      return;
    }

    if (option == SleepTimerOption.endOfChapter) {
      audioHandler.stopAtEndOfChapter = true;
      sleepTimerOptionNotifier.value = SleepTimerOption.endOfChapter;
      sleepTimerRemainingNotifier.value = null;
      return;
    }

    final duration = option.duration;
    if (duration != null) {
      audioHandler.stopAtEndOfChapter = false;
      sleepTimerOptionNotifier.value = option;
      sleepTimerRemainingNotifier.value = duration;

      _sleepCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final current = sleepTimerRemainingNotifier.value;
        if (current == null || current.inSeconds <= 1) {
          timer.cancel();
          _sleepCountdownTimer = null;
          sleepTimerOptionNotifier.value = SleepTimerOption.off;
          sleepTimerRemainingNotifier.value = null;
          pause();
        } else {
          sleepTimerRemainingNotifier.value =
              current - const Duration(seconds: 1);
        }
      });
    }
  }

  void setSyncText(bool sync) {
    syncTextNotifier.value = sync;
    _effectiveSettings?.setAudioSyncText(sync);
    if (sync) {
      final bookId = audioHandler.currentBookId;
      final chap = audioHandler.currentChapter;
      if (bookId != null && chap != null) {
        onChapterChanged?.call(bookId, chap);
      }
    }
  }

  bool hasNextChapter(int? bookId, int? chapter) {
    if (bookId == null || chapter == null) return false;
    return const AudioUrlResolver().getNextChapter(bookId, chapter) != null;
  }

  bool hasPreviousChapter(int? bookId, int? chapter) {
    if (bookId == null || chapter == null) return false;
    return const AudioUrlResolver().getPreviousChapter(bookId, chapter) != null;
  }

  void dispose() {
    _sleepCountdownTimer?.cancel();
    _mediaItemSub?.cancel();
    _positionSaveSub?.cancel();
    isPlayerVisible.dispose();
    playbackErrorNotifier.dispose();
    speedNotifier.dispose();
    playModeNotifier.dispose();
    sleepTimerOptionNotifier.dispose();
    sleepTimerRemainingNotifier.dispose();
    syncTextNotifier.dispose();
  }
}
