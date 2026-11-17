import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:bsb/infrastructure/audio/audio_models.dart';
import 'package:bsb/infrastructure/audio/audio_url_resolver.dart';
import 'package:bsb/infrastructure/audio/verse_timings.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

typedef ChapterTimingsLoader =
    Future<ChapterTimings> Function(int bookId, int chapter);

class _VersePauseTarget {
  final int bookId;
  final int chapter;
  final int? verse;
  final Duration seekPosition;

  const _VersePauseTarget({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.seekPosition,
  });
}

class BsbAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;
  final AudioPlayer? silencePlayer;
  AudioPlayer? _ownedSilencePlayer;
  bool _silenceSourceLoaded = false;

  final AudioUrlResolver _urlResolver;
  final ChapterTimingsLoader? timingsLoader;

  int? _currentBookId;
  int? _currentChapter;
  ChapterTimings? _currentTimings;
  AudioPlayMode _playMode = AudioPlayMode.continuous;
  Reference? repeatPassage;
  bool _pauseBetweenVersesEnabled = false;
  int _pauseBetweenVersesSeconds = kDefaultVersePauseSeconds;

  bool stopAtEndOfChapter = false;
  VoidCallback? onSleepTimerFired;
  ValueChanged<AudioPlayMode>? onPlayModeChanged;

  int? _repeatVerseTarget;
  VerseTiming? _expectedActiveVerse;
  bool _isLoopSeeking = false;
  bool _isInVersePause = false;
  Timer? _verseBoundaryTimer;
  Timer? _versePauseTimer;
  _VersePauseTarget? _pendingPauseTarget;

  final BehaviorSubject<int?> _currentVerseSubject = BehaviorSubject<int?>.seeded(
    null,
  );
  final BehaviorSubject<VersePauseState> _versePauseStateSubject =
      BehaviorSubject<VersePauseState>.seeded(VersePauseState.idle);

  StreamSubscription<PlaybackEvent>? _eventSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  int? get currentBookId => _currentBookId;
  int? get currentChapter => _currentChapter;
  ChapterTimings? get currentTimings => _currentTimings;
  int? get currentVerse => _currentVerseSubject.value;
  ValueStream<int?> get currentVerseStream => _currentVerseSubject.stream;
  VersePauseState get versePauseState => _versePauseStateSubject.value;
  ValueStream<VersePauseState> get versePauseStateStream =>
      _versePauseStateSubject.stream;
  bool get isInVersePause => _isInVersePause;
  AudioPlayer get player => _player;

  bool get pauseBetweenVersesEnabled => _pauseBetweenVersesEnabled;
  int get pauseBetweenVersesSeconds => _pauseBetweenVersesSeconds;

  AudioPlayMode get playMode => _playMode;
  set playMode(AudioPlayMode value) {
    if (_playMode == value) return;
    _playMode = value;
    if (value == AudioPlayMode.repeatVerse) {
      _repeatVerseTarget = _resolveLoopVerse(_player.position);
    } else {
      _repeatVerseTarget = null;
    }
    _syncVerseBoundaryTimer();
  }

  BsbAudioHandler({
    AudioPlayer? player,
    this.silencePlayer,
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
      _syncVerseBoundaryTimer(playing: state.playing);
    });
    _positionSubscription = _player.positionStream.listen(_onPositionUpdated);

    // Auto-advance or repeat when current playback completes
    _stateSubscription = _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        if (_isInVersePause || _isLoopSeeking) return;
        await _handleAudioCompleted();
      }
    });
  }

  Future<void> _handleAudioCompleted() async {
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

    final timings = _currentTimings;
    switch (_playMode) {
      case AudioPlayMode.repeatVerse:
        final target = _resolveLastVerseStart();
        if (_pauseBetweenVersesEnabled &&
            _currentBookId != null &&
            _currentChapter != null) {
          final verse = _repeatVerseTarget ?? timings?.verses.lastOrNull?.verse;
          await _enterVersePause(
            _VersePauseTarget(
              bookId: _currentBookId!,
              chapter: _currentChapter!,
              verse: verse,
              seekPosition: target,
            ),
          );
        } else {
          await seek(target);
          await play();
        }
        break;
      case AudioPlayMode.repeatPassage:
        final passageTarget = _resolveCompletedPassageTarget();
        if (passageTarget != null) {
          if (_pauseBetweenVersesEnabled) {
            await _enterVersePause(passageTarget);
          } else {
            await _jumpToTargetAndPlay(passageTarget);
          }
        } else {
          await seek(Duration.zero);
          await play();
        }
        break;
      case AudioPlayMode.repeatChapter:
        if (_pauseBetweenVersesEnabled &&
            _currentBookId != null &&
            _currentChapter != null) {
          final firstVerse = timings?.verses.firstOrNull;
          await _enterVersePause(
            _VersePauseTarget(
              bookId: _currentBookId!,
              chapter: _currentChapter!,
              verse: firstVerse?.verse ?? 1,
              seekPosition: Duration.zero,
            ),
          );
        } else {
          await seek(Duration.zero);
          await play();
        }
        break;
      case AudioPlayMode.stopAfterChapter:
        await pause();
        await seek(Duration.zero);
        break;
      case AudioPlayMode.continuous:
        if (_pauseBetweenVersesEnabled &&
            _currentBookId != null &&
            _currentChapter != null) {
          final next = _urlResolver.getNextChapter(
            _currentBookId!,
            _currentChapter!,
          );
          if (next != null) {
            await _enterVersePause(
              _VersePauseTarget(
                bookId: next.$1,
                chapter: next.$2,
                verse: null,
                seekPosition: Duration.zero,
              ),
            );
          } else {
            await stop();
          }
        } else {
          try {
            await skipToNext();
          } catch (_) {
            await stop();
          }
        }
        break;
    }
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
    } catch (_) {
      // AudioSession may not be available on all platforms/environments (e.g. desktop/test)
    }
  }

  AudioPlayer? get _activeSilencePlayer => silencePlayer ?? _ownedSilencePlayer;

  void _playFireAndForget(AudioPlayer player) {
    unawaited(player.play().catchError((_) {}));
  }

  Future<void> _ensureSilencePlayerReady() async {
    try {
      var player = _activeSilencePlayer;
      if (player == null) {
        _ownedSilencePlayer = AudioPlayer(
          handleInterruptions: false,
          androidApplyAudioAttributes: false,
        );
        player = _ownedSilencePlayer;
      }
      if (!_silenceSourceLoaded) {
        await player!.setAudioSource(
          AudioSource.asset('assets/audio/silence.wav'),
        );
        await player.setLoopMode(LoopMode.one);
        _silenceSourceLoaded = true;
      }
    } catch (_) {
      // Tests or headless environments may not implement asset/loop plugins.
    }
  }

  Future<void> _startSilenceAudio() async {
    await _ensureSilencePlayerReady();
    if (!_isInVersePause) return;
    final player = _activeSilencePlayer;
    if (player != null) {
      _playFireAndForget(player);
    }
  }

  Future<void> _stopSilenceAudio() async {
    try {
      await _activeSilencePlayer?.pause();
    } catch (_) {}
  }

  bool get _needsBoundaryPolling =>
      _playMode == AudioPlayMode.repeatVerse ||
      _playMode == AudioPlayMode.repeatPassage ||
      _pauseBetweenVersesEnabled;

  void _syncVerseBoundaryTimer({bool? playing}) {
    final shouldRun =
        _needsBoundaryPolling &&
        !_isInVersePause &&
        (playing ?? _player.playing);
    if (shouldRun && _verseBoundaryTimer == null) {
      // Poll every 50 ms so verse boundaries and loops trigger cleanly.
      _verseBoundaryTimer = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) => _onPositionUpdated(_player.position),
      );
    } else if (!shouldRun && _verseBoundaryTimer != null) {
      _verseBoundaryTimer?.cancel();
      _verseBoundaryTimer = null;
    }
  }

  Future<void> setPauseBetweenVerses({
    required bool enabled,
    int? seconds,
  }) async {
    if (seconds != null) {
      _pauseBetweenVersesSeconds = seconds.clamp(
        kMinVersePauseSeconds,
        kMaxVersePauseSeconds,
      );
    }
    _pauseBetweenVersesEnabled = enabled;
    if (enabled) {
      if (_player.speed != 1.0) {
        await _player.setSpeed(1.0);
      }
      if (_isInVersePause) {
        final currentState = _versePauseStateSubject.value;
        final clamped = currentState.remainingSeconds.clamp(
          1,
          _pauseBetweenVersesSeconds,
        );
        _versePauseStateSubject.add(
          VersePauseState(
            isPaused: true,
            remainingSeconds: clamped,
            totalSeconds: _pauseBetweenVersesSeconds,
            nextBookId: currentState.nextBookId,
            nextChapter: currentState.nextChapter,
            nextVerse: currentState.nextVerse,
          ),
        );
      }
    } else if (_isInVersePause) {
      await _cancelVersePause(resumePlayer: true);
    }
    _syncVerseBoundaryTimer();
    _broadcastState();
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
    if (_isInVersePause) return;

    final timings = _currentTimings;
    final verse = timings?.verseAt(position);
    final previousExpected = _expectedActiveVerse;
    final currentTiming = verse != null ? timings?.timingFor(verse) : null;

    // Ignore minor backward position jitter (<500 ms) from MP3 frame alignment
    // right after seeking/resuming at a verse boundary.
    final isBoundaryJitter =
        previousExpected != null &&
        currentTiming != null &&
        currentTiming.verse < previousExpected.verse &&
        previousExpected.start - position < const Duration(milliseconds: 500);
    if (isBoundaryJitter) {
      return;
    }

    if (verse != _currentVerseSubject.value) {
      _currentVerseSubject.add(verse);
      _updateMediaItemArtist(verse);
    }

    if (_isLoopSeeking || timings == null || timings.isEmpty) {
      return;
    }

    if (_playMode == AudioPlayMode.repeatVerse) {
      final targetVerse = _repeatVerseTarget ?? _resolveLoopVerse(position);
      if (targetVerse != null) {
        final vt = timings.timingFor(targetVerse);
        if (vt != null && position >= vt.end) {
          _expectedActiveVerse = vt;
          _onVerseEnded(vt);
          return;
        }
      }
      _expectedActiveVerse = currentTiming;
      return;
    }

    if (previousExpected != null && position >= previousExpected.end) {
      _onVerseEnded(previousExpected);
      return;
    }

    // Also catch endVerse if currentTiming itself crossed its end cleanly.
    if (_playMode == AudioPlayMode.repeatPassage) {
      final passageEnd = _activePassageEndVerse(timings);
      if (passageEnd != null &&
          (currentTiming?.verse == passageEnd ||
              (previousExpected == null &&
                  position >= (timings.timingFor(passageEnd)?.end ?? Duration.zero)))) {
        final endTiming = timings.timingFor(passageEnd);
        if (endTiming != null && position >= endTiming.end) {
          _onVerseEnded(endTiming);
          return;
        }
      }
    }

    _expectedActiveVerse = currentTiming;
  }

  int? _activePassageEndVerse(ChapterTimings timings) {
    final passage = repeatPassage;
    if (passage == null ||
        _currentBookId != passage.bookId ||
        _currentChapter == null) {
      return null;
    }
    final endChapter = passage.endChapter ?? passage.chapter;
    if (_currentChapter! < passage.chapter || _currentChapter! > endChapter) {
      return null;
    }
    if (_currentChapter! < endChapter) {
      return timings.verses.lastOrNull?.verse;
    }
    return passage.endVerse ??
        (passage.verse ?? timings.verses.lastOrNull?.verse);
  }

  bool _isAtPassageBoundary(VerseTiming endedVerse, ChapterTimings timings) {
    final passage = repeatPassage;
    if (passage == null ||
        _currentBookId != passage.bookId ||
        _currentChapter == null) {
      return false;
    }
    final endChapter = passage.endChapter ?? passage.chapter;
    if (_currentChapter! == endChapter) {
      final endVerse =
          passage.endVerse ?? (passage.verse ?? timings.verses.lastOrNull?.verse);
      return endVerse != null && endedVerse.verse >= endVerse;
    }
    if (_currentChapter! >= passage.chapter && _currentChapter! < endChapter) {
      final lastVerse = timings.verses.lastOrNull?.verse;
      return lastVerse != null && endedVerse.verse == lastVerse;
    }
    return false;
  }

  _VersePauseTarget? _resolveCompletedPassageTarget() {
    final passage = repeatPassage;
    if (passage == null ||
        _currentBookId == null ||
        _currentChapter == null) {
      return null;
    }
    final endChapter = passage.endChapter ?? passage.chapter;
    if (_currentBookId == passage.bookId && _currentChapter! < endChapter) {
      final nextChapter = _currentChapter! + 1;
      return _VersePauseTarget(
        bookId: passage.bookId,
        chapter: nextChapter,
        verse: 1,
        seekPosition: Duration.zero, // Refined with loaded timings in transition.
      );
    }
    final startVerse = passage.verse ?? 1;
    final seekPos =
        _currentChapter == passage.chapter && _currentBookId == passage.bookId
        ? (_currentTimings?.timingFor(startVerse)?.start ?? Duration.zero)
        : Duration.zero;
    return _VersePauseTarget(
      bookId: passage.bookId,
      chapter: passage.chapter,
      verse: startVerse,
      seekPosition: seekPos,
    );
  }

  Future<void> _onVerseEnded(VerseTiming endedVerse) async {
    final timings = _currentTimings;
    final bookId = _currentBookId;
    final chapter = _currentChapter;
    if (timings == null || bookId == null || chapter == null) return;

    _isLoopSeeking = true;
    try {
      // 1. Repeat Verse boundary
      if (_playMode == AudioPlayMode.repeatVerse) {
        if (stopAtEndOfChapter) {
          stopAtEndOfChapter = false;
          onSleepTimerFired?.call();
          await _player.pause();
          await _player.seek(endedVerse.start);
          _syncVerseAfterSeek(endedVerse.start);
          _broadcastState();
          return;
        }
        final target = _VersePauseTarget(
          bookId: bookId,
          chapter: chapter,
          verse: endedVerse.verse,
          seekPosition: endedVerse.start,
        );
        if (_pauseBetweenVersesEnabled) {
          await _enterVersePause(target);
        } else {
          await _player.seek(endedVerse.start);
          _syncVerseAfterSeek(endedVerse.start);
          _broadcastState();
        }
        return;
      }

      // 2. Repeat Passage boundary (end of chapter inside cross-chapter passage OR end of passage)
      if (_playMode == AudioPlayMode.repeatPassage &&
          _isAtPassageBoundary(endedVerse, timings)) {
        final target = _resolveCompletedPassageTarget();
        if (target != null) {
          if (stopAtEndOfChapter &&
              (chapter == (repeatPassage!.endChapter ?? repeatPassage!.chapter) ||
                  endedVerse.verse == timings.verses.lastOrNull?.verse)) {
            stopAtEndOfChapter = false;
            onSleepTimerFired?.call();
            await _jumpToTargetPaused(target);
            return;
          }
          if (_pauseBetweenVersesEnabled) {
            await _enterVersePause(target);
          } else {
            await _jumpToTargetAndPlay(target);
          }
          return;
        }
      }

      // 3. Normal / Repeat Chapter / Stop After Chapter verse-pause boundaries
      if (!_pauseBetweenVersesEnabled) {
        final idx = timings.verses.indexOf(endedVerse);
        if (idx >= 0 && idx + 1 < timings.verses.length) {
          _expectedActiveVerse = timings.verses[idx + 1];
        }
        return;
      }

      final idx = timings.verses.indexOf(endedVerse);
      if (idx >= 0 && idx + 1 < timings.verses.length) {
        final nextTiming = timings.verses[idx + 1];
        await _enterVersePause(
          _VersePauseTarget(
            bookId: bookId,
            chapter: chapter,
            verse: nextTiming.verse,
            seekPosition: nextTiming.start,
          ),
        );
        return;
      }

      // Ended last verse of the chapter with pauseBetweenVersesEnabled
      if (stopAtEndOfChapter || _playMode == AudioPlayMode.stopAfterChapter) {
        if (stopAtEndOfChapter) {
          stopAtEndOfChapter = false;
          onSleepTimerFired?.call();
        }
        await _player.pause();
        await _player.seek(Duration.zero);
        _syncVerseAfterSeek(Duration.zero);
        _broadcastState();
        return;
      }

      if (_playMode == AudioPlayMode.repeatChapter) {
        final firstVerse = timings.verses.firstOrNull;
        await _enterVersePause(
          _VersePauseTarget(
            bookId: bookId,
            chapter: chapter,
            verse: firstVerse?.verse ?? 1,
            seekPosition: Duration.zero,
          ),
        );
        return;
      }

      if (_playMode == AudioPlayMode.continuous) {
        final next = _urlResolver.getNextChapter(bookId, chapter);
        if (next != null) {
          await _enterVersePause(
            _VersePauseTarget(
              bookId: next.$1,
              chapter: next.$2,
              verse: null,
              seekPosition: Duration.zero,
            ),
          );
        } else {
          await stop();
        }
      }
    } finally {
      _isLoopSeeking = false;
    }
  }

  void _syncVerseAfterSeek(Duration position) {
    final verse = _currentTimings?.verseAt(position);
    _expectedActiveVerse =
        verse != null ? _currentTimings?.timingFor(verse) : null;
    if (verse != _currentVerseSubject.value) {
      _currentVerseSubject.add(verse);
      _updateMediaItemArtist(verse);
    }
  }

  Future<Duration> _resolveTargetSeekPosition(
    _VersePauseTarget target,
    ChapterTimings timings,
  ) async {
    if (target.seekPosition > Duration.zero) {
      return target.seekPosition;
    }
    if (target.verse != null &&
        (_playMode == AudioPlayMode.repeatPassage ||
            _playMode == AudioPlayMode.repeatVerse)) {
      return timings.timingFor(target.verse!)?.start ?? Duration.zero;
    }
    return Duration.zero;
  }

  Future<void> _jumpToTargetPaused(_VersePauseTarget target) async {
    if (_currentBookId == target.bookId && _currentChapter == target.chapter) {
      final timings =
          _currentTimings ?? await _loadTimings(target.bookId, target.chapter);
      final seekPos = await _resolveTargetSeekPosition(target, timings);
      await _player.pause();
      await _player.seek(seekPos);
      _syncVerseAfterSeek(seekPos);
      _broadcastState();
      return;
    }
    await _prepareChapterInPlayer(
      target.bookId,
      target.chapter,
      targetVerse: target.verse,
      seekPositionHint: target.seekPosition,
      autoPlay: false,
    );
  }

  Future<void> _jumpToTargetAndPlay(_VersePauseTarget target) async {
    if (_currentBookId == target.bookId && _currentChapter == target.chapter) {
      final timings =
          _currentTimings ?? await _loadTimings(target.bookId, target.chapter);
      final seekPos = await _resolveTargetSeekPosition(target, timings);
      await _player.seek(seekPos);
      _syncVerseAfterSeek(seekPos);
      if (!_player.playing) {
        _playFireAndForget(_player);
      }
      _broadcastState();
      return;
    }
    await _prepareChapterInPlayer(
      target.bookId,
      target.chapter,
      targetVerse: target.verse,
      seekPositionHint: target.seekPosition,
      autoPlay: true,
    );
  }

  Future<void> _enterVersePause(_VersePauseTarget initialTarget) async {
    _versePauseTimer?.cancel();
    _versePauseTimer = null;

    _isInVersePause = true;
    _syncVerseBoundaryTimer(playing: false);

    final totalSeconds = _pauseBetweenVersesSeconds;
    _pendingPauseTarget = initialTarget;

    // Emit pause state immediately so UI & lock-screen stay in "playing" state.
    _emitPauseCountdownState(
      remainingSeconds: totalSeconds,
      totalSeconds: totalSeconds,
      target: initialTarget,
    );
    _broadcastState();

    // Pause the main narrator immediately before preparing the silence player
    // or loading the next chapter so speech stops cleanly at the verse end.
    try {
      await _player.pause();
      if (_currentBookId == initialTarget.bookId &&
          _currentChapter == initialTarget.chapter) {
        await _player.seek(initialTarget.seekPosition);
        final upcomingTiming = initialTarget.verse != null
            ? _currentTimings?.timingFor(initialTarget.verse!)
            : null;
        _expectedActiveVerse = upcomingTiming;
      } else {
        await _prepareChapterInPlayer(
          initialTarget.bookId,
          initialTarget.chapter,
          targetVerse: initialTarget.verse,
          seekPositionHint: initialTarget.seekPosition,
          autoPlay: false,
          overrideArtistText:
              _formatPauseArtist(initialTarget.verse, totalSeconds),
        );
      }
    } catch (_) {
      await _cancelVersePause(resumePlayer: false);
      return;
    }

    if (!_isInVersePause) return;

    // Start non-blocking silent audio so OS media session stays active while locked.
    await _startSilenceAudio();

    // Re-check in case playback was cancelled while loading silence audio.
    if (!_isInVersePause) return;

    var remaining = totalSeconds;
    _versePauseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isInVersePause) {
        timer.cancel();
        return;
      }
      remaining -= 1;
      if (remaining <= 0) {
        timer.cancel();
        _versePauseTimer = null;
        unawaited(_finishVersePause());
      } else {
        final target = _pendingPauseTarget ?? initialTarget;
        _emitPauseCountdownState(
          remainingSeconds: remaining,
          totalSeconds: totalSeconds,
          target: target,
        );
      }
    });
  }

  String _formatPauseArtist(int? verse, int remainingSeconds) {
    if (verse != null) {
      return 'Next: Verse $verse (${remainingSeconds}s)';
    }
    return 'Next chapter (${remainingSeconds}s)';
  }

  void _emitPauseCountdownState({
    required int remainingSeconds,
    required int totalSeconds,
    required _VersePauseTarget target,
  }) {
    _currentVerseSubject.add(target.verse);
    _versePauseStateSubject.add(
      VersePauseState(
        isPaused: true,
        remainingSeconds: remainingSeconds,
        totalSeconds: totalSeconds,
        nextBookId: target.bookId,
        nextChapter: target.chapter,
        nextVerse: target.verse,
      ),
    );
    _updateMediaItemArtist(
      target.verse,
      customArtist: _formatPauseArtist(target.verse, remainingSeconds),
    );
  }

  Future<void> _finishVersePause() async {
    if (!_isInVersePause) return;
    final target = _pendingPauseTarget;
    _pendingPauseTarget = null;
    await _stopSilenceAudio();
    _isInVersePause = false;
    _versePauseStateSubject.add(VersePauseState.idle);

    if (target != null && target.verse != null) {
      _currentVerseSubject.add(target.verse);
      _updateMediaItemArtist(target.verse);
      _expectedActiveVerse = _currentTimings?.timingFor(target.verse!);
    } else {
      _updateMediaItemArtist(_currentVerseSubject.value);
    }

    _playFireAndForget(_player);
    _syncVerseBoundaryTimer(playing: true);
    _broadcastState();
  }

  Future<void> _cancelVersePause({required bool resumePlayer}) async {
    _versePauseTimer?.cancel();
    _versePauseTimer = null;
    if (!_isInVersePause && _versePauseStateSubject.value == VersePauseState.idle) {
      return;
    }
    final target = _pendingPauseTarget;
    _pendingPauseTarget = null;
    await _stopSilenceAudio();
    _isInVersePause = false;
    _versePauseStateSubject.add(VersePauseState.idle);

    if (target != null && target.verse != null) {
      _currentVerseSubject.add(target.verse);
      _updateMediaItemArtist(target.verse);
      _expectedActiveVerse = _currentTimings?.timingFor(target.verse!);
    } else {
      _updateMediaItemArtist(_currentVerseSubject.value);
    }

    if (resumePlayer) {
      _playFireAndForget(_player);
      _syncVerseBoundaryTimer(playing: true);
    }
    _broadcastState();
  }

  void _updateMediaItemArtist(int? verse, {String? customArtist}) {
    final current = mediaItem.value;
    if (current == null) return;
    final newArtist = customArtist ?? (verse != null ? 'Verse $verse' : null);
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
    final playing = _isInVersePause ? true : _player.playing;
    final processingState = _isInVersePause
        ? ProcessingState.ready
        : _player.processingState;

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
    await _cancelVersePause(resumePlayer: false);
    await _prepareChapterInPlayer(
      bookId,
      chapter,
      seekPositionHint: initialPosition ?? Duration.zero,
      preloadedTimings: preloadedTimings,
      autoPlay: true,
    );
  }

  Future<void> _prepareChapterInPlayer(
    int bookId,
    int chapter, {
    int? targetVerse,
    Duration seekPositionHint = Duration.zero,
    ChapterTimings? preloadedTimings,
    required bool autoPlay,
    String? overrideArtistText,
  }) async {
    _currentBookId = bookId;
    _currentChapter = chapter;
    _currentTimings = null;
    _repeatVerseTarget = null;
    _expectedActiveVerse = null;
    _currentVerseSubject.add(null);

    final timings = preloadedTimings ?? await _loadTimings(bookId, chapter);
    if (_currentBookId != bookId || _currentChapter != chapter) return;
    _currentTimings = timings;

    var startPos = seekPositionHint;
    if (startPos == Duration.zero &&
        targetVerse != null &&
        (_playMode == AudioPlayMode.repeatPassage ||
            _playMode == AudioPlayMode.repeatVerse)) {
      startPos = timings.timingFor(targetVerse)?.start ?? Duration.zero;
    }

    final initialVerse = targetVerse ?? timings.verseAt(startPos);
    _currentVerseSubject.add(initialVerse);
    _expectedActiveVerse =
        initialVerse != null ? timings.timingFor(initialVerse) : null;
    if (_playMode == AudioPlayMode.repeatVerse) {
      _repeatVerseTarget = _resolveLoopVerse(startPos);
    }

    final url = _urlResolver.getChapterUrl(bookId, chapter);
    final title = _urlResolver.getChapterTitle(bookId, chapter);

    final item = MediaItem(
      id: url,
      album: 'Berean Standard Bible',
      title: title,
      artist:
          overrideArtistText ??
          (initialVerse != null ? 'Verse $initialVerse' : null),
      extras: {'bookId': bookId, 'chapter': chapter},
    );
    mediaItem.add(item);

    try {
      final duration = await _player.setAudioSource(
        AudioSource.uri(Uri.parse(url)),
        initialPosition: startPos,
      );
      if (duration != null) {
        final latest = mediaItem.value ?? item;
        mediaItem.add(latest.copyWith(duration: duration));
      }
      if (autoPlay) {
        _playFireAndForget(_player);
        _syncVerseBoundaryTimer(playing: true);
      }
    } catch (e) {
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
  /// Unless [skipAnnouncement] is true, Verse 1 starts at 0:00 so the spoken
  /// chapter announcement is included.
  Future<void> playFromVerse(
    int bookId,
    int chapter,
    int verse, {
    bool skipAnnouncement = false,
  }) async {
    await _cancelVersePause(resumePlayer: false);
    if (_currentBookId == bookId && _currentChapter == chapter) {
      final timings = _currentTimings ?? await _loadTimings(bookId, chapter);
      _currentTimings = timings;
      final target = (verse <= 1 && !skipAnnouncement)
          ? Duration.zero
          : (timings.timingFor(verse)?.start ?? Duration.zero);
      await seek(target);
      if (!_player.playing) {
        await play();
      }
      return;
    }

    final timings = await _loadTimings(bookId, chapter);
    final target = (verse <= 1 && !skipAnnouncement)
        ? Duration.zero
        : (timings.timingFor(verse)?.start ?? Duration.zero);
    await playChapter(
      bookId,
      chapter,
      initialPosition: target,
      preloadedTimings: timings,
    );
  }

  /// Starts playback for a configured [Reference] passage range.
  Future<void> playPassageStart(Reference passage) async {
    final startVerse = passage.verse ?? 1;
    await playFromVerse(
      passage.bookId,
      passage.chapter,
      startVerse,
      skipAnnouncement: passage.verse != null,
    );
  }

  /// Seeks to the next verse in the current chapter (or wraps/advances in Repeat Passage).
  Future<void> skipToNextVerse() async {
    await _cancelVersePause(resumePlayer: false);
    final timings = _currentTimings;
    if (timings == null || timings.isEmpty) return;

    if (_playMode == AudioPlayMode.repeatPassage && repeatPassage != null) {
      final passage = repeatPassage!;
      final currentVerse = timings.verseAt(_player.position);
      final endChapter = passage.endChapter ?? passage.chapter;
      final endVerse =
          passage.endVerse ?? (passage.verse ?? timings.verses.last.verse);

      if (_currentBookId == passage.bookId && _currentChapter != null) {
        if (_currentChapter == endChapter &&
            currentVerse != null &&
            currentVerse >= endVerse) {
          await playPassageStart(passage);
          return;
        }
        if (_currentChapter! < endChapter &&
            currentVerse != null &&
            currentVerse >= timings.verses.last.verse) {
          await playFromVerse(
            passage.bookId,
            _currentChapter! + 1,
            1,
            skipAnnouncement: true,
          );
          return;
        }
      }
    }

    final target = timings.nextSeekTarget(_player.position);
    if (target != null) {
      await seek(target);
    }
  }

  /// Seeks to the start of the current verse (>2s in) or the previous verse.
  Future<void> skipToPreviousVerse() async {
    await _cancelVersePause(resumePlayer: false);
    final timings = _currentTimings;
    if (timings == null || timings.isEmpty) return;

    if (_playMode == AudioPlayMode.repeatPassage && repeatPassage != null) {
      final passage = repeatPassage!;
      final startVerse = passage.verse ?? 1;
      if (_currentBookId == passage.bookId &&
          _currentChapter == passage.chapter) {
        final startTiming = timings.timingFor(startVerse);
        final currentVerse = timings.verseAt(_player.position);
        if (currentVerse == null || currentVerse <= startVerse) {
          await seek(startTiming?.start ?? Duration.zero);
          return;
        }
      }
    }

    final target = timings.previousSeekTarget(_player.position);
    if (target != null) {
      await seek(target);
    }
  }

  bool hasNextVerse(Duration position) {
    if (_playMode == AudioPlayMode.repeatPassage && repeatPassage != null) {
      return _currentTimings != null && !_currentTimings!.isEmpty;
    }
    return _currentTimings?.nextSeekTarget(position) != null;
  }

  bool hasPreviousVerse(Duration position) {
    final timings = _currentTimings;
    if (timings == null || timings.isEmpty) return false;
    return position > Duration.zero;
  }

  @override
  Future<void> play() async {
    if (_isInVersePause) {
      await _finishVersePause();
      return;
    }
    _playFireAndForget(_player);
    _syncVerseBoundaryTimer(playing: true);
    _broadcastState();
  }

  @override
  Future<void> pause() async {
    await _cancelVersePause(resumePlayer: false);
    await _player.pause();
    _syncVerseBoundaryTimer(playing: false);
    _broadcastState();
  }

  @override
  Future<void> seek(Duration position) async {
    await _cancelVersePause(resumePlayer: false);
    if (_playMode == AudioPlayMode.repeatVerse) {
      _repeatVerseTarget = _resolveLoopVerse(position);
    }
    await _player.seek(position);
    _syncVerseAfterSeek(position);
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
    await _cancelVersePause(resumePlayer: false);
    _syncVerseBoundaryTimer(playing: false);
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_currentBookId == null || _currentChapter == null) return;
    await _cancelVersePause(resumePlayer: false);
    if (_playMode == AudioPlayMode.repeatPassage) {
      _playMode = AudioPlayMode.continuous;
      _syncVerseBoundaryTimer();
      onPlayModeChanged?.call(AudioPlayMode.continuous);
    }
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
    await _cancelVersePause(resumePlayer: false);
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
      if (_playMode == AudioPlayMode.repeatPassage) {
        _playMode = AudioPlayMode.continuous;
        _syncVerseBoundaryTimer();
        onPlayModeChanged?.call(AudioPlayMode.continuous);
      }
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
    _verseBoundaryTimer?.cancel();
    _verseBoundaryTimer = null;
    _versePauseTimer?.cancel();
    _versePauseTimer = null;
    await _positionSubscription?.cancel();
    await _eventSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _stateSubscription?.cancel();
    await _currentVerseSubject.close();
    await _versePauseStateSubject.close();
    await _player.dispose();
    if (_ownedSilencePlayer != null && !identical(_ownedSilencePlayer, _player)) {
      try {
        await _ownedSilencePlayer!.dispose();
      } catch (_) {}
    }
  }
}
