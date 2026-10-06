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

class BookMatch {
  final int bookId;
  final String bookName;
  final int count;

  const BookMatch({
    required this.bookId,
    required this.bookName,
    required this.count,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookMatch &&
          runtimeType == other.runtimeType &&
          bookId == other.bookId &&
          count == other.count;

  @override
  int get hashCode => Object.hash(bookId, count);

  @override
  String toString() => '$bookName ($count)';
}
