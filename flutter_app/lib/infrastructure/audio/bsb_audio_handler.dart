import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:bsb/infrastructure/audio/audio_models.dart';
import 'package:bsb/infrastructure/audio/audio_url_resolver.dart';
import 'package:bsb/infrastructure/audio/verse_timings.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

typedef ChapterTimingsLoader =
    Future<ChapterTimings> Function(int bookId, int chapter);

class BsbAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;
  final AudioUrlResolver _urlResolver;
  final ChapterTimingsLoader? timingsLoader;

  int? _currentBookId;
  int? _currentChapter;
  ChapterTimings? _currentTimings;
  AudioPlayMode _playMode = AudioPlayMode.continuous;
  bool stopAtEndOfChapter = false;
  VoidCallback? onSleepTimerFired;

  int? _repeatVerseTarget;
  bool _isLoopSeeking = false;
  Timer? _repeatVerseTimer;

  final BehaviorSubject<int?> _currentVerseSubject = BehaviorSubject<int?>.seeded(
    null,
  );

  StreamSubscription<PlaybackEvent>? _eventSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  int? get currentBookId => _currentBookId;
  int? get currentChapter => _currentChapter;
  ChapterTimings? get currentTimings => _currentTimings;
  int? get currentVerse => _currentVerseSubject.value;
  ValueStream<int?> get currentVerseStream => _currentVerseSubject.stream;
  AudioPlayer get player => _player;

  AudioPlayMode get playMode => _playMode;
  set playMode(AudioPlayMode value) {
    if (_playMode == value) return;
    _playMode = value;
    if (value == AudioPlayMode.repeatVerse) {
      _repeatVerseTarget = _resolveLoopVerse(_player.position);
    } else {
      _repeatVerseTarget = null;
    }
    _syncRepeatVerseTimer();
  }

  BsbAudioHandler({
    AudioPlayer? player,
    AudioUrlResolver? urlResolver,
    this.timingsLoader,
  }) : _player = player ?? AudioPlayer(),
       _urlResolver = urlResolver ?? const AudioUrlResolver() {
    _init();
  }

  void _init() {
    _initAudioSession();

    // Map playback events to AudioService PlaybackState
    _eventSubscription = _player.playbackEventStream.listen(_broadcastState);
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      _broadcastState();
      _syncRepeatVerseTimer(playing: state.playing);
    });
    _positionSubscription = _player.positionStream.listen(_onPositionUpdated);

    // Auto-advance or repeat when current playback completes
    _stateSubscription = _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        if (stopAtEndOfChapter) {
          stopAtEndOfChapter = false;
          onSleepTimerFired?.call();
          final target = _playMode == AudioPlayMode.repeatVerse
              ? _resolveLastVerseStart()
              : Duration.zero;
          await pause();
          await seek(target);
          return;
        }

        switch (_playMode) {
          case AudioPlayMode.repeatVerse:
            final target = _resolveLastVerseStart();
            await seek(target);
            await play();
            break;
          case AudioPlayMode.repeatChapter:
            await seek(Duration.zero);
            await play();
            break;
          case AudioPlayMode.stopAfterChapter:
            await pause();
            await seek(Duration.zero);
            break;
          case AudioPlayMode.continuous:
            try {
              await skipToNext();
            } catch (_) {
              await stop();
            }
            break;
        }
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

  void _syncRepeatVerseTimer({bool? playing}) {
    final shouldRun =
        _playMode == AudioPlayMode.repeatVerse && (playing ?? _player.playing);
    if (shouldRun && _repeatVerseTimer == null) {
      // Poll every 50 ms so repeat-verse loops cleanly without leaking into the next verse.
      _repeatVerseTimer = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) => _onPositionUpdated(_player.position),
      );
    } else if (!shouldRun && _repeatVerseTimer != null) {
      _repeatVerseTimer?.cancel();
      _repeatVerseTimer = null;
    }
  }

  Duration _resolveLastVerseStart() {
    final timings = _currentTimings;
    if (timings == null || timings.isEmpty) return Duration.zero;
    final targetVerse = _repeatVerseTarget ?? timings.verses.last.verse;
    return timings.timingFor(targetVerse)?.start ?? timings.verses.last.start;
  }

  int? _resolveLoopVerse(Duration position) {
    final timings = _currentTimings;
    if (timings == null || timings.isEmpty) return null;
    return timings.verseAt(position) ?? timings.verses.first.verse;
  }

  Future<ChapterTimings> _loadTimings(int bookId, int chapter) async {
    try {
      if (timingsLoader != null) {
        return await timingsLoader!(bookId, chapter);
      }
      if (getIt.isRegistered<DatabaseHelper>()) {
        return await getIt<DatabaseHelper>().getChapterTimings(bookId, chapter);
      }
    } catch (_) {
      // Gracefully degrade if timings aren't available (e.g. in minimal tests).
    }
    return ChapterTimings.empty(bookId, chapter);
  }

  void _onPositionUpdated(Duration position) {
    final timings = _currentTimings;
    final verse = timings?.verseAt(position);
    if (verse != _currentVerseSubject.value) {
      _currentVerseSubject.add(verse);
      _updateMediaItemArtist(verse);
    }

    if (_playMode == AudioPlayMode.repeatVerse &&
        !_isLoopSeeking &&
        timings != null &&
        !timings.isEmpty) {
      final targetVerse = _repeatVerseTarget ?? _resolveLoopVerse(position);
      if (targetVerse != null) {
        final vt = timings.timingFor(targetVerse);
        if (vt != null && position >= vt.end) {
          _handleLoopBoundary(vt.start);
        }
      }
    }
  }

  Future<void> _handleLoopBoundary(Duration loopStart) async {
    _isLoopSeeking = true;
    try {
      if (stopAtEndOfChapter) {
        stopAtEndOfChapter = false;
        onSleepTimerFired?.call();
        await _player.pause();
        await _player.seek(loopStart);
        _onPositionUpdated(loopStart);
        _broadcastState();
        return;
      }
      await _player.seek(loopStart);
      _onPositionUpdated(loopStart);
      _broadcastState();
    } finally {
      _isLoopSeeking = false;
    }
  }

  void _updateMediaItemArtist(int? verse) {
    final current = mediaItem.value;
    if (current == null) return;
    final newArtist = verse != null ? 'Verse $verse' : null;
    if (current.artist == newArtist) return;
    // Construct a fresh MediaItem so setting artist back to null during the
    // chapter announcement clears the previous verse label.
    mediaItem.add(
      MediaItem(
        id: current.id,
        album: current.album,
        title: current.title,
        artist: newArtist,
        duration: current.duration,
        extras: current.extras,
      ),
    );
  }

  void _broadcastState([PlaybackEvent? event]) {
    final playing = _player.playing;
    final processingState = _player.processingState;

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.fastForward,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.setSpeed,
        },
        androidCompactActionIndices: const [0, 2, 4],
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
  Future<void> playChapter(
    int bookId,
    int chapter, {
    Duration? initialPosition,
    ChapterTimings? preloadedTimings,
  }) async {
    _currentBookId = bookId;
    _currentChapter = chapter;
    _currentTimings = null;
    _repeatVerseTarget = null;
    _currentVerseSubject.add(null);

    final timings = preloadedTimings ?? await _loadTimings(bookId, chapter);
    if (_currentBookId != bookId || _currentChapter != chapter) return;
    _currentTimings = timings;

    final startPos = initialPosition ?? Duration.zero;
    final initialVerse = timings.verseAt(startPos);
    _currentVerseSubject.add(initialVerse);
    if (_playMode == AudioPlayMode.repeatVerse) {
      _repeatVerseTarget = _resolveLoopVerse(startPos);
    }

    final url = _urlResolver.getChapterUrl(bookId, chapter);
    final title = _urlResolver.getChapterTitle(bookId, chapter);

    final item = MediaItem(
      id: url,
      album: 'Berean Standard Bible',
      title: title,
      artist: initialVerse != null ? 'Verse $initialVerse' : null,
      extras: {'bookId': bookId, 'chapter': chapter},
    );
    mediaItem.add(item);

    try {
      final duration = await _player.setAudioSource(
        AudioSource.uri(Uri.parse(url)),
        initialPosition: initialPosition,
      );
      if (duration != null) {
        final latest = mediaItem.value ?? item;
        mediaItem.add(latest.copyWith(duration: duration));
      }
      await _player.play();
      _syncRepeatVerseTimer(playing: true);
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

  /// Starts playback at [verse] within [bookId] and [chapter].
  /// Verse 1 starts at 0:00 so the spoken chapter announcement is included.
  Future<void> playFromVerse(int bookId, int chapter, int verse) async {
    if (_currentBookId == bookId && _currentChapter == chapter) {
      final timings = _currentTimings ?? await _loadTimings(bookId, chapter);
      _currentTimings = timings;
      final target = verse <= 1
          ? Duration.zero
          : (timings.timingFor(verse)?.start ?? Duration.zero);
      await seek(target);
      if (!_player.playing) {
        await play();
      }
      return;
    }

    final timings = await _loadTimings(bookId, chapter);
    final target = verse <= 1
        ? Duration.zero
        : (timings.timingFor(verse)?.start ?? Duration.zero);
    await playChapter(
      bookId,
      chapter,
      initialPosition: target,
      preloadedTimings: timings,
    );
  }

  /// Seeks to the next verse in the current chapter, if one exists.
  Future<void> skipToNextVerse() async {
    final target = _currentTimings?.nextSeekTarget(_player.position);
    if (target != null) {
      await seek(target);
    }
  }

  /// Seeks to the start of the current verse (>2s in) or the previous verse.
  Future<void> skipToPreviousVerse() async {
    final target = _currentTimings?.previousSeekTarget(_player.position);
    if (target != null) {
      await seek(target);
    }
  }

  bool hasNextVerse(Duration position) {
    return _currentTimings?.nextSeekTarget(position) != null;
  }

  bool hasPreviousVerse(Duration position) {
    final timings = _currentTimings;
    if (timings == null || timings.isEmpty) return false;
    return position > Duration.zero;
  }

  @override
  Future<void> play() async {
    await _player.play();
    _syncRepeatVerseTimer(playing: true);
    _broadcastState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _syncRepeatVerseTimer(playing: false);
    _broadcastState();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_playMode == AudioPlayMode.repeatVerse) {
      _repeatVerseTarget = _resolveLoopVerse(position);
    }
    await _player.seek(position);
    _onPositionUpdated(position);
    _broadcastState();
  }

  /// Seeks relative to current playback position (e.g. +10s or -10s).
  Future<void> seekRelative(Duration offset) async {
    final current = _player.position;
    final total = _player.duration ?? Duration.zero;
    var target = current + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (total > Duration.zero && target > total) target = total;
    await seek(target);
  }

  @override
  Future<void> fastForward() => seekRelative(const Duration(seconds: 10));

  @override
  Future<void> rewind() => seekRelative(const Duration(seconds: -10));

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    _broadcastState();
  }

  @override
  Future<void> stop() async {
    _syncRepeatVerseTimer(playing: false);
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
    final prev = _urlResolver.getPreviousChapter(
      _currentBookId!,
      _currentChapter!,
    );
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
    _repeatVerseTimer?.cancel();
    _repeatVerseTimer = null;
    await _positionSubscription?.cancel();
    await _eventSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _stateSubscription?.cancel();
    await _currentVerseSubject.close();
    await _player.dispose();
  }
}
