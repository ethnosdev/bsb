import 'package:flutter/material.dart';
import 'bible_tab.dart';
import 'chapter_chip.dart';
import 'chapter_tabs_sheet.dart';
import 'composite_chip.dart';
import 'tab_manager.dart';

class ChapterTabsBar extends StatelessWidget {
  const ChapterTabsBar({
    super.key,
    required this.tabManager,
    required this.onActiveTabTapped,
    this.onTabsSheetOpened,
    this.onEmptySpaceTapped,
  });

  final TabManager tabManager;
  final void Function(BibleTab activeTab) onActiveTabTapped;
  final VoidCallback? onTabsSheetOpened;
  final VoidCallback? onEmptySpaceTapped;

  static const double deadZoneWidth = 8.0;

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

  @override
  Widget build(BuildContext context) {
    final tabs = tabManager.tabs;
    final activeTab = tabManager.activeTab;

    if (tabs.isEmpty || activeTab == null) {
      if (onEmptySpaceTapped != null) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onEmptySpaceTapped,
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
                    tabManager.reorderItem(oldIndex, newIndex),
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
                            onActiveTabTapped(activeTab);
                          } else {
                            tabManager.selectTab(tab.id);
                          }
                        },
                        onClose: () => tabManager.closeTab(tab.id),
                      ),
                    ),
                  );
                },
              ),
            ),
          );

          final spaceAfterTabs = constraints.maxWidth - totalWidth;
          final hasTappableSpace = onEmptySpaceTapped != null &&
              spaceAfterTabs > deadZoneWidth;

          if (!hasTappableSpace) {
            return chipsWidget;
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              chipsWidget,
              Positioned(
                left: totalWidth + deadZoneWidth,
                top: 0,
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onEmptySpaceTapped,
                  child: const SizedBox.expand(),
                ),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: CompositeChapterChip(
              activeTab: activeTab,
              otherTabsCount: tabs.length - 1,
              onTap: () {
                onTabsSheetOpened?.call();
                ChapterTabsSheet.show(
                  context,
                  tabManager,
                  onActiveTabTapped: onActiveTabTapped,
                );
              },
              onCloseAll: () => tabManager.closeAllTabs(),
            ),
          ),
        );

        final spaceAfterComposite = constraints.maxWidth - compositeWidth;
        final hasTappableSpace = onEmptySpaceTapped != null &&
            spaceAfterComposite > deadZoneWidth;

        if (!hasTappableSpace) {
          return compositeWidget;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            compositeWidget,
            Positioned(
              left: compositeWidth + deadZoneWidth,
              top: 0,
              bottom: 0,
              right: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onEmptySpaceTapped,
                child: const SizedBox.expand(),
              ),
            ),
          ],
        );
      },
    );
  }
}
