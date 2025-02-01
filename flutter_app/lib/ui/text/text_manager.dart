import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/source_texts.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
    final (bookId, chapter) = bookAndChapterForPageIndex(index);

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
    final (bookId, chapter) = bookAndChapterForPageIndex(index);

    // Update book and chapter title
    SchedulerBinding.instance.addPostFrameCallback((_) {
      titleNotifier.value = _formatTitle(bookId, chapter);
    });

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
      verseLines: content,
      baseFontSize: _normalTextSize,
      textColor: textColor,
      footnoteColor: footnoteColor,
      onVerseLongPress: onVerseLongPress,
      onFootnoteTap: onFootnoteTap,
    );

    // Update cache
    final key = '${bookId}_$chapter';
    _chapterCache[key] = formattedContent;
    _trackUsage(key);

    // Update notifier
    targetNotifier.value = formattedContent;
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

  // (1-3) Book Name + Chapter:Verse(-Range)
  // final _crossReference = RegExp(
  //   r'(?:(?:[1-3]\s)?[A-Z][a-z]+(?:\s[a-zA-Z]+)?)\s+\d+:\d+(?:–\d+)?',
  //   caseSensitive: true,
  // );

  TextSpan formatFootnote({
    required String footnote,
    required Color highlightColor,
    required void Function(String tappedKeyword) onTapKeyword,
  }) {
    // Make semicolon-separated content display on new lines
    final note = footnote.replaceAll('; ', ';\n');

    final patterns = [
      Reference.referenceRegex.pattern,
      ...sourceTexts.keys.map((kw) => RegExp.escape(kw)),
    ].join('|');
    final regex = RegExp('($patterns)');

    final List<TextSpan> spans = [];
    int start = 0;

    for (final match in regex.allMatches(note)) {
      // Add text before the match
      if (match.start > start) {
        spans.add(TextSpan(text: note.substring(start, match.start)));
      }

      // Add the matched keyword as a tappable span
      final matchedText = match.group(0)!;
      spans.add(
        TextSpan(
          text: matchedText,
          style: TextStyle(color: highlightColor),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              onTapKeyword(matchedText);
            },
        ),
      );

      start = match.end;
    }

    // Add remaining text after the last match
    if (start < note.length) {
      spans.add(TextSpan(text: note.substring(start)));
    }

    return TextSpan(children: spans);
  }

  // Returns the title and text body for a given tapped keyword.
  // They keyword can either be a cross reference or a source text name.
  // If a cross reference, then show the source text.
  // If a source text abbreviation, then show the full name.
  Future<TextParagraph?> lookupFootnoteDetails(String keyword) async {
    if (Reference.isValid(keyword)) {
      final reference = Reference.tryParse(keyword)!;
      final content = await _dbHelper.getRange(reference);
      return formatVerses(
        verseLines: content,
        baseFontSize: _normalTextSize,
        showSectionTitles: false,
        showVerseNumbers: false,
      );
    } else if (sourceTexts.containsKey(keyword)) {
      final source = sourceTexts[keyword]!;
      final withNewLine = source.replaceAll('; ', '\n');
      final formattedSource = TextSpan(
        text: withNewLine,
        style: TextStyle(
          fontSize: _normalTextSize,
        ),
      );
      return [(formattedSource, TextType.v, null)];
    }
    return null;
  }
}
