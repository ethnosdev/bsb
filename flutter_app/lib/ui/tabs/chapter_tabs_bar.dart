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
  });

  final TabManager tabManager;
  final void Function(BibleTab activeTab) onActiveTabTapped;

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

  @override
  Widget build(BuildContext context) {
    final tabs = tabManager.tabs;
    final activeTab = tabManager.activeTab;

    if (tabs.isEmpty || activeTab == null) {
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
          return SizedBox(
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
          );
        }

        // Overflow: show composite chip
        return Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: CompositeChapterChip(
              activeTab: activeTab,
              otherTabsCount: tabs.length - 1,
              onTap: () => ChapterTabsSheet.show(context, tabManager),
            ),
          ),
        );
      },
    );
  }
}
