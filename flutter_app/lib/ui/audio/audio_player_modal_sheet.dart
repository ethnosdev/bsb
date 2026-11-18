import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:bsb/infrastructure/audio/audio_models.dart';
import 'package:bsb/infrastructure/audio/audio_playback_manager.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the expanded full-featured audio player bottom sheet.
Future<void> showAudioPlayerModalSheet(
  BuildContext context,
  AudioPlaybackManager manager,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AudioPlayerModalSheet(manager: manager),
  );
}

class AudioPlayerModalSheet extends StatefulWidget {
  final AudioPlaybackManager manager;

  const AudioPlayerModalSheet({super.key, required this.manager});

  @override
  State<AudioPlayerModalSheet> createState() => _AudioPlayerModalSheetState();
}

class _AudioPlayerModalSheetState extends State<AudioPlayerModalSheet> {
  AudioPlaybackManager get manager => widget.manager;
  bool _isScrubbing = false;
  int? _scrubVerse;

  void _updateScrubPosition(Duration position) {
    final verse = manager.currentTimings?.verseAt(position);
    if (!_isScrubbing || verse != _scrubVerse) {
      setState(() {
        _isScrubbing = true;
        _scrubVerse = verse;
      });
    }
  }

  void _endScrub() {
    if (_isScrubbing) {
      setState(() {
        _isScrubbing = false;
        _scrubVerse = null;
      });
    }
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
                      final isSelected = (speed - currentSpeed).abs() < 0.01;
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
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showVersePausePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: ValueListenableBuilder<bool>(
              valueListenable: manager.pauseBetweenVersesEnabledNotifier,
              builder: (context, pauseEnabled, _) {
                return ValueListenableBuilder<int>(
                  valueListenable: manager.pauseBetweenVersesSecondsNotifier,
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
                            'Pause After Verse',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListTile(
                          title: const Text('Off (0s)'),
                          leading: Icon(
                            !pauseEnabled
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: !pauseEnabled
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          selected: !pauseEnabled,
                          onTap: () {
                            manager.setPauseBetweenVerses(enabled: false);
                            Navigator.pop(sheetContext);
                          },
                        ),
                        ListTile(
                          title: Text('Pause for ${pauseSeconds}s'),
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 16, 8),
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
                                        pauseSeconds > kMinVersePauseSeconds
                                        ? () => manager.setPauseBetweenVerses(
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
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    key: const ValueKey(
                                      'verse_pause_increment',
                                    ),
                                    icon: const Icon(Icons.add_circle_outline),
                                    tooltip: 'Increase pause',
                                    onPressed:
                                        pauseSeconds < kMaxVersePauseSeconds
                                        ? () => manager.setPauseBetweenVerses(
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
                                children: kVersePausePresetSeconds.map((secs) {
                                  return ChoiceChip(
                                    label: Text('${secs}s'),
                                    selected:
                                        pauseEnabled && pauseSeconds == secs,
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
            ),
          ),
        );
      },
    );
  }

  String _formatContextButtonLabel(AudioPlayContext ctx, Reference? activeRange) {
    switch (ctx) {
      case AudioPlayContext.chapter:
        return 'Chapter';
      case AudioPlayContext.range:
        return activeRange != null
            ? formatCompactPassageReference(activeRange)
            : 'Range';
      case AudioPlayContext.verse:
        return 'Verse';
    }
  }

  void _showContextPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: ValueListenableBuilder<AudioPlayContext>(
              valueListenable: manager.playContextNotifier,
              builder: (context, currentContext, _) {
                return ValueListenableBuilder<Reference?>(
                  valueListenable: manager.activeRangeNotifier,
                  builder: (context, activeRange, _) {
                    final colorScheme = Theme.of(context).colorScheme;
                    final availableContexts = [
                      AudioPlayContext.chapter,
                      if (activeRange != null) AudioPlayContext.range,
                      AudioPlayContext.verse,
                    ];

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
                            'Context',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...availableContexts.map((ctx) {
                          final isSelected = ctx == currentContext;
                          final title =
                              ctx == AudioPlayContext.range &&
                                  activeRange != null
                              ? activeRange.toString()
                              : ctx.label;
                          return ListTile(
                            title: Text(title),
                            leading: Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            trailing: Icon(
                              ctx.icon,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            selected: isSelected,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              manager.setPlayContext(ctx);
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

  void _showRepeatPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: ValueListenableBuilder<AudioRepeatBehavior>(
              valueListenable: manager.repeatBehaviorNotifier,
              builder: (context, currentRepeat, _) {
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
                    ...AudioRepeatBehavior.values.map((behavior) {
                      final isSelected = behavior == currentRepeat;
                      return ListTile(
                        title: Text(behavior.label),
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        trailing: Icon(
                          behavior.icon,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        selected: isSelected,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          manager.setRepeatBehavior(behavior);
                        },
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                );
              },
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

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(top: 6, bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Currently Playing Reference
                    ValueListenableBuilder<int?>(
                      valueListenable: manager.currentVerseNotifier,
                      builder: (context, verse, _) {
                        final displayedVerse = _isScrubbing
                            ? _scrubVerse
                            : verse;
                        return Text(
                          manager.formatDisplayTitle(mediaItem, displayedVerse),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
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
                          onDragStart: (details) =>
                              _updateScrubPosition(details.timeStamp),
                          onDragUpdate: (details) =>
                              _updateScrubPosition(details.timeStamp),
                          onDragEnd: _endScrub,
                          onSeek: (position) {
                            _endScrub();
                            manager.seek(position);
                          },
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

                    // Primary Control Cluster: Speed, Prev Verse, Play/Pause, Next Verse, Pause
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
                            // Playback Speed
                            ValueListenableBuilder<double>(
                              valueListenable: manager.speedNotifier,
                              builder: (context, speed, _) {
                                return TextButton(
                                  key: const ValueKey('audio_speed_button'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    minimumSize: const Size(44, 40),
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor:
                                        colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () => _showSpeedPicker(context),
                                  child: Text('${speed}x'),
                                );
                              },
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

                            // Pause After Verse
                            ValueListenableBuilder<bool>(
                              valueListenable:
                                  manager.pauseBetweenVersesEnabledNotifier,
                              builder: (context, pauseEnabled, _) {
                                return ValueListenableBuilder<int>(
                                  valueListenable:
                                      manager.pauseBetweenVersesSecondsNotifier,
                                  builder: (context, pauseSeconds, _) {
                                    return ValueListenableBuilder<
                                      VersePauseState
                                    >(
                                      valueListenable:
                                          manager.versePauseStateNotifier,
                                      builder: (context, pauseState, _) {
                                        final displaySeconds =
                                            pauseState.isPaused
                                            ? '${pauseState.remainingSeconds}s'
                                            : (pauseEnabled
                                                  ? '${pauseSeconds}s'
                                                  : '0s');
                                        return TextButton(
                                          key: const ValueKey(
                                            'audio_verse_pause_button',
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 6,
                                            ),
                                            minimumSize: const Size(44, 40),
                                            visualDensity:
                                                VisualDensity.compact,
                                            foregroundColor:
                                                colorScheme.onSurfaceVariant,
                                          ),
                                          onPressed: () =>
                                              _showVersePausePicker(context),
                                          child: Text(displaySeconds),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Bottom Outlined Action Chips: Repeat, Context
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        // Repeat Behavior (Stop after / Repeat / Continue after)
                        ValueListenableBuilder<AudioRepeatBehavior>(
                          valueListenable: manager.repeatBehaviorNotifier,
                          builder: (context, repeatBehavior, _) {
                            final isHighlighted =
                                repeatBehavior !=
                                AudioRepeatBehavior.continueOn;
                            return OutlinedButton(
                              key: const ValueKey('audio_repeat_chip'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                visualDensity: VisualDensity.compact,
                                foregroundColor: isHighlighted
                                    ? colorScheme.primary
                                    : null,
                              ),
                              onPressed: () => _showRepeatPicker(context),
                              child: Text(repeatBehavior.label),
                            );
                          },
                        ),

                        // Playback Context (Chapter / Verse / Range)
                        ValueListenableBuilder<AudioPlayContext>(
                          valueListenable: manager.playContextNotifier,
                          builder: (context, playContext, _) {
                            return ValueListenableBuilder<Reference?>(
                              valueListenable: manager.activeRangeNotifier,
                              builder: (context, activeRange, _) {
                                final label = _formatContextButtonLabel(
                                  playContext,
                                  activeRange,
                                );
                                final isHighlighted =
                                    playContext != AudioPlayContext.chapter;
                                return OutlinedButton(
                                  key: const ValueKey('audio_context_chip'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: isHighlighted
                                        ? colorScheme.primary
                                        : null,
                                  ),
                                  onPressed: () => _showContextPicker(context),
                                  child: Text(label),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
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
