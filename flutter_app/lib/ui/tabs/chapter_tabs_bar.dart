import 'package:flutter/material.dart';
import 'bible_tab.dart';
import 'chapter_chip.dart';
import 'chapter_tabs_sheet.dart';
import 'composite_chip.dart';
import 'tab_manager.dart';

class ChapterTabsBar extends StatefulWidget {
  const ChapterTabsBar({
    super.key,
    required this.tabManager,
    required this.onActiveTabTapped,
    this.onTabsSheetOpened,
    this.onEmptySpaceTapped,
    this.onCloseAll,
  });

  final TabManager tabManager;
  final void Function(BibleTab activeTab) onActiveTabTapped;
  final VoidCallback? onTabsSheetOpened;
  final VoidCallback? onEmptySpaceTapped;
  final VoidCallback? onCloseAll;

  static const double deadZoneWidth = 8.0;

  @override
  State<ChapterTabsBar> createState() => _ChapterTabsBarState();
}

class _ChapterTabsBarState extends State<ChapterTabsBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  static const double _flingVelocityThreshold = 300.0;
  double _verticalDragDistance = 0.0;

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

  void _handleCloseAll() {
    if (widget.onCloseAll != null) {
      widget.onCloseAll!();
    } else {
      widget.tabManager.closeAllTabs();
    }
  }

  void _handleFlingCloseAll() {
    if (_slideController.isAnimating) return;
    _slideController.forward().then((_) {
      _handleCloseAll();
      if (mounted) {
        _slideController.reset();
      }
    });
  }

  double _estimateChipWidth(BuildContext context, BibleTab tab, bool isActive) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: tab.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              letterSpacing: 0.5,
            ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final textWidth = textPainter.width;
    if (isActive) {
      return textWidth + 42.0; // Padding + spacing + close icon + borders
    } else {
      return textWidth + 24.0; // Padding + borders
    }
  }

  double _estimateCompositeChipWidth(
    BuildContext context,
    BibleTab activeTab,
    int otherTabsCount,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: activeTab.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final countPainter = TextPainter(
      text: TextSpan(
        text: '+$otherTabsCount',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 10.0,
            ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    return textPainter.width + countPainter.width + 68.4;
  }

  Widget _buildEmptySpaceDetector({required double left}) {
    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      right: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onEmptySpaceTapped,
        onVerticalDragStart: (_) {
          _verticalDragDistance = 0.0;
        },
        onVerticalDragUpdate: (details) {
          _verticalDragDistance += details.primaryDelta ?? 0.0;
        },
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0.0;
          if (velocity > _flingVelocityThreshold ||
              _verticalDragDistance > 25.0) {
            _handleFlingCloseAll();
          }
        },
        child: const SizedBox.expand(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.tabManager.tabs;
    final activeTab = widget.tabManager.activeTab;

    if (tabs.isEmpty || activeTab == null) {
      if (widget.onEmptySpaceTapped != null) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onEmptySpaceTapped,
          child: const SizedBox.expand(),
        );
      }
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 6.0;
        double totalWidth = 0.0;

        for (int i = 0; i < tabs.length; i++) {
          final tab = tabs[i];
          final isActive = tab.id == activeTab.id;
          totalWidth += _estimateChipWidth(context, tab, isActive);
          if (i > 0) totalWidth += spacing;
        }

        // If all chips fit within available width, show them individually
        if (totalWidth <= constraints.maxWidth) {
          final chipsWidget = Align(
            alignment: Alignment.centerLeft,
            child: SlideTransition(
              position: _slideAnimation,
              child: SizedBox(
                height: 36,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  padding: EdgeInsets.zero,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      color: Colors.transparent,
                      elevation: 6.0,
                      shadowColor: Colors.black26,
                      child: child,
                    );
                  },
                  itemCount: tabs.length,
                  onReorderItem: (oldIndex, newIndex) =>
                      widget.tabManager.reorderItem(oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final tab = tabs[index];
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(tab.id),
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: ChapterChip(
                          tab: tab,
                          isActive: tab.id == activeTab.id,
                          onTap: () {
                            if (tab.id == activeTab.id) {
                              widget.onActiveTabTapped(activeTab);
                            } else {
                              widget.tabManager.selectTab(tab.id);
                            }
                          },
                          onClose: () => widget.tabManager.closeTab(tab.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );

          final spaceAfterTabs = constraints.maxWidth - totalWidth;
          final hasTappableSpace = widget.onEmptySpaceTapped != null &&
              spaceAfterTabs > ChapterTabsBar.deadZoneWidth;

          if (!hasTappableSpace) {
            return chipsWidget;
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              chipsWidget,
              _buildEmptySpaceDetector(
                left: totalWidth + ChapterTabsBar.deadZoneWidth,
              ),
            ],
          );
        }

        // Overflow: show composite chip
        final compositeWidth = _estimateCompositeChipWidth(
          context,
          activeTab,
          tabs.length - 1,
        );
        final compositeWidget = Align(
          alignment: Alignment.centerLeft,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: CompositeChapterChip(
                activeTab: activeTab,
                otherTabsCount: tabs.length - 1,
                onTap: () {
                  widget.onTabsSheetOpened?.call();
                  ChapterTabsSheet.show(
                    context,
                    widget.tabManager,
                    onActiveTabTapped: widget.onActiveTabTapped,
                  );
                },
                onCloseAll: _handleCloseAll,
              ),
            ),
          ),
        );

        final spaceAfterComposite = constraints.maxWidth - compositeWidth;
        final hasTappableSpace = widget.onEmptySpaceTapped != null &&
            spaceAfterComposite > ChapterTabsBar.deadZoneWidth;

        if (!hasTappableSpace) {
          return compositeWidget;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            compositeWidget,
            _buildEmptySpaceDetector(
              left: compositeWidth + ChapterTabsBar.deadZoneWidth,
            ),
          ],
        );
      },
    );
  }
}
