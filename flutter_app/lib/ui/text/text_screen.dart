import 'package:bsb/core/font_family.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/ui/hebrew_greek/hebrew_greek_screen.dart';
import 'package:bsb/ui/home/chapter_chooser.dart';
import 'package:bsb/ui/shared/snappy_scroll_physics.dart';
import 'package:bsb/ui/text/chapter/chapter_text.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scripture/scripture.dart';
import 'package:url_launcher/url_launcher.dart';

import 'screen_manager.dart';

class TextScreen extends StatefulWidget {
  const TextScreen({
    super.key,
    required this.bookId,
    required this.chapter,
  });

  final int bookId;
  final int chapter;

  @override
  State<TextScreen> createState() => _TextScreenState();
}

class _TextScreenState extends State<TextScreen> {
  final _screenManager = TextScreenManager();
  static const _initialPageOffset = 10000;
  late final PageController _pageController;
  final _chapterNotifier = ValueNotifier<(int, int)?>(null);
  final _showBottomBarNotifier = ValueNotifier<bool>(false);
  int _pageIndex = 0;
  ScriptureSelectionController? _activeController;

  @override
  void initState() {
    super.initState();
    _pageIndex = _screenManager.pageIndexForBookAndChapter(
      bookId: widget.bookId,
      chapter: widget.chapter,
    );
    _screenManager.updateTitle(index: _pageIndex);
    _pageController = PageController(
      initialPage: _initialPageOffset + _pageIndex,
    );
    _pageController.addListener(() {
      final page = _pageController.page ?? _initialPageOffset;
      final currentIndex = (page - _initialPageOffset).round();
      if (currentIndex != _pageIndex) {
        _pageIndex = currentIndex;
        _screenManager.updateTitle(
          index: _pageIndex,
        );
        // Hide the bottom bar when swiping to a new page
        if (_showBottomBarNotifier.value) {
          _showBottomBarNotifier.value = false;
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _showBottomBarNotifier.dispose();
    _chapterNotifier.dispose();
    _screenManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<String>(
          valueListenable: _screenManager.titleNotifier,
          builder: (context, title, child) {
            return GestureDetector(
              onTap: () {
                final (bookId, chapterCount) =
                    _screenManager.currentBookAndChapterCount(_pageIndex);
                _chapterNotifier.value = (bookId, chapterCount);
              },
              child: Text(title),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          _buildChapterTextPageView(),
          _buildChapterChooserOverlay(),
          _buildBottomMenuBar(),
        ],
      ),
    );
  }

  Widget _buildChapterTextPageView() {
    return PageView.builder(
      controller: _pageController,
      physics: const SnappyScrollPhysics(),
      itemBuilder: (context, index) {
        final pageIndex = index - _initialPageOffset;
        final (bookId, chapter) =
            _screenManager.bookAndChapterForPageIndex(pageIndex);
        return ChapterText(
          bookId: bookId,
          chapter: chapter,
          onSelectionChanged: (controller) {
            _activeController = controller;
            final hasSelection = controller.hasSelection;
            if (_showBottomBarNotifier.value != hasSelection) {
              _showBottomBarNotifier.value = hasSelection;
            }
          },
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
          chapterCount: chapterCount,
          onChapterSelected: (chapter) {
            _chapterNotifier.value = null;
            if (chapter == null) return;
            final pageIndex = _screenManager.pageIndexForBookAndChapter(
              bookId: bookId,
              chapter: chapter,
            );
            final index = pageIndex + _initialPageOffset;
            _pageController.jumpToPage(index);
          },
        );
      },
    );
  }

  Widget _buildBottomMenuBar() {
    return ValueListenableBuilder(
        valueListenable: _showBottomBarNotifier,
        builder: (context, showBar, child) {
          final language = showBar ? _getCurrentLanguage() : Language.greek;
          return Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSlide(
              offset: showBar ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Theme.of(context).colorScheme.onSurface,
                unselectedItemColor: Theme.of(context).colorScheme.onSurface,
                selectedFontSize: 12.0,
                unselectedFontSize: 12.0,
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.content_copy),
                    label: 'Copy',
                  ),
                  BottomNavigationBarItem(
                    icon: _getLanguageIcon(language),
                    label: _getLanguageLabel(language),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.compare),
                    label: 'Compare',
                  ),
                ],
                onTap: (index) => _handleBottomBarTap(index, language),
              ),
            ),
          );
        });
  }

  Language _getCurrentLanguage() {
    final wordId = _activeController!.startId!;
    final reference = Reference.fromWordId(packedInt: wordId);
    final language = _screenManager.verseLanguageLabel(_pageIndex, reference);
    return language;
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
        return Icon(CustomIcons.alpha);
      case Language.hebrew:
      case Language.aramaic:
        return Icon(CustomIcons.aleph);
    }
  }

  Future<void> _handleBottomBarTap(int index, Language language) async {
    if (_activeController == null || !_activeController!.hasSelection) return;

    final startId = _activeController!.startId!;

    // Extract context using the Extension
    final reference = Reference.fromWordId(packedInt: startId);

    switch (index) {
      case 0:
        await _handleCopy();
      case 1:
        _handleHebrewGreek(reference, language);
      case 2:
        _handleCompare(reference);
    }

    // Clear selection after action
    _activeController?.clear();
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
          verse: reference.verse,
          language: language,
        ),
      ),
    );
  }

  void _handleCompare(Reference reference) {
    final url = _screenManager.bibleHubUrl(
      bookId: reference.bookId,
      chapter: reference.chapter,
      verse: reference.verse,
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
