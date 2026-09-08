import 'package:database_builder/database_builder.dart';

/// A verse element is either a word or punctuation.
sealed class VerseElement {}

class OriginalWord extends VerseElement {
  OriginalWord({
    this.id = 0,
    this.originalId = 0,
    required this.language,
    required this.word,
    required this.transliteration,
    required this.englishGloss,
    required this.strongsNumber,
    required this.partOfSpeech,
    this.punctuation,
    this.bsbSort = 0,
  });

  final int id;
  final int originalId;
  final Language language;
  final String word;
  final String transliteration;
  final String englishGloss;
  final int strongsNumber;
  final String partOfSpeech;
  final String? punctuation;
  final int bsbSort;

  bool get isUntranslated => englishGloss == '-' || englishGloss.trim().isEmpty;
}

class Punctuation extends VerseElement {
  Punctuation({required this.punctuation});
  final String punctuation;
}
