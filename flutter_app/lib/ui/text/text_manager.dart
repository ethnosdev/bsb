import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'format_verses.dart';

typedef TextParagraph = List<(TextSpan, TextType, Format?)>;

class TextManager {
  final _dbHelper = getIt<DatabaseHelper>();
  final _chapterCache = <String, List<(TextSpan, TextType, Format?)>>{};
  static const _maxCacheSize = 3;
  final _recentlyUsed = <String>[];

  static const _chaptersInBible = 1189;
  static const maxPageIndex = _chaptersInBible - 1;

  double _normalTextSize = 14.0;
  double get paragraphSpacing => _normalTextSize * 0.6;

  final titleNotifier = ValueNotifier<String>('');

  List<ValueNotifier<TextParagraph>> _notifiers = [];

  ValueNotifier<TextParagraph> notifier(int index) {
    if (_notifiers.isEmpty) {
      _notifiers = List.generate(
        _maxCacheSize,
        (_) => ValueNotifier<TextParagraph>([]),
      );
    }
    final loopedIndex = index % _maxCacheSize;
    return _notifiers[loopedIndex];
  }

  void updateTitle({
    required int? index,
  }) {
    if (index == null) return;
    final (bookId, chapter) = _currentBookAndChapter(index);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      titleNotifier.value = _formatTitle(bookId, chapter);
    });
  }

  Future<void> requestText({
    required int index,
    required Color textColor,
    required Color footnoteColor,
    required void Function(int) onVerseLongPress,
    required void Function(String) onFootnoteTap,
  }) async {
    final (bookId, chapter) = _currentBookAndChapter(index);

    // Update book and chapter title
    SchedulerBinding.instance.addPostFrameCallback((_) {
      titleNotifier.value = _formatTitle(bookId, chapter);
    });

    final key = '${bookId}_$chapter';
    final targetNotifier = notifier(index);

    // Check if content is already in the target notifier
    if (_isContentAlreadyLoaded(targetNotifier, bookId, chapter)) {
      return;
    }

    // Perform database lookup only if not cached
    final content = await _dbHelper.getChapter(bookId, chapter);

    // Format content
    _normalTextSize = getIt<UserSettings>().textSize;

    final formattedContent = formatVerses(
      content,
      _normalTextSize,
      textColor,
      footnoteColor,
      onVerseLongPress,
      onFootnoteTap,
    );

    // Update cache
    _chapterCache[key] = formattedContent;
    _trackUsage(key);

    // Update notifier
    targetNotifier.value = formattedContent;
  }

  (int bookId, int chapter) currentBookAndChapterCount(int index) {
    final (bookId, _) = _currentBookAndChapter(index);
    final chapterCount = bookIdToChapterCountMap[bookId]!;
    return (bookId, chapterCount);
  }

  (int bookId, int chapter) _currentBookAndChapter(
    int index,
  ) {
    int pageIndex = index % (maxPageIndex + 1);

    int currentBookId = 1;
    int currentChapter = 1;
    int remainingIndex = pageIndex;

    // Find the book based on index
    for (final entry in bookIdToChapterCountMap.entries) {
      if (remainingIndex < entry.value) {
        currentBookId = entry.key;
        currentChapter = remainingIndex + 1;
        break;
      }
      remainingIndex -= entry.value;
    }

    return (currentBookId, currentChapter);
  }

  bool _isContentAlreadyLoaded(
    ValueNotifier<TextParagraph> targetNotifier,
    int bookId,
    int chapter,
  ) {
    if (targetNotifier.value.isEmpty) return false;

    final key = '${bookId}_$chapter';
    final cachedContent = _chapterCache[key];
    if (cachedContent == null) return false;

    return listEquals(targetNotifier.value, cachedContent);
  }

  void _cleanCache() {
    // Remove oldest entries when cache exceeds size
    while (_chapterCache.length > _maxCacheSize) {
      final oldest = _recentlyUsed.removeAt(0);
      _chapterCache.remove(oldest);
    }
  }

  void _trackUsage(String key) {
    _recentlyUsed.remove(key);
    _recentlyUsed.add(key);
    _cleanCache();
  }

  String _formatTitle(int bookId, int chapter) {
    final book = bookIdToFullNameMap[bookId]!;
    return '$book $chapter';
  }

  int pageIndexForBookAndChapter({
    required int bookId,
    required int chapter,
  }) {
    return bookIdToIndexMap[bookId]! + chapter - 1;
  }
}

final bookIdToIndexMap = {
  1: 0, // Genesis
  2: 50, // Exodus
  3: 90, // Leviticus
  4: 117, // Numbers
  5: 153, // Deuteronomy
  6: 187, // Joshua
  7: 211, // Judges
  8: 232, // Ruth
  9: 236, // 1 Samuel
  10: 267, // 2 Samuel
  11: 291, // 1 Kings
  12: 313, // 2 Kings
  13: 338, // 1 Chronicles
  14: 367, // 2 Chronicles
  15: 403, // Ezra
  16: 413, // Nehemiah
  17: 426, // Esther
  18: 436, // Job
  19: 478, // Psalms
  20: 628, // Proverbs
  21: 659, // Ecclesiastes
  22: 671, // Song of Solomon
  23: 679, // Isaiah
  24: 745, // Jeremiah
  25: 797, // Lamentations
  26: 802, // Ezekiel
  27: 850, // Daniel
  28: 862, // Hosea
  29: 876, // Joel
  30: 879, // Amos
  31: 888, // Obadiah
  32: 889, // Jonah
  33: 893, // Micah
  34: 900, // Nahum
  35: 903, // Habakkuk
  36: 906, // Zephaniah
  37: 909, // Haggai
  38: 911, // Zechariah
  39: 925, // Malachi
  40: 929, // Matthew
  41: 957, // Mark
  42: 973, // Luke
  43: 997, // John
  44: 1018, // Acts
  45: 1046, // Romans
  46: 1062, // 1 Corinthians
  47: 1078, // 2 Corinthians
  48: 1091, // Galatians
  49: 1097, // Ephesians
  50: 1103, // Philippians
  51: 1107, // Colossians
  52: 1111, // 1 Thessalonians
  53: 1116, // 2 Thessalonians
  54: 1119, // 1 Timothy
  55: 1125, // 2 Timothy
  56: 1129, // Titus
  57: 1132, // Philemon
  58: 1133, // Hebrews
  59: 1146, // James
  60: 1151, // 1 Peter
  61: 1156, // 2 Peter
  62: 1159, // 1 John
  63: 1164, // 2 John
  64: 1165, // 3 John
  65: 1166, // Jude
  66: 1167, // Revelation
};

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
