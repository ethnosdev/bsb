import 'package:bsb/app_state.dart';
import 'package:bsb/core/font_family.dart';
import 'package:bsb/core/font_scale.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/ui/hebrew_greek/hebrew_greek_screen.dart';
import 'package:bsb/ui/home/chapter_chooser.dart';
import 'package:bsb/ui/shared/snappy_scroll_physics.dart';
import 'package:bsb/ui/shared/zoom_wrapper.dart';
import 'package:bsb/ui/text/chapter/chapter_text.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scripture/scripture.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:bsb/ui/text/highlight_palette_sheet.dart';
import 'package:bsb/ui/text/note_editor_sheet.dart';
import 'screen_manager.dart';

class TextScreen extends StatefulWidget {
  const TextScreen({
    super.key,
    required this.bookId,
    required this.chapter,
    this.initialSectionHeading,
    this.initialTargetVerse,
    this.chapterChooserNotifier,
    this.onChapterChanged,
  });

  final int bookId;
  final int chapter;
  final String? initialSectionHeading;
  final int? initialTargetVerse;
  final ValueNotifier<(int, int)?>? chapterChooserNotifier;
  final void Function(int bookId, int chapter)? onChapterChanged;

  @override
  State<TextScreen> createState() => _TextScreenState();
}

class _TextScreenState extends State<TextScreen> {
  final _screenManager = TextScreenManager();
  static const _initialPageOffset = 10000;
  late final PageController _pageController;
  final _internalChapterNotifier = ValueNotifier<(int, int)?>(null);
  ValueNotifier<(int, int)?> get _chapterNotifier =>
      widget.chapterChooserNotifier ?? _internalChapterNotifier;
  final _showBottomBarNotifier = ValueNotifier<bool>(false);
  late final ValueNotifier<int> _activePageIndexNotifier;
  final _showScrubberNotifier = ValueNotifier<int>(0);
  bool _hasHorizontalUserDrag = false;
  double _horizontalDragStartPixels = 0.0;
  int _horizontalDragStartPage = 0;
  bool _swipedTowardsNextChapter = false;
  int _pageIndex = 0;
  int? _targetSectionBookId;
  int? _targetSectionChapter;
  String? _pendingSectionHeading;
  int? _targetVerseBookId;
  int? _targetVerseChapter;
  int? _pendingTargetVerse;
  ScriptureSelectionController? _activeController;
  final _moreKey = GlobalKey();
  late Language _currentLanguage;

  @override
  void initState() {
    super.initState();
    _pendingSectionHeading = widget.initialSectionHeading;
    if (widget.initialSectionHeading != null) {
      _targetSectionBookId = widget.bookId;
      _targetSectionChapter = widget.chapter;
    }
    _pendingTargetVerse = widget.initialTargetVerse;
    if (widget.initialTargetVerse != null) {
      _targetVerseBookId = widget.bookId;
      _targetVerseChapter = widget.chapter;
    }
    _currentLanguage = widget.bookId >= 40 ? Language.greek : Language.hebrew;
    _pageIndex = _screenManager.pageIndexForBookAndChapter(
      bookId: widget.bookId,
      chapter: widget.chapter,
    );
    _activePageIndexNotifier = ValueNotifier<int>(_pageIndex);
    _screenManager.updateTitle(index: _pageIndex);
    _pageController = PageController(
      initialPage: _initialPageOffset + _pageIndex,
      // trick to keep adjacent page scroll position in memory
      viewportFraction: 0.99,
    );
    _pageController.addListener(() {
      final page = _pageController.page ?? _initialPageOffset;
      final currentIndex = (page - _initialPageOffset).round();
      if (currentIndex != _pageIndex) {
        _pageIndex = currentIndex;
        _activePageIndexNotifier.value = currentIndex;
        _screenManager.updateTitle(
          index: _pageIndex,
        );
        _pendingSectionHeading = null;
        _targetSectionBookId = null;
        _targetSectionChapter = null;
        _pendingTargetVerse = null;
        _targetVerseBookId = null;
        _targetVerseChapter = null;
        // Hide the bottom bar when swiping to a new page
        if (_showBottomBarNotifier.value) {
          _showBottomBarNotifier.value = false;
        }
        final (bookId, chapter) =
            _screenManager.bookAndChapterForPageIndex(_pageIndex);
        widget.onChapterChanged?.call(bookId, chapter);
      }
    });
  }

  @override
  void didUpdateWidget(covariant TextScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bookId != oldWidget.bookId ||
        widget.chapter != oldWidget.chapter ||
        widget.initialSectionHeading != oldWidget.initialSectionHeading ||
        widget.initialTargetVerse != oldWidget.initialTargetVerse) {
      _navigateToChapterAndSection(
        widget.bookId,
        widget.chapter,
        widget.initialSectionHeading,
        widget.initialTargetVerse,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _showBottomBarNotifier.dispose();
    _activePageIndexNotifier.dispose();
    _showScrubberNotifier.dispose();
    _internalChapterNotifier.dispose();
    _screenManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildChapterTextPageView(),
        _buildChapterChooserOverlay(),
        _buildBottomMenuBar(),
      ],
    );
  }

  bool _isTargetSection(int bookId, int chapter) {
    return _pendingSectionHeading != null &&
        bookId == _targetSectionBookId &&
        chapter == _targetSectionChapter;
  }

  bool _isTargetVerse(int bookId, int chapter) {
    return _pendingTargetVerse != null &&
        bookId == _targetVerseBookId &&
        chapter == _targetVerseChapter;
  }

  Widget _buildChapterTextPageView() {
    final pageView = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.horizontal) {
          if (notification is ScrollStartNotification) {
            if (notification.dragDetails != null) {
              _hasHorizontalUserDrag = true;
              _horizontalDragStartPixels = notification.metrics.pixels;
              _horizontalDragStartPage = _pageIndex;
              _swipedTowardsNextChapter = false;
            }
          } else if (notification is ScrollUpdateNotification) {
            if (_hasHorizontalUserDrag) {
              final dragDelta =
                  notification.metrics.pixels - _horizontalDragStartPixels;
              if (dragDelta > 10.0) {
                _swipedTowardsNextChapter = true;
              } else if (notification.dragDetails != null &&
                  dragDelta < -10.0) {
                _swipedTowardsNextChapter = false;
              }
            }
          } else if (notification is ScrollEndNotification) {
            if (_hasHorizontalUserDrag) {
              final settledBack = _pageIndex == _horizontalDragStartPage &&
                  (notification.metrics.pixels - _horizontalDragStartPixels)
                          .abs() <
                      50.0;
              if (_swipedTowardsNextChapter && settledBack) {
                _showScrubberNotifier.value++;
              }
              _hasHorizontalUserDrag = false;
              _swipedTowardsNextChapter = false;
            }
          }
        }
        return false;
      },
      child: PageView.builder(
        controller: _pageController,
        physics: const SnappyScrollPhysics(),
        itemBuilder: (context, index) {
          final pageIndex = index - _initialPageOffset;
          final (bookId, chapter) =
              _screenManager.bookAndChapterForPageIndex(pageIndex);
          return ChapterText(
            key: ValueKey('chapter_${bookId}_$chapter'),
            bookId: bookId,
            chapter: chapter,
            activePageIndexListenable: _activePageIndexNotifier,
            showScrubberNotifier: _showScrubberNotifier,
            pageIndex: pageIndex,
          targetSection: _isTargetSection(bookId, chapter)
              ? _pendingSectionHeading
              : null,
          targetVerse: _isTargetVerse(bookId, chapter)
              ? _pendingTargetVerse
              : null,
          onTargetSectionScrolled: () {
            _pendingSectionHeading = null;
            _targetSectionBookId = null;
            _targetSectionChapter = null;
            if (getIt.isRegistered<TabManager>()) {
              final activeTab = getIt<TabManager>().activeTab;
              if (activeTab != null) {
                activeTab.sectionHeading = null;
              }
            }
          },
          onTargetVerseScrolled: () {
            _pendingTargetVerse = null;
            _targetVerseBookId = null;
            _targetVerseChapter = null;
            if (getIt.isRegistered<TabManager>()) {
              final activeTab = getIt<TabManager>().activeTab;
              if (activeTab != null) {
                activeTab.targetVerse = null;
              }
            }
          },
          onSelectionChanged: (controller) {
            _activeController = controller;
            final hasSelection = controller.hasSelection;
            if (hasSelection && controller.startId != null) {
              final startId = controller.startId!;
              final reference = Reference.fromWordId(packedInt: startId);
              setState(() {
                _currentLanguage = languageForVerse(
                  bookId: reference.bookId,
                  chapter: reference.chapter,
                  verse: reference.verse ?? 1,
                );
              });
            }
            if (_showBottomBarNotifier.value != hasSelection) {
              _showBottomBarNotifier.value = hasSelection;
            }
          },
        );
      },
    ),
  );

    final appState = getIt.isRegistered<AppState>() ? getIt<AppState>() : null;
    if (appState == null) return pageView;

    return ValueListenableBuilder<double>(
      valueListenable: appState.textSizeNotifier,
      builder: (context, currentSize, _) {
        return ZoomWrapper(
          initialScale: currentSize,
          minScale: FontScale.minBaseSize,
          maxScale: FontScale.maxBaseSize,
          onScaleChanged: (newScale) {
            appState.setTextSize(newScale);
          },
          builder: (context, scale) => pageView,
        );
      },
    );
  }

  Widget _buildChapterChooserOverlay() {
    return ValueListenableBuilder<(int, int)?>(
      valueListenable: _chapterNotifier,
      builder: (context, bookChapter, child) {
        if (bookChapter == null) {
          return const SizedBox();
        }
        final (bookId, chapterCount) = bookChapter;
        return ChapterChooser(
          bookId: bookId,
          chapterCount: chapterCount,
          onChapterSelected: (chapter) {
            _chapterNotifier.value = null;
            if (chapter == null) return;
            _navigateToChapterAndSection(bookId, chapter);
            widget.onChapterChanged?.call(bookId, chapter);
          },
          onSectionSelected: (chapter, sectionHeading) {
            _chapterNotifier.value = null;
            _navigateToChapterAndSection(bookId, chapter, sectionHeading);
            widget.onChapterChanged?.call(bookId, chapter);
          },
        );
      },
    );
  }

  void _navigateToChapterAndSection(
    int bookId,
    int chapter, [
    String? sectionHeading,
    int? targetVerse,
  ]) {
    final pageIndex = _screenManager.pageIndexForBookAndChapter(
      bookId: bookId,
      chapter: chapter,
    );
    final index = pageIndex + _initialPageOffset;

    setState(() {
      _targetSectionBookId = bookId;
      _targetSectionChapter = chapter;
      _pendingSectionHeading = sectionHeading;
      _targetVerseBookId = bookId;
      _targetVerseChapter = chapter;
      _pendingTargetVerse = targetVerse;
      _pageIndex = pageIndex;
      _activePageIndexNotifier.value = pageIndex;
      _screenManager.updateTitle(index: pageIndex);
    });

    if (_pageController.hasClients) {
      final currentPage = (_pageController.page ?? _initialPageOffset).round();
      if (currentPage != index) {
        _pageController.jumpToPage(index);
      }
    }
  }

  Widget _buildBottomMenuBar() {
    return ValueListenableBuilder(
        valueListenable: _showBottomBarNotifier,
        builder: (context, showBar, child) {
          final language = _currentLanguage;
          final theme = Theme.of(context);
          final navBarBgColor = theme.bottomNavigationBarTheme.backgroundColor ??
              theme.colorScheme.surface;

          return Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSlide(
              offset: showBar ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Material(
                color: navBarBgColor,
                elevation: 8,
                child: SafeArea(
                  top: false,
                  child: BottomNavigationBar(
                    type: BottomNavigationBarType.fixed,
                    selectedItemColor: theme.colorScheme.onSurface,
                    unselectedItemColor: theme.colorScheme.onSurface,
                    selectedFontSize: 12.0,
                    unselectedFontSize: 12.0,
                    items: [
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.border_color),
                        label: 'Highlight',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.edit_note),
                        label: 'Note',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.content_copy),
                        label: 'Copy',
                      ),
                      BottomNavigationBarItem(
                        icon: _getLanguageIcon(language),
                        label: _getLanguageLabel(language),
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.more_horiz, key: _moreKey),
                        label: 'More',
                      ),
                    ],
                    onTap: (index) => _handleBottomBarTap(index, language),
                  ),
                ),
              ),
            ),
          );
        });
  }

  String _getLanguageLabel(Language language) {
    switch (language) {
      case Language.greek:
        return 'Greek';
      case Language.hebrew:
        return 'Hebrew';
      case Language.aramaic:
        return 'Aramaic';
    }
  }

  Icon _getLanguageIcon(Language language) {
    switch (language) {
      case Language.greek:
        return const Icon(CustomIcons.alpha);
      case Language.hebrew:
      case Language.aramaic:
        return const Icon(CustomIcons.aleph);
    }
  }

  Future<void> _handleBottomBarTap(int index, Language language) async {
    if (_activeController == null || !_activeController!.hasSelection) return;

    final startId = _activeController!.startId!;

    // Extract context using the Extension
    final reference = Reference.fromWordId(packedInt: startId);

    bool shouldClear = true;
    switch (index) {
      case 0:
        await _handleHighlight(reference);
      case 1:
        await _handleNote(reference);
      case 2:
        await _handleCopy();
      case 3:
        _handleHebrewGreek(reference, language);
      case 4:
        shouldClear = await _handleMore(reference);
    }

    if (shouldClear) {
      // Clear selection after action
      _activeController?.clear();
    }
  }

  Future<void> _handleHighlight(Reference reference) async {
    if (_activeController == null || !_activeController!.hasSelection) return;
    final startId = _activeController!.startId!;
    final endId = _activeController!.endId!;
    final selectedText = _activeController!.getSelectedText();
    final annotationService = getIt<AnnotationService>();

    await HighlightPaletteSheet.show(
      context: context,
      onColorSelected: (color) async {
        await annotationService.addHighlight(
          bookId: reference.bookId,
          chapter: reference.chapter,
          startWordId: startId,
          endWordId: endId,
          color: color,
          text: selectedText,
        );
      },
      onClear: () async {
        await annotationService.clearHighlightsInRange(
          bookId: reference.bookId,
          chapter: reference.chapter,
          startWordId: startId,
          endWordId: endId,
        );
      },
    );
  }

  Future<void> _handleNote(Reference reference) async {
    if (_activeController == null || !_activeController!.hasSelection) return;
    final startId = _activeController!.startId!;
    final endId = _activeController!.endId!;
    final bodyText = _activeController!.getSelectedText();
    final fullRef = Reference.fromWordId(
      packedInt: startId,
      packedIntEnd: endId,
    );
    final annotationService = getIt<AnnotationService>();

    await NoteEditorSheet.show(
      context: context,
      title: fullRef.toString(),
      passageText: bodyText,
      onSave: (content) async {
        await annotationService.saveNote(
          bookId: reference.bookId,
          chapter: reference.chapter,
          startWordId: startId,
          endWordId: endId,
          content: content,
          passageText: bodyText,
        );
      },
    );
  }

  Future<void> _handleCopy() async {
    if (_activeController == null || !_activeController!.hasSelection) return;

    final bodyText = _activeController!.getSelectedText();
    final reference = Reference.fromWordId(
      packedInt: _activeController!.startId!,
      packedIntEnd: _activeController!.endId!,
    );

    final StringBuffer fullText = StringBuffer();
    fullText.writeln(reference);
    fullText.write(bodyText);

    await Clipboard.setData(ClipboardData(text: fullText.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(milliseconds: 300),
        ),
      );
    }
  }

  void _handleHebrewGreek(Reference reference, Language language) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HebrewGreekScreen(
          bookId: reference.bookId,
          chapter: reference.chapter,
          verse: reference.verse ?? 1,
          language: language,
        ),
      ),
    );
  }

  Future<bool> _handleMore(Reference reference) async {
    final RenderBox? button =
        _moreKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? overlay =
        Navigator.of(context).overlay?.context.findRenderObject()
            as RenderBox? ??
        Overlay.of(context).context.findRenderObject() as RenderBox?;

    final RelativeRect position;
    if (button != null && overlay != null) {
      final buttonRect = Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      );
      position = RelativeRect.fromRect(buttonRect, Offset.zero & overlay.size);
    } else {
      final size = MediaQuery.of(context).size;
      position = RelativeRect.fromLTRB(
        size.width - 150,
        size.height - 80,
        0,
        0,
      );
    }

    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem<String>(
          value: 'compare',
          child: Text('Compare'),
        ),
        PopupMenuItem<String>(
          value: 'cross_reference',
          child: Text('Cross Reference'),
        ),
      ],
    );

    if (selected == 'compare') {
      _handleCompare(reference);
      return true;
    } else if (selected == 'cross_reference') {
      _handleCrossReference(reference);
      return true;
    }
    return false;
  }

  void _handleCompare(Reference reference) {
    final url = _screenManager.bibleHubUrl(
      bookId: reference.bookId,
      chapter: reference.chapter,
      verse: reference.verse ?? 1,
    );
    _launch(url);
  }

  void _handleCrossReference(Reference reference) {
    final url = _screenManager.bibleHubCrossReferenceUrl(
      bookId: reference.bookId,
      chapter: reference.chapter,
      verse: reference.verse ?? 1,
    );
    _launch(url);
  }

  Future<void> _launch(String webpage) async {
    final url = Uri.parse(webpage);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
