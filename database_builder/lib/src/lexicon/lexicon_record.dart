class LexiconRecord {
  final int language; // 0: Hebrew, 1: Aramaic, 2: Greek
  final int strongs;
  final String lemma;
  final String content;

  const LexiconRecord({
    required this.language,
    required this.strongs,
    required this.lemma,
    required this.content,
  });
}
