import 'package:bsb/core/font_family.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:bsb/ui/hebrew_greek/passage_cards.dart';
import 'package:bsb/ui/hebrew_greek/similar_verses/similar_verse_manager.dart';
import 'package:bsb/ui/hebrew_greek/similar_verses/similar_verses_page.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

const Map<String, int> _osisBookToIdMap = {
  'Gen': 1, 'Exod': 2, 'Lev': 3, 'Num': 4, 'Deut': 5,
  'Josh': 6, 'Judg': 7, 'Ruth': 8, '1Sam': 9, '2Sam': 10,
  '1Kgs': 11, '1Ki': 11, '2Kgs': 12, '2King': 12, '1Chr': 13, '2Chr': 14,
  'Ezra': 15, 'Neh': 16, 'Esth': 17, 'Job': 18, 'Ps': 19, 'Psa': 19,
  'Prov': 20, 'Eccl': 21, 'Song': 22, 'Isa': 23, 'Jer': 24, 'Lam': 25,
  'Ezek': 26, 'Exek': 26, 'Dan': 27, 'DAn': 27, 'Hos': 28, 'Joel': 29,
  'Amos': 30, 'Am': 30, 'Obad': 31, 'Jonah': 32, 'Jon': 32, 'Mic': 33,
  'Nah': 34, 'Hab': 35, 'Zeph': 36, 'Hag': 37, 'Zech': 38, 'Mal': 39,
  'Matt': 40, 'Mat': 40, 'Mark': 41, 'Mar': 41, 'Mark14': 41, 'Luke': 42,
  'John': 43, 'Acts': 44, 'Act': 44, 'Rom': 45, '1Cor': 46, '1Cor15': 46,
  '2Cor': 47, 'Gal': 48, 'Eph': 49, 'Phil': 50, 'Phi': 50, 'Col': 51,
  '1Thess': 52, '2Thess': 53, '1Tim': 54, '2Tim': 55, '2Ti': 55, 'Titus': 56,
  'Phlm': 57, 'Heb': 58, 'Jas': 59, 'Jam': 59, '1Pet': 60, '2Pet': 61,
  '1John': 62, '2John': 63, '3John': 64, 'Jude': 65, 'Rev': 66, 'REv': 66,
};

Reference? resolveReferenceString(String refStr) {
  final clean = refStr.trim();
  final packed = int.tryParse(clean);
  if (packed != null) {
    try {
      return Reference.fromVerseId(packedInt: packed);
    } catch (_) {
      return null;
    }
  }

  final parsed = Reference.tryParse(clean);
  if (parsed != null) return parsed;

  final parts = clean.split('.');
  if (parts.length >= 3) {
    final bookId = _osisBookToIdMap[parts[0]];
    final ch = int.tryParse(parts[1]);
    final vs = int.tryParse(parts[2]);
    if (bookId != null && ch != null && vs != null) {
      try {
        return Reference(bookId: bookId, chapter: ch, verse: vs);
      } catch (_) {
        return null;
      }
    }
  }
  return null;
}

Future<void> showVerseReferenceModal({
  required BuildContext context,
  required Reference reference,
  int? initialStrongs,
  int? initialOriginalId,
  String? initialExactWord,
  DatabaseHelper? dbHelper,
}) {
  final db = dbHelper ?? getIt<DatabaseHelper>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => VerseReferenceModal(
      reference: reference,
      initialStrongs: initialStrongs,
      initialOriginalId: initialOriginalId,
      initialExactWord: initialExactWord,
      dbHelper: db,
    ),
  );
}

Future<void> showReferenceModal({
  required BuildContext context,
  required String href,
  Language? defaultLanguage,
  int? targetStrongs,
  DatabaseHelper? dbHelper,
}) async {
  final db = dbHelper ?? getIt<DatabaseHelper>();

  if (href.startsWith('http://') || href.startsWith('https://')) {
    final uri = Uri.parse(href);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return;
  }

  if (href.startsWith('ref:')) {
    final refStr = href.substring(4);
    final reference = resolveReferenceString(refStr);
    if (reference != null) {
      return showVerseReferenceModal(
        context: context,
        reference: reference,
        initialStrongs: targetStrongs,
        dbHelper: db,
      );
    }
  }

  if (href.startsWith('lex:')) {
    final lemma = href.substring(4);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => LexiconEntryModal(
        lemma: lemma,
        language: defaultLanguage,
        dbHelper: db,
      ),
    );
  }
}

class VerseReferenceModal extends StatefulWidget {
  const VerseReferenceModal({
    super.key,
    required this.reference,
    this.initialStrongs,
    this.initialOriginalId,
    this.initialExactWord,
    this.dbHelper,
  });

  final Reference reference;
  final int? initialStrongs;
  final int? initialOriginalId;
  final String? initialExactWord;
  final DatabaseHelper? dbHelper;

  @override
  State<VerseReferenceModal> createState() => _VerseReferenceModalState();
}

class _VerseReferenceModalState extends State<VerseReferenceModal> {
  DatabaseHelper get _db => widget.dbHelper ?? getIt<DatabaseHelper>();

  bool _loading = true;
  String? _englishText;
  List<VerseElement> _interlinear = [];
  OriginalWord? _selectedWord;
  String? _lexiconContent;
  bool _loadingLexicon = false;

  @override
  void initState() {
    super.initState();
    _loadVerse();
  }

  Future<void> _loadVerse() async {
    final packed = widget.reference.packedVerse;
    final english = await _db.getVerseText(packed);
    final elements = await _db.getOriginalLanguageData(widget.reference);

    final originalWords = elements.whereType<OriginalWord>().toList();
    OriginalWord? initialWord;
    if (widget.initialOriginalId != null && widget.initialOriginalId! > 0) {
      initialWord = originalWords
          .where((w) => w.originalId == widget.initialOriginalId)
          .firstOrNull;
    }
    if (initialWord == null &&
        widget.initialExactWord != null &&
        widget.initialExactWord!.isNotEmpty) {
      initialWord = originalWords
          .where((w) => w.word == widget.initialExactWord)
          .firstOrNull;
    }
    if (initialWord == null &&
        widget.initialStrongs != null &&
        widget.initialStrongs! > 0) {
      initialWord = originalWords
          .where((w) => w.strongsNumber == widget.initialStrongs)
          .firstOrNull;
    }
    final englishWords = originalWords
        .where((w) => w.hasEnglishChip)
        .toList()
      ..sort((a, b) => a.bsbSort.compareTo(b.bsbSort));
    initialWord ??= englishWords.firstOrNull ?? originalWords.firstOrNull;

    if (mounted) {
      setState(() {
        _englishText = english;
        _interlinear = elements;
        _selectedWord = initialWord;
        _loading = false;
      });
      if (initialWord != null) {
        _loadLexicon(initialWord);
      }
    }
  }

  Future<void> _loadLexicon(OriginalWord word) async {
    setState(() {
      _loadingLexicon = true;
    });

    final content = await _db.getLexiconContent(word.language, word.strongsNumber);

    if (mounted) {
      setState(() {
        _lexiconContent = content;
        _loadingLexicon = false;
      });
    }
  }

  void _onWordSelected(OriginalWord word) {
    if (_selectedWord?.id == word.id) return;
    setState(() {
      _selectedWord = word;
    });
    _loadLexicon(word);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final originalWords = _interlinear.whereType<OriginalWord>().toList();
    final englishWords = originalWords
        .where((w) => w.hasEnglishChip)
        .toList()
      ..sort((a, b) => a.bsbSort.compareTo(b.bsbSort));
    final Language language = originalWords.isNotEmpty
        ? originalWords.first.language
        : (widget.reference.bookId <= 39 ? Language.hebrew : Language.greek);
    final fontFamily = fontFamilyForLanguage(language);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_stories,
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.reference.toString(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        EnglishPassageCard(
                          words: englishWords,
                          selectedWord: _selectedWord,
                          onWordSelected: _onWordSelected,
                          fallbackText: _englishText,
                        ),
                        const SizedBox(height: 12),
                        OriginalPassageCard(
                          language: language,
                          words: originalWords,
                          selectedWord: _selectedWord,
                          onWordSelected: _onWordSelected,
                        ),
                        const SizedBox(height: 16),

                        // Lexicon Section for Selected Word
                        if (_selectedWord != null) ...[
                          Card(
                            elevation: 0,
                            color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant.withAlpha(80),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      _selectedWord!.word,
                                      style: TextStyle(
                                        fontFamily: fontFamily,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  if (_selectedWord!.transliteration.isNotEmpty)
                                    Center(
                                      child: Text(
                                        _selectedWord!.transliteration,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Center(
                                    child: Text(
                                      _selectedWord!.isVvv &&
                                              _selectedWord!.partOfTranslation !=
                                                  null
                                          ? 'Translated as part of "${_selectedWord!.partOfTranslation}"'
                                          : (_selectedWord!.isUntranslated
                                              ? '(not translated)'
                                              : _selectedWord!.englishGloss),
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontStyle:
                                            (_selectedWord!.isUntranslated ||
                                                    _selectedWord!.isVvv)
                                                ? FontStyle.italic
                                                : FontStyle.normal,
                                      ),
                                    ),
                                  ),
                                  if (_selectedWord!.strongsNumber > 0) ...[
                                    const SizedBox(height: 8),
                                    Center(
                                      child: Chip(
                                        label: Text(
                                          '${_selectedWord!.language == Language.greek ? "G" : "H"}${_selectedWord!.strongsNumber}',
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 8,
                                    children: [
                                      ActionChip(
                                        avatar: const Icon(
                                          Icons.format_list_numbered,
                                          size: 18,
                                        ),
                                        label: const Text('Occurrences'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  SimilarVersesPage(
                                                word: _selectedWord!,
                                                initialMode:
                                                    WordSearchMode.exactForm,
                                                dbHelper: _db,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      if (_selectedWord!.strongsNumber > 0)
                                        ActionChip(
                                          avatar: const Icon(
                                            Icons.open_in_browser,
                                            size: 18,
                                          ),
                                          label: const Text('Bible Hub'),
                                          onPressed: () {
                                            final lang =
                                                _selectedWord!.language ==
                                                        Language.greek
                                                    ? 'greek'
                                                    : 'hebrew';
                                            final url =
                                                'https://biblehub.com/$lang/${_selectedWord!.strongsNumber}.htm';
                                            showReferenceModal(
                                              context: context,
                                              href: url,
                                              dbHelper: _db,
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.menu_book,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _selectedWord!.language == Language.greek
                                            ? 'Abbott-Smith Lexicon'
                                            : 'Brown-Driver-Briggs Lexicon',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (_loadingLexicon)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  else if (_lexiconContent != null && _lexiconContent!.isNotEmpty)
                                    MarkdownBody(
                                      data: _lexiconContent!,
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
                                          fontSize: 14.5,
                                          height: 1.5,
                                        ),
                                      ),
                                      onTapLink: (text, href, title) {
                                        if (href != null) {
                                          showReferenceModal(
                                            context: context,
                                            href: href,
                                            defaultLanguage: _selectedWord!.language,
                                            targetStrongs: _selectedWord!.strongsNumber,
                                            dbHelper: _db,
                                          );
                                        }
                                      },
                                    )
                                  else
                                    Text(
                                      'No lexicon entry available for this word.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class LexiconEntryModal extends StatefulWidget {
  const LexiconEntryModal({
    super.key,
    required this.lemma,
    this.language,
    this.dbHelper,
  });

  final String lemma;
  final Language? language;
  final DatabaseHelper? dbHelper;

  @override
  State<LexiconEntryModal> createState() => _LexiconEntryModalState();
}

class _LexiconEntryModalState extends State<LexiconEntryModal> {
  DatabaseHelper get _db => widget.dbHelper ?? getIt<DatabaseHelper>();

  bool _loading = true;
  String? _content;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  Future<void> _loadEntry() async {
    final result = await _db.getLexiconContentByLemma(widget.language, widget.lemma);
    if (mounted) {
      setState(() {
        _content = result;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontFamily = fontFamilyForLanguage(
      widget.language ?? Language.hebrew,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.lemma,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        if (_content != null && _content!.isNotEmpty)
                          MarkdownBody(
                            data: _content!,
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
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                            onTapLink: (text, href, title) {
                              if (href != null) {
                                showReferenceModal(
                                  context: context,
                                  href: href,
                                  defaultLanguage: widget.language,
                                  dbHelper: _db,
                                );
                              }
                            },
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Text(
                                'No lexicon entry found for "${widget.lemma}".',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
