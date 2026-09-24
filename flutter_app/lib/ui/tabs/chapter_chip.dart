import 'package:flutter/material.dart';
import 'bible_tab.dart';

/// A single tab chip. Supports:
/// - Tap to activate / navigate
/// - Tap the × to close (active tab only)
/// - Downward fling to close (animates the chip sliding off the bottom)
class ChapterChip extends StatefulWidget {
  const ChapterChip({
    super.key,
    required this.tab,
    required this.isActive,
    required this.onTap,
    this.onClose,
  });

  final BibleTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  @override
  State<ChapterChip> createState() => _ChapterChipState();
}

class _ChapterChipState extends State<ChapterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Velocity threshold (pixels/second) to count as a fling downward.
  static const double _flingVelocityThreshold = 300.0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 3),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleFlingClose() {
    if (widget.onClose == null) return;
    _slideController.forward().then((_) {
      widget.onClose?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = widget.isActive
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    final foregroundColor = widget.isActive
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return GestureDetector(
      // Detect downward fling on the whole chip.
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > _flingVelocityThreshold) {
          _handleFlingClose();
        }
      },
      child: SlideTransition(
        position: _slideAnimation,
        child: SizedBox(
          height: 36.0,
          child: Material(
            color: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
              side: widget.isActive
                  ? BorderSide(color: colorScheme.primary, width: 1.2)
                  : BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 10.0,
                  right: widget.isActive && widget.onClose != null ? 4.0 : 10.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.tab.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: foregroundColor,
                        fontWeight: widget.isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (widget.isActive && widget.onClose != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onClose,
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: foregroundColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
