import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:bsb/infrastructure/audio/audio_models.dart';
import 'package:bsb/infrastructure/audio/audio_playback_manager.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/ui/playlists/widgets/passage_range_picker_dialog.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the expanded full-featured audio player bottom sheet.
Future<void> showAudioPlayerModalSheet(
  BuildContext context,
  AudioPlaybackManager manager, {
  VoidCallback? onGoToChapter,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        AudioPlayerModalSheet(manager: manager, onGoToChapter: onGoToChapter),
  );
}

class AudioPlayerModalSheet extends StatelessWidget {
  final AudioPlaybackManager manager;
  final VoidCallback? onGoToChapter;

  const AudioPlayerModalSheet({
    super.key,
    required this.manager,
    this.onGoToChapter,
  });

  String _formatTimerDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSpeedPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: ValueListenableBuilder<double>(
              valueListenable: manager.speedNotifier,
              builder: (context, currentSpeed, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: manager.pauseBetweenVersesEnabledNotifier,
                  builder: (context, pauseEnabled, _) {
                    return ValueListenableBuilder<int>(
                      valueListenable:
                          manager.pauseBetweenVersesSecondsNotifier,
                      builder: (context, pauseSeconds, _) {
                        final colorScheme = Theme.of(context).colorScheme;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.3,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Playback Speed',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...kAudioSpeedOptions.map((speed) {
                              final isSelected =
                                  !pauseEnabled &&
                                  (speed - currentSpeed).abs() < 0.01;
                              return ListTile(
                                title: Text(
                                  '${speed}x${speed == 1.0 ? ' (Normal)' : ''}',
                                ),
                                leading: Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                selected: isSelected,
                                onTap: () {
                                  manager.setSpeed(speed);
                                  Navigator.pop(sheetContext);
                                },
                              );
                            }),
                            ListTile(
                              title: Text(
                                '1.0x (with $pauseSeconds second pause)',
                              ),
                              leading: Icon(
                                pauseEnabled
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: pauseEnabled
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              selected: pauseEnabled,
                              onTap: () {
                                manager.setPauseBetweenVerses(enabled: true);
                              },
                            ),
                            if (pauseEnabled)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  0,
                                  16,
                                  8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('Pause duration:'),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          key: const ValueKey(
                                            'verse_pause_decrement',
                                          ),
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                          tooltip: 'Decrease pause',
                                          onPressed:
                                              pauseSeconds >
                                                  kMinVersePauseSeconds
                                              ? () => manager
                                                    .setPauseBetweenVerses(
                                                      enabled: true,
                                                      seconds: pauseSeconds - 1,
                                                    )
                                              : null,
                                        ),
                                        Text(
                                          '${pauseSeconds}s',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        IconButton(
                                          key: const ValueKey(
                                            'verse_pause_increment',
                                          ),
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                          tooltip: 'Increase pause',
                                          onPressed:
                                              pauseSeconds <
                                                  kMaxVersePauseSeconds
                                              ? () => manager
                                                    .setPauseBetweenVerses(
                                                      enabled: true,
                                                      seconds: pauseSeconds + 1,
                                                    )
                                              : null,
                                        ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(sheetContext),
                                          child: const Text('Done'),
                                        ),
                                      ],
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      children: kVersePausePresetSeconds.map((
                                        secs,
                                      ) {
                                        return ChoiceChip(
                                          label: Text('${secs}s'),
                                          selected: pauseSeconds == secs,
                                          onSelected: (_) {
                                            manager.setPauseBetweenVerses(
                                              enabled: true,
                                              seconds: secs,
                                            );
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickRepeatPassage(BuildContext context) async {
    Reference? initialRef = manager.repeatPassageNotifier.value;
    if (initialRef == null) {
      final bookId = manager.audioHandler.currentBookId;
      final chapter = manager.audioHandler.currentChapter;
      if (bookId != null && chapter != null) {
        initialRef = Reference(
          bookId: bookId,
          chapter: chapter,
          verse: manager.currentVerseNotifier.value ?? 1,
        );
      }
    }

    final result = await PassageRangePickerDialog.show(
      context,
      initialReference: initialRef,
      confirmButtonText: 'Repeat Passage',
    );
    if (result != null) {
      await manager.setRepeatPassage(
        result.reference,
        playImmediately: true,
        forceRestart: true,
      );
    }
  }

  void _showPlayModePicker(BuildContext context) {
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: ValueListenableBuilder<AudioPlayMode>(
              valueListenable: manager.playModeNotifier,
              builder: (context, currentMode, _) {
                return ValueListenableBuilder<Reference?>(
                  valueListenable: manager.repeatPassageNotifier,
                  builder: (context, repeatPassage, _) {
                    final colorScheme = Theme.of(context).colorScheme;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Repeat Mode',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...AudioPlayMode.values.map((mode) {
                          final isSelected = mode == currentMode;
                          final isPassageMode =
                              mode == AudioPlayMode.repeatPassage;
                          return ListTile(
                            title: Text(mode.label),
                            subtitle: isPassageMode
                                ? Text(
                                    repeatPassage?.toString() ??
                                        'Choose a range of verses',
                                  )
                                : null,
                            leading: Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            trailing: isPassageMode && repeatPassage != null
                                ? IconButton(
                                    key: const ValueKey(
                                      'edit_repeat_passage_button',
                                    ),
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Edit passage range',
                                    onPressed: () {
                                      Navigator.pop(sheetContext);
                                      _pickRepeatPassage(parentContext);
                                    },
                                  )
                                : Icon(
                                    mode.icon,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            selected: isSelected,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              if (isPassageMode) {
                                if (repeatPassage == null ||
                                    currentMode ==
                                        AudioPlayMode.repeatPassage) {
                                  _pickRepeatPassage(parentContext);
                                } else {
                                  manager.setRepeatPassage(
                                    repeatPassage,
                                    playImmediately: true,
                                  );
                                }
                              } else {
                                manager.setPlayMode(mode);
                              }
                            },
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showSleepTimerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final currentOption = manager.sleepTimerOptionNotifier.value;
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Sleep Timer',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ...SleepTimerOption.values.map((option) {
                  final isSelected = option == currentOption;
                  return ListTile(
                    title: Text(option.label),
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    selected: isSelected,
                    onTap: () {
                      manager.setSleepTimer(option);
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: StreamBuilder<MediaItem?>(
              stream: manager.mediaItemStream,
              builder: (context, mediaSnapshot) {
                final mediaItem = mediaSnapshot.data;
                final bookId = mediaItem?.extras?['bookId'] as int?;
                final chapter = mediaItem?.extras?['chapter'] as int?;

                final hasPrev = manager.hasPreviousChapter(bookId, chapter);
                final hasNext = manager.hasNextChapter(bookId, chapter);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(top: 4, bottom: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header Row: Collapse button, Title, Sync Text Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down),
                          tooltip: 'Collapse',
                          iconSize: 28,
                          onPressed: () => Navigator.pop(context),
                        ),
                        Flexible(
                          child: Text(
                            'Audio Player',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: manager.syncTextNotifier,
                          builder: (context, sync, _) {
                            return IconButton(
                              icon: Icon(
                                sync ? Icons.sync : Icons.sync_disabled,
                                color: sync
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              tooltip: sync
                                  ? 'Sync text with audio (Enabled)'
                                  : 'Sync text with audio (Disabled)',
                              onPressed: () => manager.setSyncText(!sync),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Scripture Artwork Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24.0,
                        horizontal: 16.0,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.headphones_rounded,
                            size: 40,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          ValueListenableBuilder<int?>(
                            valueListenable: manager.currentVerseNotifier,
                            builder: (context, verse, _) {
                              return Text(
                                manager.formatDisplayTitle(mediaItem, verse),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bob Souer',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          ValueListenableBuilder<VersePauseState>(
                            valueListenable: manager.versePauseStateNotifier,
                            builder: (context, pauseState, _) {
                              final status = pauseState.statusText;
                              if (status == null) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  status,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Progress Scrubber
                    StreamBuilder<PositionData>(
                      stream: manager.positionDataStream,
                      builder: (context, snapshot) {
                        final data =
                            snapshot.data ??
                            const PositionData(
                              Duration.zero,
                              Duration.zero,
                              Duration.zero,
                            );

                        return ProgressBar(
                          progress: data.position,
                          buffered: data.bufferedPosition,
                          total: data.duration,
                          onSeek: (position) => manager.seek(position),
                          timeLabelLocation: TimeLabelLocation.sides,
                          timeLabelType: TimeLabelType.totalTime,
                          barHeight: 4.5,
                          thumbRadius: 7.0,
                          thumbGlowRadius: 18.0,
                          progressBarColor: colorScheme.primary,
                          thumbColor: colorScheme.primary,
                          baseBarColor: colorScheme.onSurface.withValues(
                            alpha: 0.12,
                          ),
                          bufferedBarColor: colorScheme.onSurface.withValues(
                            alpha: 0.22,
                          ),
                          timeLabelTextStyle: theme.textTheme.labelSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    // Primary Control Cluster: Prev Ch, Prev Verse, Play/Pause, Next Verse, Next Ch
                    StreamBuilder<PositionData>(
                      stream: manager.positionDataStream,
                      builder: (context, posSnapshot) {
                        final pos =
                            posSnapshot.data?.position ?? Duration.zero;
                        final hasPrevVerse = manager.hasPreviousVerse(pos);
                        final hasNextVerse = manager.hasNextVerse(pos);

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Skip Previous Chapter
                            IconButton(
                              icon: const Icon(Icons.skip_previous),
                              tooltip: 'Previous Chapter',
                              iconSize: 32,
                              onPressed: hasPrev ? manager.skipToPrevious : null,
                            ),

                            // Previous Verse
                            IconButton(
                              icon: const Icon(Icons.fast_rewind),
                              tooltip: 'Previous Verse',
                              iconSize: 32,
                              onPressed: hasPrevVerse
                                  ? manager.skipToPreviousVerse
                                  : null,
                            ),

                            // Large Circular Play / Pause
                            StreamBuilder<PlaybackState>(
                              stream: manager.playbackStateStream,
                              builder: (context, stateSnapshot) {
                                final state = stateSnapshot.data;
                                final playing = state?.playing ?? false;
                                final processingState =
                                    state?.processingState ??
                                    AudioProcessingState.idle;

                                final isLoading =
                                    processingState ==
                                        AudioProcessingState.loading ||
                                    processingState ==
                                        AudioProcessingState.buffering;

                                return Material(
                                  elevation: 4,
                                  shape: const CircleBorder(),
                                  color: colorScheme.primary,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: isLoading
                                        ? null
                                        : (playing
                                              ? manager.pause
                                              : manager.play),
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      alignment: Alignment.center,
                                      child: isLoading
                                          ? SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                color: colorScheme.onPrimary,
                                              ),
                                            )
                                          : Icon(
                                              playing
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              size: 38,
                                              color: colorScheme.onPrimary,
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Next Verse
                            IconButton(
                              icon: const Icon(Icons.fast_forward),
                              tooltip: 'Next Verse',
                              iconSize: 32,
                              onPressed: hasNextVerse
                                  ? manager.skipToNextVerse
                                  : null,
                            ),

                            // Skip Next Chapter
                            IconButton(
                              icon: const Icon(Icons.skip_next),
                              tooltip: 'Next Chapter',
                              iconSize: 32,
                              onPressed: hasNext ? manager.skipToNext : null,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Quick Action Chips: Speed, Sleep Timer, Play Mode
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Playback Speed
                          ValueListenableBuilder<double>(
                            valueListenable: manager.speedNotifier,
                            builder: (context, speed, _) {
                              return ValueListenableBuilder<bool>(
                                valueListenable:
                                    manager.pauseBetweenVersesEnabledNotifier,
                                builder: (context, pauseEnabled, _) {
                                  return ValueListenableBuilder<int>(
                                    valueListenable: manager
                                        .pauseBetweenVersesSecondsNotifier,
                                    builder: (context, pauseSeconds, _) {
                                      return OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          foregroundColor: pauseEnabled
                                              ? colorScheme.primary
                                              : null,
                                        ),
                                        icon: const Icon(Icons.speed, size: 16),
                                        label: Text(
                                          pauseEnabled
                                              ? '1.0x (${pauseSeconds}s)'
                                              : '${speed}x',
                                        ),
                                        onPressed: () =>
                                            _showSpeedPicker(context),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),

                          const SizedBox(width: 8),

                          // Sleep Timer
                          ValueListenableBuilder<SleepTimerOption>(
                            valueListenable: manager.sleepTimerOptionNotifier,
                            builder: (context, option, _) {
                              return ValueListenableBuilder<Duration?>(
                                valueListenable:
                                    manager.sleepTimerRemainingNotifier,
                                builder: (context, remaining, _) {
                                  final label = remaining != null
                                      ? _formatTimerDuration(remaining)
                                      : (option == SleepTimerOption.endOfChapter
                                            ? 'End of Ch'
                                            : 'Sleep');
                                  final isActive =
                                      option != SleepTimerOption.off;

                                  return OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      foregroundColor: isActive
                                          ? colorScheme.primary
                                          : null,
                                    ),
                                    icon: Icon(
                                      isActive
                                          ? Icons.timer
                                          : Icons.timer_outlined,
                                      size: 16,
                                    ),
                                    label: Text(label),
                                    onPressed: () =>
                                        _showSleepTimerPicker(context),
                                  );
                                },
                              );
                            },
                          ),

                          const SizedBox(width: 8),

                          // Play Mode
                          ValueListenableBuilder<AudioPlayMode>(
                            valueListenable: manager.playModeNotifier,
                            builder: (context, mode, _) {
                              return ValueListenableBuilder<Reference?>(
                                valueListenable: manager.repeatPassageNotifier,
                                builder: (context, repeatPassage, _) {
                                  final isPassageActive =
                                      mode == AudioPlayMode.repeatPassage &&
                                      repeatPassage != null;
                                  final label = isPassageActive
                                      ? formatCompactPassageReference(
                                          repeatPassage,
                                        )
                                      : mode.label;
                                  return OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      foregroundColor:
                                          mode == AudioPlayMode.repeatPassage
                                          ? colorScheme.primary
                                          : null,
                                    ),
                                    icon: Icon(mode.icon, size: 16),
                                    label: Text(label),
                                    onPressed: () =>
                                        _showPlayModePicker(context),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // "Read Chapter" Button
                    if (onGoToChapter != null)
                      TextButton.icon(
                        icon: const Icon(Icons.menu_book, size: 18),
                        label: const Text('Go to Chapter'),
                        onPressed: () {
                          onGoToChapter?.call();
                          Navigator.pop(context);
                        },
                      ),

                    const SizedBox(height: 4),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
