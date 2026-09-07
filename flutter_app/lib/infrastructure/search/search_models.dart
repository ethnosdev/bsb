import '../reference.dart';

enum SearchScope {
  all,
  ot,
  nt,
  book,
}

class SearchResult {
  final Reference reference;
  final String text;
  final List<(int, int)> matchSpans;

  const SearchResult({
    required this.reference,
    required this.text,
    this.matchSpans = const [],
  });

  @override
  String toString() => '$reference: $text';
}

class ParsedReference {
  final int bookId;
  final int chapter;
  final int? verse;
  final int? endVerse;
  final bool isExactVerse;

  const ParsedReference({
    required this.bookId,
    required this.chapter,
    this.verse,
    this.endVerse,
    required this.isExactVerse,
  });

  Reference toReference() {
    return Reference(
      bookId: bookId,
      chapter: chapter,
      verse: verse ?? 1,
      endVerse: endVerse,
    );
  }
}
