import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/extrabiblical_texts.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/source_texts.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

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

  RegExp footnoteKeywords() {
    const verseRange = '\\d+:\\d+(?:–\\d+)?';
    final patterns = [
      ...validBookNames.map((kw) => '$kw $verseRange'),
      ...sourceTexts.keys.map((kw) => '\\b$kw\\b'),
      ...validExtraBiblicalTexts.keys,
    ].join('|');
    return RegExp('($patterns)');
  }

  // Returns the title and text body for a given tapped keyword.
  // If a cross reference, then show the source text.
  // If a source text abbreviation, then show the full name.
  // If extrabiblical text, then show the source text.
  Future<List<UsfmLine>?> lookupFootnoteDetails(String keyword) async {
    final reference = Reference.tryParse(keyword);
    if (reference != null) {
      return await _dbHelper.getRange(reference);
    }

    if (sourceTexts.containsKey(keyword)) {
      final source = sourceTexts[keyword]!;
      final withNewLine = source.replaceAll('; ', '\n');
      return [
        UsfmLine(
            bookChapterVerse: 0, text: withNewLine, format: ParagraphFormat.m)
      ];
    }

    return _extrabiblicalContent(keyword);
  }

  List<UsfmLine>? _extrabiblicalContent(String keyword) {
    String? content;
    switch (keyword) {
      case 'Jasher 79:27':
        content = jasher7927;
      case 'Jasher 88:63':
        content = jasher8863;
      case 'Jasher 88:64':
        content = jasher8864;
      case '1 Esdras 8:32':
        content = esdras832;
      case '1 Esdras 8:36':
        content = esdras836;
      case '1 Enoch 1:9':
        content = enoch1;
      case '1 Enoch 13:1–11':
        content = enoch13;
      case '1 Enoch 20:1–4':
        content = enoch20;
      default:
        content = null;
    }
    if (content == null) return null;
    return [
      UsfmLine(bookChapterVerse: 0, text: content, format: ParagraphFormat.m)
    ];
  }
}
