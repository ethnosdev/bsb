import 'package:bsb/infrastructure/reference.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

/// Information about a single biblical word in a passage, including its packed word ID.
class ScriptureWordInfo {
  final int wordId;
  final String word;
  final int bookId;
  final int chapter;
  final int verse;
  final int wordIndex;

  const ScriptureWordInfo({
    required this.wordId,
    required this.word,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.wordIndex,
  });

  @override
  String toString() => 'Word($word, id: $wordId, $bookId $chapter:$verse#$wordIndex)';
}

/// Extracts all biblical words from [lines] with their exact packed word IDs (BBCCCVVVWWW).
/// The word IDs match those assigned by [UsfmParser.getWords].
List<ScriptureWordInfo> extractWordsFromLines(List<UsfmLine> lines) {
  final result = <ScriptureWordInfo>[];
  int currentVerseNum = -1;
  int currentWordOffset = 0;

  for (final line in lines) {
    if (!line.format.isBiblicalText || line.verse <= 0) continue;

    if (line.verse != currentVerseNum) {
      currentVerseNum = line.verse;
      currentWordOffset = 0;
    }

    final elements = UsfmParser.getWords(line, currentWordOffset);
    final words = elements.whereType<Word>().toList();
    for (final word in words) {
      result.add(ScriptureWordInfo(
        wordId: word.id,
        word: word.text,
        bookId: line.bookId,
        chapter: line.chapter,
        verse: line.verse,
        wordIndex: word.id % 1000,
      ));
    }
    currentWordOffset += words.length;
  }
  return result;
}

/// Computes the adjusted [Reference] given [startWordId] and [endWordId].
/// If entire verses at the beginning or end were trimmed away, the reference adjusts
/// to start or end at the first/last remaining verse. If words are trimmed within
/// the same verses, the reference display remains unchanged.
Reference computeAdjustedReference({
  required Reference originalReference,
  int? startWordId,
  int? endWordId,
  List<ScriptureWordInfo>? allWords,
}) {
  if (startWordId == null && endWordId == null) {
    return originalReference;
  }

  int newStartChapter;
  int newStartVerse;
  int newEndChapter;
  int newEndVerse;
  int bookId = originalReference.bookId;

  if (allWords != null && allWords.isNotEmpty) {
    final effectiveStart = startWordId ?? allWords.first.wordId;
    final effectiveEnd = endWordId ?? allWords.last.wordId;
    final selected = allWords
        .where((w) => w.wordId >= effectiveStart && w.wordId <= effectiveEnd)
        .toList();
    if (selected.isEmpty) return originalReference;
    final first = selected.first;
    final last = selected.last;
    bookId = first.bookId;
    newStartChapter = first.chapter;
    newStartVerse = first.verse;
    newEndChapter = last.chapter;
    newEndVerse = last.verse;
  } else {
    newStartChapter = startWordId != null
        ? (startWordId ~/ 1000000) % 1000
        : originalReference.chapter;
    newStartVerse = startWordId != null
        ? (startWordId ~/ 1000) % 1000
        : (originalReference.verse ?? 1);
    newEndChapter = endWordId != null
        ? (endWordId ~/ 1000000) % 1000
        : (originalReference.endChapter ?? originalReference.chapter);
    newEndVerse = endWordId != null
        ? (endWordId ~/ 1000) % 1000
        : (originalReference.endVerse ?? originalReference.verse ?? 1);
    if (startWordId != null) {
      bookId = startWordId ~/ 1000000000;
    }
  }

  if (newStartChapter == newEndChapter && newStartVerse == newEndVerse) {
    return Reference(
      bookId: bookId,
      chapter: newStartChapter,
      verse: newStartVerse,
    );
  } else if (newStartChapter == newEndChapter) {
    return Reference(
      bookId: bookId,
      chapter: newStartChapter,
      verse: newStartVerse,
      endVerse: newEndVerse,
    );
  } else {
    return Reference(
      bookId: bookId,
      chapter: newStartChapter,
      verse: newStartVerse,
      endChapter: newEndChapter,
      endVerse: newEndVerse,
    );
  }
}

/// Trims [lines] to only include words between [startWordId] and [endWordId] (inclusive).
///
/// Rules:
/// - Words before [startWordId] or after [endWordId] are omitted.
/// - If the first word of a verse was trimmed (e.g., [startWordId] is mid-verse), the
///   verse number for that starting verse is not rendered (its `verse` is set to 0).
/// - Subsequent verses retain their verse numbers.
/// - USFM formatting tags (such as `\wj` Words of Jesus) and paragraph formatting are preserved.
List<UsfmLine> trimPassageLines(
  List<UsfmLine> lines,
  int? startWordId,
  int? endWordId,
) {
  if (startWordId == null && endWordId == null) {
    return lines;
  }

  final effectiveStart = startWordId ?? 0;
  final effectiveEnd = endWordId ?? 99999999999;

  final trimmedLines = <UsfmLine>[];
  int currentVerseNum = -1;
  int currentWordOffset = 0;

  for (final line in lines) {
    // Drop footnote lines
    if (line.format == ParagraphFormat.r) continue;

    // Handle non-biblical lines (e.g. paragraph spacing)
    if (!line.format.isBiblicalText || line.verse <= 0) {
      if (trimmedLines.isNotEmpty && line.format == ParagraphFormat.b) {
        trimmedLines.add(line);
      }
      continue;
    }

    if (line.verse != currentVerseNum) {
      currentVerseNum = line.verse;
      currentWordOffset = 0;
    }

    final tokenizer = RegExp(r'(\\f.+?\\f\*)|(\\[a-zA-Z0-9*]+)|(\s+)|([^\s\\]+)');
    final matches = tokenizer.allMatches(line.text);

    final keptTokens = <String>[];
    bool inWj = false;
    bool hasKeptWords = false;

    for (final match in matches) {
      // Footnote token
      if (match.group(1) != null) continue;

      // USFM tag token
      final tag = match.group(2);
      if (tag != null) {
        if (tag == r'\wj') {
          inWj = true;
        } else if (tag == r'\wj*') {
          inWj = false;
          if (hasKeptWords && !keptTokens.contains(r'\wj*')) {
            keptTokens.add(r'\wj*');
          }
        }
        continue;
      }

      // Word token
      final word = match.group(4);
      if (word != null) {
        final id = (line.bookChapterVerse * 1000) + currentWordOffset;
        currentWordOffset++;

        if (id >= effectiveStart && id <= effectiveEnd) {
          if (inWj && !keptTokens.contains(r'\wj')) {
            keptTokens.add(r'\wj');
          }
          keptTokens.add(word);
          hasKeptWords = true;
        }
      }
    }

    if (inWj && hasKeptWords && !keptTokens.contains(r'\wj*')) {
      keptTokens.add(r'\wj*');
    }

    if (!hasKeptWords) continue;

    // Check if the first word of this verse was trimmed away
    final wasFirstWordOfVerseTrimmed =
        startWordId != null &&
        (startWordId % 1000 > 0) &&
        (startWordId ~/ 1000 == line.bookChapterVerse);

    final resolvedBookChapterVerse = wasFirstWordOfVerseTrimmed
        ? (line.bookChapterVerse ~/ 1000) * 1000 + 0 // verse 0 suppresses verse number
        : line.bookChapterVerse;

    trimmedLines.add(
      UsfmLine(
        bookChapterVerse: resolvedBookChapterVerse,
        text: keptTokens.join(' '),
        format: line.format,
      ),
    );
  }

  return trimmedLines;
}
