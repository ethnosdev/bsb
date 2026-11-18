import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:bsb/infrastructure/audio/audio_models.dart';
import 'package:bsb/infrastructure/audio/bsb_audio_handler.dart';
import 'package:bsb/infrastructure/audio/verse_timings.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
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
  final ValueNotifier<String?> playbackErrorNotifier = ValueNotifier<String?>(
    null,
  );
  final ValueNotifier<double> speedNotifier;
  final ValueNotifier<bool> pauseBetweenVersesEnabledNotifier;
  final ValueNotifier<int> pauseBetweenVersesSecondsNotifier;
  final ValueNotifier<VersePauseState> versePauseStateNotifier =
      ValueNotifier<VersePauseState>(VersePauseState.idle);
  final ValueNotifier<AudioPlayContext> playContextNotifier =
      ValueNotifier<AudioPlayContext>(AudioPlayContext.chapter);
  final ValueNotifier<AudioRepeatBehavior> repeatBehaviorNotifier;
  final ValueNotifier<Reference?> activeRangeNotifier =
      ValueNotifier<Reference?>(null);
  final ValueNotifier<int?> lockedVerseNotifier = ValueNotifier<int?>(null);
  AudioRepeatBehavior _chapterRepeatPreference;
  final ValueNotifier<String?> audioTabIdNotifier = ValueNotifier<String?>(
    null,
  );
  final ValueNotifier<int?> currentVerseNotifier = ValueNotifier<int?>(null);

  StreamSubscription<MediaItem?>? _mediaItemSub;
  StreamSubscription<Duration>? _positionSaveSub;
  StreamSubscription<int?>? _verseSub;
  StreamSubscription<VersePauseState>? _versePauseSub;

  int? _lastNotifiedBookId;
  int? _lastNotifiedChapter;

  void Function(int bookId, int chapter)? onChapterChanged;

  ChapterTimings? get currentTimings => audioHandler.currentTimings;

  UserSettings? get _effectiveSettings {
    if (userSettings != null) return userSettings;
    if (getIt.isRegistered<UserSettings>()) {
      return getIt<UserSettings>();
    }
    return null;
  }

  static UserSettings? _resolveInitialSettings(UserSettings? userSettings) {
    if (userSettings != null) return userSettings;
    if (getIt.isRegistered<UserSettings>()) {
      return getIt<UserSettings>();
    }
    return null;
  }

  AudioPlaybackManager({required this.audioHandler, this.userSettings})
    : speedNotifier = ValueNotifier<double>(
        _resolveInitialSettings(userSettings)?.audioSpeed ?? 1.0,
      ),
      pauseBetweenVersesEnabledNotifier = ValueNotifier<bool>(
        _resolveInitialSettings(userSettings)?.audioPauseBetweenVersesEnabled ??
            false,
      ),
      pauseBetweenVersesSecondsNotifier = ValueNotifier<int>(
        _resolveInitialSettings(userSettings)?.audioPauseBetweenVersesSeconds ??
            kDefaultVersePauseSeconds,
      ),
      _chapterRepeatPreference = AudioRepeatBehavior.fromString(
        _resolveInitialSettings(userSettings)?.audioPlayMode,
      ),
      repeatBehaviorNotifier = ValueNotifier<AudioRepeatBehavior>(
        AudioRepeatBehavior.fromString(
          _resolveInitialSettings(userSettings)?.audioPlayMode,
        ),
      ) {
    audioHandler.defaultChapterRepeat = _chapterRepeatPreference;
    audioHandler.setPlayContext(AudioPlayContext.chapter);
    audioHandler.setRepeatBehavior(_chapterRepeatPreference);
    audioHandler.setSpeed(speedNotifier.value);
    audioHandler.setPauseBetweenVerses(
      enabled: pauseBetweenVersesEnabledNotifier.value,
      seconds: pauseBetweenVersesSecondsNotifier.value,
    );

    audioHandler.onModeChanged = (context, repeat, range, lockedVerse) {
      playContextNotifier.value = context;
      repeatBehaviorNotifier.value = repeat;
      activeRangeNotifier.value = range;
      lockedVerseNotifier.value = lockedVerse;
    };
    audioHandler.onSpeedChanged = (speed) {
      if ((speedNotifier.value - speed).abs() > 0.001) {
        speedNotifier.value = speed;
        _effectiveSettings?.setAudioSpeed(speed);
      }
    };
    audioHandler.onPaused = () => _saveCurrentState();
    audioHandler.onStopped = () {
      if (isPlayerVisible.value) {
        _saveCurrentState();
      }
      _clearPlayerUiState();
    };

    _mediaItemSub = audioHandler.mediaItem.listen((item) {
      if (item == null) return;
      final bookId = item.extras?['bookId'] as int?;
      final chapter = item.extras?['chapter'] as int?;
      if (bookId == null || chapter == null) return;

      // De-duplicate on (bookId, chapter) because MediaItem also updates when
      // the live verse/countdown title changes every few seconds.
      if (bookId == _lastNotifiedBookId && chapter == _lastNotifiedChapter) {
        return;
      }
      _lastNotifiedBookId = bookId;
      _lastNotifiedChapter = chapter;
      onChapterChanged?.call(bookId, chapter);
    });

    _verseSub = audioHandler.currentVerseStream.listen((verse) {
      currentVerseNotifier.value = verse;
    });

    _versePauseSub = audioHandler.versePauseStateStream.listen((pauseState) {
      versePauseStateNotifier.value = pauseState;
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
        (position, buffered, duration) =>
            PositionData(position, buffered, duration ?? Duration.zero),
      );

  /// Formats the display reference for the mini player and expanded sheet
  /// (e.g. "John 10:14", or "John 10" during the chapter announcement).
  String formatDisplayTitle(MediaItem? item, int? verse) {
    final title =
        (item?.extras?['chapterTitle'] as String?) ??
        item?.title ??
        'Audio Player';
    if (verse == null) return title;
    return '$title:$verse';
  }

  void _bindActiveTabIfAvailable() {
    if (getIt.isRegistered<TabManager>()) {
      final activeId = getIt<TabManager>().activeTabId;
      if (activeId != null) {
        audioTabIdNotifier.value = activeId;
      }
    }
  }

  void _resetToChapterContext() {
    activeRangeNotifier.value = null;
    audioHandler.activeRange = null;
    audioHandler.setPlayContext(AudioPlayContext.chapter);
    audioHandler.setRepeatBehavior(_chapterRepeatPreference);
  }

  /// Starts or resumes playing the given chapter and ensures player bar is visible.
  Future<void> playOrToggleChapter(int bookId, int chapter) async {
    _bindActiveTabIfAvailable();
    isPlayerVisible.value = true;
    playbackErrorNotifier.value = null;

    final currentBook = audioHandler.currentBookId;
    final currentChap = audioHandler.currentChapter;

    try {
      if (currentBook == bookId &&
          currentChap == chapter &&
          playContextNotifier.value == AudioPlayContext.chapter) {
        if (audioHandler.player.playing || audioHandler.isInVersePause) {
          return;
        } else {
          await audioHandler.play();
          return;
        }
      }

      // Starting playback from the app bar enters Chapter context and restores
      // the saved chapter-level Repeat preference.
      _resetToChapterContext();

      if (currentBook == bookId && currentChap == chapter) {
        await audioHandler.playChapter(bookId, chapter);
        return;
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

      await audioHandler.playChapter(
        bookId,
        chapter,
        initialPosition: resumePos,
      );
    } catch (e) {
      playbackErrorNotifier.value =
          'Unable to play audio. Check internet connection.';
    }
  }

  /// Starts playback from [verse] in [bookId] and [chapter].
  Future<void> playFromVerse(int bookId, int chapter, int verse) async {
    _bindActiveTabIfAvailable();
    isPlayerVisible.value = true;
    playbackErrorNotifier.value = null;
    try {
      await audioHandler.playFromVerse(bookId, chapter, verse);
    } catch (e) {
      playbackErrorNotifier.value =
          'Unable to play audio. Check internet connection.';
    }
  }

  /// Syncs audio to [bookId] and [chapter] when the audio tab navigates chapters.
  ///
  /// Resets session Context/Range/Verse state back to Chapter mode with the saved
  /// chapter Repeat preference, then plays if active or cues paused otherwise.
  Future<void> navigateTabToChapter(
    int bookId,
    int chapter, {
    int? targetVerse,
  }) async {
    if (!isPlayerVisible.value) return;
    playbackErrorNotifier.value = null;

    _resetToChapterContext();

    try {
      await audioHandler.navigateToChapter(
        bookId,
        chapter,
        targetVerse: targetVerse,
      );
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

  Future<void> skipToNextVerse() async {
    await audioHandler.skipToNextVerse();
  }

  Future<void> skipToPreviousVerse() async {
    await audioHandler.skipToPreviousVerse();
  }

  bool hasNextVerse(Duration position) => audioHandler.hasNextVerse(position);

  bool hasPreviousVerse(Duration position) =>
      audioHandler.hasPreviousVerse(position);

  void _clearPlayerUiState() {
    isPlayerVisible.value = false;
    audioTabIdNotifier.value = null;
    _lastNotifiedBookId = null;
    _lastNotifiedChapter = null;
  }

  Future<void> closePlayer() async {
    _clearPlayerUiState();
    _saveCurrentState();
    await audioHandler.stop();
  }

  Future<void> setSpeed(double speed) async {
    speedNotifier.value = speed;
    await audioHandler.setSpeed(speed);
    await _effectiveSettings?.setAudioSpeed(speed);
  }

  Future<void> setPauseBetweenVerses({
    required bool enabled,
    int? seconds,
  }) async {
    final clampedSeconds = seconds?.clamp(
      kMinVersePauseSeconds,
      kMaxVersePauseSeconds,
    );
    if (clampedSeconds != null) {
      pauseBetweenVersesSecondsNotifier.value = clampedSeconds;
      await _effectiveSettings?.setAudioPauseBetweenVersesSeconds(
        clampedSeconds,
      );
    }
    pauseBetweenVersesEnabledNotifier.value = enabled;
    await _effectiveSettings?.setAudioPauseBetweenVersesEnabled(enabled);
    await audioHandler.setPauseBetweenVerses(
      enabled: enabled,
      seconds: clampedSeconds,
    );
  }

  Future<void> setPlayContext(AudioPlayContext context) async {
    if (context == AudioPlayContext.range) {
      final range = activeRangeNotifier.value;
      if (range == null) return;
      audioHandler.activeRange = range;
      audioHandler.setPlayContext(AudioPlayContext.range);
      if (!_isCurrentlyWithinPassage(range)) {
        isPlayerVisible.value = true;
        playbackErrorNotifier.value = null;
        try {
          await audioHandler.playPassageStart(range);
        } catch (e) {
          playbackErrorNotifier.value =
              'Unable to play audio. Check internet connection.';
        }
      }
      return;
    }

    if (context == AudioPlayContext.verse) {
      final targetVerse = currentVerseNotifier.value ?? 1;
      audioHandler.setPlayContext(
        AudioPlayContext.verse,
        targetVerse: targetVerse,
      );
      return;
    }

    audioHandler.setPlayContext(AudioPlayContext.chapter);
  }

  void setRepeatBehavior(AudioRepeatBehavior behavior) {
    repeatBehaviorNotifier.value = behavior;
    audioHandler.setRepeatBehavior(behavior);
    if (playContextNotifier.value == AudioPlayContext.chapter) {
      _chapterRepeatPreference = behavior;
      audioHandler.defaultChapterRepeat = behavior;
      _effectiveSettings?.setAudioPlayMode(behavior.toStorageString());
    }
  }

  bool _isCurrentlyWithinPassage(Reference passage) {
    final bookId = audioHandler.currentBookId;
    final chapter = audioHandler.currentChapter;
    if (bookId != passage.bookId || chapter == null) return false;
    final endChapter = passage.endChapter ?? passage.chapter;
    if (chapter < passage.chapter || chapter > endChapter) return false;

    final verse = currentVerseNotifier.value;
    if (verse == null) return false;
    if (chapter == passage.chapter &&
        passage.verse != null &&
        verse < passage.verse!) {
      return false;
    }
    if (chapter == endChapter &&
        passage.endVerse != null &&
        verse > passage.endVerse!) {
      return false;
    }
    return true;
  }

  /// Plays [reference] once from long-press text selection:
  /// - 1 verse -> Context = Verse, Repeat = Stop
  /// - 2+ verses (or multi-chapter) -> Context = Range, Repeat = Stop
  /// - Whole single chapter -> Context = Chapter, Repeat = Stop
  Future<void> playSelection(Reference reference) async {
    final verse = reference.verse;
    final endChapter = reference.endChapter;
    final endVerse = reference.endVerse;

    _bindActiveTabIfAvailable();
    isPlayerVisible.value = true;
    playbackErrorNotifier.value = null;

    try {
      if (verse == null) {
        if (endChapter != null && endChapter > reference.chapter) {
          activeRangeNotifier.value = reference;
          audioHandler.activeRange = reference;
          audioHandler.setPlayContext(AudioPlayContext.range);
          audioHandler.setRepeatBehavior(AudioRepeatBehavior.stop);
          await audioHandler.playPassageStart(reference);
        } else {
          activeRangeNotifier.value = null;
          audioHandler.activeRange = null;
          audioHandler.setPlayContext(AudioPlayContext.chapter);
          audioHandler.setRepeatBehavior(AudioRepeatBehavior.stop);
          await audioHandler.playChapter(reference.bookId, reference.chapter);
        }
        return;
      }

      final isMultiVerse =
          (endChapter != null && endChapter > reference.chapter) ||
          (endVerse != null && endVerse > verse);
      if (isMultiVerse) {
        activeRangeNotifier.value = reference;
        audioHandler.activeRange = reference;
        audioHandler.setPlayContext(AudioPlayContext.range);
        audioHandler.setRepeatBehavior(AudioRepeatBehavior.stop);
        await audioHandler.playPassageStart(reference);
      } else {
        activeRangeNotifier.value = null;
        audioHandler.activeRange = null;
        audioHandler.setPlayContext(AudioPlayContext.verse, targetVerse: verse);
        audioHandler.setRepeatBehavior(AudioRepeatBehavior.stop);
        await audioHandler.playFromVerse(
          reference.bookId,
          reference.chapter,
          verse,
          skipAnnouncement: true,
        );
      }
    } catch (e) {
      playbackErrorNotifier.value =
          'Unable to play audio. Check internet connection.';
    }
  }

  void dispose() {
    _mediaItemSub?.cancel();
    _positionSaveSub?.cancel();
    _verseSub?.cancel();
    _versePauseSub?.cancel();
    isPlayerVisible.dispose();
    playbackErrorNotifier.dispose();
    speedNotifier.dispose();
    pauseBetweenVersesEnabledNotifier.dispose();
    pauseBetweenVersesSecondsNotifier.dispose();
    versePauseStateNotifier.dispose();
    playContextNotifier.dispose();
    repeatBehaviorNotifier.dispose();
    activeRangeNotifier.dispose();
    lockedVerseNotifier.dispose();
    audioTabIdNotifier.dispose();
    currentVerseNotifier.dispose();
  }
}
