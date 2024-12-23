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
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ValueListenableBuilder<String>(
              valueListenable: textManager.textNotifier,
              builder: (context, text, child) {
                return SelectableText(
                  text,
                  style: const TextStyle(
                    fontSize: 12.0,
                    height: 1.5,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.justify,
                );
              }),
        ),
      ),
    );
  }
}
