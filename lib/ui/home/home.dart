import 'package:bsb/ui/home/book_chooser.dart';
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
      // appBar: AppBar(),
      body: BookChooser(
        onBookSelected: (book) {
          print(book);
        },
      ),
    );
  }
}
