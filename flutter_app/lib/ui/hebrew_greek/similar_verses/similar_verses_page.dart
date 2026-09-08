import 'package:bsb/core/font_family.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'similar_verse_manager.dart';

class SimilarVersesPage extends StatefulWidget {
  const SimilarVersesPage({
    super.key,
    required this.word,
    this.initialMode = WordSearchMode.strongs,
  });

  final OriginalWord word;
  final WordSearchMode initialMode;

  @override
  State<SimilarVersesPage> createState() => _SimilarVersesPageState();
}

class _SimilarVersesPageState extends State<SimilarVersesPage> {
  final manager = SimilarVerseManager();

  @override
  void initState() {
    super.initState();
    manager.init(widget.word, initialMode: widget.initialMode);
  }

  Future<void> _launch(String webpage) async {
    final url = Uri.parse(webpage);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: ValueListenableBuilder<WordSearchMode>(
              valueListenable: manager.searchModeNotifier,
              builder: (context, mode, child) {
                return SegmentedButton<WordSearchMode>(
                  segments: [
                    ButtonSegment<WordSearchMode>(
                      value: WordSearchMode.exactForm,
                      label: Text('Exact Form (${manager.exactCount})'),
                      icon: const Icon(Icons.spellcheck),
                    ),
                    ButtonSegment<WordSearchMode>(
                      value: WordSearchMode.strongs,
                      label: Text("Strong's (${manager.strongsCount})"),
                      icon: const Icon(Icons.tag),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (Set<WordSearchMode> newSelection) {
                    manager.switchMode(newSelection.first);
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

                        return FutureBuilder<TextSpan>(
                          future: manager.getVerseContent(
                            reference,
                            Theme.of(context).colorScheme.primary,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData) {
                              final verse = snapshot.data!;
                              return ListTile(
                                title: Text(
                                  formattedReference,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text.rich(
                                    verse,
                                    textDirection: widget.word.language.isLTR
                                        ? TextDirection.ltr
                                        : TextDirection.rtl,
                                  ),
                                ),
                              );
                            } else {
                              return const SizedBox(height: 60);
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
