import 'package:database_builder/bsb/database_builder.dart';

class VerseLine {
  VerseLine({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.footnote,
    required this.format,
    required this.type,
  });

  final int bookId;
  final int chapter;
  final int verse;
  final String text;
  final String? footnote;
  final Format? format;
  final TextType type;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VerseLine &&
        other.bookId == bookId &&
        other.chapter == chapter &&
        other.verse == verse &&
        other.text == text &&
        other.footnote == footnote &&
        other.format == format &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(
        bookId,
        chapter,
        verse,
        text,
        footnote,
        format,
        type,
      );
}
