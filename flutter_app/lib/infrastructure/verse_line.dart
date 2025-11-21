import 'package:scripture/scripture_core.dart';

class UsfmLine {
  UsfmLine({
    required this.bookChapterVerse,
    required this.text,
    required this.format,
  });

  /// BBCCCVVV
  final int bookChapterVerse;
  final String text;
  final ParagraphFormat format;

  int get bookId => bookChapterVerse ~/ 1000000;
  int get chapter => (bookChapterVerse ~/ 1000) % 1000;
  int get verse => bookChapterVerse % 1000;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsfmLine &&
        other.bookChapterVerse == bookChapterVerse &&
        other.text == text &&
        other.format == format;
  }

  @override
  int get hashCode => Object.hash(
        bookChapterVerse,
        text,
        format,
      );
}
