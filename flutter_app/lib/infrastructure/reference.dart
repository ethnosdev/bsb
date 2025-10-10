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

  factory Reference.from({required int packedInt}) {
    const int bookMultiplier = 1000000;
    const int chapterMultiplier = 1000;
    final bookId = packedInt ~/ bookMultiplier;
    final chapter = (packedInt % bookMultiplier) ~/ chapterMultiplier;
    final verse = packedInt % chapterMultiplier;
    return Reference(bookId: bookId, chapter: chapter, verse: verse);
  }

  final int bookId;
  final int chapter;
  final int verse;

  int get packedVerse => bookId * 1000000 + chapter * 1000 + verse;

  /// If not null, the reference is a range of verses.
  final int? endVerse;

  int? get packedEndVerse =>
      (endVerse == null) ? null : bookId * 1000000 + chapter * 1000 + endVerse!;

  static Reference? tryParse(String reference) {
    // reference is in the form: "1 Corinthians 1:1" or "Romans 1:1–3"
    final regex = RegExp(
      r'((?:[1-3]\s)?[A-Z][a-z]+(?:\s[a-zA-Z]+)?)\s+(\d+):(\d+)(?:–(\d+))?',
      caseSensitive: true,
    );

    final match = regex.firstMatch(reference);
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

  @override
  String toString() {
    final bookName = bookIdToFullNameMap[bookId];
    return '$bookName $chapter:$verse${endVerse == null ? '' : '–$endVerse'}';
  }
}

const validBookNames = [
  'Genesis',
  'Exodus',
  'Leviticus',
  'Numbers',
  'Deuteronomy',
  'Joshua',
  'Judges',
  'Ruth',
  '1 Samuel',
  '2 Samuel',
  '1 Kings',
  '2 Kings',
  '1 Chronicles',
  '2 Chronicles',
  'Ezra',
  'Nehemiah',
  'Esther',
  'Job',
  'Psalm', // Psalm is a special case
  'Psalms',
  'Proverbs',
  'Ecclesiastes',
  'Song of Solomon',
  'Isaiah',
  'Jeremiah',
  'Lamentations',
  'Ezekiel',
  'Daniel',
  'Hosea',
  'Joel',
  'Amos',
  'Obadiah',
  'Jonah',
  'Micah',
  'Nahum',
  'Habakkuk',
  'Zephaniah',
  'Haggai',
  'Zechariah',
  'Malachi',
  'Matthew',
  'Mark',
  'Luke',
  'John',
  'Acts',
  'Romans',
  '1 Corinthians',
  '2 Corinthians',
  'Galatians',
  'Ephesians',
  'Philippians',
  'Colossians',
  '1 Thessalonians',
  '2 Thessalonians',
  '1 Timothy',
  '2 Timothy',
  'Titus',
  'Philemon',
  'Hebrews',
  'James',
  '1 Peter',
  '2 Peter',
  '1 John',
  '2 John',
  '3 John',
  'Jude',
  'Revelation',
];
