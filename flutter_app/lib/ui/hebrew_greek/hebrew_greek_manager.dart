import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class HebrewGreekManager {
  final _dbHelper = getIt<DatabaseHelper>();
  final titleNotifier = ValueNotifier('');
  final verseCountNotifier = ValueNotifier<int?>(null);
  final showEnglishNotifier = ValueNotifier(false);

  Future<void> init(int bookId, int chapter, int verse) async {
    verseCountNotifier.value = await _dbHelper.getVerseCount(bookId, chapter);
    updateTitle(bookId: bookId, chapter: chapter, verse: verse);
  }

  bool get showInterlinearEnglish => getIt<UserSettings>().showInterlinearEnglish;

  void toggleShowInterlinearEnglish() {
    final settings = getIt<UserSettings>();
    final show = settings.showInterlinearEnglish;
    settings.setShowInterlinearEnglish(!show);
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
