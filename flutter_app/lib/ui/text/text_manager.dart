import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:flutter/foundation.dart';

class TextManager {
  final _dbHelper = getIt<DatabaseHelper>();
  final textNotifier = ValueNotifier<String>('');

  Future<void> getText(int bookId, int chapter) async {
    final text = await _dbHelper.getChapter(bookId, chapter);
    textNotifier.value = text;
  }
}
