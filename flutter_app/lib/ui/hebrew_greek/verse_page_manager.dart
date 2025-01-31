import 'package:bsb/core/font_family.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// This class manages a single page of the PageView for swiping between verses.
class VersePageManager extends ChangeNotifier {
  final _dbHelper = getIt<DatabaseHelper>();
  var interlinearText = const TextSpan();
  OriginalWord? originalWord;
  final Language language;

  VersePageManager(this.language);

  TextDirection get textDirection {
    final showEnglish = getIt<UserSettings>().showInterlinearEnglish;
    final isLtr = language.isLTR;
    return (showEnglish || isLtr) ? TextDirection.ltr : TextDirection.rtl;
  }

  Future<void> requestVerseContent({
    required int bookId,
    required int chapter,
    required int verse,
    required Color textColor,
    required Color highlightColor,
    required bool showEnglish,
  }) async {
    final reference = Reference(bookId: bookId, chapter: chapter, verse: verse);
    final data = await _dbHelper.getOriginalLanguageData(reference);
    final textSize = getIt<UserSettings>().textSize;
    interlinearText = formatVerse(
      data,
      textSize,
      textColor,
      highlightColor,
      _onWordTap,
      showEnglish,
    );
    notifyListeners();
  }

  void _onWordTap(OriginalWord word) {
    originalWord = word;
    notifyListeners();
  }

  TextSpan formatVerse(
    List<VerseElement> data,
    double textSize,
    Color textColor,
    Color highlightColor,
    void Function(OriginalWord) onWordTap,
    bool showEnglish,
  ) {
    final spans = <TextSpan>[];
    for (final element in data) {
      if (element is OriginalWord) {
        final fontFamily = fontFamilyForLanguage(element.language);
        spans.add(
          TextSpan(
            text: '${element.word} ',
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: textSize,
              color: highlightColor,
            ),
            recognizer: TapGestureRecognizer() //
              ..onTap = () => onWordTap(element),
          ),
        );
        if (showEnglish) {
          spans.add(
            TextSpan(
              text: '(${element.englishGloss}) ',
              style: TextStyle(
                fontSize: textSize,
                color: textColor,
              ),
            ),
          );
        }
      } else if (element is Punctuation) {
        spans.add(
          TextSpan(
            text: element.punctuation,
            style: TextStyle(
              fontSize: textSize,
              color: textColor,
            ),
          ),
        );
      }
    }
    return TextSpan(children: spans);
  }
}
