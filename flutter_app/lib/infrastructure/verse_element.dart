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
    this.partOfTranslation,
    this.clusterWordIds = const {},
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

  /// If this word is part of a multi-word translation cluster (e.g. 'vvv'),
  /// this holds the English translation of the cluster (e.g. "seed-bearing").
  final String? partOfTranslation;

  /// Token IDs (`id`) of all original words in this cluster.
  final Set<int> clusterWordIds;

  bool get isVvv => englishGloss.trim() == 'vvv';

  bool get isUntranslated {
    final clean = englishGloss.trim();
    return clean.isEmpty ||
        clean == '-' ||
        clean == '. . .' ||
        clean == '...' ||
        clean == '( -';
  }

  /// Whether this original word has its own distinct English chip in the English passage card.
  bool get hasEnglishChip => !isUntranslated && !isVvv;

  OriginalWord copyWith({
    int? id,
    int? originalId,
    Language? language,
    String? word,
    String? transliteration,
    String? englishGloss,
    int? strongsNumber,
    String? partOfSpeech,
    String? punctuation,
    int? bsbSort,
    String? partOfTranslation,
    Set<int>? clusterWordIds,
  }) {
    return OriginalWord(
      id: id ?? this.id,
      originalId: originalId ?? this.originalId,
      language: language ?? this.language,
      word: word ?? this.word,
      transliteration: transliteration ?? this.transliteration,
      englishGloss: englishGloss ?? this.englishGloss,
      strongsNumber: strongsNumber ?? this.strongsNumber,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      punctuation: punctuation ?? this.punctuation,
      bsbSort: bsbSort ?? this.bsbSort,
      partOfTranslation: partOfTranslation ?? this.partOfTranslation,
      clusterWordIds: clusterWordIds ?? this.clusterWordIds,
    );
  }
}

class Punctuation extends VerseElement {
  Punctuation({required this.punctuation});
  final String punctuation;
}
