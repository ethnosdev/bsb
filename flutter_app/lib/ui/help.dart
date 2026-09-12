import 'package:bsb/app_state.dart';
import 'package:bsb/core/font_scale.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textSizeNotifier = getIt.isRegistered<AppState>()
        ? getIt<AppState>().textSizeNotifier
        : ValueNotifier<double>(getIt<UserSettings>().textSize);

    return Scaffold(
      appBar: AppBar(title: const Text('Help'), elevation: 0),
      body: SafeArea(
        top: false,
        child: ValueListenableBuilder<double>(
          valueListenable: textSizeNotifier,
          builder: (context, fontSize, _) {
            final titleStyle = TextStyle(
              fontSize: FontScale.infoTitle(fontSize),
              fontWeight: FontWeight.bold,
            );
            final contentStyle = TextStyle(fontSize: fontSize);

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _HelpCard(
                  title: 'Book selection',
                  content:
                      'On the book selection screen, tap any book to choose a chapter '
                      'using the keypad (single-chapter books open directly). '
                      'Alternatively, swipe up on a book to go straight to the first chapter, '
                      'or swipe down to go to the last chapter. '
                      'Tap the list icon on the keypad to browse by section heading.',
                  titleStyle: titleStyle,
                  contentStyle: contentStyle,
                ),
                const SizedBox(height: 16),
                _HelpCard(
                  title: 'Navigation',
                  content:
                      'While reading the biblical text, swipe left or right to move between chapters. '
                      'Tap the active chapter in the app bar to reopen the chapter keypad. '
                      'Drag along the verse scrubber on the right edge to jump directly to any verse, '
                      'or pinch the screen to adjust the font size.',
                  titleStyle: titleStyle,
                  contentStyle: contentStyle,
                ),
                const SizedBox(height: 16),
                _HelpCard(
                  title: 'Tabs',
                  content:
                      'Tap the + icon in the app bar to open a chapter in a new tab. '
                      'Tap any tab to switch to it, drag tabs to reorder them, '
                      'or tap the close icon on the active tab to close it.',
                  titleStyle: titleStyle,
                  contentStyle: contentStyle,
                ),
                const SizedBox(height: 16),
                _HelpCard(
                  title: 'Footnotes',
                  content:
                      'Tap an asterisk (*) or the preceding word in the text to view footnotes. '
                      'Tap any cross-reference link inside a footnote to preview the passage, '
                      'which can also be opened in a new tab.',
                  titleStyle: titleStyle,
                  contentStyle: contentStyle,
                ),
                const SizedBox(height: 16),
                _HelpCard(
                  title: 'Verse tools',
                  content:
                      'Long press a verse to select it. Use the bottom toolbar to highlight '
                      'in multiple colors, attach a personal note, copy with the reference, '
                      'or explore the original Hebrew and Greek. '
                      'Tap the note icon in the text to view or edit an existing note.',
                  titleStyle: titleStyle,
                  contentStyle: contentStyle,
                ),
                const SizedBox(height: 16),
                _HelpCard(
                  title: 'Search',
                  content:
                      'Search for words or phrases across the entire Bible, Old Testament, '
                      'New Testament, or the current book. '
                      'Use the "Exact" filter to match exact phrases or words, '
                      'and tap any result to open it in a chapter tab.',
                  titleStyle: titleStyle,
                  contentStyle: contentStyle,
                ),
                const SizedBox(height: 16),
                _HelpCard(
                  title: 'Hebrew and Greek',
                  content:
                      'Access original language study by selecting a verse and tapping the Hebrew or Greek icon. '
                      'Tap any word in English or the original text to highlight both and view its transliteration, '
                      'grammatical details, and full lexicon entry (Abbott-Smith or BDB). '
                      'Tap "Occurrences" to see every verse where the word or root appears in Scripture, '
                      'or swipe left and right to navigate between verses.',
                  titleStyle: titleStyle,
                  contentStyle: contentStyle,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final String title;
  final String content;
  final TextStyle titleStyle;
  final TextStyle contentStyle;

  const _HelpCard({
    required this.title,
    required this.content,
    required this.titleStyle,
    required this.contentStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleStyle),
            const SizedBox(height: 8),
            Text(content, style: contentStyle),
          ],
        ),
      ),
    );
  }
}
