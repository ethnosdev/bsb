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

class VerseDisplayContent {
  final TextSpan english;
  final TextSpan original;

  const VerseDisplayContent({
    required this.english,
    required this.original,
  });
}

class SimilarVerseManager {
  SimilarVerseManager({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? getIt<DatabaseHelper>();

  final DatabaseHelper _dbHelper;
  final similarVersesNotifier = ValueNotifier<List<Reference>>([]);
  final searchModeNotifier =
      ValueNotifier<WordSearchMode>(WordSearchMode.strongs);
  final isLoadingNotifier = ValueNotifier<bool>(true);
  final countsNotifier =
      ValueNotifier<({int exact, int strongs})>((exact: 0, strongs: 0));

  late OriginalWord word;
  int exactCount = 0;
  int strongsCount = 0;

  Future<void> init(
    OriginalWord word, {
    WordSearchMode initialMode = WordSearchMode.strongs,
    int? initialExactCount,
    int? initialStrongsCount,
  }) async {
    this.word = word;
    searchModeNotifier.value = initialMode;
    if (initialExactCount != null) {
      exactCount = initialExactCount;
    }
    if (initialStrongsCount != null) {
      strongsCount = initialStrongsCount;
    }
    countsNotifier.value = (exact: exactCount, strongs: strongsCount);
    isLoadingNotifier.value = true;

    final exactFuture = _dbHelper.getExactWordCount(word.originalId);
    final strongsFuture = _dbHelper.getStrongNumberCount(
      word.language,
      word.strongsNumber,
    );

    final counts = await Future.wait([exactFuture, strongsFuture]);
    exactCount = counts[0];
    strongsCount = counts[1];
    countsNotifier.value = (exact: exactCount, strongs: strongsCount);

    await _loadVersesForMode(initialMode);
  }

  void dispose() {
    similarVersesNotifier.dispose();
    searchModeNotifier.dispose();
    isLoadingNotifier.dispose();
    countsNotifier.dispose();
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

  /// Returns the verse text in English and original language with the matched words highlighted.
  Future<VerseDisplayContent> getVerseContent(
    Reference reference,
    Color highlightColor,
  ) async {
    final data = await _dbHelper.getOriginalLanguageData(reference);
    return VerseDisplayContent(
      english: _formatEnglish(data, highlightColor),
      original: _formatOriginal(data, highlightColor),
    );
  }

  TextSpan _formatEnglish(
    List<VerseElement> data,
    Color highlightColor,
  ) {
    final spans = <TextSpan>[];
    final isExact = searchModeNotifier.value == WordSearchMode.exactForm;
    final englishWords = data
        .whereType<OriginalWord>()
        .where((w) => !w.isUntranslated)
        .toList()
      ..sort((a, b) => a.bsbSort.compareTo(b.bsbSort));

    for (int i = 0; i < englishWords.length; i++) {
      final element = englishWords[i];
      final bool isMatch = isExact
          ? (element.originalId == word.originalId)
          : (element.strongsNumber == word.strongsNumber &&
              word.strongsNumber > 0);

      final color = isMatch ? highlightColor : null;
      final bold = isMatch ? FontWeight.bold : null;
      final punct = element.punctuation ?? '';
      final hasTrailingSpace =
          punct.endsWith(' ') || (i == englishWords.length - 1);
      final trailingSpace = hasTrailingSpace ? '' : ' ';

      spans.add(
        TextSpan(
          text: '${element.englishGloss}$punct$trailingSpace',
          style: TextStyle(
            color: color,
            fontWeight: bold,
          ),
        ),
      );
    }
    return TextSpan(children: spans);
  }

  TextSpan _formatOriginal(
    List<VerseElement> data,
    Color highlightColor,
  ) {
    final spans = <TextSpan>[];
    final isExact = searchModeNotifier.value == WordSearchMode.exactForm;

    for (int i = 0; i < data.length; i++) {
      final element = data[i];
      if (element is OriginalWord) {
        final fontFamily = fontFamilyForLanguage(element.language);
        final bool isMatch = isExact
            ? (element.originalId == word.originalId)
            : (element.strongsNumber == word.strongsNumber &&
                word.strongsNumber > 0);

        final color = isMatch ? highlightColor : null;
        final bold = isMatch ? FontWeight.bold : null;
        final trailingSpace = (i < data.length - 1) ? ' ' : '';

        spans.add(
          TextSpan(
            text: '${element.word}$trailingSpace',
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
