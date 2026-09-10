import 'package:audio_service/audio_service.dart';
import 'package:bsb/infrastructure/audio/audio_url_resolver.dart';
import 'package:bsb/infrastructure/audio/bsb_audio_handler.dart';
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
  final ValueNotifier<bool> isPlayerVisible = ValueNotifier<bool>(false);

  AudioPlaybackManager({required this.audioHandler});

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

    final currentBook = audioHandler.currentBookId;
    final currentChap = audioHandler.currentChapter;

    if (currentBook == bookId && currentChap == chapter) {
      if (audioHandler.player.playing) {
        // If already playing, keep playing (and player is made visible)
        return;
      } else {
        await audioHandler.play();
        return;
      }
    }

    await audioHandler.playChapter(bookId, chapter);
  }

  Future<void> play() async {
    isPlayerVisible.value = true;
    await audioHandler.play();
  }

  Future<void> pause() async {
    await audioHandler.pause();
  }

  Future<void> seek(Duration position) async {
    await audioHandler.seek(position);
  }

  Future<void> skipToNext() async {
    await audioHandler.skipToNext();
  }

  Future<void> skipToPrevious() async {
    await audioHandler.skipToPrevious();
  }

  Future<void> closePlayer() async {
    isPlayerVisible.value = false;
    await audioHandler.stop();
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
    isPlayerVisible.dispose();
  }
}
