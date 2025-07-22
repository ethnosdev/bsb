import 'package:bsb/core/font_family.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class SimilarVerseManager {
  final _dbHelper = getIt<DatabaseHelper>();
  final similarVersesNotifier = ValueNotifier<List<Reference>>([]);

  Future<void> init(OriginalWord word) async {
    final verses = await _dbHelper.getVersesWithStrongNumber(
      word.language,
      word.strongsNumber,
    );
    similarVersesNotifier.value = verses;
  }

  String formatReference(Reference reference) {
    final book = bookIdToFullNameMap[reference.bookId]!;
    return '$book ${reference.chapter}:${reference.verse}';
  }

  /// Returns the the verse text with the words highlighted based on
  /// the Strong's number.
  Future<TextSpan> getVerseContent(
    Reference reference,
    int strongsNumber,
    Color highlightColor,
    bool showEnglish,
  ) async {
    final data = await _dbHelper.getOriginalLanguageData(reference);
    return _formatVerse(
      data,
      strongsNumber,
      highlightColor,
      showEnglish,
    );
  }

  TextSpan _formatVerse(
    List<VerseElement> data,
    int strongsNumber,
    Color highlightColor,
    bool showEnglish,
  ) {
    final spans = <TextSpan>[];
    for (final element in data) {
      if (element is OriginalWord) {
        final fontFamily = fontFamilyForLanguage(element.language);
        final color =
            (element.strongsNumber == strongsNumber) ? highlightColor : null;
        final bold =
            (element.strongsNumber == strongsNumber) ? FontWeight.bold : null;
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
        if (showEnglish) {
          spans.add(
            TextSpan(
              text: '(${element.englishGloss}) ',
              style: TextStyle(
                color: color,
                fontWeight: bold,
              ),
            ),
          );
        }
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
