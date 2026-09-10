import 'package:flutter/material.dart';

sealed class ScrubberItem {
  const ScrubberItem();
}

class VerseLabelItem extends ScrubberItem {
  const VerseLabelItem(this.verse);
  final int verse;
}

class VerseDotItem extends ScrubberItem {
  const VerseDotItem();
}

class VerseScrubber extends StatefulWidget {
  const VerseScrubber({
    super.key,
    required this.verses,
    required this.isVisible,
    this.isActive = true,
    required this.onVerseSelected,
    required this.onSwipeIn,
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

  /// Callback when a verse is selected (on tap or drag release).
  final ValueChanged<int> onVerseSelected;

  /// Callback when the user swipes in from the right edge.
  final VoidCallback onSwipeIn;

  /// Optional callback when the user swipes right on the bar to dismiss it.
  final VoidCallback? onDismiss;

  /// Called when the user touches/scrubs the bar (to pause auto-dismiss timers).
  final VoidCallback? onInteractionStart;

  /// Called when the user finishes touching/scrubbing the bar (to resume auto-dismiss timers).
  final VoidCallback? onInteractionEnd;

  @override
  State<VerseScrubber> createState() => _VerseScrubberState();
}

class _VerseScrubberState extends State<VerseScrubber> {
  bool _isDragging = false;
  int _currentScrubbedVerse = 1;
  double _touchY = 0.0;
  double? _edgeStartX;

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

  List<ScrubberItem> _buildItems(List<int> verses) {
    final total = verses.length;
    if (total <= 30) {
      return verses.map((v) => VerseLabelItem(v)).toList();
    }

    final items = <ScrubberItem>[];
    if (total <= 60) {
      // Show every 5th verse + first and last
      for (var i = 0; i < total; i++) {
        final v = verses[i];
        if (i == 0 || i == total - 1 || v % 5 == 0) {
          items.add(VerseLabelItem(v));
        } else if (v % 5 == 2 || (i > 0 && items.last is VerseLabelItem)) {
          if (items.isEmpty || items.last is! VerseDotItem) {
            items.add(const VerseDotItem());
          }
        }
      }
      return items;
    }

    // Greater than 60 verses (e.g. Psalm 119 with 176 verses)
    final interval = total > 90 ? 20 : 10;
    for (var i = 0; i < total; i++) {
      final v = verses[i];
      if (i == 0 || i == total - 1 || v % interval == 0) {
        items.add(VerseLabelItem(v));
      } else if (v % (interval ~/ 2) == 0) {
        if (items.isEmpty || items.last is! VerseDotItem) {
          items.add(const VerseDotItem());
        }
      }
    }
    return items;
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
    // Edge case: No need to show verse bar at all if there are less than 10 verses (9 or fewer)
    if (widget.verses.length < 10) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final items = _buildItems(widget.verses);
    final isActuallyVisible = widget.isVisible && widget.isActive;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeight = constraints.maxHeight;
        final itemHeight = widget.verses.length <= 30 ? 22.0 : 18.0;
        final calculatedBarHeight =
            (items.length * itemHeight).clamp(160.0, stackHeight - 48.0);
        final barTop = (stackHeight - calculatedBarHeight) / 2;

        const double bubbleHeight = 44.0;
        // Clamp the bubble strictly inside the visible stack bounds
        final clampedBubbleTop =
            (_touchY - (bubbleHeight / 2)).clamp(12.0, stackHeight - bubbleHeight - 12.0);

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Edge swipe-in detector: active only when bar is offscreen AND page is active
            Positioned(
              key: const ValueKey('verse_scrubber_edge_detector_positioned'),
              right: 0,
              top: barTop,
              height: calculatedBarHeight,
              width: 28,
              child: IgnorePointer(
                ignoring: isActuallyVisible || !widget.isActive,
                child: Listener(
                  key: const ValueKey('verse_scrubber_edge_detector'),
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) {
                    _edgeStartX = event.position.dx;
                  },
                  onPointerMove: (event) {
                    if (_edgeStartX != null &&
                        (event.position.dx - _edgeStartX!) < -8.0) {
                      _edgeStartX = null;
                      widget.onSwipeIn();
                    }
                  },
                  onPointerUp: (_) => _edgeStartX = null,
                  onPointerCancel: (_) => _edgeStartX = null,
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: items.map((item) {
                          switch (item) {
                            case VerseLabelItem(:final verse):
                              return Text(
                                '$verse',
                                style: TextStyle(
                                  fontSize: items.length > 25 ? 9.5 : 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.0,
                                ),
                              );
                            case VerseDotItem():
                              return Container(
                                width: 3.5,
                                height: 3.5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              );
                          }
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
