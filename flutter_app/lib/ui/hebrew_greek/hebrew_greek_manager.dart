import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class HebrewGreekManager {
  final _dbHelper = getIt<DatabaseHelper>();
  final titleNotifier = ValueNotifier<String>('');
  final verseCountNotifier = ValueNotifier<int?>(null);

  Future<void> init(int bookId, int chapter, int verse) async {
    verseCountNotifier.value = await _dbHelper.getVerseCount(bookId, chapter);
    updateTitle(bookId: bookId, chapter: chapter, verse: verse);
  }

  void updateTitle({
    required int bookId,
    required int chapter,
    required int verse,
  }) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      titleNotifier.value = _formatTitle(bookId, chapter, verse);
    });
  }

  String _formatTitle(int bookId, int chapter, int verse) {
    final book = bookIdToFullNameMap[bookId]!;
    return '$book $chapter:$verse';
  }
}
