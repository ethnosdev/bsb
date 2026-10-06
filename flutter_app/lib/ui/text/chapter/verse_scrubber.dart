import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class VerseScrubber extends StatefulWidget {
  const VerseScrubber({
    super.key,
    required this.verses,
    required this.isVisible,
    this.isActive = true,
    this.canScroll = true,
    this.hasSelection = false,
    this.isDistractionFree = false,
    required this.onVerseSelected,
    this.onDismiss,
    this.onInteractionStart,
    this.onInteractionEnd,
  });

  /// All available verse numbers in the current chapter (e.g. [1, 2, ..., 31]).
  final List<int> verses;

  /// Whether the scrubber bar is currently visible on screen.
  final bool isVisible;

  /// Whether the host page is currently the active chapter.
  final bool isActive;

  /// Whether the chapter content overflows the viewport and requires scrolling.
  final bool canScroll;

  /// Whether scripture text is currently selected (disables edge drag activation).
  final bool hasSelection;

  /// Whether the app is currently in full-screen (distraction-free) mode where the app bar is hidden.
  final bool isDistractionFree;

  /// Callback when a verse is selected (on tap or drag release).
  final ValueChanged<int> onVerseSelected;

  /// Optional callback when the user swipes right on the bar to dismiss it.
  final VoidCallback? onDismiss;

  /// Called when the user touches/scrubs the bar (to pause auto-dismiss timers).
  final VoidCallback? onInteractionStart;

  /// Called when the user finishes touching/scrubbing the bar (to resume auto-dismiss timers).
  final VoidCallback? onInteractionEnd;

  /// Computes the list of verse numbers to display along the scrubber bar
  /// given the maximum number of labels that can comfortably fit vertically.
  static List<int> computeDisplayVerses(List<int> verses, int maxLabels) {
    if (verses.length <= maxLabels) {
      return verses;
    }

    const steps = [2, 5, 10, 20, 25, 50];
    for (final step in steps) {
      final candidate = _buildVersesWithStep(verses, step);
      if (candidate.length <= maxLabels) {
        return candidate;
      }
    }

    return _buildVersesWithStep(verses, steps.last);
  }

  static List<int> _buildVersesWithStep(List<int> verses, int step) {
    if (verses.isEmpty) return const [];
    final result = <int>[];
    final first = verses.first;
    final last = verses.last;

    for (final v in verses) {
      if (v == first) {
        result.add(v);
      } else if (step == 2) {
        if ((v - first) % 2 == 0) {
          result.add(v);
        }
      } else if (v % step == 0) {
        result.add(v);
      }
    }

    if (result.isEmpty || result.last != last) {
      if (result.length > 1 && (last - result.last) <= (step * 0.5)) {
        result[result.length - 1] = last;
      } else {
        result.add(last);
      }
    }

    return result;
  }

  @override
  State<VerseScrubber> createState() => _VerseScrubberState();
}

class _VerseScrubberState extends State<VerseScrubber> {
  bool _isDragging = false;
  int _currentScrubbedVerse = 1;
  double _touchY = 0.0;
  double? _lastDragGlobalX;

  @override
  void initState() {
    super.initState();
    if (widget.verses.isNotEmpty) {
      _currentScrubbedVerse = widget.verses.first;
    }
  }

  @override
  void didUpdateWidget(covariant VerseScrubber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.verses.isNotEmpty &&
        !widget.verses.contains(_currentScrubbedVerse)) {
      _currentScrubbedVerse = widget.verses.first;
    }
    if (!widget.isActive && _isDragging) {
      _cancelScrub();
    }
  }

  void _updateScrub({
    required double localYInScrubber,
    required double barTop,
    required double barHeight,
  }) {
    if (widget.verses.isEmpty || barHeight <= 0) return;

    final barLocalY = localYInScrubber - barTop;
    final normalized = (barLocalY / barHeight).clamp(0.0, 1.0);
    final targetIndex = (normalized * (widget.verses.length - 1))
        .round()
        .clamp(0, widget.verses.length - 1);
    final selectedVerse = widget.verses[targetIndex];

    setState(() {
      _currentScrubbedVerse = selectedVerse;
      _touchY = localYInScrubber;
    });
  }

  void _finishScrub() {
    if (_isDragging) {
      setState(() {
        _isDragging = false;
      });
      widget.onVerseSelected(_currentScrubbedVerse);
      widget.onInteractionEnd?.call();
    }
  }

  void _cancelScrub() {
    if (_isDragging) {
      setState(() {
        _isDragging = false;
      });
      widget.onInteractionEnd?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Edge case: No need to show verse bar at all if there are less than 4 verses
    // or if the chapter fits completely on screen without scrolling.
    if (widget.verses.length < 4 || !widget.canScroll) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isActuallyVisible =
        (widget.isVisible || _isDragging) && widget.isActive;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeight = constraints.maxHeight;
        final totalVerses = widget.verses.length;

        final mediaQuery = MediaQuery.paddingOf(context);
        final topSafeArea = mediaQuery.top;
        final bottomSafeArea = mediaQuery.bottom;
        final hasScaffoldAppBar = Scaffold.maybeOf(context)?.hasAppBar ?? false;
        final isAppBarShowing = hasScaffoldAppBar && !widget.isDistractionFree;

        final double topBound;
        if (hasScaffoldAppBar) {
          if (isAppBarShowing) {
            // In Scaffold with extendBodyBehindAppBar, topSafeArea already includes the app bar height
            topBound = topSafeArea + 12.0;
          } else {
            // Distraction-free: subtract the app bar height that Scaffold added to find actual status bar
            final rawTopSafeArea =
                (topSafeArea - kToolbarHeight).clamp(0.0, double.infinity);
            topBound = rawTopSafeArea > 0 ? (rawTopSafeArea + 8.0) : 16.0;
          }
        } else {
          topBound = topSafeArea > 0 ? (topSafeArea + 8.0) : 16.0;
        }

        final double bottomBound =
            bottomSafeArea > 0 ? (bottomSafeArea + 8.0) : 16.0;

        // For chapters with many verses, expand up to the full usable height of the screen
        // (strictly below the app bar and above the bottom safe area).
        // For shorter chapters, calculate proportional height centered within the usable area.
        final double usableHeight =
            (stackHeight - topBound - bottomBound).clamp(160.0, double.infinity);
        final double idealItemHeight = totalVerses <= 30 ? 20.0 : 16.0;
        final double calculatedBarHeight =
            (totalVerses * idealItemHeight).clamp(160.0, usableHeight);
        final double barTop =
            topBound + (usableHeight - calculatedBarHeight) / 2;

        const verticalPadding = 8.0;
        final availableHeight =
            (calculatedBarHeight - (verticalPadding * 2)).clamp(1.0, double.infinity);

        // A minimum height of 13.0dp per label guarantees crisp readability and breathing room.
        final maxLabels =
            (availableHeight / 13.0).floor().clamp(2, totalVerses);
        final displayVerses =
            VerseScrubber.computeDisplayVerses(widget.verses, maxLabels);

        final slotHeight = availableHeight / displayVerses.length;
        final fontSize = (slotHeight * 0.75).clamp(8.0, 10.5);
        const fontWeight = FontWeight.w600;

        const double bubbleHeight = 44.0;
        // Clamp the bubble strictly inside the visible stack bounds
        final clampedBubbleTop = (_touchY - (bubbleHeight / 2)).clamp(
          topBound,
          (stackHeight - bottomBound - bubbleHeight).clamp(topBound, double.infinity),
        );

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Right-edge vertical drag detector: active only when isActive and not hasSelection.
            // Translucent with hit-test pass-through so taps/long-presses/selection handles
            // reach the underlying scripture text when not dragging.
            Positioned(
              key: const ValueKey('verse_scrubber_edge_drag_detector_positioned'),
              right: 0,
              top: topBound,
              bottom: bottomBound,
              width: 34,
              child: IgnorePointer(
                ignoring: !widget.isActive || widget.hasSelection,
                child: _PassThroughHitTargetWidget(
                  child: RawGestureDetector(
                    key: const ValueKey('verse_scrubber_edge_drag_detector'),
                    behavior: HitTestBehavior.translucent,
                    gestures: {
                      _ScrubberDragGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                            _ScrubberDragGestureRecognizer
                          >(
                            () => _ScrubberDragGestureRecognizer(),
                            (instance) {
                              instance
                                ..onStart = (details) {
                                  final scrubberBox =
                                      context.findRenderObject() as RenderBox?;
                                  if (scrubberBox != null && scrubberBox.hasSize) {
                                    final localPos = scrubberBox.globalToLocal(
                                      details.globalPosition,
                                    );
                                    _lastDragGlobalX = details.globalPosition.dx;
                                    setState(() {
                                      _isDragging = true;
                                    });
                                    widget.onInteractionStart?.call();
                                    _updateScrub(
                                      localYInScrubber: localPos.dy,
                                      barTop: barTop,
                                      barHeight: calculatedBarHeight,
                                    );
                                  }
                                }
                                ..onUpdate = (details) {
                                  if (_isDragging) {
                                    if (_lastDragGlobalX != null &&
                                        (details.globalPosition.dx -
                                                _lastDragGlobalX!) >
                                            8.0 &&
                                        widget.onDismiss != null) {
                                      widget.onDismiss!();
                                      _cancelScrub();
                                      return;
                                    }
                                    _lastDragGlobalX = details.globalPosition.dx;
                                    final scrubberBox =
                                        context.findRenderObject() as RenderBox?;
                                    if (scrubberBox != null &&
                                        scrubberBox.hasSize) {
                                      final localPos = scrubberBox.globalToLocal(
                                        details.globalPosition,
                                      );
                                      _updateScrub(
                                        localYInScrubber: localPos.dy,
                                        barTop: barTop,
                                        barHeight: calculatedBarHeight,
                                      );
                                    }
                                  }
                                }
                                ..onEnd = (_) {
                                  _lastDragGlobalX = null;
                                  _finishScrub();
                                }
                                ..onCancel = () {
                                  _lastDragGlobalX = null;
                                  _cancelScrub();
                                };
                            },
                          ),
                    },
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),

            // Vertical Scrubber Bar with stable key: always animates smoothly between onscreen and offscreen
            Positioned(
              key: const ValueKey('verse_scrubber_bar_positioned'),
              right: 0,
              top: barTop,
              child: AnimatedSlide(
                key: const ValueKey('verse_scrubber_animated_slide'),
                offset: isActuallyVisible ? Offset.zero : const Offset(1.2, 0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: IgnorePointer(
                  ignoring: !widget.isActive,
                  child: Listener(
                    key: const ValueKey('verse_scrubber_gesture_area'),
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (event) {
                      final scrubberBox =
                          context.findRenderObject() as RenderBox?;
                      if (scrubberBox != null && scrubberBox.hasSize) {
                        final localPos =
                            scrubberBox.globalToLocal(event.position);
                        setState(() {
                          _isDragging = true;
                        });
                        widget.onInteractionStart?.call();
                        _updateScrub(
                          localYInScrubber: localPos.dy,
                          barTop: barTop,
                          barHeight: calculatedBarHeight,
                        );
                      }
                    },
                    onPointerMove: (event) {
                      if (_isDragging) {
                        // Swipe right on the bar dismisses it
                        if (event.delta.dx > 4.0 && widget.onDismiss != null) {
                          widget.onDismiss!();
                          _cancelScrub();
                          return;
                        }
                        final scrubberBox =
                            context.findRenderObject() as RenderBox?;
                        if (scrubberBox != null && scrubberBox.hasSize) {
                          final localPos =
                              scrubberBox.globalToLocal(event.position);
                          _updateScrub(
                            localYInScrubber: localPos.dy,
                            barTop: barTop,
                            barHeight: calculatedBarHeight,
                          );
                        }
                      }
                    },
                    onPointerUp: (_) => _finishScrub(),
                    onPointerCancel: (_) => _cancelScrub(),
                    child: Container(
                      width: 34,
                      height: calculatedBarHeight,
                      padding: EdgeInsets.symmetric(vertical: verticalPadding),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh
                            .withValues(alpha: 0.88),
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(16),
                        ),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.35),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(-1, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        children: displayVerses.map((verse) {
                          return Expanded(
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$verse',
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: fontWeight,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Floating overlay bubble directly left of the user's thumb
            if (_isDragging && widget.isActive)
              Positioned(
                key: const ValueKey('verse_scrubber_overlay_bubble_positioned'),
                right: 48,
                top: clampedBubbleTop,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(20),
                  color: theme.colorScheme.primary,
                  child: Container(
                    key: const ValueKey('verse_scrubber_overlay_bubble'),
                    constraints:
                        const BoxConstraints(minWidth: 44, minHeight: bubbleHeight),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    alignment: Alignment.center,
                    child: Text(
                      '$_currentScrubbedVerse',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PassThroughHitTargetWidget extends SingleChildRenderObjectWidget {
  const _PassThroughHitTargetWidget({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPassThroughHitTarget();
}

class _RenderPassThroughHitTarget extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position)) {
      hitTestChildren(result, position: position);
      return false;
    }
    return false;
  }
}

class _ScrubberDragGestureRecognizer extends VerticalDragGestureRecognizer {
  _ScrubberDragGestureRecognizer() {
    onlyAcceptDragOnThreshold = true;
  }

  Offset? _startGlobalPosition;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _startGlobalPosition = event.position;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent && _startGlobalPosition != null) {
      final totalDelta = event.position - _startGlobalPosition!;
      // If horizontal movement clearly dominates before vertical drag threshold is met,
      // reject this gesture so PageView (horizontal paging) can win immediately.
      if (totalDelta.dx.abs() > totalDelta.dy.abs() &&
          totalDelta.dx.abs() > 10.0) {
        resolve(GestureDisposition.rejected);
        _startGlobalPosition = null;
        return;
      }
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _startGlobalPosition = null;
    }
    super.handleEvent(event);
  }

  @override
  void rejectGesture(int pointer) {
    _startGlobalPosition = null;
    super.rejectGesture(pointer);
  }
}
