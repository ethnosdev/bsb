import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/home/book_chooser.dart';
import 'package:bsb/ui/home/drawer.dart';
import 'package:bsb/ui/search/search_page.dart';
import 'package:bsb/ui/tabs/chapter_tabs_bar.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:bsb/ui/text/text_screen.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _tabManager = getIt<TabManager>();
  final _chapterChooserNotifier = ValueNotifier<(int, int)?>(null);

  @override
  void dispose() {
    _chapterChooserNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _tabManager,
      builder: (context, child) {
        final tabs = _tabManager.tabs;
        final activeTab = _tabManager.activeTab;
        final isAdding = _tabManager.isAddingTab;
        final hasTabs = tabs.isNotEmpty && activeTab != null;

        return PopScope(
          canPop: !isAdding,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && isAdding) {
              _tabManager.cancelAddingTab();
            }
          },
          child: Scaffold(
            drawer: const AppDrawer(),
            appBar: AppBar(
              title: !hasTabs
                  ? const Text('Berean Standard Bible')
                  : ChapterTabsBar(
                      tabManager: _tabManager,
                      onActiveTabTapped: (tab) {
                        final chapterCount =
                            bookIdToChapterCountMap[tab.bookId] ?? 1;
                        _chapterChooserNotifier.value =
                            (tab.bookId, chapterCount);
                      },
                    ),
              leading: isAdding
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Cancel',
                      onPressed: _tabManager.cancelAddingTab,
                    )
                  : null,
              actions: [
                if (isAdding)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancel',
                    onPressed: _tabManager.cancelAddingTab,
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Search',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchPage(
                            currentBookId: activeTab?.bookId,
                          ),
                        ),
                      );
                    },
                  ),
                  if (hasTabs)
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Open Chapter',
                      onPressed: _tabManager.startAddingTab,
                    ),
                ],
              ],
            ),
            body: (!hasTabs || isAdding)
                ? SafeArea(
                    child: BookChooser(
                      onSelected: (bookId, chapter, [sectionHeading]) {
                        _tabManager.openTab(bookId, chapter, sectionHeading);
                      },
                    ),
                  )
                : TextScreen(
                    key: const ValueKey('text_reader_screen'),
                    bookId: activeTab.bookId,
                    chapter: activeTab.chapter,
                    initialSectionHeading: activeTab.sectionHeading,
                    initialTargetVerse: activeTab.targetVerse,
                    chapterChooserNotifier: _chapterChooserNotifier,
                    onChapterChanged: (bookId, chapter) {
                      _tabManager.updateActiveChapter(bookId, chapter);
                    },
                  ),
          ),
        );
      },
    );
  }
}
