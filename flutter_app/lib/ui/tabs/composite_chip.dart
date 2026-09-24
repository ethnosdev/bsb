import 'package:flutter/material.dart';
import 'bible_tab.dart';

/// The composite chip shown when tabs overflow. Supports:
/// - Tap to open the tabs sheet
/// - Downward fling to close all open tabs (animates off screen)
class CompositeChapterChip extends StatefulWidget {
  const CompositeChapterChip({
    super.key,
    required this.activeTab,
    required this.otherTabsCount,
    required this.onTap,
    this.onCloseAll,
  });

  final BibleTab activeTab;
  final int otherTabsCount;
  final VoidCallback onTap;

  /// Called when the user flings the chip downward. Should close all tabs.
  final VoidCallback? onCloseAll;

  @override
  State<CompositeChapterChip> createState() => _CompositeChapterChipState();
}

class _CompositeChapterChipState extends State<CompositeChapterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

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
    if (widget.onCloseAll == null) return;
    _slideController.forward().then((_) {
      widget.onCloseAll?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
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
            color: colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
              side: BorderSide(color: colorScheme.primary, width: 1.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.activeTab.label,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '+${widget.otherTabsCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: colorScheme.onPrimaryContainer,
                    ),
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
