import 'package:bsb/app_state.dart';
import 'package:bsb/core/font_family.dart';
import 'package:bsb/core/font_scale.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:bsb/ui/hebrew_greek/hebrew_greek_manager.dart';
import 'package:bsb/ui/hebrew_greek/passage_cards.dart';
import 'package:bsb/ui/hebrew_greek/reference_modal_sheet.dart';
import 'package:bsb/ui/hebrew_greek/similar_verses/similar_verse_manager.dart';
import 'package:bsb/ui/hebrew_greek/similar_verses/similar_verses_page.dart';
import 'package:bsb/ui/hebrew_greek/verse_page_manager.dart';
import 'package:bsb/ui/shared/snappy_scroll_physics.dart';
import 'package:bsb/ui/shared/zoom_wrapper.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class HebrewGreekScreen extends StatefulWidget {
  const HebrewGreekScreen({
    super.key,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.language,
  });

  final int bookId;
  final int chapter;
  final int verse;
  final Language language;

  @override
  State<HebrewGreekScreen> createState() => _HebrewGreekScreenState();
}

class _HebrewGreekScreenState extends State<HebrewGreekScreen> {
  final manager = HebrewGreekManager();
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    manager.init(widget.bookId, widget.chapter, widget.verse);
    _pageIndex = widget.verse - 1;
    _pageController = PageController(
      initialPage: _pageIndex,
    );
    _pageController.addListener(() {
      final currentIndex = (_pageController.page ?? widget.verse - 1).round();
      if (_pageIndex != currentIndex) {
        _pageIndex = currentIndex;
        manager.updateTitle(
          bookId: widget.bookId,
          chapter: widget.chapter,
          verse: _pageIndex + 1,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<String>(
          valueListenable: manager.titleNotifier,
          builder: (context, title, child) {
            return Text(title);
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: ValueListenableBuilder<int?>(
          valueListenable: manager.verseCountNotifier,
          builder: (context, verseCount, child) {
            if (verseCount == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final pageView = PageView.builder(
              controller: _pageController,
              physics: const SnappyScrollPhysics(),
              itemCount: verseCount,
              itemBuilder: (context, index) {
                return _VersePageView(
                  bookId: widget.bookId,
                  chapter: widget.chapter,
                  verse: index + 1,
                  language: widget.language,
                );
              },
            );

            final appState =
                getIt.isRegistered<AppState>() ? getIt<AppState>() : null;
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
          },
        ),
      ),
    );
  }
}

class _VersePageView extends StatefulWidget {
  const _VersePageView({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.language,
  });

  final int bookId;
  final int chapter;
  final int verse;
  final Language language;

  @override
  State<_VersePageView> createState() => _VersePageViewState();
}

class _VersePageViewState extends State<_VersePageView> {
  late final VersePageManager verseManager;

  @override
  void initState() {
    super.initState();
    verseManager = VersePageManager(widget.language);
    verseManager.requestVerseContent(
      bookId: widget.bookId,
      chapter: widget.chapter,
      verse: widget.verse,
    );
  }

  @override
  void dispose() {
    verseManager.dispose();
    super.dispose();
  }

  Future<void> _launch(String webpage) async {
    final url = Uri.parse(webpage);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = getIt.isRegistered<AppState>() ? getIt<AppState>() : null;
    final textSizeNotifier = appState?.textSizeNotifier ??
        ValueNotifier<double>(FontScale.defaultBaseSize);

    return ValueListenableBuilder<double>(
      valueListenable: textSizeNotifier,
      builder: (context, baseTextSize, _) {
        return ListenableBuilder(
          listenable: verseManager,
          builder: (context, child) {
            if (verseManager.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EnglishPassageCard(
                      words: verseManager.englishWords,
                      selectedWord: verseManager.selectedWord,
                      onWordSelected: verseManager.selectWord,
                      baseTextSize: baseTextSize,
                    ),
                    const SizedBox(height: 12),
                    OriginalPassageCard(
                      language: widget.language,
                      words: verseManager.originalWords,
                      selectedWord: verseManager.selectedWord,
                      onWordSelected: verseManager.selectWord,
                      baseTextSize: baseTextSize,
                    ),
                    const SizedBox(height: 16),
                    if (verseManager.selectedWord != null)
                      _buildWordDetailsCard(
                        theme,
                        verseManager.selectedWord!,
                        baseTextSize,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWordDetailsCard(
    ThemeData theme,
    OriginalWord word,
    double baseTextSize,
  ) {
    final fontFamily = fontFamilyForLanguage(word.language);
    final lexiconTitle = word.language == Language.greek
        ? 'Abbott-Smith Greek Lexicon'
        : 'Brown-Driver-Briggs Lexicon';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(120)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headword row
            Center(
              child: SelectableText(
                word.word,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: FontScale.heroWord(baseTextSize),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (word.transliteration.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    word.transliteration,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                word.isVvv && word.partOfTranslation != null
                    ? 'Translated as part of "${word.partOfTranslation}"'
                    : (word.isUntranslated
                        ? '(not translated in English text)'
                        : word.englishGloss),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontStyle: (word.isUntranslated || word.isVvv)
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                word.partOfSpeech,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons Row: Occurrences, Bible Hub
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.format_list_numbered, size: 18),
                  label: const Text('Occurrences'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SimilarVersesPage(
                          word: word,
                          initialMode: WordSearchMode.exactForm,
                          initialExactCount: verseManager.exactCount,
                          initialStrongsCount: verseManager.strongsCount,
                        ),
                      ),
                    );
                  },
                ),
                if (word.strongsNumber > 0)
                  ActionChip(
                    avatar: const Icon(Icons.open_in_browser, size: 18),
                    label: const Text('Bible Hub'),
                    onPressed: () {
                      final lang = word.language == Language.greek
                          ? 'greek'
                          : 'hebrew';
                      _launch(
                        'https://biblehub.com/$lang/${word.strongsNumber}.htm',
                      );
                    },
                  ),
              ],
            ),
            const Divider(height: 32),

            // Lexicon Header
            Row(
              children: [
                Icon(
                  Icons.menu_book,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  lexiconTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lexicon Markdown Body
            if (verseManager.isLoadingLexicon)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (verseManager.lexiconContent != null &&
                verseManager.lexiconContent!.isNotEmpty)
              MarkdownBody(
                data: verseManager.lexiconContent!,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  a: TextStyle(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: theme.colorScheme.primary,
                  ),
                  h3: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  p: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: FontScale.lexiconBody(baseTextSize),
                    height: 1.5,
                  ),
                  listBullet: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: FontScale.lexiconBody(baseTextSize),
                  ),
                ),
                onTapLink: (text, href, title) {
                  if (href != null) {
                    showReferenceModal(
                      context: context,
                      href: href,
                      defaultLanguage: word.language,
                      targetStrongs: word.strongsNumber,
                    );
                  }
                },
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No lexicon entry available for this word.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
