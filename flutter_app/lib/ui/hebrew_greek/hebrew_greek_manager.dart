import 'dart:ui';

import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class HebrewGreekManager {
  final _dbHelper = getIt<DatabaseHelper>();
  // final _pageCache = <int, OriginalLanguageData>{};
  final titleNotifier = ValueNotifier<String>('');
  final verseCountNotifier = ValueNotifier<int?>(null);
  static const _maxCacheSize = 3;

  // List<ValueNotifier<OriginalLanguageData?>> _notifiers = [];
  // ValueNotifier<OriginalLanguageData?> notifier(int index) {
  //   if (_notifiers.isEmpty) {
  //     _notifiers = List.generate(
  //       _maxCacheSize,
  //       (_) => ValueNotifier<OriginalLanguageData?>(null),
  //     );
  //   }
  //   final loopedIndex = index % _maxCacheSize;
  //   return _notifiers[loopedIndex];
  // }

  Future<void> init(int bookId, int chapter) async {
    verseCountNotifier.value = await _dbHelper.getVerseCount(bookId, chapter);
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

  // bool _isContentAlreadyLoaded(
  //   ValueNotifier<OriginalLanguageData?> targetNotifier,
  //   int verse,
  // ) {
  //   if (targetNotifier.value == null) return false;

  //   final cachedContent = _pageCache[verse];
  //   if (cachedContent == null) return false;

  //   return targetNotifier.value == cachedContent;
  // }
}
