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
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: spacing),
                  ChapterChip(
                    tab: tabs[i],
                    isActive: tabs[i].id == activeTab.id,
                    onTap: () {
                      if (tabs[i].id == activeTab.id) {
                        onActiveTabTapped(activeTab);
                      } else {
                        tabManager.selectTab(tabs[i].id);
                      }
                    },
                    onClose: () => tabManager.closeTab(tabs[i].id),
                  ),
                ],
              ],
            ),
          );
        }

        // Overflow: show composite chip
        return CompositeChapterChip(
          activeTab: activeTab,
          otherTabsCount: tabs.length - 1,
          onTap: () => ChapterTabsSheet.show(context, tabManager),
        );
      },
    );
  }
}
