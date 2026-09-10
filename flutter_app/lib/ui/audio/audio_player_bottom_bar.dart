import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:bsb/infrastructure/audio/audio_playback_manager.dart';
import 'package:flutter/material.dart';

class AudioPlayerBottomBar extends StatelessWidget {
  final AudioPlaybackManager manager;

  const AudioPlayerBottomBar({
    super.key,
    required this.manager,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 8,
      color: colorScheme.surfaceContainer,
      shape: Border(
        top: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Title, Previous, Play/Pause, Next, Close
              StreamBuilder<MediaItem?>(
                stream: manager.mediaItemStream,
                builder: (context, mediaSnapshot) {
                  final mediaItem = mediaSnapshot.data;
                  final title = mediaItem?.title ?? 'Audio Player';
                  final bookId = mediaItem?.extras?['bookId'] as int?;
                  final chapter = mediaItem?.extras?['chapter'] as int?;

                  final hasPrev = manager.hasPreviousChapter(bookId, chapter);
                  final hasNext = manager.hasNextChapter(bookId, chapter);

                  return Row(
                    children: [
                      // Chapter Title
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Previous Chapter
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        tooltip: 'Previous Chapter',
                        iconSize: 24,
                        visualDensity: VisualDensity.compact,
                        onPressed: hasPrev ? manager.skipToPrevious : null,
                      ),

                      // Play/Pause/Buffering
                      StreamBuilder<PlaybackState>(
                        stream: manager.playbackStateStream,
                        builder: (context, stateSnapshot) {
                          final state = stateSnapshot.data;
                          final playing = state?.playing ?? false;
                          final processingState =
                              state?.processingState ?? AudioProcessingState.idle;

                          if (processingState == AudioProcessingState.loading ||
                              processingState == AudioProcessingState.buffering) {
                            return const SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }

                          return IconButton(
                            icon: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                            ),
                            tooltip: playing ? 'Pause' : 'Play',
                            iconSize: 28,
                            visualDensity: VisualDensity.compact,
                            onPressed: playing ? manager.pause : manager.play,
                          );
                        },
                      ),

                      // Next Chapter
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        tooltip: 'Next Chapter',
                        iconSize: 24,
                        visualDensity: VisualDensity.compact,
                        onPressed: hasNext ? manager.skipToNext : null,
                      ),

                      // Close Button
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Close Player',
                        iconSize: 20,
                        visualDensity: VisualDensity.compact,
                        onPressed: manager.closePlayer,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 4),

              // Progress Bar
              StreamBuilder<PositionData>(
                stream: manager.positionDataStream,
                builder: (context, snapshot) {
                  final positionData = snapshot.data ??
                      const PositionData(Duration.zero, Duration.zero, Duration.zero);

                  return ProgressBar(
                    progress: positionData.position,
                    buffered: positionData.bufferedPosition,
                    total: positionData.duration,
                    onSeek: (position) => manager.seek(position),
                    timeLabelLocation: TimeLabelLocation.sides,
                    barHeight: 3.5,
                    thumbRadius: 6.0,
                    progressBarColor: colorScheme.primary,
                    thumbColor: colorScheme.primary,
                    baseBarColor: colorScheme.onSurface.withValues(alpha: 0.15),
                    bufferedBarColor:
                        colorScheme.onSurface.withValues(alpha: 0.25),
                    timeLabelTextStyle: theme.textTheme.labelSmall,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
