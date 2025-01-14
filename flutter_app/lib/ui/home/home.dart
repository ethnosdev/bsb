import 'package:bsb/ui/home/book_chooser.dart';
import 'package:bsb/ui/home/drawer.dart';
import 'package:bsb/ui/text/text_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Berean Standard Bible'),
      ),
      drawer: const AppDrawer(),
      body: BookChooser(
        onSelected: (bookId, chapter) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TextPage(
                bookId: bookId,
                chapter: chapter,
              ),
            ),
          );
        },
      ),
    );
  }
}
