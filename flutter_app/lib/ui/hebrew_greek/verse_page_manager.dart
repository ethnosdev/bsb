import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';

/// Manages the state of a single verse page: dual passage tokens,
/// selected word, lexicon entry, and occurrence counts.
class VersePageManager extends ChangeNotifier {
  final _dbHelper = getIt<DatabaseHelper>();
  final Language language;

  VersePageManager(this.language);

  List<OriginalWord> originalWords = [];
  List<OriginalWord> englishWords = [];
  OriginalWord? selectedWord;
  String? lexiconContent;
  int exactCount = 0;
  int strongsCount = 0;
  bool isLoading = true;
  bool isLoadingLexicon = false;

  TextDirection get originalTextDirection =>
      language.isLTR ? TextDirection.ltr : TextDirection.rtl;

  Future<void> requestVerseContent({
    required int bookId,
    required int chapter,
    required int verse,
  }) async {
    isLoading = true;
    notifyListeners();

    final reference = Reference(bookId: bookId, chapter: chapter, verse: verse);
    final data = await _dbHelper.getOriginalLanguageData(reference);

    originalWords = data.whereType<OriginalWord>().toList();
    englishWords = originalWords
        .where((w) => !w.isUntranslated)
        .toList()
      ..sort((a, b) => a.bsbSort.compareTo(b.bsbSort));

    isLoading = false;

    if (selectedWord == null && originalWords.isNotEmpty) {
      // Pick the first word that has an English gloss or first word
      final initialWord = originalWords.firstWhere(
        (w) => !w.isUntranslated,
        orElse: () => originalWords.first,
      );
      await selectWord(initialWord);
    } else {
      notifyListeners();
    }
  }

  Future<void> selectWord(OriginalWord word) async {
    selectedWord = word;
    isLoadingLexicon = true;
    notifyListeners();

    final contentFuture = _dbHelper.getLexiconContent(
      language,
      word.strongsNumber,
    );
    final exactFuture = _dbHelper.getExactWordCount(word.originalId);
    final strongsFuture = _dbHelper.getStrongNumberCount(
      language,
      word.strongsNumber,
    );

    final results = await Future.wait([
      contentFuture,
      exactFuture,
      strongsFuture,
    ]);

    lexiconContent = results[0] as String?;
    exactCount = results[1] as int;
    strongsCount = results[2] as int;
    isLoadingLexicon = false;

    notifyListeners();
  }
}
