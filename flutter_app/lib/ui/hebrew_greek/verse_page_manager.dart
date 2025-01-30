import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class VersePageManager extends ChangeNotifier {
  final _dbHelper = getIt<DatabaseHelper>();
  var interlinearText = const TextSpan();
  OriginalWord? originalWord;

  Future<void> requestVerseContent({
    required int bookId,
    required int chapter,
    required int verse,
    required Color textColor,
    required Color highlightColor,
  }) async {
    final data = await _dbHelper.getOriginalLanguageData(bookId, chapter, verse);
    final textSize = getIt<UserSettings>().textSize;
    interlinearText = formatVerse(
      data,
      textSize,
      textColor,
      highlightColor,
      _onWordTap,
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
  ) {
    final spans = <TextSpan>[];
    for (final element in data) {
      if (element is OriginalWord) {
        final fontFamily = (element.language == Language.greek) ? 'Galatia' : 'Ezra';
        spans.add(
          TextSpan(
            text: element.word,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: textSize,
              color: highlightColor,
            ),
            recognizer: TapGestureRecognizer() //
              ..onTap = () => onWordTap(element),
          ),
        );
        spans.add(
          TextSpan(
            text: ' (${element.englishGloss}) ',
            style: TextStyle(
              fontSize: textSize,
              color: textColor,
            ),
          ),
        );
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
