import 'dart:async';
import 'dart:developer';

import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reading_plan_models.dart';
import 'package:bsb/infrastructure/reading_plan_service.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:bsb/ui/text/annotation_disambiguation_sheet.dart';
import 'package:bsb/ui/text/chapter/chapter_manager.dart';
import 'package:bsb/ui/text/chapter/verse_scrubber.dart';
import 'package:bsb/ui/text/note_viewer_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show BoxParentData;
import 'package:database_builder/database_builder.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

class ChapterText extends StatefulWidget {
  const ChapterText({
    super.key,
    required this.bookId,
    required this.chapter,
    this.targetSection,
    this.targetVerse,
    this.activePageIndexListenable,
    this.showScrubberNotifier,
    this.zoomStartNotifier,
    this.pageIndex,
    this.onSelectionChanged,
    this.onTargetSectionScrolled,
    this.onTargetVerseScrolled,
    this.onToggleDistractionFree,
  });

  final int bookId;
  final int chapter;
  final String? targetSection;
  final int? targetVerse;
  final ValueListenable<int>? activePageIndexListenable;
  final ValueListenable<int>? showScrubberNotifier;
  final ValueListenable<int>? zoomStartNotifier;
  final int? pageIndex;
  final void Function(ScriptureSelectionController controller)?
  onSelectionChanged;
  final VoidCallback? onTargetSectionScrolled;
  final VoidCallback? onTargetVerseScrolled;
  final VoidCallback? onToggleDistractionFree;

  @override
  State<ChapterText> createState() => _ChapterTextState();
}

class _ChapterTextState extends State<ChapterText>
    with AutomaticKeepAliveClientMixin {
  final manager = ChapterManager();
  final _selectionController = ScriptureSelectionController();
  final _scrollController = ScrollController();
  String? _lastScrolledSection;
  int? _lastScrolledVerse;
  String? _activeTargetSection;
  int? _activeTargetVerse;

  int? _verseAtZoomStart;
  double? _lastRenderedTextSize;

  final GlobalKey _contentColumnKey = GlobalKey();
  bool _doesContentOverflow = false;
  bool _isVerseScrubberVisible = false;
  bool _isScrubbing = false;
  Timer? _verseScrubberTimer;
  Timer? _sectionScrollTimer;
  Timer? _verseScrollTimer;
  bool _hasInitiallyShownScrubber = false;

  @override
  bool get wantKeepAlive => true;

  String get _chapterTitle {
    final book =
        bookIdToFullNameMap[widget.bookId] ??
        (bookIdToBookNameMap[widget.bookId] == 'Psalms'
            ? 'Psalm'
            : bookIdToBookNameMap[widget.bookId] ?? '');
    return '$book ${widget.chapter}';
  }

  bool get _isActive {
    if (widget.activePageIndexListenable == null || widget.pageIndex == null) {
      return true;
    }
    return widget.activePageIndexListenable!.value == widget.pageIndex;
  }

  bool get _isVerseSidebarEnabled {
    final appState = getIt.isRegistered<AppState>() ? getIt<AppState>() : null;
    final userSettings = getIt.isRegistered<UserSettings>()
        ? getIt<UserSettings>()
        : null;
    final showVerseGrid =
        appState?.showVerseGridNotifier.value ??
        userSettings?.showVerseGrid ??
        false;
    return !showVerseGrid;
  }

  void _scheduleOverflowCheck(List<int> sortedVerses) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkContentOverflow(sortedVerses);
    });
  }

  void _checkContentOverflow(List<int> sortedVerses) {
    if (!mounted) return;
    if (sortedVerses.length < 4) {
      if (_doesContentOverflow) {
        setState(() {
          _doesContentOverflow = false;
          _isVerseScrubberVisible = false;
        });
      }
      return;
    }

    final renderBox =
        _contentColumnKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final contentHeight = _topPadding + renderBox.size.height;
    final viewportHeight =
        (_scrollController.hasClients &&
            _scrollController.position.hasViewportDimension)
        ? _scrollController.position.viewportDimension
        : MediaQuery.sizeOf(context).height;

    final overflows = contentHeight > viewportHeight;
    final overflowChanged = overflows != _doesContentOverflow;

    if (overflowChanged) {
      _doesContentOverflow = overflows;
      if (!overflows && _isVerseScrubberVisible) {
        _isVerseScrubberVisible = false;
      }
    }

    if (overflows && !_hasInitiallyShownScrubber && _isVerseSidebarEnabled) {
      _hasInitiallyShownScrubber = true;
      if (_isActive) {
        _showVerseScrubberWithTimeout();
        return;
      }
    }

    if (overflowChanged) {
      setState(() {});
    }
  }

  void _handleActivePageChange() {
    if (!_isVerseSidebarEnabled) return;
    if (_isActive && _doesContentOverflow) {
      _showVerseScrubberWithTimeout();
    } else {
      _hideVerseScrubber();
    }
  }

  void _handleShowScrubberRequest() {
    if (!_isVerseSidebarEnabled || !_doesContentOverflow) return;
    if (_isActive) {
      _showVerseScrubberWithTimeout();
    }
  }

  void _showVerseScrubberWithTimeout({
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!_isVerseSidebarEnabled || !_doesContentOverflow) return;
    _verseScrubberTimer?.cancel();
    if (!_isVerseScrubberVisible) {
      setState(() {
        _isVerseScrubberVisible = true;
      });
    }
    _verseScrubberTimer = Timer(duration, () {
      if (mounted && !_isScrubbing) {
        setState(() {
          _isVerseScrubberVisible = false;
        });
      }
    });
  }

  void _hideVerseScrubber() {
    _verseScrubberTimer?.cancel();
    if (_isVerseScrubberVisible) {
      setState(() {
        _isVerseScrubberVisible = false;
      });
    }
  }

  void _scrollFromScrubber(int verse) {
    _verseScrollTimer?.cancel();
    _activeTargetVerse = null;
    _lastScrolledVerse = widget.targetVerse;
    _performScrollToVerse(verse);
  }

  @override
  void initState() {
    super.initState();
    widget.activePageIndexListenable?.addListener(_handleActivePageChange);
    widget.showScrubberNotifier?.addListener(_handleShowScrubberRequest);
    widget.zoomStartNotifier?.addListener(_handleZoomStart);
    manager.requestText(bookId: widget.bookId, chapter: widget.chapter);
    _selectionController.addListener(_handleSelectionChange);
    if (widget.targetSection != null) {
      _scrollToTargetSection(widget.targetSection);
    }
    if (widget.targetVerse != null) {
      _scrollToTargetVerse(widget.targetVerse);
    }
  }

  void _handleZoomStart() {
    if (!_isActive) return;
    _verseAtZoomStart = _getTopVisibleVerse();
  }

  double _maxTopInset = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final topInset = MediaQuery.paddingOf(context).top;
    if (topInset > _maxTopInset) {
      _maxTopInset = topInset;
    }
  }

  double get _topPadding => _maxTopInset + 16.0;

  void _handleReaderTap() {
    if (_selectionController.hasSelection) {
      _selectionController.clear();
      return;
    }
    if (_isVerseScrubberVisible && !_isScrubbing) {
      _hideVerseScrubber();
      return;
    }
    widget.onToggleDistractionFree?.call();
  }

  @override
  void didUpdateWidget(covariant ChapterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activePageIndexListenable !=
        oldWidget.activePageIndexListenable) {
      oldWidget.activePageIndexListenable?.removeListener(
        _handleActivePageChange,
      );
      widget.activePageIndexListenable?.addListener(_handleActivePageChange);
    }
    if (widget.showScrubberNotifier != oldWidget.showScrubberNotifier) {
      oldWidget.showScrubberNotifier?.removeListener(
        _handleShowScrubberRequest,
      );
      widget.showScrubberNotifier?.addListener(_handleShowScrubberRequest);
    }
    if (widget.zoomStartNotifier != oldWidget.zoomStartNotifier) {
      oldWidget.zoomStartNotifier?.removeListener(_handleZoomStart);
      widget.zoomStartNotifier?.addListener(_handleZoomStart);
    }
    if (widget.bookId != oldWidget.bookId ||
        widget.chapter != oldWidget.chapter) {
      _hasInitiallyShownScrubber = false;
      _doesContentOverflow = false;
      _isVerseScrubberVisible = false;
      _verseAtZoomStart = null;
      _lastRenderedTextSize = null;
      _verseScrubberTimer?.cancel();
      manager.requestText(bookId: widget.bookId, chapter: widget.chapter);
    }
    if (widget.targetSection == null) {
      _sectionScrollTimer?.cancel();
      _lastScrolledSection = null;
    }
    if (widget.targetVerse == null) {
      _verseScrollTimer?.cancel();
      _lastScrolledVerse = null;
    }
    if (widget.targetSection != null &&
        (widget.targetSection != oldWidget.targetSection ||
            widget.targetSection != _lastScrolledSection)) {
      _scrollToTargetSection(widget.targetSection);
    }
    if (widget.targetVerse != null &&
        (widget.targetVerse != oldWidget.targetVerse ||
            widget.targetVerse != _lastScrolledVerse)) {
      _scrollToTargetVerse(widget.targetVerse);
    }
  }

  @override
  void dispose() {
    _verseScrubberTimer?.cancel();
    _sectionScrollTimer?.cancel();
    _verseScrollTimer?.cancel();
    widget.showScrubberNotifier?.removeListener(_handleShowScrubberRequest);
    widget.zoomStartNotifier?.removeListener(_handleZoomStart);
    widget.activePageIndexListenable?.removeListener(_handleActivePageChange);
    _selectionController.removeListener(_handleSelectionChange);
    _selectionController.dispose();
    _scrollController.dispose();
    manager.dispose();
    super.dispose();
  }

  void _handleSelectionChange() {
    if (_selectionController.hasSelection) {
      _hideVerseScrubber();
    }
    if (mounted && widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(_selectionController);
    }
  }

  void _scrollToTargetSection([String? section, int attempt = 0]) {
    final target = section ?? widget.targetSection;
    if (target == null || target.isEmpty) return;
    if (target == _lastScrolledSection) return;
    if (attempt == 0 && target == _activeTargetSection) return;

    _sectionScrollTimer?.cancel();
    _activeTargetSection = target;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _activeTargetSection = null;
        return;
      }
      final success = _performScrollToSection(target);
      if (success) {
        _lastScrolledSection = target;
        _activeTargetSection = null;
        if (target == widget.targetSection) {
          widget.onTargetSectionScrolled?.call();
        }
      } else if (attempt < 15) {
        _sectionScrollTimer = Timer(const Duration(milliseconds: 50), () {
          if (mounted && widget.targetSection == target) {
            _scrollToTargetSection(target, attempt + 1);
          } else {
            _activeTargetSection = null;
          }
        });
      } else {
        _activeTargetSection = null;
      }
    });
  }

  bool _performScrollToSection(String target) {
    if (!_scrollController.hasClients) return false;
    if (!_scrollController.position.hasContentDimensions) return false;

    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return false;

    RenderPassage? passage;
    void findPassage(RenderObject ro) {
      if (passage != null) return;
      if (ro is RenderPassage) {
        passage = ro;
        return;
      }
      ro.visitChildren(findPassage);
    }

    findPassage(renderObject);

    if (passage == null || !passage!.hasSize) return false;

    RenderBox? child = passage!.firstChild;
    while (child != null) {
      if (child is RenderParagraph) {
        final text = _getParagraphText(child);
        if (_matchesHeading(text, target)) {
          final parentData = child.parentData as PassageParentData;
          final passageOffset = _getPassageOffsetInColumn(passage!);
          final targetOffset = passageOffset + parentData.offset.dy;
          final maxScroll = _scrollController.position.maxScrollExtent;
          if (targetOffset > 50.0 && maxScroll <= 0.0) {
            return false;
          }
          final scrollOffset = targetOffset.clamp(0.0, maxScroll);
          _scrollController.animateTo(
            scrollOffset,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
          return true;
        }
      }
      child = (child.parentData as PassageParentData).nextSibling;
    }
    return false;
  }

  void _scrollToTargetVerse([int? verse, int attempt = 0]) {
    final target = verse ?? widget.targetVerse;
    if (target == null || target <= 0) return;
    if (target == _lastScrolledVerse) return;
    if (attempt == 0 && target == _activeTargetVerse) return;

    _verseScrollTimer?.cancel();
    _activeTargetVerse = target;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _activeTargetVerse = null;
        return;
      }
      final success = _performScrollToVerse(target);
      if (success) {
        _lastScrolledVerse = target;
        _activeTargetVerse = null;
        if (target == widget.targetVerse) {
          widget.onTargetVerseScrolled?.call();
        }
      } else if (attempt < 15) {
        _verseScrollTimer = Timer(const Duration(milliseconds: 50), () {
          if (mounted && widget.targetVerse == target) {
            _scrollToTargetVerse(target, attempt + 1);
          } else {
            _activeTargetVerse = null;
          }
        });
      } else {
        _activeTargetVerse = null;
      }
    });
  }

  RenderPassage? _findRenderPassage() {
    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return null;

    RenderPassage? passage;
    void findPassage(RenderObject ro) {
      if (passage != null) return;
      if (ro is RenderPassage) {
        passage = ro;
        return;
      }
      ro.visitChildren(findPassage);
    }

    findPassage(renderObject);
    return passage;
  }

  int? _extractVerseFromElement(RenderBox elem) {
    if (elem is RenderVerseNumber) {
      return int.tryParse(elem.number);
    }
    if (elem is RenderWord) {
      final v = (elem.id ~/ 1000) % 1000;
      return v > 0 ? v : null;
    }
    if (elem is RenderTextAtom) {
      RenderBox? atomChild = elem.firstChild;
      while (atomChild != null) {
        if (atomChild is RenderWord) {
          final v = (atomChild.id ~/ 1000) % 1000;
          if (v > 0) return v;
        }
        atomChild = (atomChild.parentData as TextAtomParentData).nextSibling;
      }
    }
    return null;
  }

  int? _getVerseAtPassageY(RenderPassage passage, double passageY) {
    if (passageY <= 0) return 1;

    int? lastSeenVerse;

    RenderBox? child = passage.firstChild;
    while (child != null) {
      if (child is RenderParagraph) {
        final parentData = child.parentData as PassageParentData;
        final paragraphTop = parentData.offset.dy;
        final paragraphBottom = paragraphTop + child.size.height;

        RenderBox? elem = child.firstChild;
        while (elem != null) {
          final elemData = elem.parentData as ParagraphParentData;
          final elemY = paragraphTop + elemData.offset.dy;
          final v = _extractVerseFromElement(elem);

          if (v != null) {
            if (elemY <= passageY + 4.0) {
              lastSeenVerse = v;
            } else {
              return lastSeenVerse ?? v;
            }
          }
          elem = elemData.nextSibling;
        }

        if (passageY < paragraphBottom) {
          final dyInParagraph = (passageY - paragraphTop).clamp(
            0.0,
            child.size.height,
          );
          final wordId = child.getWordClosestToOffset(
            Offset(50.0, dyInParagraph),
          );
          if (wordId != null && wordId > 0) {
            final ref = Reference.fromWordId(packedInt: wordId);
            if (ref.verse != null && ref.verse! > 0) {
              return ref.verse;
            }
          }
          if (lastSeenVerse != null) return lastSeenVerse;
        }
      }
      child = (child.parentData as PassageParentData).nextSibling;
    }

    return lastSeenVerse ?? 1;
  }

  double _getPassageOffsetInColumn(RenderPassage passage) {
    final columnBox =
        _contentColumnKey.currentContext?.findRenderObject() as RenderBox?;
    if (columnBox != null && columnBox.attached && passage.attached) {
      try {
        return passage.localToGlobal(Offset.zero, ancestor: columnBox).dy;
      } catch (_) {}
    }
    return (passage.parentData is BoxParentData)
        ? (passage.parentData as BoxParentData).offset.dy
        : 0.0;
  }

  int? _getTopVisibleVerse() {
    if (!_scrollController.hasClients) return null;
    final passage = _findRenderPassage();
    if (passage == null || !passage.hasSize) return null;

    final scrollOffset = _scrollController.position.pixels;
    final passageOffset = _getPassageOffsetInColumn(passage);

    final passageY = scrollOffset - passageOffset;
    return _getVerseAtPassageY(passage, passageY);
  }

  double? _findVerseDyInParagraph(
    RenderParagraph paragraph,
    String targetVerseStr,
    int expectedPackedRef,
  ) {
    RenderBox? elem = paragraph.firstChild;
    while (elem != null) {
      final elemData = elem.parentData as ParagraphParentData;
      if (elem is RenderVerseNumber && elem.number == targetVerseStr) {
        return elemData.offset.dy;
      }
      if (elem is RenderWord && elem.id ~/ 1000 == expectedPackedRef) {
        return elemData.offset.dy;
      }
      if (elem is RenderTextAtom) {
        RenderBox? atomChild = elem.firstChild;
        while (atomChild != null) {
          if (atomChild is RenderWord &&
              atomChild.id ~/ 1000 == expectedPackedRef) {
            final atomData = atomChild.parentData as TextAtomParentData;
            return elemData.offset.dy + atomData.offset.dy;
          }
          atomChild = (atomChild.parentData as TextAtomParentData).nextSibling;
        }
      }
      elem = elemData.nextSibling;
    }
    return null;
  }

  double? _getVerseOffset(RenderPassage passage, int targetVerse) {
    if (targetVerse == 1) return 0.0;

    final passageOffset = _getPassageOffsetInColumn(passage);
    final targetVerseStr = targetVerse.toString();
    final expectedPackedRef =
        widget.bookId * 1000000 + widget.chapter * 1000 + targetVerse;

    RenderBox? child = passage.firstChild;
    while (child != null) {
      if (child is RenderParagraph) {
        final verseDy = _findVerseDyInParagraph(
          child,
          targetVerseStr,
          expectedPackedRef,
        );

        if (verseDy != null) {
          final parentData = child.parentData as PassageParentData;
          return passageOffset + parentData.offset.dy + verseDy;
        }
      }
      child = (child.parentData as PassageParentData).nextSibling;
    }
    return null;
  }

  bool _performScrollToVerse(int targetVerse, {bool animate = true}) {
    if (!_scrollController.hasClients) return false;
    if (!_scrollController.position.hasContentDimensions) return false;

    if (targetVerse == 1) {
      if (animate) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      } else {
        _scrollController.jumpTo(0.0);
      }
      return true;
    }

    final passage = _findRenderPassage();
    if (passage == null || !passage.hasSize) return false;

    final targetOffset = _getVerseOffset(passage, targetVerse);
    if (targetOffset == null) return false;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (targetOffset > 50.0 && maxScroll <= 0.0) {
      return false;
    }
    final scrollOffset = targetOffset.clamp(0.0, maxScroll);
    if (animate) {
      _scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.jumpTo(scrollOffset);
    }
    return true;
  }

  void _scheduleRestoreVerseAfterResize(int? verse, [int attempt = 0]) {
    if (verse == null || !_isActive) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isActive) return;
      final success = _performScrollToVerse(verse, animate: false);
      if (!success && attempt < 5) {
        Timer(const Duration(milliseconds: 30), () {
          if (mounted && _isActive) {
            _scheduleRestoreVerseAfterResize(verse, attempt + 1);
          }
        });
      }
    });
  }

  String _getParagraphText(RenderBox p) {
    final words = <String>[];
    void collectWords(RenderObject ro) {
      if (ro is RenderWord) {
        words.add(ro.text);
        return;
      }
      ro.visitChildren(collectWords);
    }

    collectWords(p);
    return words.join(' ');
  }

  bool _matchesHeading(String text, String target) {
    final cleanText = text
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    final cleanTarget = target
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    if (cleanText.isEmpty || cleanTarget.isEmpty) return false;
    return cleanText == cleanTarget ||
        cleanText.startsWith(cleanTarget) ||
        cleanTarget.startsWith(cleanText);
  }

  Widget _buildReadingPlanButton() {
    if (!getIt.isRegistered<ReadingPlanService>())
      return const SizedBox.shrink();
    final service = getIt<ReadingPlanService>();
    return ValueListenableBuilder<UserPlanProgress?>(
      valueListenable: service.activeProgressNotifier,
      builder: (context, progress, child) {
        if (progress == null || progress.isPlanFinished) {
          return const SizedBox.shrink();
        }
        final plan = service.getActivePlan();
        if (plan == null) return const SizedBox.shrink();

        final nextDayNum = progress.nextUncompletedDayNumber;
        if (nextDayNum <= 0 || nextDayNum > plan.days.length) {
          return const SizedBox.shrink();
        }

        final currentDay = plan.days[nextDayNum - 1];

        final readingIndex = currentDay.readings.indexWhere(
          (r) =>
              r.bookId == widget.bookId &&
              widget.chapter >= r.startChapter &&
              widget.chapter <= r.endChapter,
        );

        if (readingIndex == -1) return const SizedBox.shrink();

        final reading = currentDay.readings[readingIndex];
        final isCompleted = progress.isReadingCompleted(nextDayNum, reading);

        final isLastChapterOfReading = widget.chapter == reading.endChapter;
        final isLastReadingOfDay =
            readingIndex == currentDay.readings.length - 1;
        final isFinished = isLastReadingOfDay && isLastChapterOfReading;

        return Padding(
          padding: const EdgeInsets.only(top: 48.0, bottom: 24.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reading plan',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (isLastChapterOfReading && !isCompleted) {
                      await service.toggleReadingComplete(nextDayNum, reading);
                    }

                    if (!isFinished) {
                      int nextBookId = widget.bookId;
                      int nextChapter = widget.chapter + 1;

                      if (isLastChapterOfReading) {
                        final nextReading =
                            currentDay.readings[readingIndex + 1];
                        nextBookId = nextReading.bookId;
                        nextChapter = nextReading.startChapter;
                      }

                      if (getIt.isRegistered<TabManager>()) {
                        getIt<TabManager>().openTab(
                          nextBookId,
                          nextChapter,
                          null,
                          null,
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Day $nextDayNum completed!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(isFinished ? 'Finished' : 'Next Chapter'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final brightness = Theme.of(context).brightness;
    final textSizeListenable = getIt.isRegistered<AppState>()
        ? getIt<AppState>().textSizeNotifier
        : ValueNotifier<double>(manager.textSize);
    final wordsOfJesusInRedListenable = getIt.isRegistered<AppState>()
        ? getIt<AppState>().wordsOfJesusInRedNotifier
        : ValueNotifier<bool>(false);

    return ValueListenableBuilder<double>(
      valueListenable: textSizeListenable,
      builder: (context, currentTextSize, child) {
        if (_lastRenderedTextSize != null &&
            (currentTextSize - _lastRenderedTextSize!).abs() > 0.01) {
          final verseToRestore = _verseAtZoomStart ?? _getTopVisibleVerse();
          _verseAtZoomStart = null;
          _scheduleRestoreVerseAfterResize(verseToRestore);
        }
        _lastRenderedTextSize = currentTextSize;

        return ValueListenableBuilder<bool>(
          valueListenable: wordsOfJesusInRedListenable,
          builder: (context, wordsOfJesusInRed, child) {
            return ValueListenableBuilder<List<UsfmLine>>(
              valueListenable: manager.textParagraphNotifier,
              builder: (context, verseLines, child) {
                if (verseLines.isNotEmpty &&
                    widget.targetSection != null &&
                    _lastScrolledSection != widget.targetSection) {
                  _scrollToTargetSection(widget.targetSection);
                }
                if (verseLines.isNotEmpty &&
                    widget.targetVerse != null &&
                    _lastScrolledVerse != widget.targetVerse) {
                  _scrollToTargetVerse(widget.targetVerse);
                }
                final verses = <int>{};
                for (final line in verseLines) {
                  if (line.verse > 0) {
                    verses.add(line.verse);
                  }
                }
                final sortedVerses = verses.toList()..sort();

                if (sortedVerses.isNotEmpty) {
                  _scheduleOverflowCheck(sortedVerses);
                }

                return ValueListenableBuilder<List<Highlight>>(
                  valueListenable: manager.highlightsNotifier,
                  builder: (context, rawHighlights, child) {
                    final highlights = rawHighlights
                        .map((h) => h.toHighlightRange(brightness))
                        .toList();
                    return ValueListenableBuilder<List<NoteMarker>>(
                      valueListenable: manager.noteMarkersNotifier,
                      builder: (context, noteMarkers, child) {
                        return ClipRect(
                          child: Stack(
                            children: [
                              NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  if (notification is ScrollStartNotification &&
                                      notification.dragDetails != null) {
                                    if (_isVerseScrubberVisible &&
                                        !_isScrubbing) {
                                      _hideVerseScrubber();
                                    }
                                  }
                                  return false;
                                },
                                child: SingleChildScrollView(
                                  controller: _scrollController,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _handleReaderTap,
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          left: 16.0,
                                          top: _topPadding,
                                          right: 16.0,
                                          bottom: screenHeight * 0.8,
                                        ),
                                        child: Column(
                                          key: _contentColumnKey,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 24.0,
                                              ),
                                              child: Text(
                                                _chapterTitle,
                                                key: ValueKey(
                                                  'chapter_header_${widget.bookId}_${widget.chapter}',
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineMedium
                                                    ?.copyWith(
                                                      fontSize:
                                                          currentTextSize * 1.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            UsfmWidget(
                                              verseLines: verseLines,
                                              selectionController:
                                                  _selectionController,
                                              highlights: highlights,
                                              noteMarkers: noteMarkers,
                                              onFootnoteTapped:
                                                  _onFootnoteTapped,
                                              onNoteTapped: _onNoteTapped,
                                              onAmbiguousTapped:
                                                  _onAmbiguousTapped,
                                              onTapWhitespace: _handleReaderTap,
                                              onWordTapped: (id) {
                                                log("Tapped word $id");
                                                _handleReaderTap();
                                              },
                                              onSelectionRequested: (wordId) {
                                                ScriptureLogic.highlightVerse(
                                                  _selectionController,
                                                  verseLines,
                                                  wordId,
                                                );
                                              },
                                              styleBuilder: (format) {
                                                final base =
                                                    UsfmParagraphStyle.usfmDefaults(
                                                      format:
                                                          format ==
                                                              ParagraphFormat.p
                                                          ? ParagraphFormat.m
                                                          : format,
                                                      baseStyle:
                                                          Theme.of(context)
                                                              .textTheme
                                                              .bodyMedium!
                                                              .copyWith(
                                                                fontSize:
                                                                    currentTextSize,
                                                              ),
                                                    );
                                                if (wordsOfJesusInRed) {
                                                  final isDark =
                                                      brightness ==
                                                      Brightness.dark;
                                                  final redColor = isDark
                                                      ? const Color(0xFFFF8A80)
                                                      : const Color(0xFFB71C1C);
                                                  return base.copyWith(
                                                    wordsOfJesusStyle: base
                                                        .textStyle
                                                        .copyWith(
                                                          color: redColor,
                                                        ),
                                                  );
                                                }
                                                return base;
                                              },
                                            ),
                                            _buildReadingPlanButton(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              _buildVerseScrubberOverlay(sortedVerses),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildVerseScrubberOverlay(List<int> sortedVerses) {
    final appState = getIt.isRegistered<AppState>() ? getIt<AppState>() : null;
    if (appState != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: appState.showVerseGridNotifier,
        builder: (context, showVerseGrid, child) {
          if (showVerseGrid) {
            return const SizedBox.shrink();
          }
          return _buildVerseScrubberWidget(sortedVerses);
        },
      );
    }
    final userSettings = getIt.isRegistered<UserSettings>()
        ? getIt<UserSettings>()
        : null;
    if (userSettings?.showVerseGrid ?? false) {
      return const SizedBox.shrink();
    }
    return _buildVerseScrubberWidget(sortedVerses);
  }

  Widget _buildVerseScrubberWidget(List<int> sortedVerses) {
    if (widget.activePageIndexListenable != null && widget.pageIndex != null) {
      return ValueListenableBuilder<int>(
        valueListenable: widget.activePageIndexListenable!,
        builder: (context, activeIndex, _) {
          final isCurrentActivePage = activeIndex == widget.pageIndex;
          return VerseScrubber(
            verses: sortedVerses,
            isActive: isCurrentActivePage,
            isVisible: _isVerseScrubberVisible,
            canScroll: _doesContentOverflow,
            onVerseSelected: (verse) {
              _scrollFromScrubber(verse);
              _showVerseScrubberWithTimeout();
            },
            onDismiss: () {
              _hideVerseScrubber();
            },
            onInteractionStart: () {
              _isScrubbing = true;
              _verseScrubberTimer?.cancel();
            },
            onInteractionEnd: () {
              _isScrubbing = false;
              _showVerseScrubberWithTimeout();
            },
          );
        },
      );
    } else {
      return VerseScrubber(
        verses: sortedVerses,
        isVisible: _isVerseScrubberVisible,
        canScroll: _doesContentOverflow,
        onVerseSelected: (verse) {
          _scrollFromScrubber(verse);
          _showVerseScrubberWithTimeout();
        },
        onDismiss: () {
          _hideVerseScrubber();
        },
        onInteractionStart: () {
          _isScrubbing = true;
          _verseScrubberTimer?.cancel();
        },
        onInteractionEnd: () {
          _isScrubbing = false;
          _showVerseScrubberWithTimeout();
        },
      );
    }
  }

  Future<void> _onAmbiguousTapped({
    required int wordId,
    required String footnoteText,
    required String noteId,
  }) async {
    final note = await manager.getNoteById(noteId);
    final ref = Reference.fromWordId(packedInt: wordId);

    if (!mounted) return;

    await AnnotationDisambiguationSheet.show(
      context: context,
      title: ref.toString(),
      notePreview: note?.content ?? '',
      footnotePreview: footnoteText
          .replaceAll(RegExp(r'\\[a-z0-9*]+'), '')
          .trim(),
      onSelectNote: () => _onNoteTapped(noteId),
      onSelectFootnote: () => _onFootnoteTapped(footnoteText),
    );
  }

  Future<void> _onNoteTapped(String noteId) async {
    final note = await manager.getNoteById(noteId);
    if (note == null || !mounted) return;

    final ref = Reference.fromWordId(
      packedInt: note.startWordId,
      packedIntEnd: note.endWordId,
    );

    String? passageText = note.passageText;
    if (passageText == null || passageText.isEmpty) {
      passageText = await getIt<DatabaseHelper>().getTextForRange(
        bookId: note.bookId,
        chapter: note.chapter,
        startWordId: note.startWordId,
        endWordId: note.endWordId,
      );
    }
    if (!mounted) return;

    await NoteViewerSheet.show(
      context: context,
      title: ref.toString(),
      passageText: passageText,
      content: note.content,
      onSave: (newContent) {
        manager.saveNote(
          bookId: note.bookId,
          chapter: note.chapter,
          startWordId: note.startWordId,
          endWordId: note.endWordId,
          content: newContent,
          passageText: passageText,
          existingNoteId: note.id,
        );
      },
      onDelete: () {
        manager.deleteNote(note.id);
      },
    );
  }

  void _onFootnoteTapped(String footnoteText) {
    showDialog(
      context: context,
      builder: (context) => _FootnoteDialog(
        footnoteText: footnoteText,
        manager: manager,
        onShowDetails: _showDetailsDialog,
      ),
    );
  }

  Future<void> _showDetailsDialog(String title, List<UsfmLine> passage) async {
    final fontSize = manager.textSize;
    final reference = Reference.tryParse(title);
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            constraints: const BoxConstraints(maxHeight: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (reference != null) const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (reference != null)
                      IconButton(
                        icon: const Icon(Icons.open_in_new),
                        tooltip: 'Open in new tab',
                        onPressed: () {
                          Navigator.of(context)
                              .popUntil((route) => route is! PopupRoute);
                          if (getIt.isRegistered<TabManager>()) {
                            getIt<TabManager>().openTab(
                              reference.bookId,
                              reference.chapter,
                              null,
                              reference.verse,
                            );
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: UsfmWidget(
                      verseLines: passage,
                      selectionController: ScriptureSelectionController(),
                      selectionColor: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.3),
                      onFootnoteTapped: _onFootnoteTapped,
                      styleBuilder: (format) {
                        final base = UsfmParagraphStyle.usfmDefaults(
                          format: format == ParagraphFormat.p
                              ? ParagraphFormat.m
                              : format,
                          baseStyle: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(fontSize: manager.textSize),
                        );
                        final isRed = getIt.isRegistered<AppState>()
                            ? getIt<AppState>().wordsOfJesusInRedNotifier.value
                            : false;
                        if (isRed) {
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          final redColor = isDark
                              ? const Color(0xFFFF8A80)
                              : const Color(0xFFB71C1C);
                          return base.copyWith(
                            wordsOfJesusStyle: base.textStyle.copyWith(
                              color: redColor,
                            ),
                          );
                        }
                        return base;
                      },
                      showHeadings: false,
                      showVerseNumbers: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FootnoteDialog extends StatefulWidget {
  final String footnoteText;
  final ChapterManager manager;
  final void Function(String keyword, List<UsfmLine> details) onShowDetails;

  const _FootnoteDialog({
    required this.footnoteText,
    required this.manager,
    required this.onShowDetails,
  });

  @override
  State<_FootnoteDialog> createState() => _FootnoteDialogState();
}

class _FootnoteDialogState extends State<_FootnoteDialog> {
  final List<GestureRecognizer> _recognizers = [];
  TextSpan? _content;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disposeRecognizers();
    _content = formatFootnote(
      footnote: widget.footnoteText,
      highlightColor: Theme.of(context).colorScheme.primary,
      keywords: widget.manager.footnoteKeywords(),
      recognizersToDispose: _recognizers,
      onTapKeyword: (keyword, count) async {
        if (count == 1) {
          Navigator.of(context).pop();
        }
        final text = await widget.manager.lookupFootnoteDetails(keyword);
        if (text == null) return;
        widget.onShowDetails(keyword, text);
      },
    );
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SelectableText.rich(
        _content ?? const TextSpan(),
        style: TextStyle(fontSize: widget.manager.textSize),
      ),
    );
  }
}

TextSpan formatFootnote({
  required String footnote,
  required Color highlightColor,
  required RegExp keywords,
  required void Function(String tappedKeyword, int keywordCount) onTapKeyword,
  List<GestureRecognizer>? recognizersToDispose,
}) {
  // Make semicolon-separated content display on new lines
  final note = footnote.replaceAll('; ', ';\n');

  final List<TextSpan> spans = [];
  int start = 0;
  bool isItalic = false;

  // Match \fqa* first (without trailing spaces), then \fqa (with trailing space separator), then keywords
  final tagOrKeywordPattern = RegExp(
    r'(\\fqa\*)|(\\fqa)\s*|' + keywords.pattern,
  );
  final matches = tagOrKeywordPattern.allMatches(note);

  final keywordCount = matches
      .where((m) => m.group(1) == null && m.group(2) == null)
      .length;

  for (final match in matches) {
    // Add text before the match
    if (match.start > start) {
      final text = note.substring(start, match.start);
      if (text.isNotEmpty) {
        spans.add(
          TextSpan(
            text: text,
            style: isItalic
                ? const TextStyle(fontStyle: FontStyle.italic)
                : null,
          ),
        );
      }
    }

    final isFqaClose = match.group(1) != null;
    final isFqaOpen = match.group(2) != null;
    final matchedText = match.group(0)!;

    if (isFqaClose) {
      isItalic = false;
    } else if (isFqaOpen) {
      isItalic = true;
    } else {
      // Add the matched keyword as a tappable span
      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          onTapKeyword(matchedText, keywordCount);
        };
      recognizersToDispose?.add(recognizer);
      spans.add(
        TextSpan(
          text: matchedText,
          style: TextStyle(
            color: highlightColor,
            fontStyle: isItalic ? FontStyle.italic : null,
          ),
          recognizer: recognizer,
        ),
      );
    }

    start = match.end;
  }

  // Add remaining text after the last match
  if (start < note.length) {
    final text = note.substring(start);
    if (text.isNotEmpty) {
      spans.add(
        TextSpan(
          text: text,
          style: isItalic ? const TextStyle(fontStyle: FontStyle.italic) : null,
        ),
      );
    }
  }

  return TextSpan(children: spans);
}
