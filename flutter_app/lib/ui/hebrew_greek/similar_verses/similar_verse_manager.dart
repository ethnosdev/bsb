import 'package:bsb/core/font_family.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

enum WordSearchMode {
  exactForm,
  strongs,
}

class SimilarVerseManager {
  final _dbHelper = getIt<DatabaseHelper>();
  final similarVersesNotifier = ValueNotifier<List<Reference>>([]);
  final searchModeNotifier =
      ValueNotifier<WordSearchMode>(WordSearchMode.strongs);
  final isLoadingNotifier = ValueNotifier<bool>(true);

  late OriginalWord word;
  int exactCount = 0;
  int strongsCount = 0;

  Future<void> init(
    OriginalWord word, {
    WordSearchMode initialMode = WordSearchMode.strongs,
  }) async {
    this.word = word;
    searchModeNotifier.value = initialMode;
    isLoadingNotifier.value = true;

    final exactFuture = _dbHelper.getExactWordCount(word.originalId);
    final strongsFuture = _dbHelper.getStrongNumberCount(
      word.language,
      word.strongsNumber,
    );

    final counts = await Future.wait([exactFuture, strongsFuture]);
    exactCount = counts[0];
    strongsCount = counts[1];

    await _loadVersesForMode(initialMode);
  }

  Future<void> switchMode(WordSearchMode mode) async {
    if (searchModeNotifier.value == mode && !isLoadingNotifier.value) return;
    searchModeNotifier.value = mode;
    await _loadVersesForMode(mode);
  }

  Future<void> _loadVersesForMode(WordSearchMode mode) async {
    isLoadingNotifier.value = true;
    final List<Reference> verses;
    if (mode == WordSearchMode.exactForm) {
      verses = await _dbHelper.getVersesWithExactWord(word.originalId);
    } else {
      verses = await _dbHelper.getVersesWithStrongNumber(
        word.language,
        word.strongsNumber,
      );
    }
    similarVersesNotifier.value = verses;
    isLoadingNotifier.value = false;
  }

  String formatReference(Reference reference) {
    final book = bookIdToFullNameMap[reference.bookId]!;
    return '$book ${reference.chapter}:${reference.verse}';
  }

  /// Returns the verse text with the matched words highlighted.
  Future<TextSpan> getVerseContent(
    Reference reference,
    Color highlightColor,
  ) async {
    final data = await _dbHelper.getOriginalLanguageData(reference);
    return _formatVerse(data, highlightColor);
  }

  TextSpan _formatVerse(
    List<VerseElement> data,
    Color highlightColor,
  ) {
    final spans = <TextSpan>[];
    final isExact = searchModeNotifier.value == WordSearchMode.exactForm;

    for (final element in data) {
      if (element is OriginalWord) {
        final fontFamily = fontFamilyForLanguage(element.language);
        final bool isMatch = isExact
            ? (element.originalId == word.originalId)
            : (element.strongsNumber == word.strongsNumber &&
                word.strongsNumber > 0);

        final color = isMatch ? highlightColor : null;
        final bold = isMatch ? FontWeight.bold : null;

        spans.add(
          TextSpan(
            text: '${element.word} ',
            style: TextStyle(
              fontFamily: fontFamily,
              color: color,
              fontWeight: bold,
            ),
          ),
        );
      } else if (element is Punctuation) {
        spans.add(
          TextSpan(
            text: element.punctuation,
          ),
        );
      }
    }
    return TextSpan(children: spans);
  }
}
