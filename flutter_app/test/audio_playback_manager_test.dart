import 'package:bsb/infrastructure/audio/audio_models.dart';
import 'package:bsb/infrastructure/audio/audio_playback_manager.dart';
import 'package:bsb/infrastructure/audio/bsb_audio_handler.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAudioPlayer extends AudioPlayer {
  double currentSpeed = 1.0;
  Duration currentPosition = Duration.zero;
  Duration? currentDuration = const Duration(minutes: 5);
  bool isPlaying = false;

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
  Future<void> play() async {
    isPlaying = true;
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    if (position != null) {
      currentPosition = position;
    }
  }

  @override
  Future<void> stop() async {
    isPlaying = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserSettings userSettings;
  late MockAudioPlayer mockPlayer;
  late BsbAudioHandler audioHandler;
  late AudioPlaybackManager manager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    userSettings = UserSettings();
    await userSettings.init();

    mockPlayer = MockAudioPlayer();
    audioHandler = BsbAudioHandler(player: mockPlayer);
    manager = AudioPlaybackManager(
      audioHandler: audioHandler,
      userSettings: userSettings,
    );
  });

  tearDown(() {
    manager.dispose();
  });

  group('AudioPlaybackManager logic', () {
    test('default settings are loaded from userSettings', () {
      expect(manager.speedNotifier.value, 1.0);
      expect(manager.playModeNotifier.value, AudioPlayMode.continuous);
      expect(manager.syncTextNotifier.value, isTrue);
      expect(manager.sleepTimerOptionNotifier.value, SleepTimerOption.off);
    });

    test('setSpeed updates handler, notifier, and persists to userSettings', () async {
      await manager.setSpeed(1.5);
      expect(manager.speedNotifier.value, 1.5);
      expect(mockPlayer.currentSpeed, 1.5);
      expect(userSettings.audioSpeed, 1.5);
    });

    test('setPlayMode and cyclePlayMode cycle properly and persist', () {
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
      expect(manager.sleepTimerOptionNotifier.value, SleepTimerOption.endOfChapter);
      expect(audioHandler.stopAtEndOfChapter, isTrue);
      expect(manager.sleepTimerRemainingNotifier.value, isNull);

      manager.setSleepTimer(SleepTimerOption.off);
      expect(manager.sleepTimerOptionNotifier.value, SleepTimerOption.off);
      expect(audioHandler.stopAtEndOfChapter, isFalse);
    });

    test('setSleepTimer duration initializes remaining countdown', () {
      manager.setSleepTimer(SleepTimerOption.fifteenMinutes);
      expect(manager.sleepTimerOptionNotifier.value, SleepTimerOption.fifteenMinutes);
      expect(manager.sleepTimerRemainingNotifier.value, const Duration(minutes: 15));

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
  });
}
