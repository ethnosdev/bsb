import 'package:database_builder/database_builder.dart';

class Reference {
  Reference({
    required this.bookId,
    required this.chapter,
    this.verse,
    this.endVerse,
    this.endChapter,
  })  : assert(bookId >= 1 && bookId <= 66),
        assert(chapter >= 1 && chapter <= 150),
        assert(endChapter == null || endChapter >= chapter),
        assert(verse == null || verse >= 0),
        assert(verse == null || endChapter == null),
        assert(verse != null || endVerse == null),
        assert(endVerse == null || (verse != null && verse <= endVerse));

  /// [packedInt] is in the form BBCCCVVV
  factory Reference.fromVerseId({required int packedInt, int? packedIntEnd}) {
    const int bookMultiplier = 1000000;
    const int chapterMultiplier = 1000;
    final bookId = packedInt ~/ bookMultiplier;
    final chapter = (packedInt % bookMultiplier) ~/ chapterMultiplier;
    final verse = packedInt % chapterMultiplier;
    int? endVerse;
    if (packedIntEnd != null) {
      endVerse = packedIntEnd % chapterMultiplier;
    }
    return Reference(
        bookId: bookId, chapter: chapter, verse: verse, endVerse: endVerse);
  }

  /// [packedInt] is in the form BBCCCVVVWWW
  factory Reference.fromWordId({required int packedInt, int? packedIntEnd}) {
    const int bookMultiplier = 1000000000;
    const int chapterMultiplier = 1000000;
    const int verseMultiplier = 1000;
    final bookId = packedInt ~/ bookMultiplier;
    final chapter = (packedInt % bookMultiplier) ~/ chapterMultiplier;
    final verse = (packedInt % chapterMultiplier) ~/ verseMultiplier;
    int? endVerse;
    if (packedIntEnd != null) {
      endVerse = (packedIntEnd % chapterMultiplier) ~/ verseMultiplier;
    }
    return Reference(
        bookId: bookId, chapter: chapter, verse: verse, endVerse: endVerse);
  }

  final int bookId;
  final int chapter;
  final int? verse;

  int get packedVerse => bookId * 1000000 + chapter * 1000 + (verse ?? 0);

  /// If not null, the reference is a range of verses.
  final int? endVerse;

  /// If not null, the reference is a range of chapters.
  final int? endChapter;

  int? get packedEndVerse {
    if (verse == null) {
      final targetEndChapter = endChapter ?? chapter;
      return bookId * 1000000 + targetEndChapter * 1000 + 999;
    }
    return (endVerse == null)
        ? null
        : bookId * 1000000 + chapter * 1000 + endVerse!;
  }

  static Reference? tryParse(String reference) {
    // reference can be in the form:
    // - "1 Corinthians 1:1" or "Romans 1:1–3" (or with hyphen "1:1-3")
    // - "Leviticus 13" or "Psalm 23"
    // - "1 Samuel 21–29" or "Psalms 56–60" (or with hyphen)
    final regex = RegExp(
      r'((?:[1-3]\s)?[A-Z][a-z]+(?:\s+[a-zA-Z]+)*)\s+(\d+)(?::(\d+)(?:[–\-—](\d+))?|(?:[–\-—](\d+))?\b(?!:))',
      caseSensitive: true,
    );

    final match = regex.firstMatch(reference);
    if (match == null) {
      return null;
    }

    final bookName =
        match.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim();
    final chapter = int.parse(match.group(2)!);
    final verse =
        match.group(3) != null ? int.parse(match.group(3)!) : null;
    final endVerse =
        match.group(4) != null ? int.parse(match.group(4)!) : null;
    final endChapter =
        match.group(5) != null ? int.parse(match.group(5)!) : null;

    final bookId = fullNameToBookIdMap[bookName];
    if (bookId == null) {
      return null;
    }

    final maxChapters = bookIdToChapterCountMap[bookId] ?? 150;
    if (chapter < 1 || chapter > maxChapters) {
      return null;
    }

    if (endChapter != null &&
        (endChapter < chapter || endChapter > maxChapters)) {
      return null;
    }

    if (verse != null && endVerse != null && endVerse < verse) {
      return null;
    }

    return Reference(
      bookId: bookId,
      chapter: chapter,
      verse: verse,
      endVerse: endVerse,
      endChapter: endChapter,
    );
  }

  @override
  String toString() {
    final bookName =
        (bookId == 19 && endChapter != null && endChapter != chapter)
            ? 'Psalms'
            : bookIdToFullNameMap[bookId];
    if (verse == null) {
      if (endChapter != null && endChapter != chapter) {
        return '$bookName $chapter–$endChapter';
      }
      return '$bookName $chapter';
    }
    if (endVerse != null && endVerse != verse) {
      return '$bookName $chapter:$verse–$endVerse';
    }
    return '$bookName $chapter:$verse';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reference &&
          runtimeType == other.runtimeType &&
          bookId == other.bookId &&
          chapter == other.chapter &&
          verse == other.verse &&
          endVerse == other.endVerse &&
          endChapter == other.endChapter;

  @override
  int get hashCode =>
      Object.hash(bookId, chapter, verse, endVerse, endChapter);
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
