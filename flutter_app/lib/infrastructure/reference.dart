import 'package:database_builder/database_builder.dart';

class Reference {
  Reference({
    required this.bookId,
    required this.chapter,
    required this.verse,
    this.endVerse,
  })  : assert(bookId >= 1 && bookId <= 66),
        assert(chapter >= 1 && chapter <= 150),
        assert(endVerse == null || verse <= endVerse);

  final int bookId;
  final int chapter;
  final int verse;

  /// If not null, the reference is a range of verses.
  final int? endVerse;

  static Reference? tryParse(String reference) {
    // reference is in the form: "1 Corinthians 1:1" or "Romans 1:1–3"
    final match = referenceRegex.firstMatch(reference);
    if (match == null) {
      return null;
    }

    final bookName = match.group(1)!;
    final chapter = int.parse(match.group(2)!);
    final verse = int.parse(match.group(3)!);
    final endVerse = match.group(4) != null ? int.parse(match.group(4)!) : null;

    final bookId = fullNameToBookIdMap[bookName];
    if (bookId == null) {
      return null;
    }

    return Reference(
      bookId: bookId,
      chapter: chapter,
      verse: verse,
      endVerse: endVerse,
    );
  }

  static final referenceRegex = RegExp(
    r'^((?:[1-3]\s)?[A-Z][a-z]+(?:\s[a-zA-Z]+)?)\s+(\d+):(\d+)(?:–(\d+))?$',
    caseSensitive: true,
  );

  static bool isValid(String reference) {
    return referenceRegex.hasMatch(reference);
  }

  @override
  String toString() {
    final bookName = bookIdToFullNameMap[bookId];
    return '$bookName $chapter:$verse${endVerse == null ? '' : '–$endVerse'}';
  }
}
