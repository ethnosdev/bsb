import 'package:flutter/material.dart';
import 'bible_tab.dart';
import 'tab_manager.dart';

class ChapterTabsSheet extends StatelessWidget {
  const ChapterTabsSheet({
    super.key,
    required this.tabManager,
    this.onActiveTabTapped,
  });

  final TabManager tabManager;
  final void Function(BibleTab activeTab)? onActiveTabTapped;

  static Future<void> show(
    BuildContext context,
    TabManager tabManager, {
    void Function(BibleTab activeTab)? onActiveTabTapped,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ChapterTabsSheet(
        tabManager: tabManager,
        onActiveTabTapped: onActiveTabTapped,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: tabManager,
      builder: (context, child) {
        final tabs = tabManager.tabs;
        final activeTabId = tabManager.activeTabId;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Open Chapters',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${tabs.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: tabs.isEmpty
                      ? Center(
                          child: Text(
                            'No open chapters',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ReorderableListView.builder(
                          scrollController: scrollController,
                          itemCount: tabs.length,
                          buildDefaultDragHandles: false,
                          onReorderItem: (oldIndex, newIndex) {
                            tabManager.reorderItem(oldIndex, newIndex);
                          },
                          proxyDecorator: (child, index, animation) {
                            return Material(
                              color: colorScheme.surfaceContainerHighest,
                              elevation: 4.0,
                              shadowColor: Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                              child: child,
                            );
                          },
                          itemBuilder: (context, index) {
                            final tab = tabs[index];
                            final isActive = tab.id == activeTabId;

                            return ReorderableDelayedDragStartListener(
                              key: ValueKey(tab.id),
                              index: index,
                              child: Dismissible(
                                key: ValueKey('dismiss_${tab.id}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  color: colorScheme.errorContainer,
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                                onDismissed: (_) {
                                  tabManager.closeTab(tab.id);
                                  if (tabManager.tabs.isEmpty) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isActive
                                        ? colorScheme.primary
                                        : colorScheme.surfaceContainerHighest,
                                    child: Text(
                                      tab.label.split(' ').first,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isActive
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    tab.fullTitle,
                                    style: TextStyle(
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isActive
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    tooltip: 'Close tab',
                                    onPressed: () {
                                      tabManager.closeTab(tab.id);
                                      if (tabManager.tabs.isEmpty) {
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                  selected: isActive,
                                  onTap: () {
                                    if (isActive) {
                                      Navigator.pop(context);
                                      onActiveTabTapped?.call(tab);
                                    } else {
                                      tabManager.selectTab(tab.id);
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
