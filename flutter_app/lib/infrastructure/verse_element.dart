import 'package:database_builder/database_builder.dart';

/// A verse element is either a word or punctuation.
sealed class VerseElement {}

class OriginalWord extends VerseElement {
  OriginalWord({
    required this.language,
    required this.word,
    required this.englishGloss,
    required this.strongsNumber,
    required this.partOfSpeech,
  });

  final Language language;
  final String word;
  final String englishGloss;
  final int strongsNumber;
  final String partOfSpeech;
}

class Punctuation extends VerseElement {
  Punctuation({required this.punctuation});
  final String punctuation;
}
