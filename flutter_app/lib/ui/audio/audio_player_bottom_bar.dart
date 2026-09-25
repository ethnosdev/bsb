import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:bsb/infrastructure/audio/audio_playback_manager.dart';
import 'package:flutter/material.dart';

class AudioPlayerBottomBar extends StatelessWidget {
  final AudioPlaybackManager manager;
  final VoidCallback? onOpenExpandedSheet;

  const AudioPlayerBottomBar({
    super.key,
    required this.manager,
    this.onOpenExpandedSheet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      elevation: 6,
      color: colorScheme.surfaceContainerHigh,
      shape: Border(
        top: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Slim progress bar along the top edge of the mini player
            StreamBuilder<PositionData>(
              stream: manager.positionDataStream,
              builder: (context, snapshot) {
                final data = snapshot.data ??
                    const PositionData(
                      Duration.zero,
                      Duration.zero,
                      Duration.zero,
                    );

                return SizedBox(
                  height: 3,
                  child: ProgressBar(
                    progress: data.position,
                    buffered: data.bufferedPosition,
                    total: data.duration,
                    onSeek: (position) => manager.seek(position),
                    timeLabelLocation: TimeLabelLocation.none,
                    barHeight: 3.0,
                    thumbRadius: 0.0,
                    progressBarColor: colorScheme.primary,
                    baseBarColor: colorScheme.onSurface.withValues(alpha: 0.1),
                    bufferedBarColor:
                        colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                );
              },
            ),

            // Mini Player Body
            Padding(
              padding: const EdgeInsets.only(
                left: 14.0,
                right: 6.0,
                top: 4.0,
                bottom: 4.0,
              ),
              child: StreamBuilder<MediaItem?>(
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
                      // Tappable title and subtitle that opens the expanded sheet
                      Expanded(
                        child: InkWell(
                          onTap: onOpenExpandedSheet,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6.0,
                              horizontal: 2.0,
                            ),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_up,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Previous Chapter
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        tooltip: 'Previous Chapter',
                        iconSize: 22,
                        visualDensity: VisualDensity.compact,
                        onPressed: hasPrev ? manager.skipToPrevious : null,
                      ),

                      // Play / Pause / Buffering
                      StreamBuilder<PlaybackState>(
                        stream: manager.playbackStateStream,
                        builder: (context, stateSnapshot) {
                          final state = stateSnapshot.data;
                          final playing = state?.playing ?? false;
                          final processingState =
                              state?.processingState ??
                              AudioProcessingState.idle;

                          if (processingState ==
                                  AudioProcessingState.loading ||
                              processingState ==
                                  AudioProcessingState.buffering) {
                            return const SizedBox(
                              width: 36,
                              height: 36,
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }

                          return IconButton(
                            icon: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                            ),
                            tooltip: playing ? 'Pause' : 'Play',
                            iconSize: 26,
                            visualDensity: VisualDensity.compact,
                            onPressed: playing ? manager.pause : manager.play,
                          );
                        },
                      ),

                      // Next Chapter
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        tooltip: 'Next Chapter',
                        iconSize: 22,
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
            ),
          ],
        ),
      ),
    );
  }
}
