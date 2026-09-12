import 'dart:async';

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
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _tabManager = getIt<TabManager>();
  final _chapterChooserNotifier = ValueNotifier<(int, int)?>(null);
  AudioPlaybackManager? _cachedAudioManager;
  bool _isDistractionFree = false;
  bool _showDistractionFreeOverlay = false;
  Timer? _overlayHideTimer;
  Offset? _pointerDownPos;
  DateTime? _pointerDownTime;

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
    _overlayHideTimer?.cancel();
    if (_isDistractionFree) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _cachedAudioManager?.isPlayerVisible
        .removeListener(_onPlayerVisibilityChanged);
    _chapterChooserNotifier.dispose();
    super.dispose();
  }

  void _enterDistractionFree() {
    setState(() {
      _isDistractionFree = true;
      _showDistractionFreeOverlay = true;
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _scheduleOverlayHide();
  }

  void _exitDistractionFree() {
    _overlayHideTimer?.cancel();
    setState(() {
      _isDistractionFree = false;
      _showDistractionFreeOverlay = false;
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _scheduleOverlayHide() {
    _overlayHideTimer?.cancel();
    _overlayHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isDistractionFree && _showDistractionFreeOverlay) {
        setState(() {
          _showDistractionFreeOverlay = false;
        });
      }
    });
  }

  void _showOverlayAndScheduleHide() {
    setState(() {
      _showDistractionFreeOverlay = true;
    });
    _scheduleOverlayHide();
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

        if (!hasTabs && _isDistractionFree) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isDistractionFree) {
              _exitDistractionFree();
            }
          });
        }

        return PopScope(
          canPop: !isAdding && !_isDistractionFree,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              if (_isDistractionFree) {
                _exitDistractionFree();
              } else if (isAdding) {
                _tabManager.cancelAddingTab();
              }
            }
          },
          child: Scaffold(
            drawer: _isDistractionFree ? null : const AppDrawer(),
            drawerEnableOpenDragGesture: !_isDistractionFree,
            appBar: _isDistractionFree
                ? null
                : AppBar(
                    titleSpacing: 0,
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
                              } else if (value == 'distraction_free') {
                                _enterDistractionFree();
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
                              const PopupMenuItem(
                                value: 'distraction_free',
                                child: Row(
                                  children: [
                                    Icon(Icons.fullscreen),
                                    SizedBox(width: 12),
                                    Expanded(child: Text('Distraction free')),
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
                : Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (event) {
                      if (_isDistractionFree) {
                        _pointerDownPos = event.position;
                        _pointerDownTime = DateTime.now();
                      }
                    },
                    onPointerUp: (event) {
                      if (_isDistractionFree && _pointerDownPos != null) {
                        final delta =
                            (event.position - _pointerDownPos!).distance;
                        final elapsed =
                            DateTime.now().difference(_pointerDownTime!);
                        if (delta < 15.0 &&
                            elapsed < const Duration(milliseconds: 500)) {
                          if (_showDistractionFreeOverlay) {
                            if (event.position.dy > 90) {
                              setState(() {
                                _showDistractionFreeOverlay = false;
                              });
                              _overlayHideTimer?.cancel();
                            }
                          } else {
                            if (event.position.dy < 90) {
                              _showOverlayAndScheduleHide();
                            }
                          }
                        }
                        _pointerDownPos = null;
                      }
                    },
                    child: Stack(
                      children: [
                        SafeArea(
                          top: _isDistractionFree,
                          bottom: false,
                          child: TextScreen(
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
                        if (_isDistractionFree)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: AnimatedSlide(
                              offset: _showDistractionFreeOverlay
                                  ? Offset.zero
                                  : const Offset(0, -1),
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: AnimatedOpacity(
                                opacity:
                                    _showDistractionFreeOverlay ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 250),
                                child: IgnorePointer(
                                  key: const Key(
                                      'distraction_free_overlay_ignore_pointer'),
                                  ignoring: !_showDistractionFreeOverlay,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.95),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: SafeArea(
                                      bottom: false,
                                      child: SizedBox(
                                        height: kToolbarHeight,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon:
                                                  const Icon(Icons.arrow_back),
                                              tooltip: 'Exit distraction free',
                                              onPressed: _exitDistractionFree,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                activeTab.label,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.fullscreen_exit),
                                              tooltip: 'Exit distraction free',
                                              onPressed: _exitDistractionFree,
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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
  }
}
