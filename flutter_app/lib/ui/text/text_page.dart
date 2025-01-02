import 'package:bsb/ui/text/chapter_layout.dart';
import 'package:database_builder/schema.dart';
import 'package:flutter/material.dart';

import 'text_manager.dart';

class TextPage extends StatefulWidget {
  const TextPage({
    super.key,
    required this.bookId,
    required this.chapter,
  });

  final int bookId;
  final int chapter;

  @override
  State<TextPage> createState() => _TextPageState();
}

class _TextPageState extends State<TextPage> {
  final textManager = TextManager();

  @override
  void initState() {
    super.initState();
    textManager.getText(widget.bookId, widget.chapter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(textManager.formatTitle(widget.bookId, widget.chapter)),
        actions: [
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: () {
              final (bookId, chapter) = textManager.getNextChapter(widget.bookId, widget.chapter);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TextPage(
                    bookId: bookId,
                    chapter: chapter,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ValueListenableBuilder<List<(TextSpan, TextType)>>(
            valueListenable: textManager.paragraphNotifier,
            builder: (context, paragraphs, child) {
              return ChapterLayout(paragraphs: paragraphs);
            },
          ),
        ),
      ),
    );
  }
}
