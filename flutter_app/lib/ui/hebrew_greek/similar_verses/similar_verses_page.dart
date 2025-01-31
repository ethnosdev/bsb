import 'package:bsb/core/font_family.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:flutter/material.dart';

import 'similar_verse_manager.dart';

class SimilarVersesPage extends StatefulWidget {
  const SimilarVersesPage({
    super.key,
    required this.word,
    required this.showEnglish,
  });

  final OriginalWord word;
  final bool showEnglish;

  @override
  State<SimilarVersesPage> createState() => _SimilarVersesPageState();
}

class _SimilarVersesPageState extends State<SimilarVersesPage> {
  final manager = SimilarVerseManager();

  @override
  void initState() {
    super.initState();
    manager.init(widget.word);
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = fontFamilyForLanguage(widget.word.language);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.word.word} (${widget.word.strongsNumber})',
          style: TextStyle(
            fontFamily: fontFamily,
          ),
        ),
      ),
      body: ValueListenableBuilder<List<Reference>>(
        valueListenable: manager.similarVersesNotifier,
        builder: (context, verseList, child) {
          return ListView.builder(
            itemCount: verseList.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Center(
                  child: Text(
                    '${verseList.length} results',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(100),
                    ),
                  ),
                );
              }
              final referenceIndex = index - 1;
              final reference = verseList[referenceIndex];
              final formattedReference = manager.formatReference(reference);
              return FutureBuilder<TextSpan>(
                future: manager.getVerseContent(
                  reference,
                  widget.word.strongsNumber,
                  Theme.of(context).colorScheme.error,
                  widget.showEnglish,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    final verse = snapshot.data!;
                    return ListTile(
                      title: Text(formattedReference),
                      subtitle: Text.rich(verse),
                    );
                  } else {
                    // Giving the widget a height ensures that the
                    // ListView.builder will not try to build the
                    // every item in the list just because they all
                    // theoretically fit with a zero height.
                    return const SizedBox(height: 50);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
