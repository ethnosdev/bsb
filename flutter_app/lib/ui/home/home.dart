import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/audio/audio_playback_manager.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/audio/audio_player_bottom_bar.dart';
import 'package:bsb/ui/home/book_chooser.dart';
import 'package:bsb/ui/home/drawer.dart';
import 'package:bsb/ui/home/list_book_chooser.dart';
import 'package:bsb/ui/playlists/playlist_share_handler.dart';
import 'package:bsb/ui/search/search_page.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/chapter_tabs_bar.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:bsb/ui/text/text_screen.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _tabManager = getIt<TabManager>();
  final _chapterChooserNotifier = ValueNotifier<(int, int, int?)?>(null);
  AudioPlaybackManager? _cachedAudioManager;
  PlaylistShareHandler? _playlistShareHandler;
  bool _isDistractionFree = false;

  bool _resolveShowVerseGrid() {
    final appState = getIt.isRegistered<AppState>() ? getIt<AppState>() : null;
    if (appState != null) {
      return appState.showVerseGridNotifier.value;
    }
    final userSettings =
        getIt.isRegistered<UserSettings>() ? getIt<UserSettings>() : null;
    return userSettings?.showVerseGrid ?? false;
  }

  @override
  void initState() {
    super.initState();
    _tabManager.addListener(_onTabManagerChanged);
    if (getIt.isRegistered<AudioPlaybackManager>()) {
      _cachedAudioManager = getIt<AudioPlaybackManager>();
      _cachedAudioManager!.isPlayerVisible
          .addListener(_onPlayerVisibilityChanged);
      _cachedAudioManager!.playbackErrorNotifier.addListener(_onAudioError);
    }
    _playlistShareHandler = PlaylistShareHandler();
    _playlistShareHandler!.initDeepLinks(context);
  }

  void _onTabManagerChanged() {
    if (_chapterChooserNotifier.value != null) {
      _chapterChooserNotifier.value = null;
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
    _tabManager.removeListener(_onTabManagerChanged);
    if (_isDistractionFree) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _cachedAudioManager?.isPlayerVisible
        .removeListener(_onPlayerVisibilityChanged);
    _cachedAudioManager?.playbackErrorNotifier.removeListener(_onAudioError);
    _playlistShareHandler?.dispose();
    _chapterChooserNotifier.dispose();
    super.dispose();
  }

  void _onAudioError() {
    final err = _cachedAudioManager?.playbackErrorNotifier.value;
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _toggleDistractionFree() {
    if (_isDistractionFree) {
      _exitDistractionFree();
    } else {
      _enterDistractionFree();
    }
  }

  void _enterDistractionFree() {
    setState(() {
      _isDistractionFree = true;
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitDistractionFree() {
    setState(() {
      _isDistractionFree = false;
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Widget _buildBookChooser() {
    void onSelected(int bookId, int chapter, [String? sectionHeading]) {
      _chapterChooserNotifier.value = null;
      _tabManager.openTab(bookId, chapter, sectionHeading);
    }

    void onVerseSelected(int bookId, int chapter, int verse) {
      _chapterChooserNotifier.value = null;
      _tabManager.openTab(bookId, chapter, null, verse);
    }

    final appState = getIt.isRegistered<AppState>() ? getIt<AppState>() : null;
    if (appState != null) {
      return ValueListenableBuilder<BookChooserStyle>(
        valueListenable: appState.bookChooserStyleNotifier,
        builder: (context, style, _) {
          if (style == BookChooserStyle.list) {
            return ListBookChooser(
              onSelected: onSelected,
              onVerseSelected: onVerseSelected,
            );
          }
          return BookChooser(
            onSelected: onSelected,
            onVerseSelected: onVerseSelected,
          );
        },
      );
    }

    final userSettings =
        getIt.isRegistered<UserSettings>() ? getIt<UserSettings>() : null;
    final style = userSettings?.bookChooserStyle ?? BookChooserStyle.grid;
    if (style == BookChooserStyle.list) {
      return ListBookChooser(
        onSelected: onSelected,
        onVerseSelected: onVerseSelected,
      );
    }
    return BookChooser(
      onSelected: onSelected,
      onVerseSelected: onVerseSelected,
    );
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

        if (!hasTabs && _isDistractionFree) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isDistractionFree) {
              _exitDistractionFree();
            }
          });
        }

        return ValueListenableBuilder<(int, int, int?)?>(
          valueListenable: _chapterChooserNotifier,
          builder: (context, chapterChooserValue, _) {
            return PopScope(
              canPop: !isAdding &&
                  !_isDistractionFree &&
                  chapterChooserValue == null,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) {
                  if (_chapterChooserNotifier.value != null) {
                    _chapterChooserNotifier.value = null;
                  } else if (_isDistractionFree) {
                    _exitDistractionFree();
                  } else if (isAdding) {
                    _tabManager.cancelAddingTab();
                  }
                }
              },
          child: Scaffold(
            drawer: _isDistractionFree ? null : const AppDrawer(),
            onDrawerChanged: (isOpen) {
              if (isOpen) {
                _chapterChooserNotifier.value = null;
              }
            },
            drawerEnableOpenDragGesture: !_isDistractionFree,
            extendBodyBehindAppBar: hasTabs && !isAdding,
            appBar: (hasTabs && !isAdding)
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(kToolbarHeight),
                    child: AnimatedSlide(
                      key: const Key('app_bar_animated_slide'),
                      offset: _isDistractionFree
                          ? const Offset(0, -1)
                          : Offset.zero,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: AnimatedOpacity(
                        opacity: _isDistractionFree ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: IgnorePointer(
                          ignoring: _isDistractionFree,
                          child: AppBar(
                            titleSpacing: 0,
                            title: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                _chapterChooserNotifier.value = null;
                                _tabManager.startAddingTab();
                              },
                              child: SizedBox(
                                height: kToolbarHeight,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ChapterTabsBar(
                                    tabManager: _tabManager,
                                    onTabsSheetOpened: () {
                                      _chapterChooserNotifier.value = null;
                                    },
                                    onActiveTabTapped: (tab) {
                                      if (_chapterChooserNotifier.value !=
                                          null) {
                                        _chapterChooserNotifier.value = null;
                                        return;
                                      }
                                      final chapterCount =
                                          bookIdToChapterCountMap[tab.bookId] ??
                                              1;
                                      final initialChapter =
                                          _resolveShowVerseGrid()
                                              ? tab.chapter
                                              : null;
                                      _chapterChooserNotifier.value = (
                                        tab.bookId,
                                        chapterCount,
                                        initialChapter,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            actions: [
                              IconButton(
                                icon: const Icon(Icons.add),
                                tooltip: 'Open Chapter',
                                onPressed: () {
                                  _chapterChooserNotifier.value = null;
                                  _tabManager.startAddingTab();
                                },
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                tooltip: 'More options',
                                onSelected: (value) {
                                  _chapterChooserNotifier.value = null;
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
                                        Expanded(child: Text('Search')),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'play',
                                    child: Row(
                                      children: [
                                        Icon(Icons.play_arrow),
                                        SizedBox(width: 12),
                                        Expanded(child: Text('Play Audio')),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : AppBar(
                    titleSpacing: 0,
                    title: const Text('Berean Standard Bible'),
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
                      else
                        IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: 'Search',
                          onPressed: () {
                            _chapterChooserNotifier.value = null;
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
                    ],
                  ),
            body: (!hasTabs || isAdding)
                ? SafeArea(
                    child: _buildBookChooser(),
                  )
                : SafeArea(
                    top: false,
                    bottom: false,
                    child: TextScreen(
                      key: const ValueKey('text_reader_screen'),
                      bookId: activeTab.bookId,
                      chapter: activeTab.chapter,
                      initialSectionHeading: activeTab.sectionHeading,
                      initialTargetVerse: activeTab.targetVerse,
                      chapterChooserNotifier: _chapterChooserNotifier,
                      onToggleDistractionFree: _toggleDistractionFree,
                      onChapterChanged:
                          (bookId, chapter, [sectionHeading, targetVerse]) {
                        _tabManager.updateActiveChapter(
                          bookId,
                          chapter,
                          sectionHeading,
                          targetVerse,
                        );
                      },
                    ),
                  ),
            bottomNavigationBar: (!_isDistractionFree &&
                    audioManager != null &&
                    audioManager.isPlayerVisible.value)
                ? AudioPlayerBottomBar(manager: audioManager)
                : null,
          ),
        );
      },
    );
  },
);
  }
}
