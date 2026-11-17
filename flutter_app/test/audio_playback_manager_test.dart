import 'dart:async';

import 'package:bsb/infrastructure/audio/audio_models.dart';
import 'package:bsb/infrastructure/audio/audio_playback_manager.dart';
import 'package:bsb/infrastructure/audio/bsb_audio_handler.dart';
import 'package:bsb/infrastructure/audio/verse_timings.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAudioPlayer extends AudioPlayer {
  double currentSpeed = 1.0;
  Duration currentPosition = Duration.zero;
  Duration? currentDuration = const Duration(minutes: 5);
  bool isPlaying = false;
  int setAudioSourceCalls = 0;
  Duration? lastInitialPosition;

  final StreamController<Duration> positionController =
      StreamController<Duration>.broadcast();
  final StreamController<PlayerState> playerStateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<PlaybackEvent> eventController =
      StreamController<PlaybackEvent>.broadcast();

  @override
  Stream<Duration> get positionStream => positionController.stream;

  @override
  Stream<Duration> get bufferedPositionStream => Stream.value(Duration.zero);

  @override
  Stream<Duration?> get durationStream => Stream.value(currentDuration);

  @override
  Stream<PlayerState> get playerStateStream => playerStateController.stream;

  @override
  Stream<PlaybackEvent> get playbackEventStream => eventController.stream;

  @override
  ProcessingState get processingState => ProcessingState.ready;

  @override
  double get speed => currentSpeed;

  @override
  Future<void> setSpeed(double speed) async {
    currentSpeed = speed;
  }

  LoopMode currentLoopMode = LoopMode.off;

  @override
  Future<void> setLoopMode(LoopMode mode) async {
    currentLoopMode = mode;
  }

  @override
  Duration get position => currentPosition;

  @override
  Duration? get duration => currentDuration;

  @override
  bool get playing => isPlaying;

  @override
  Future<Duration?> setAudioSource(
    AudioSource source, {
    int? initialIndex,
    Duration? initialPosition,
    bool preload = true,
  }) async {
    setAudioSourceCalls++;
    lastInitialPosition = initialPosition;
    currentPosition = initialPosition ?? Duration.zero;
    return currentDuration;
  }

  bool holdPlayFutureUntilPaused = false;
  Completer<void>? _playCompleter;

  void _completePendingPlay() {
    if (_playCompleter != null && !_playCompleter!.isCompleted) {
      _playCompleter!.complete();
    }
    _playCompleter = null;
  }

  @override
  Future<void> play() async {
    isPlaying = true;
    playerStateController.add(PlayerState(true, ProcessingState.ready));
    if (holdPlayFutureUntilPaused) {
      _completePendingPlay();
      _playCompleter = Completer<void>();
      return _playCompleter!.future;
    }
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
    _completePendingPlay();
    playerStateController.add(PlayerState(false, ProcessingState.ready));
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    if (position != null) {
      currentPosition = position;
      positionController.add(position);
    }
  }

  @override
  Future<void> stop() async {
    isPlaying = false;
    _completePendingPlay();
  }

  void emitPosition(Duration pos) {
    currentPosition = pos;
    positionController.add(pos);
  }

  void emitCompleted() {
    playerStateController.add(PlayerState(false, ProcessingState.completed));
  }

  @override
  Future<void> dispose() async {
    _completePendingPlay();
    await positionController.close();
    await playerStateController.close();
    await eventController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const john10Timings = ChapterTimings(
    bookId: 43,
    chapter: 10,
    verses: [
      VerseTiming(
        verse: 1,
        start: Duration(milliseconds: 4700),
        end: Duration(milliseconds: 12950),
      ),
      VerseTiming(
        verse: 2,
        start: Duration(milliseconds: 12950),
        end: Duration(milliseconds: 16690),
      ),
      VerseTiming(
        verse: 3,
        start: Duration(milliseconds: 16690),
        end: Duration(milliseconds: 24830),
      ),
    ],
  );

  const john11Timings = ChapterTimings(
    bookId: 43,
    chapter: 11,
    verses: [
      VerseTiming(
        verse: 1,
        start: Duration(milliseconds: 4000),
        end: Duration(milliseconds: 10000),
      ),
      VerseTiming(
        verse: 2,
        start: Duration(milliseconds: 10000),
        end: Duration(milliseconds: 15000),
      ),
    ],
  );

  late UserSettings userSettings;
  late MockAudioPlayer mockPlayer;
  late MockAudioPlayer mockSilencePlayer;
  late BsbAudioHandler audioHandler;
  late AudioPlaybackManager manager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    userSettings = UserSettings();
    await userSettings.init();

    mockPlayer = MockAudioPlayer();
    mockSilencePlayer = MockAudioPlayer();
    audioHandler = BsbAudioHandler(
      player: mockPlayer,
      silencePlayer: mockSilencePlayer,
      timingsLoader: (bookId, chapter) async {
        if (bookId == 43 && chapter == 10) return john10Timings;
        if (bookId == 43 && chapter == 11) return john11Timings;
        return ChapterTimings.empty(bookId, chapter);
      },
    );
    manager = AudioPlaybackManager(
      audioHandler: audioHandler,
      userSettings: userSettings,
    );
  });

  tearDown(() async {
    manager.dispose();
    await audioHandler.dispose();
  });

  group('AudioPlaybackManager logic', () {
    test('default settings are loaded from userSettings', () {
      expect(manager.speedNotifier.value, 1.0);
      expect(manager.playModeNotifier.value, AudioPlayMode.continuous);
      expect(manager.syncTextNotifier.value, isTrue);
      expect(manager.sleepTimerOptionNotifier.value, SleepTimerOption.off);
    });

    test(
      'setSpeed updates handler, notifier, and persists to userSettings',
      () async {
        await manager.setSpeed(1.5);
        expect(manager.speedNotifier.value, 1.5);
        expect(mockPlayer.currentSpeed, 1.5);
        expect(userSettings.audioSpeed, 1.5);
      },
    );

    test('setPlayMode and cyclePlayMode cycle through all 4 modes and persist', () {
      expect(manager.playModeNotifier.value, AudioPlayMode.continuous);

      manager.cyclePlayMode();
      expect(manager.playModeNotifier.value, AudioPlayMode.repeatChapter);
      expect(audioHandler.playMode, AudioPlayMode.repeatChapter);
      expect(userSettings.audioPlayMode, 'repeatChapter');

      manager.cyclePlayMode();
      expect(manager.playModeNotifier.value, AudioPlayMode.stopAfterChapter);
      expect(audioHandler.playMode, AudioPlayMode.stopAfterChapter);
      expect(userSettings.audioPlayMode, 'stopAfterChapter');

      manager.cyclePlayMode();
      expect(manager.playModeNotifier.value, AudioPlayMode.repeatVerse);
      expect(audioHandler.playMode, AudioPlayMode.repeatVerse);
      expect(userSettings.audioPlayMode, 'repeatVerse');
      expect(AudioPlayMode.fromString('repeatVerse'), AudioPlayMode.repeatVerse);

      manager.cyclePlayMode();
      expect(manager.playModeNotifier.value, AudioPlayMode.continuous);
      expect(audioHandler.playMode, AudioPlayMode.continuous);
      expect(userSettings.audioPlayMode, 'continuous');
    });

    test('setSyncText updates notifier and persists', () {
      manager.setSyncText(false);
      expect(manager.syncTextNotifier.value, isFalse);
      expect(userSettings.audioSyncText, isFalse);

      manager.setSyncText(true);
      expect(manager.syncTextNotifier.value, isTrue);
      expect(userSettings.audioSyncText, isTrue);
    });

    test('setSleepTimer endOfChapter sets handler flag', () {
      manager.setSleepTimer(SleepTimerOption.endOfChapter);
      expect(
        manager.sleepTimerOptionNotifier.value,
        SleepTimerOption.endOfChapter,
      );
      expect(audioHandler.stopAtEndOfChapter, isTrue);
      expect(manager.sleepTimerRemainingNotifier.value, isNull);

      manager.setSleepTimer(SleepTimerOption.off);
      expect(manager.sleepTimerOptionNotifier.value, SleepTimerOption.off);
      expect(audioHandler.stopAtEndOfChapter, isFalse);
    });

    test('setSleepTimer duration initializes remaining countdown', () {
      manager.setSleepTimer(SleepTimerOption.fifteenMinutes);
      expect(
        manager.sleepTimerOptionNotifier.value,
        SleepTimerOption.fifteenMinutes,
      );
      expect(
        manager.sleepTimerRemainingNotifier.value,
        const Duration(minutes: 15),
      );

      manager.setSleepTimer(SleepTimerOption.off);
      expect(manager.sleepTimerRemainingNotifier.value, isNull);
    });

    test('seekForward10 and seekBackward10 relative seeks properly', () async {
      mockPlayer.currentPosition = const Duration(seconds: 30);
      await manager.seekForward10();
      expect(mockPlayer.currentPosition, const Duration(seconds: 40));

      await manager.seekBackward10();
      expect(mockPlayer.currentPosition, const Duration(seconds: 30));
    });

    test('seekBackward10 clamps at zero', () async {
      mockPlayer.currentPosition = const Duration(seconds: 5);
      await manager.seekBackward10();
      expect(mockPlayer.currentPosition, Duration.zero);
    });

    test('seekForward10 clamps at total duration', () async {
      mockPlayer.currentPosition = const Duration(minutes: 4, seconds: 55);
      await manager.seekForward10();
      expect(mockPlayer.currentPosition, const Duration(minutes: 5));
    });

    test('playFromVerse starts verse 1 at 0:00 and verse N at start_ms, reusing loaded chapter', () async {
      await manager.playFromVerse(43, 10, 1);
      expect(mockPlayer.setAudioSourceCalls, 1);
      expect(mockPlayer.lastInitialPosition, Duration.zero);
      expect(manager.isPlayerVisible.value, isTrue);

      // Same chapter: seeks directly without calling setAudioSource again
      await manager.playFromVerse(43, 10, 2);
      await Future<void>.delayed(Duration.zero);
      expect(mockPlayer.setAudioSourceCalls, 1);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 12950));
      expect(manager.currentVerseNotifier.value, 2);

      // Different chapter: calls setAudioSource again
      await manager.playFromVerse(1, 1, 1);
      expect(mockPlayer.setAudioSourceCalls, 2);
      expect(mockPlayer.lastInitialPosition, Duration.zero);
    });

    test('skipToNextVerse and skipToPreviousVerse respect timings and 2-second rule', () async {
      await audioHandler.playChapter(43, 10);
      expect(manager.currentVerseNotifier.value, isNull); // announcement

      // Announcement -> Next Verse goes to verse 1 start
      await manager.skipToNextVerse();
      await Future<void>.delayed(Duration.zero);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 4700));
      expect(manager.currentVerseNotifier.value, 1);

      // Verse 1 -> Next Verse goes to verse 2 start
      await manager.skipToNextVerse();
      await Future<void>.delayed(Duration.zero);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 12950));
      expect(manager.currentVerseNotifier.value, 2);

      // > 2s into verse 2 -> Previous restarts verse 2
      mockPlayer.emitPosition(const Duration(milliseconds: 15500));
      await manager.skipToPreviousVerse();
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 12950));

      // <= 2s into verse 2 -> Previous goes to verse 1
      await manager.skipToPreviousVerse();
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 4700));
    });

    test('MediaItem artist updates on verse change do not re-trigger onChapterChanged', () async {
      int chapterNotifications = 0;
      manager.onChapterChanged = (b, c) {
        chapterNotifications++;
      };

      await audioHandler.playChapter(43, 10);
      await Future<void>.delayed(Duration.zero);
      expect(chapterNotifications, 1);
      expect(audioHandler.mediaItem.value?.title, 'John 10');
      expect(audioHandler.mediaItem.value?.artist, isNull);

      mockPlayer.emitPosition(const Duration(milliseconds: 5000));
      await Future<void>.delayed(Duration.zero);
      expect(audioHandler.mediaItem.value?.artist, 'Verse 1');
      expect(chapterNotifications, 1);

      mockPlayer.emitPosition(const Duration(milliseconds: 13500));
      await Future<void>.delayed(Duration.zero);
      expect(audioHandler.mediaItem.value?.artist, 'Verse 2');
      expect(chapterNotifications, 1);

      // Back to announcement clears artist without firing onChapterChanged
      mockPlayer.emitPosition(const Duration(milliseconds: 1000));
      await Future<void>.delayed(Duration.zero);
      expect(audioHandler.mediaItem.value?.artist, isNull);
      expect(chapterNotifications, 1);
    });

    test('repeatVerse loops back to verse start_ms (skipping announcement for v1) and loops last verse on completion', () async {
      await audioHandler.playChapter(43, 10);
      manager.setPlayMode(AudioPlayMode.repeatVerse);

      // Move into verse 1, then past verse 1 end -> loops back to v1 start_ms (4.7s), not 0:00
      await manager.seek(const Duration(milliseconds: 6000));
      mockPlayer.emitPosition(const Duration(milliseconds: 13000));
      await Future<void>.delayed(Duration.zero);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 4700));

      // Seek to last verse (v3) and emit completed -> seeks back to v3 start_ms (16.69s) and stays on John 10
      await manager.seek(const Duration(milliseconds: 18000));
      mockPlayer.emitCompleted();
      await Future<void>.delayed(Duration.zero);
      expect(audioHandler.currentBookId, 43);
      expect(audioHandler.currentChapter, 10);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 16690));
      expect(mockPlayer.isPlaying, isTrue);
    });

    test('pauseBetweenVerses persists, enforces 1.0x speed, and clears on normal speed', () async {
      await manager.setSpeed(1.5);
      expect(manager.pauseBetweenVersesEnabledNotifier.value, isFalse);

      await manager.setPauseBetweenVerses(enabled: true, seconds: 8);
      expect(manager.pauseBetweenVersesEnabledNotifier.value, isTrue);
      expect(manager.pauseBetweenVersesSecondsNotifier.value, 8);
      expect(manager.speedNotifier.value, 1.0);
      expect(mockPlayer.currentSpeed, 1.0);
      expect(userSettings.audioPauseBetweenVersesEnabled, isTrue);
      expect(userSettings.audioPauseBetweenVersesSeconds, 8);

      // Clamping checks
      await manager.setPauseBetweenVerses(enabled: true, seconds: 120);
      expect(userSettings.audioPauseBetweenVersesSeconds, kMaxVersePauseSeconds);

      // Selecting standard speed disables pauseBetweenVerses
      await manager.setSpeed(1.25);
      expect(manager.pauseBetweenVersesEnabledNotifier.value, isFalse);
      expect(userSettings.audioPauseBetweenVersesEnabled, isFalse);
      expect(mockPlayer.currentSpeed, 1.25);
    });

    test('pauseBetweenVerses plays verse 1 immediately, pauses with silence after v1, and resumes at v2', () async {
      await manager.setPauseBetweenVerses(enabled: true, seconds: 2);
      await audioHandler.playChapter(43, 10);
      expect(mockPlayer.isPlaying, isTrue);

      // Enter verse 1, then cross verse 1 end boundary (12950 ms)
      mockPlayer.emitPosition(const Duration(milliseconds: 6000));
      await Future<void>.delayed(Duration.zero);
      expect(manager.versePauseStateNotifier.value.isPaused, isFalse);

      mockPlayer.emitPosition(const Duration(milliseconds: 13000));
      await Future<void>.delayed(Duration.zero);

      // Main player paused & pre-seeked to verse 2 start; silence player plays; UI stays "playing"
      expect(mockPlayer.isPlaying, isFalse);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 12950));
      expect(mockSilencePlayer.isPlaying, isTrue);
      expect(mockSilencePlayer.currentLoopMode, LoopMode.one);
      expect(audioHandler.playbackState.value.playing, isTrue);
      expect(manager.versePauseStateNotifier.value.isPaused, isTrue);
      expect(manager.versePauseStateNotifier.value.remainingSeconds, 2);
      expect(manager.currentVerseNotifier.value, 2);
      expect(audioHandler.mediaItem.value?.artist, 'Next: Verse 2 (2s)');

      // After >2s countdown finishes, silence pauses and main player resumes at verse 2 start
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      expect(mockSilencePlayer.isPlaying, isFalse);
      expect(mockPlayer.isPlaying, isTrue);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 12950));
      expect(manager.versePauseStateNotifier.value.isPaused, isFalse);
      expect(audioHandler.mediaItem.value?.artist, 'Verse 2');
    });

    test('pausing manually during between-verse pause cancels silence and parks at upcoming verse', () async {
      await manager.setPauseBetweenVerses(enabled: true, seconds: 5);
      await audioHandler.playChapter(43, 10);
      mockPlayer.emitPosition(const Duration(milliseconds: 6000));
      mockPlayer.emitPosition(const Duration(milliseconds: 13000));
      await Future<void>.delayed(Duration.zero);

      expect(audioHandler.isInVersePause, isTrue);
      expect(mockSilencePlayer.isPlaying, isTrue);

      await manager.pause();
      await Future<void>.delayed(Duration.zero);

      expect(audioHandler.isInVersePause, isFalse);
      expect(mockSilencePlayer.isPlaying, isFalse);
      expect(mockPlayer.isPlaying, isFalse);
      expect(audioHandler.playbackState.value.playing, isFalse);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 12950));
    });

    test('repeatPassage loops single-chapter and cross-chapter passages cleanly', () async {
      // Single-chapter: John 10:1-2
      final singlePassage = Reference(
        bookId: 43,
        chapter: 10,
        verse: 1,
        endVerse: 2,
      );
      await manager.setRepeatPassage(singlePassage);
      await Future<void>.delayed(Duration.zero);

      expect(manager.playModeNotifier.value, AudioPlayMode.repeatPassage);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 4700)); // v1 start, skipping announcement
      expect(userSettings.audioRepeatPassage, singlePassage);

      // Move into v2, then pass v2 end (16690ms) -> loops to v1 start (4700ms)
      mockPlayer.emitPosition(const Duration(milliseconds: 13500));
      mockPlayer.emitPosition(const Duration(milliseconds: 16800));
      await Future<void>.delayed(Duration.zero);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 4700));

      // Cross-chapter: John 10:2-11:1
      final crossPassage = Reference(
        bookId: 43,
        chapter: 10,
        verse: 2,
        endChapter: 11,
        endVerse: 1,
      );
      await manager.setRepeatPassage(crossPassage, forceRestart: true);
      await Future<void>.delayed(Duration.zero);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 12950));

      // Advance into last verse (John 10:3, ends at 24830ms) and finish -> moves to John 11:1 start (4000ms)
      mockPlayer.emitPosition(const Duration(milliseconds: 17000));
      mockPlayer.emitPosition(const Duration(milliseconds: 25000));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(audioHandler.currentChapter, 11);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 4000));

      // Finish John 11:1 -> loops back to John 10:2 start (12950ms)
      mockPlayer.emitPosition(const Duration(milliseconds: 10100));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(audioHandler.currentChapter, 10);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 12950));

      // Chapter Skip exits Repeat Passage back to Continuous
      await manager.skipToNext();
      await Future<void>.delayed(Duration.zero);
      expect(manager.playModeNotifier.value, AudioPlayMode.continuous);
      expect(audioHandler.currentChapter, 11);
      expect(userSettings.audioPlayMode, 'continuous');
    });

    test('playSelection enables repeatVerse for 1 verse and repeatPassage for 2+ verses', () async {
      await manager.playSelection(Reference(bookId: 43, chapter: 10, verse: 2));
      await Future<void>.delayed(Duration.zero);
      expect(manager.playModeNotifier.value, AudioPlayMode.repeatVerse);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 12950));

      final multi = Reference(bookId: 43, chapter: 10, verse: 1, endVerse: 2);
      await manager.playSelection(multi);
      await Future<void>.delayed(Duration.zero);
      expect(manager.playModeNotifier.value, AudioPlayMode.repeatPassage);
      expect(manager.repeatPassageNotifier.value, multi);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 4700));
    });

    test('UserSettings validates and round-trips repeatPassage including corrupt fallback', () async {
      final cross = Reference(
        bookId: 43,
        chapter: 10,
        verse: 2,
        endChapter: 11,
        endVerse: 1,
      );
      await userSettings.setAudioRepeatPassage(cross);
      expect(userSettings.audioRepeatPassage, cross);

      final wholeChapters = Reference(
        bookId: 43,
        chapter: 10,
        endChapter: 11,
      );
      await userSettings.setAudioRepeatPassage(wholeChapters);
      expect(userSettings.audioRepeatPassage, wholeChapters);

      // Corrupt out-of-range book returns null cleanly
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('audioRepeatPassageStartVerse', 99001001);
      expect(userSettings.audioRepeatPassage, isNull);
    });

    test('pauseBetweenVerses works with just_audio play() future contract and avoids boundary double-pause', () async {
      mockPlayer.holdPlayFutureUntilPaused = true;
      mockSilencePlayer.holdPlayFutureUntilPaused = true;

      await manager.setPauseBetweenVerses(enabled: true, seconds: 1);
      await audioHandler.playChapter(43, 10);
      expect(mockPlayer.isPlaying, isTrue);

      // Enter verse 1, then cross end boundary (12950 ms)
      mockPlayer.emitPosition(const Duration(milliseconds: 6000));
      mockPlayer.emitPosition(const Duration(milliseconds: 13000));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(mockPlayer.isPlaying, isFalse);
      expect(mockSilencePlayer.isPlaying, isTrue);
      expect(audioHandler.isInVersePause, isTrue);

      // Countdown finishes even when silencePlayer.play() never resolved on its own
      await Future<void>.delayed(const Duration(milliseconds: 1150));
      expect(mockSilencePlayer.isPlaying, isFalse);
      expect(mockPlayer.isPlaying, isTrue);
      expect(audioHandler.isInVersePause, isFalse);

      // Simulate MP3 frame alignment landing 15ms before boundary right after resume -> no second pause
      mockPlayer.emitPosition(const Duration(milliseconds: 12935));
      mockPlayer.emitPosition(const Duration(milliseconds: 12960));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(audioHandler.isInVersePause, isFalse);
      expect(mockPlayer.isPlaying, isTrue);
    });
  });
}
