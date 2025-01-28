import 'dart:ui';

import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class VersePageManager extends ChangeNotifier {
  // final interlinearNotifier = ValueNotifier<String>('');
  final _dbHelper = getIt<DatabaseHelper>();

  Future<void> requestVerseContent({
    required int bookId,
    required int chapter,
    required int verse,
    required Color textColor,
  }) async {
    // SchedulerBinding.instance.addPostFrameCallback((_) {
    //   titleNotifier.value = _formatTitle(bookId, chapter, verse);
    // });

    // final targetNotifier = notifier(verse - 1);

    // Check if content is already in the target notifier
    // if (_isContentAlreadyLoaded(targetNotifier, verse)) {
    //   return;
    // }

    // Perform database lookup only if not cached
    final data = await _dbHelper.getOriginalLanguageData(bookId, chapter, verse);

    // Format content
    final textSize = getIt<UserSettings>().textSize;

    print('OriginalLanguageData: $data');

    // final formattedContent = formatVerse(
    //   data,
    //   textSize,
    //   textColor,
    //   onWordTap,
    // );

    // Update cache
    // final key = '${bookId}_$chapter';
    // _pageCache[verse] = formattedContent;
    // _trackUsage(key);

    // // Update notifier
    // targetNotifier.value = formattedContent;
  }

  // @override
  // void dispose() {
  //   interlinearNotifier.dispose();
  //   super.dispose();
  // }
}
