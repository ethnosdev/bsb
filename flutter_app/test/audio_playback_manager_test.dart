import 'dart:async';

import 'package:bsb/infrastructure/audio/audio_models.dart';
import 'package:bsb/infrastructure/audio/audio_playback_manager.dart';
import 'package:bsb/infrastructure/audio/bsb_audio_handler.dart';
import 'package:bsb/infrastructure/audio/verse_timings.dart';
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

  @override
  Future<void> play() async {
    isPlaying = true;
    playerStateController.add(PlayerState(true, ProcessingState.ready));
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
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

  late UserSettings userSettings;
  late MockAudioPlayer mockPlayer;
  late BsbAudioHandler audioHandler;
  late AudioPlaybackManager manager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    userSettings = UserSettings();
    await userSettings.init();

    mockPlayer = MockAudioPlayer();
    audioHandler = BsbAudioHandler(
      player: mockPlayer,
      timingsLoader: (bookId, chapter) async {
        if (bookId == 43 && chapter == 10) return john10Timings;
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
  });
}
