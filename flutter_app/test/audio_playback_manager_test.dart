import 'dart:async';

import 'package:audio_service/audio_service.dart';
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
      expect(manager.playContextNotifier.value, AudioPlayContext.chapter);
      expect(
        manager.repeatBehaviorNotifier.value,
        AudioRepeatBehavior.continueOn,
      );
      expect(manager.audioTabIdNotifier.value, isNull);
    });

    test('setRepeatBehavior in Chapter context persists and migrates legacy keys', () {
      expect(
        AudioRepeatBehavior.fromString('continuous'),
        AudioRepeatBehavior.continueOn,
      );
      expect(
        AudioRepeatBehavior.fromString('repeatChapter'),
        AudioRepeatBehavior.repeat,
      );
      expect(
        AudioRepeatBehavior.fromString('stopAfterChapter'),
        AudioRepeatBehavior.stop,
      );

      manager.setRepeatBehavior(AudioRepeatBehavior.repeat);
      expect(
        manager.repeatBehaviorNotifier.value,
        AudioRepeatBehavior.repeat,
      );
      expect(audioHandler.repeatBehavior, AudioRepeatBehavior.repeat);
      expect(userSettings.audioPlayMode, 'repeat');

      manager.setRepeatBehavior(AudioRepeatBehavior.stop);
      expect(userSettings.audioPlayMode, 'stop');

      // Transient Repeat changes in Verse context do not overwrite chapter-level preference
      manager.setPlayContext(AudioPlayContext.verse);
      manager.setRepeatBehavior(AudioRepeatBehavior.continueOn);
      expect(userSettings.audioPlayMode, 'stop');
    });

    test('setSpeed updates handler, notifier, and persists to userSettings', () async {
      await manager.setSpeed(1.5);
      expect(manager.speedNotifier.value, 1.5);
      expect(mockPlayer.currentSpeed, 1.5);
      expect(userSettings.audioSpeed, 1.5);
    });

    test('closePlayer clears audioTabIdNotifier and hides player', () async {
      manager.audioTabIdNotifier.value = 'tab-1';
      manager.isPlayerVisible.value = true;
      await manager.closePlayer();
      expect(manager.isPlayerVisible.value, isFalse);
      expect(manager.audioTabIdNotifier.value, isNull);
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

    test('MediaItem title updates on verse change do not re-trigger onChapterChanged', () async {
      int chapterNotifications = 0;
      manager.onChapterChanged = (b, c) {
        chapterNotifications++;
      };

      await audioHandler.playChapter(43, 10);
      await Future<void>.delayed(Duration.zero);
      expect(chapterNotifications, 1);
      expect(audioHandler.mediaItem.value?.title, 'John 10');
      expect(audioHandler.mediaItem.value?.artist, 'Berean Standard Bible');

      mockPlayer.emitPosition(const Duration(milliseconds: 5000));
      await Future<void>.delayed(Duration.zero);
      expect(audioHandler.mediaItem.value?.title, 'John 10:1');
      expect(audioHandler.mediaItem.value?.artist, 'Berean Standard Bible');
      expect(chapterNotifications, 1);

      mockPlayer.emitPosition(const Duration(milliseconds: 13500));
      await Future<void>.delayed(Duration.zero);
      expect(audioHandler.mediaItem.value?.title, 'John 10:2');
      expect(chapterNotifications, 1);

      // Back to announcement restores plain chapter title without firing onChapterChanged
      mockPlayer.emitPosition(const Duration(milliseconds: 1000));
      await Future<void>.delayed(Duration.zero);
      expect(audioHandler.mediaItem.value?.title, 'John 10');
      expect(chapterNotifications, 1);
    });

    test('Verse context with Repeat loops verse and Continue advances to Chapter context', () async {
      await audioHandler.playChapter(43, 10);
      await manager.setPlayContext(AudioPlayContext.verse);
      manager.setRepeatBehavior(AudioRepeatBehavior.repeat);

      // Move into verse 1, then past verse 1 end -> loops back to v1 start_ms (4.7s), not 0:00
      await manager.seek(const Duration(milliseconds: 6000));
      mockPlayer.emitPosition(const Duration(milliseconds: 13000));
      await Future<void>.delayed(Duration.zero);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 4700));
      expect(manager.playContextNotifier.value, AudioPlayContext.verse);

      // Seek to last verse (v3) and emit completed -> seeks back to v3 start_ms (16.69s)
      await manager.seek(const Duration(milliseconds: 18000));
      mockPlayer.emitCompleted();
      await Future<void>.delayed(Duration.zero);
      expect(audioHandler.currentBookId, 43);
      expect(audioHandler.currentChapter, 10);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 16690));
      expect(mockPlayer.isPlaying, isTrue);

      // Switching to Continue advances past verse 1 end into Chapter context seamlessly
      await manager.seek(const Duration(milliseconds: 6000));
      manager.setRepeatBehavior(AudioRepeatBehavior.continueOn);
      mockPlayer.emitPosition(const Duration(milliseconds: 13000));
      await Future<void>.delayed(Duration.zero);
      expect(manager.playContextNotifier.value, AudioPlayContext.chapter);
      expect(mockPlayer.isPlaying, isTrue);
    });

    test('pauseBetweenVerses and speed persist and operate independently', () async {
      await manager.setSpeed(1.5);
      expect(manager.speedNotifier.value, 1.5);
      expect(manager.pauseBetweenVersesEnabledNotifier.value, isFalse);

      await manager.setPauseBetweenVerses(enabled: true, seconds: 8);
      expect(manager.pauseBetweenVersesEnabledNotifier.value, isTrue);
      expect(manager.pauseBetweenVersesSecondsNotifier.value, 8);
      expect(manager.speedNotifier.value, 1.5);
      expect(mockPlayer.currentSpeed, 1.5);
      expect(userSettings.audioPauseBetweenVersesEnabled, isTrue);
      expect(userSettings.audioPauseBetweenVersesSeconds, 8);

      // Clamping checks
      await manager.setPauseBetweenVerses(enabled: true, seconds: 120);
      expect(userSettings.audioPauseBetweenVersesSeconds, kMaxVersePauseSeconds);

      // Changing speed leaves pauseBetweenVerses enabled
      await manager.setSpeed(1.25);
      expect(manager.pauseBetweenVersesEnabledNotifier.value, isTrue);
      expect(userSettings.audioPauseBetweenVersesEnabled, isTrue);
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
      expect(audioHandler.mediaItem.value?.title, 'John 10:2 (2s)');
      expect(audioHandler.mediaItem.value?.artist, 'Berean Standard Bible');

      // After >2s countdown finishes, silence pauses and main player resumes at verse 2 start
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      expect(mockSilencePlayer.isPlaying, isFalse);
      expect(mockPlayer.isPlaying, isTrue);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 12950));
      expect(manager.versePauseStateNotifier.value.isPaused, isFalse);
      expect(audioHandler.mediaItem.value?.title, 'John 10:2');
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

    test('changing pause duration mid-countdown restarts countdown with new duration', () async {
      await manager.setPauseBetweenVerses(enabled: true, seconds: 2);
      await audioHandler.playChapter(43, 10);
      mockPlayer.emitPosition(const Duration(milliseconds: 6000));
      mockPlayer.emitPosition(const Duration(milliseconds: 13000));
      await Future<void>.delayed(Duration.zero);

      expect(audioHandler.isInVersePause, isTrue);
      expect(manager.versePauseStateNotifier.value.remainingSeconds, 2);

      // Update duration to 3s mid-countdown -> restarts at 3s
      await manager.setPauseBetweenVerses(enabled: true, seconds: 3);
      expect(manager.versePauseStateNotifier.value.isPaused, isTrue);
      expect(manager.versePauseStateNotifier.value.totalSeconds, 3);
      expect(manager.versePauseStateNotifier.value.remainingSeconds, 3);

      // After 2.2s (past old 2s deadline), still paused with 1s remaining
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      expect(audioHandler.isInVersePause, isTrue);
      expect(manager.versePauseStateNotifier.value.remainingSeconds, 1);
      expect(mockPlayer.isPlaying, isFalse);

      // After final ~1s tick completes, narrator resumes
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(audioHandler.isInVersePause, isFalse);
      expect(mockPlayer.isPlaying, isTrue);
    });

    test('Range context supports Stop, Repeat (single/cross-chapter), Continue, and Chapter Skip reset', () async {
      // Single-chapter selection from long-press starts in (Range, Stop) and stops after end
      final singleRange = Reference(
        bookId: 43,
        chapter: 10,
        verse: 1,
        endVerse: 2,
      );
      await manager.playSelection(singleRange);
      await Future<void>.delayed(Duration.zero);

      expect(manager.playContextNotifier.value, AudioPlayContext.range);
      expect(manager.repeatBehaviorNotifier.value, AudioRepeatBehavior.stop);
      expect(manager.activeRangeNotifier.value, singleRange);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 4700)); // v1 start, skipping announcement
      expect(mockPlayer.isPlaying, isTrue);

      // Finish verse 2 -> stops cleanly at range start (4700ms)
      mockPlayer.emitPosition(const Duration(milliseconds: 13500));
      mockPlayer.emitPosition(const Duration(milliseconds: 16800));
      await Future<void>.delayed(Duration.zero);
      expect(mockPlayer.isPlaying, isFalse);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 4700));

      // Switch to Repeat -> loops cross-chapter range John 10:2-11:1 cleanly
      final crossRange = Reference(
        bookId: 43,
        chapter: 10,
        verse: 2,
        endChapter: 11,
        endVerse: 1,
      );
      await manager.playSelection(crossRange);
      manager.setRepeatBehavior(AudioRepeatBehavior.repeat);
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

      // Switch to Continue -> passing end transitions Context to Chapter cleanly
      manager.setRepeatBehavior(AudioRepeatBehavior.continueOn);
      mockPlayer.emitPosition(const Duration(milliseconds: 17000));
      mockPlayer.emitPosition(const Duration(milliseconds: 25000));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(audioHandler.currentChapter, 11);
      mockPlayer.emitPosition(const Duration(milliseconds: 10100));
      await Future<void>.delayed(Duration.zero);
      expect(manager.playContextNotifier.value, AudioPlayContext.chapter);

      // System player skipToNext skips verse within Range (preserving Range mode),
      // while navigating chapters resets activeRange and restores saved chapter Repeat preference.
      manager.setRepeatBehavior(AudioRepeatBehavior.repeat);
      await manager.playSelection(singleRange);
      expect(manager.playContextNotifier.value, AudioPlayContext.range);
      await audioHandler.skipToNext();
      await Future<void>.delayed(Duration.zero);
      expect(manager.playContextNotifier.value, AudioPlayContext.range);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 12950));

      await manager.navigateTabToChapter(43, 11);
      await Future<void>.delayed(Duration.zero);
      expect(manager.playContextNotifier.value, AudioPlayContext.chapter);
      expect(manager.activeRangeNotifier.value, isNull);
      expect(manager.repeatBehaviorNotifier.value, AudioRepeatBehavior.repeat);
      expect(audioHandler.currentChapter, 11);
    });

    test('OS player mirrors app controls and syncs speed, pause, and stop back to manager', () async {
      final localPlayer = MockAudioPlayer();
      final localSilencePlayer = MockAudioPlayer();
      final artUri = Uri.file('/tmp/test_logo.png');
      final customHandler = BsbAudioHandler(
        player: localPlayer,
        silencePlayer: localSilencePlayer,
        artworkUriLoader: () async => artUri,
        timingsLoader: (bookId, chapter) async {
          if (bookId == 43 && chapter == 10) {
            return const ChapterTimings(
              bookId: 43,
              chapter: 10,
              verses: [
                VerseTiming(verse: 1, start: Duration(seconds: 4), end: Duration(seconds: 12)),
                VerseTiming(verse: 2, start: Duration(seconds: 12), end: Duration(seconds: 18)),
              ],
            );
          }
          return ChapterTimings.empty(bookId, chapter);
        },
      );
      final customManager = AudioPlaybackManager(
        audioHandler: customHandler,
        userSettings: userSettings,
      );

      await customManager.playOrToggleChapter(43, 10);
      await Future<void>.delayed(Duration.zero);

      expect(customHandler.mediaItem.value?.artUri, artUri);
      expect(customHandler.playbackState.value.controls, const [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
      ]);
      expect(customHandler.playbackState.value.systemActions, const {
        MediaAction.seek,
        MediaAction.setSpeed,
      });

      // OS skipToNext/skipToPrevious move verse-by-verse
      await customHandler.skipToNext();
      expect(localPlayer.currentPosition, const Duration(seconds: 4));
      await customHandler.skipToNext();
      expect(localPlayer.currentPosition, const Duration(seconds: 12));
      await customHandler.skipToPrevious();
      expect(localPlayer.currentPosition, const Duration(seconds: 4));

      // OS setSpeed syncs speedNotifier & userSettings
      await customHandler.setSpeed(1.5);
      await Future<void>.delayed(Duration.zero);
      expect(customManager.speedNotifier.value, 1.5);
      expect(userSettings.audioSpeed, 1.5);

      // OS pause saves position immediately
      localPlayer.emitPosition(const Duration(seconds: 15));
      await customHandler.pause();
      await Future<void>.delayed(Duration.zero);
      expect(userSettings.lastAudioBookId, 43);
      expect(userSettings.lastAudioChapter, 10);
      expect(userSettings.lastAudioPositionMs, 15000);

      // OS task removal / stop hides player UI
      expect(customManager.isPlayerVisible.value, isTrue);
      await customHandler.onTaskRemoved();
      expect(customManager.isPlayerVisible.value, isFalse);

      customManager.dispose();
      await customHandler.dispose();
    });

    test('playSelection plays 1 verse once; AppBar playOrToggleChapter restores Chapter & saved repeat', () async {
      // Save chapter repeat = repeat
      manager.setRepeatBehavior(AudioRepeatBehavior.repeat);
      expect(userSettings.audioPlayMode, 'repeat');

      // Long-press 1 verse -> Verse + Stop (does not overwrite saved chapter repeat)
      await manager.playSelection(Reference(bookId: 43, chapter: 10, verse: 2));
      await Future<void>.delayed(Duration.zero);
      expect(manager.playContextNotifier.value, AudioPlayContext.verse);
      expect(manager.repeatBehaviorNotifier.value, AudioRepeatBehavior.stop);
      expect(manager.lockedVerseNotifier.value, 2);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 12950));
      expect(userSettings.audioPlayMode, 'repeat');

      // Crossing verse 2 end stops playback cleanly at verse 2 start
      mockPlayer.emitPosition(const Duration(milliseconds: 16800));
      await Future<void>.delayed(Duration.zero);
      expect(mockPlayer.isPlaying, isFalse);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 12950));

      // AppBar Play Audio resets to Chapter and restores saved chapter repeat
      await manager.playOrToggleChapter(43, 10);
      await Future<void>.delayed(Duration.zero);
      expect(manager.playContextNotifier.value, AudioPlayContext.chapter);
      expect(manager.repeatBehaviorNotifier.value, AudioRepeatBehavior.repeat);
      expect(mockPlayer.currentPosition, Duration.zero);
      expect(mockPlayer.isPlaying, isTrue);
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

    test('navigateTabToChapter plays when playing, cues paused when paused, and resets Context to Chapter', () async {
      // Save chapter repeat preference = repeat, then enter a Range + Stop session
      manager.setRepeatBehavior(AudioRepeatBehavior.repeat);
      await manager.playSelection(
        Reference(bookId: 43, chapter: 10, verse: 2, endChapter: 10, endVerse: 3),
      );
      await Future<void>.delayed(Duration.zero);
      expect(manager.playContextNotifier.value, AudioPlayContext.range);
      expect(manager.repeatBehaviorNotifier.value, AudioRepeatBehavior.stop);
      expect(mockPlayer.isPlaying, isTrue);

      // Navigating while playing auto-plays the new chapter and restores Chapter + repeat
      await manager.navigateTabToChapter(43, 11);
      await Future<void>.delayed(Duration.zero);
      expect(audioHandler.currentBookId, 43);
      expect(audioHandler.currentChapter, 11);
      expect(mockPlayer.isPlaying, isTrue);
      expect(mockPlayer.currentPosition, Duration.zero);
      expect(manager.playContextNotifier.value, AudioPlayContext.chapter);
      expect(manager.activeRangeNotifier.value, isNull);
      expect(manager.repeatBehaviorNotifier.value, AudioRepeatBehavior.repeat);

      // Pause playback, then navigate to chapter 10 at verse 2 -> cues paused at verse 2 start
      await manager.pause();
      await Future<void>.delayed(Duration.zero);
      expect(mockPlayer.isPlaying, isFalse);

      await manager.navigateTabToChapter(43, 10, targetVerse: 2);
      await Future<void>.delayed(Duration.zero);
      expect(audioHandler.currentBookId, 43);
      expect(audioHandler.currentChapter, 10);
      expect(mockPlayer.isPlaying, isFalse);
      expect(mockPlayer.currentPosition, const Duration(milliseconds: 12950));
      expect(manager.currentVerseNotifier.value, 2);
    });
  });
}
