import 'package:database_builder/database_builder.dart';

class VerseLine {
  VerseLine({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.footnote,
    required this.format,
  });

  final int bookId;
  final int chapter;
  final int verse;
  final String text;
  final String? footnote;
  final ParagraphFormat format;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VerseLine &&
        other.bookId == bookId &&
        other.chapter == chapter &&
        other.verse == verse &&
        other.text == text &&
        other.footnote == footnote &&
        other.format == format;
  }

  @override
  int get hashCode => Object.hash(
        bookId,
        chapter,
        verse,
        text,
        footnote,
        format,
      );
}
