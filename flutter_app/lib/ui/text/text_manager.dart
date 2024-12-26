import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class TextManager {
  final _dbHelper = getIt<DatabaseHelper>();
  final textNotifier = ValueNotifier<TextSpan>(const TextSpan());
  static const multiplier = 1.5;

  Future<void> getText(int bookId, int chapter) async {
    final content = await _dbHelper.getChapter(bookId, chapter);
    final text = _formatVerses(content);
    textNotifier.value = text;
  }

  TextSpan _formatVerses(List<Map<String, Object?>> content) {
    final spans = <TextSpan>[];
    for (final row in content) {
      final type = TextType.fromInt(row['type'] as int);
      final text = row['text'] as String;

      switch (type) {
        case TextType.v:
          if (text == '\n') {
            _addNewLine(spans);
          } else {
            spans.add(TextSpan(
              text: text,
              style: const TextStyle(
                fontSize: 14 * multiplier,
              ),
            ));
            spans.add(const TextSpan(text: ' '));
          }

        case TextType.d:
          spans.add(TextSpan(
            text: text,
            style: const TextStyle(
              fontSize: 14 * multiplier,
              fontStyle: FontStyle.italic,
            ),
          ));
          _addNewLine(spans);

        case TextType.r:
          spans.add(TextSpan(
            text: text,
            style: const TextStyle(
              fontSize: 12 * multiplier,
              color: Colors.grey,
            ),
          ));
          _addNewLine(spans, addParagraphSpace: false);

        case TextType.s1:
          _addNewLine(spans);
          spans.add(TextSpan(
            text: text,
            style: const TextStyle(fontSize: 18 * multiplier, fontWeight: FontWeight.bold),
          ));
          _addNewLine(spans, addParagraphSpace: false);

        case TextType.s2:
          _addNewLine(spans);
          spans.add(TextSpan(
            text: text,
            style: const TextStyle(fontSize: 16 * multiplier, fontWeight: FontWeight.bold),
          ));
          _addNewLine(spans, addParagraphSpace: false);

        case TextType.ms:
          spans.add(TextSpan(
            text: text,
            style: const TextStyle(fontSize: 20 * multiplier, fontWeight: FontWeight.bold),
          ));
          _addNewLine(spans, addParagraphSpace: false);

        case TextType.mr:
          spans.add(TextSpan(
            text: text,
            style: const TextStyle(fontSize: 16 * multiplier, color: Colors.grey),
          ));

        case TextType.qa:
          spans.add(TextSpan(
            text: text,
            style: const TextStyle(fontSize: 14 * multiplier, fontWeight: FontWeight.bold),
          ));
          _addNewLine(spans, addParagraphSpace: false);
      }
    }
    return TextSpan(children: spans);
  }

  void _addNewLine(List<TextSpan> spans, {bool addParagraphSpace = true}) {
    if (spans.isEmpty) return;
    spans.add(const TextSpan(text: '\n'));
    if (addParagraphSpace) {
      spans.add(
        const TextSpan(text: '\n'),
      );
    }
  }

  String formatTitle(int bookId, int chapter) {
    final book = bookIdToFullNameMap[bookId]!;
    return '$book $chapter';
  }
}
