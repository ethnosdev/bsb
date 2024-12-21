import 'package:flutter/material.dart';

class TextPage extends StatelessWidget {
  const TextPage({
    super.key,
    required this.bookId,
    required this.chapter,
  });

  final String bookId;
  final int chapter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SelectableText(
            '$bookId $chapter',
            style: const TextStyle(
              fontSize: 50.0,
              height: 1.5,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.justify,
          ),
        ),
      ),
    );
  }
}
