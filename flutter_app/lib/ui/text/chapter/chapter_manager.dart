import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/verse_line.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ChapterManager {
  final _dbHelper = getIt<DatabaseHelper>();
  final textParagraphNotifier = ValueNotifier<List<UsfmLine>>([]);

  double get textSize => getIt<UserSettings>().textSize;

  Future<void> requestText({
    required int bookId,
    required int chapter,
  }) async {
    textParagraphNotifier.value = await _dbHelper.getChapter(bookId, chapter);
  }

  Future<String> verseTextForClipboard(
    int bookId,
    int chapter,
    int verseNumber,
  ) async {
    final reference = Reference(
      bookId: bookId,
      chapter: chapter,
      verse: verseNumber,
    );
    final verse = await _dbHelper.getRange(reference);
    final verseString = StringBuffer();
    for (final line in verse) {
      if (line.text == '\n') continue;
      verseString.write(line.text);
      verseString.write(' ');
    }
    verseString.write('($reference)');
    return verseString.toString();
  }
}
