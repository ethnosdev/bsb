import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:bsb/infrastructure/audio/audio_url_resolver.dart';
import 'package:just_audio/just_audio.dart';

class BsbAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;
  final AudioUrlResolver _urlResolver;

  int? _currentBookId;
  int? _currentChapter;
  StreamSubscription<PlaybackEvent>? _eventSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  int? get currentBookId => _currentBookId;
  int? get currentChapter => _currentChapter;
  AudioPlayer get player => _player;

  BsbAudioHandler({
    AudioPlayer? player,
    AudioUrlResolver? urlResolver,
  })  : _player = player ?? AudioPlayer(),
        _urlResolver = urlResolver ?? const AudioUrlResolver() {
    _init();
  }

  void _init() {
    _initAudioSession();

    // Map playback events to AudioService PlaybackState
    _eventSubscription = _player.playbackEventStream.listen(_broadcastState);

    // Auto-advance to next chapter when current playback completes
    _stateSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
    } catch (_) {
      // AudioSession may not be available on all platforms/environments (e.g. desktop/test)
    }
  }

  void _broadcastState([PlaybackEvent? event]) {
    final playing = _player.playing;
    final processingState = _player.processingState;

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  /// Plays the audio for the specified book and chapter.
  Future<void> playChapter(int bookId, int chapter) async {
    _currentBookId = bookId;
    _currentChapter = chapter;

    final url = _urlResolver.getChapterUrl(bookId, chapter);
    final title = _urlResolver.getChapterTitle(bookId, chapter);

    final item = MediaItem(
      id: url,
      album: 'Berean Standard Bible',
      title: title,
      artist: 'David Souer',
      extras: {
        'bookId': bookId,
        'chapter': chapter,
      },
    );
    mediaItem.add(item);

    try {
      final duration = await _player.setAudioSource(
        AudioSource.uri(Uri.parse(url)),
      );
      if (duration != null) {
        mediaItem.add(item.copyWith(duration: duration));
      }
      await _player.play();
    } catch (e) {
      // Error loading stream
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.idle,
          playing: false,
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_currentBookId == null || _currentChapter == null) return;
    final next = _urlResolver.getNextChapter(_currentBookId!, _currentChapter!);
    if (next != null) {
      await playChapter(next.$1, next.$2);
    } else {
      await stop();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_currentBookId == null || _currentChapter == null) return;
    // If we've played for more than 3 seconds, replay from start of current chapter
    if (_player.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }
    final prev = _urlResolver.getPreviousChapter(_currentBookId!, _currentChapter!);
    if (prev != null) {
      await playChapter(prev.$1, prev.$2);
    } else {
      await seek(Duration.zero);
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await _stateSubscription?.cancel();
    await _player.dispose();
  }
}
