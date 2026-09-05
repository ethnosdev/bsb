class SectionHeading {
  final int bookId;
  final int chapter;
  final int verse;
  final String text;
  final String format; // 's1' or 's2'

  const SectionHeading({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.format,
  });

  bool get isSubheading => format == 's2';

  String get referenceDisplay => '$chapter:$verse';
}
