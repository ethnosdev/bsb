import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/audio/audio_playback_manager.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/audio/audio_player_bottom_bar.dart';
import 'package:bsb/ui/home/book_chooser.dart';
import 'package:bsb/ui/home/drawer.dart';
import 'package:bsb/ui/home/list_book_chooser.dart';
import 'package:bsb/ui/search/search_page.dart';
import 'package:bsb/ui/settings/user_settings.dart';
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
  AudioPlaybackManager? _cachedAudioManager;

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<AudioPlaybackManager>()) {
      _cachedAudioManager = getIt<AudioPlaybackManager>();
      _cachedAudioManager!.isPlayerVisible
          .addListener(_onPlayerVisibilityChanged);
    }
  }

  void _onPlayerVisibilityChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  AudioPlaybackManager? get _audioManager {
    if (_cachedAudioManager == null &&
        getIt.isRegistered<AudioPlaybackManager>()) {
      _cachedAudioManager = getIt<AudioPlaybackManager>();
      _cachedAudioManager!.isPlayerVisible
          .addListener(_onPlayerVisibilityChanged);
    }
    return _cachedAudioManager;
  }

  @override
  void dispose() {
    _cachedAudioManager?.isPlayerVisible
        .removeListener(_onPlayerVisibilityChanged);
    _chapterChooserNotifier.dispose();
    super.dispose();
  }

  Widget _buildBookChooser() {
    void onSelected(int bookId, int chapter, [String? sectionHeading]) {
      _tabManager.openTab(bookId, chapter, sectionHeading);
    }

    final appState = getIt.isRegistered<AppState>() ? getIt<AppState>() : null;
    if (appState != null) {
      return ValueListenableBuilder<BookChooserStyle>(
        valueListenable: appState.bookChooserStyleNotifier,
        builder: (context, style, _) {
          if (style == BookChooserStyle.list) {
            return ListBookChooser(onSelected: onSelected);
          }
          return BookChooser(onSelected: onSelected);
        },
      );
    }

    final userSettings =
        getIt.isRegistered<UserSettings>() ? getIt<UserSettings>() : null;
    final style = userSettings?.bookChooserStyle ?? BookChooserStyle.grid;
    if (style == BookChooserStyle.list) {
      return ListBookChooser(onSelected: onSelected);
    }
    return BookChooser(onSelected: onSelected);
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = _audioManager;

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
                  if (!hasTabs)
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
                    )
                  else ...[
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Open Chapter',
                      onPressed: _tabManager.startAddingTab,
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'More options',
                      onSelected: (value) {
                        if (value == 'search') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchPage(
                                currentBookId: activeTab.bookId,
                              ),
                            ),
                          );
                        } else if (value == 'play') {
                          audioManager?.playOrToggleChapter(
                            activeTab.bookId,
                            activeTab.chapter,
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'search',
                          child: Row(
                            children: [
                              Icon(Icons.search),
                              SizedBox(width: 12),
                              Text('Search'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'play',
                          child: Row(
                            children: [
                              Icon(Icons.play_arrow),
                              SizedBox(width: 12),
                              Text('Play Audio'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
            body: (!hasTabs || isAdding)
                ? SafeArea(
                    child: _buildBookChooser(),
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
            bottomNavigationBar: (audioManager != null &&
                    audioManager.isPlayerVisible.value)
                ? AudioPlayerBottomBar(manager: audioManager)
                : null,
          ),
        );
      },
    );
  }
}
