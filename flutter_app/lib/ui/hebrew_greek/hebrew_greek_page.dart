import 'package:flutter/material.dart';

class HebrewGreekPage extends StatelessWidget {
  const HebrewGreekPage({super.key, required int bookId, required int chapter, required int verseNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hebrew & Greek'),
      ),
      body: Container(),
    );
  }
}
