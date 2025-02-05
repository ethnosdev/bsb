import 'package:database_builder/database_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// This class manages the whole screen while TextPageManager only
/// handles one PageView page.
class TextScreenManager {
  static const _chaptersInBible = 1189;
  static const maxPageIndex = _chaptersInBible - 1;

  final titleNotifier = ValueNotifier<String>('');

  void updateTitle({
    required int? index,
  }) {
    if (index == null) return;
    final (bookId, chapter) = bookAndChapterForPageIndex(index);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      titleNotifier.value = formatTitle(bookId, chapter);
    });
  }

  (int bookId, int chapter) currentBookAndChapterCount(int index) {
    final (bookId, _) = bookAndChapterForPageIndex(index);
    final chapterCount = bookIdToChapterCountMap[bookId]!;
    return (bookId, chapterCount);
  }

  (int bookId, int chapter) bookAndChapterForPageIndex(
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

  String formatTitle(int bookId, int chapter, [int? verse]) {
    final book = bookIdToFullNameMap[bookId]!;
    return verse != null ? '$book $chapter:$verse' : '$book $chapter';
  }

  int pageIndexForBookAndChapter({
    required int bookId,
    required int chapter,
  }) {
    return bookIdToChapterIndexMap[bookId]! + chapter - 1;
  }

  Language verseLanguageLabel(int pageIndex, int verseNumber) {
    final (bookId, chapter) = bookAndChapterForPageIndex(pageIndex);
    final language = languageForVerse(
      bookId: bookId,
      chapter: chapter,
      verse: verseNumber,
    );
    return language;
  }
}
