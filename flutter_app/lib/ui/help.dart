import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  late double fontSize;
  late TextStyle _titleStyle;
  late TextStyle _contentStyle;

  @override
  void initState() {
    super.initState();
    fontSize = getIt<UserSettings>().textSize;
    _titleStyle = TextStyle(
      fontSize: fontSize * 1.2,
      fontWeight: FontWeight.bold,
    );
    _contentStyle = TextStyle(
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _HelpCard(
            title: 'Chapter selection',
            content: 'On the main screen, tap any book to select a chapter and then go to the text. '
                'Alternatively, swipe up on a book to go to the first chapter '
                'or swipe down to go to the last chapter.',
            titleStyle: _titleStyle,
            contentStyle: _contentStyle,
          ),
          const SizedBox(height: 16),
          _HelpCard(
            title: 'Navigation',
            content: 'While in the chapter text screen, swipe to the right or left '
                'to go to the next or previous chapter. You can also tap book name '
                'on the app bar to show the chapter chooser dialog.',
            titleStyle: _titleStyle,
            contentStyle: _contentStyle,
          ),
          const SizedBox(height: 16),
          _HelpCard(
            title: 'Footnotes',
            content: 'If you see an asterisk (*) in the text, tap it to learn additional information.',
            titleStyle: _titleStyle,
            contentStyle: _contentStyle,
          ),
          const SizedBox(height: 16),
          _HelpCard(
            title: 'Additional tools',
            content: 'Long press on the text of a verse to copy, view the '
                'original Hebrew/Greek, or compare with other translations.',
            titleStyle: _titleStyle,
            contentStyle: _contentStyle,
          ),
        ],
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
            Text(
              title,
              style: titleStyle,
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: contentStyle,
            ),
          ],
        ),
      ),
    );
  }
}
