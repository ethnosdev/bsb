import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          _HelpCard(
            title: 'Chapter selection',
            content: 'On the main screen, tap any book to select a chapter and then go to the text. '
                'Alternatively, double tap a book to go to chapter 1.',
          ),
          SizedBox(height: 16),
          _HelpCard(
            title: 'Navigation',
            content: 'While in the chapter text screen, swipe to the right or left '
                'to go to the next or previous chapter.',
          ),
          SizedBox(height: 16),
          _HelpCard(
            title: 'Footnotes',
            content: 'If you see an asterisk (*) in the text, tap it to learn additional information.',
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final String title;
  final String content;

  const _HelpCard({
    required this.title,
    required this.content,
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
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
