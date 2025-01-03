import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/verse_line.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';

class TextManager {
  final _dbHelper = getIt<DatabaseHelper>();
  final paragraphNotifier = ValueNotifier<List<(InlineSpan, TextType, Format?)>>([]);
  static const msTitleSize = 20.0;
  static const mrTitleSize = 16.0;
  static const verseNumberSize = 10.0;
  static const normalTextSize = 14.0;
  static const multiplier = 1.5;

  Future<void> getText(int bookId, int chapter) async {
    final content = await _dbHelper.getChapter(bookId, chapter);
    _formatVerses(content);
  }

  void _formatVerses(List<VerseLine> content) {
    final paragraphs = <(InlineSpan, TextType, Format?)>[];
    var verseSpans = <InlineSpan>[];
    int oldVerseNumber = 0;
    Format oldFormat = Format.m;

    for (final row in content) {
      final type = row.type;
      final format = row.format;
      final text = row.text;
      final verseNumber = row.verse;

      if (type != TextType.v && verseSpans.isNotEmpty) {
        paragraphs.add((TextSpan(children: verseSpans), TextType.v, oldFormat));
        verseSpans = [];
      }

      switch (type) {
        case TextType.v:
          if (text == '\n') {
            paragraphs.add((TextSpan(children: verseSpans), type, oldFormat));
            verseSpans = [];
            break;
          }
          // add verse number
          if (oldVerseNumber != verseNumber) {
            oldVerseNumber = verseNumber;
            verseSpans.add(
              WidgetSpan(
                child: Transform.translate(
                  offset: const Offset(0, -1 * normalTextSize * multiplier / 3),
                  child: Text(
                    '$verseNumber ',
                    style: const TextStyle(
                      fontSize: verseNumberSize * multiplier,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }
          // add verse line text
          if (format == Format.qr) {
            verseSpans.add(TextSpan(
              text: text,
              style: const TextStyle(
                fontSize: normalTextSize * multiplier,
                fontStyle: FontStyle.italic,
              ),
            ));
          } else {
            verseSpans.add(TextSpan(
              text: '$text ',
              style: const TextStyle(
                fontSize: normalTextSize * multiplier,
              ),
            ));
          }

          // handle poetry
          if (format == Format.q1 || format == Format.q2 || format == Format.qr) {
            paragraphs.add((TextSpan(children: verseSpans), type, format));
            verseSpans = [];
          }
          oldFormat = format ?? Format.m;

        case TextType.d:
          paragraphs.add((
            TextSpan(
              text: text,
              style: const TextStyle(
                fontSize: normalTextSize * multiplier,
                fontStyle: FontStyle.italic,
              ),
            ),
            type,
            format,
          ));

        case TextType.r:
          paragraphs.add((
            TextSpan(
              text: text,
              style: const TextStyle(
                fontSize: normalTextSize * multiplier,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            type,
            format,
          ));

        case TextType.s1:
          paragraphs.add((
            TextSpan(
              text: text,
              style: const TextStyle(
                fontSize: normalTextSize * multiplier,
                fontWeight: FontWeight.bold,
              ),
            ),
            type,
            format,
          ));

        case TextType.s2:
          paragraphs.add((
            TextSpan(
              text: text,
              style: const TextStyle(
                fontSize: normalTextSize * multiplier,
                fontStyle: FontStyle.italic,
              ),
            ),
            type,
            format,
          ));

        case TextType.ms:
          paragraphs.add((
            TextSpan(
              text: text,
              style: const TextStyle(
                fontSize: msTitleSize * multiplier,
                fontWeight: FontWeight.bold,
              ),
            ),
            type,
            format,
          ));

        case TextType.mr:
          paragraphs.add((
            TextSpan(
              text: text,
              style: const TextStyle(
                fontSize: mrTitleSize * multiplier,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            type,
            format,
          ));

        case TextType.qa:
          paragraphs.add((
            TextSpan(
              text: text,
              style: const TextStyle(
                fontSize: 14 * multiplier,
                fontWeight: FontWeight.bold,
              ),
            ),
            type,
            format,
          ));
      }
    }

    if (verseSpans.isNotEmpty) {
      paragraphs.add((TextSpan(children: verseSpans), TextType.v, oldFormat));
    }

    paragraphNotifier.value = paragraphs;
  }

  String formatTitle(int bookId, int chapter) {
    final book = bookIdToFullNameMap[bookId]!;
    return '$book $chapter';
  }

  (int bookId, int chapter) getNextChapter(int bookId, int chapter) {
    final maxChapters = bookIdToChapterCountMap[bookId]!;

    if (chapter < maxChapters) {
      return (bookId, chapter + 1);
    }

    final nextBookId = bookId + 1;
    if (bookIdToChapterCountMap.containsKey(nextBookId)) {
      return (nextBookId, 1);
    }

    return (1, 1);
  }
}

final Map<int, int> bookIdToChapterCountMap = {
  1: 50, // Genesis
  2: 40, // Exodus
  3: 27, // Leviticus
  4: 36, // Numbers
  5: 34, // Deuteronomy
  6: 24, // Joshua
  7: 21, // Judges
  8: 4, // Ruth
  9: 31, // 1 Samuel
  10: 24, // 2 Samuel
  11: 22, // 1 Kings
  12: 25, // 2 Kings
  13: 29, // 1 Chronicles
  14: 36, // 2 Chronicles
  15: 10, // Ezra
  16: 13, // Nehemiah
  17: 10, // Esther
  18: 42, // Job
  19: 150, // Psalms
  20: 31, // Proverbs
  21: 12, // Ecclesiastes
  22: 8, // Song of Solomon
  23: 66, // Isaiah
  24: 52, // Jeremiah
  25: 5, // Lamentations
  26: 48, // Ezekiel
  27: 12, // Daniel
  28: 14, // Hosea
  29: 3, // Joel
  30: 9, // Amos
  31: 1, // Obadiah
  32: 4, // Jonah
  33: 7, // Micah
  34: 3, // Nahum
  35: 3, // Habakkuk
  36: 3, // Zephaniah
  37: 2, // Haggai
  38: 14, // Zechariah
  39: 4, // Malachi
  40: 28, // Matthew
  41: 16, // Mark
  42: 24, // Luke
  43: 21, // John
  44: 28, // Acts
  45: 16, // Romans
  46: 16, // 1 Corinthians
  47: 13, // 2 Corinthians
  48: 6, // Galatians
  49: 6, // Ephesians
  50: 4, // Philippians
  51: 4, // Colossians
  52: 5, // 1 Thessalonians
  53: 3, // 2 Thessalonians
  54: 6, // 1 Timothy
  55: 4, // 2 Timothy
  56: 3, // Titus
  57: 1, // Philemon
  58: 13, // Hebrews
  59: 5, // James
  60: 5, // 1 Peter
  61: 3, // 2 Peter
  62: 5, // 1 John
  63: 1, // 2 John
  64: 1, // 3 John
  65: 1, // Jude
  66: 22, // Revelation
};
