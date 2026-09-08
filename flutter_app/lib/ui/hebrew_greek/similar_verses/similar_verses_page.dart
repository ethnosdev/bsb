import 'package:bsb/core/font_family.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:bsb/ui/hebrew_greek/reference_modal_sheet.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'similar_verse_manager.dart';

class SimilarVersesPage extends StatefulWidget {
  const SimilarVersesPage({
    super.key,
    required this.word,
    this.initialMode = WordSearchMode.exactForm,
    this.initialExactCount,
    this.initialStrongsCount,
    this.dbHelper,
  });

  final OriginalWord word;
  final WordSearchMode initialMode;
  final int? initialExactCount;
  final int? initialStrongsCount;
  final DatabaseHelper? dbHelper;

  @override
  State<SimilarVersesPage> createState() => _SimilarVersesPageState();
}

class _SimilarVersesPageState extends State<SimilarVersesPage> {
  late final SimilarVerseManager manager;

  @override
  void initState() {
    super.initState();
    manager = SimilarVerseManager(dbHelper: widget.dbHelper);
    manager.init(
      widget.word,
      initialMode: widget.initialMode,
      initialExactCount: widget.initialExactCount,
      initialStrongsCount: widget.initialStrongsCount,
    );
  }

  @override
  void dispose() {
    manager.dispose();
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
    final fontFamily = fontFamilyForLanguage(widget.word.language);
    final prefix = widget.word.language == Language.greek ? 'G' : 'H';
    final strongsTag =
        widget.word.strongsNumber > 0 ? ' ($prefix${widget.word.strongsNumber})' : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.word.word}$strongsTag',
          style: TextStyle(
            fontFamily: fontFamily,
          ),
        ),
        actions: [
          if (widget.word.strongsNumber > 0)
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              tooltip: "View on Bible Hub",
              onPressed: () {
                final lang = widget.word.language == Language.greek
                    ? 'greek'
                    : 'hebrew';
                _launch(
                  'https://biblehub.com/$lang/${widget.word.strongsNumber}.htm',
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ValueListenableBuilder<({int exact, int strongs})>(
              valueListenable: manager.countsNotifier,
              builder: (context, counts, child) {
                return ValueListenableBuilder<WordSearchMode>(
                  valueListenable: manager.searchModeNotifier,
                  builder: (context, mode, child) {
                    return SegmentedButton<WordSearchMode>(
                      expandedInsets: EdgeInsets.zero,
                      segments: [
                        ButtonSegment<WordSearchMode>(
                          value: WordSearchMode.exactForm,
                          label: Text('Exact Form (${counts.exact})'),
                          icon: const Icon(
                            Icons.check,
                            color: Colors.transparent,
                          ),
                        ),
                        ButtonSegment<WordSearchMode>(
                          value: WordSearchMode.strongs,
                          label: Text('Lexical Form (${counts.strongs})'),
                          icon: const Icon(
                            Icons.check,
                            color: Colors.transparent,
                          ),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (Set<WordSearchMode> newSelection) {
                        manager.switchMode(newSelection.first);
                      },
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: manager.isLoadingNotifier,
              builder: (context, isLoading, child) {
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ValueListenableBuilder<List<Reference>>(
                  valueListenable: manager.similarVersesNotifier,
                  builder: (context, verseList, child) {
                    if (verseList.isEmpty) {
                      return const Center(
                        child: Text('No occurrences found.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: verseList.length,
                      itemBuilder: (context, index) {
                        final reference = verseList[index];
                        final formattedReference =
                            manager.formatReference(reference);

                        return FutureBuilder<VerseDisplayContent>(
                          key: ValueKey(
                            '${reference.packedVerse}_${manager.searchModeNotifier.value.name}',
                          ),
                          future: manager.getVerseContent(
                            reference,
                            theme.colorScheme.primary,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData) {
                              final content = snapshot.data!;
                              return ListTile(
                                title: Text(
                                  formattedReference,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text.rich(
                                        content.english,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text.rich(
                                        content.original,
                                        textDirection:
                                            widget.word.language.isLTR
                                                ? TextDirection.ltr
                                                : TextDirection.rtl,
                                        style: TextStyle(
                                          fontFamily: fontFamily,
                                          fontSize: widget.word.language ==
                                                  Language.hebrew
                                              ? 18
                                              : 16,
                                          height: 1.4,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  final isExact =
                                      manager.searchModeNotifier.value ==
                                          WordSearchMode.exactForm;
                                  showVerseReferenceModal(
                                    context: context,
                                    reference: reference,
                                    initialStrongs: widget.word.strongsNumber,
                                    initialOriginalId:
                                        isExact ? widget.word.originalId : null,
                                    initialExactWord:
                                        isExact ? widget.word.word : null,
                                    dbHelper: widget.dbHelper,
                                  );
                                },
                              );
                            } else {
                              return const SizedBox(height: 80);
                            }
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
