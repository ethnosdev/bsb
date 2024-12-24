import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class TextManager {
  final _dbHelper = getIt<DatabaseHelper>();
  final textNotifier = ValueNotifier<TextSpan>(const TextSpan());

  Future<void> getText(int bookId, int chapter) async {
    final content = await _dbHelper.getChapter(bookId, chapter);
    final text = _formatVerses(content);
    textNotifier.value = text;
  }

  TextSpan _formatVerses(List<Map<String, Object?>> content) {
    final spans = TextSpan(children: []);
    for (final row in content) {
      final type = TextType.fromInt(row['type'] as int);
      final text = row['text'] as String;

      switch (type) {
        case TextType.v:
          spans.children?.add(TextSpan(text: text));
          spans.children?.add(const TextSpan(text: ' '));

        case TextType.d:
          _addNewLineIfNeeded(spans);
          spans.children?.add(TextSpan(
            text: text,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ));
          _addNewLineIfNeeded(spans);

        case TextType.r:
          _addNewLineIfNeeded(spans);
          spans.children?.add(TextSpan(
            text: text,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ));
          _addNewLineIfNeeded(spans);

        case TextType.s1:
          _addNewLineIfNeeded(spans);
          spans.children?.add(TextSpan(
            text: text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ));
          _addNewLineIfNeeded(spans);

        case TextType.s2:
          _addNewLineIfNeeded(spans);
          spans.children?.add(TextSpan(
            text: text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ));
          _addNewLineIfNeeded(spans);

        case TextType.ms:
          _addNewLineIfNeeded(spans);
          spans.children?.add(TextSpan(
            text: text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ));
          _addNewLineIfNeeded(spans);

        case TextType.mr:
          _addNewLineIfNeeded(spans);
          spans.children?.add(TextSpan(
            text: text,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ));
          _addNewLineIfNeeded(spans);

        case TextType.qa:
          _addNewLineIfNeeded(spans);
          spans.children?.add(TextSpan(
            text: text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ));
          _addNewLineIfNeeded(spans);
      }
    }
    return spans;
  }

  void _addNewLineIfNeeded(TextSpan text) {
    final spans = text.children;
    if (spans == null) return;
    if (spans.isEmpty) return;
    if (spans.last.toPlainText().endsWith('\n')) return;
    text.children?.add(const TextSpan(text: '\n'));
  }

  String formatTitle(int bookId, int chapter) {
    final book = bookIdToFullNameMap[bookId]!;
    return '$book $chapter';
  }
}
