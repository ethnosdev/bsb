import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/ui/playlists/widgets/passage_trim_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

void main() {
  group('Passage Trim Helper Tests', () {
    final sampleLines = [
      UsfmLine(
        bookChapterVerse: 43003016, // John 3:16
        text: r'\wj For God so loved the world that He gave His one and only\f + \ft footnote\f* Son,\wj*',
        format: ParagraphFormat.p,
      ),
      UsfmLine(
        bookChapterVerse: 43003017, // John 3:17
        text: r'\wj For God did not send His Son into the world to condemn the world,\wj*',
        format: ParagraphFormat.p,
      ),
      UsfmLine(
        bookChapterVerse: 43003018, // John 3:18
        text: r'\wj Whoever believes in Him is not condemned,\wj*',
        format: ParagraphFormat.p,
      ),
    ];

    test('extractWordsFromLines extracts words with matching packed IDs', () {
      final words = extractWordsFromLines(sampleLines);
      expect(words.isNotEmpty, isTrue);
      // Verse 16
      expect(words.first.word, 'For');
      expect(words.first.wordId, 43003016000);
      expect(words[1].word, 'God');
      expect(words[1].wordId, 43003016001);
      // Verse 17
      final v17Words = words.where((w) => w.verse == 17).toList();
      expect(v17Words.first.word, 'For');
      expect(v17Words.first.wordId, 43003017000);
    });

    test('computeAdjustedReference keeps original reference when verses are partially trimmed', () {
      final allWords = extractWordsFromLines(sampleLines);
      final origRef = Reference(bookId: 43, chapter: 3, verse: 16, endVerse: 18);

      // Trim words 2..end in verse 16 (verse 16 still partially included)
      final startWordId = 43003016002;
      final endWordId = 43003018005;

      final adjusted = computeAdjustedReference(
        originalReference: origRef,
        startWordId: startWordId,
        endWordId: endWordId,
        allWords: allWords,
      );

      expect(adjusted.toString(), 'John 3:16–18');
    });

    test('computeAdjustedReference adjusts start verse when entire verse 16 is trimmed away', () {
      final allWords = extractWordsFromLines(sampleLines);
      final origRef = Reference(bookId: 43, chapter: 3, verse: 16, endVerse: 18);

      // Trim start into verse 17
      final startWordId = 43003017001; // "God" in verse 17
      final endWordId = 43003018005;

      final adjusted = computeAdjustedReference(
        originalReference: origRef,
        startWordId: startWordId,
        endWordId: endWordId,
        allWords: allWords,
      );

      expect(adjusted.toString(), 'John 3:17–18');
    });

    test('computeAdjustedReference adjusts end verse when entire verse 18 is trimmed away', () {
      final allWords = extractWordsFromLines(sampleLines);
      final origRef = Reference(bookId: 43, chapter: 3, verse: 16, endVerse: 18);

      // End in verse 17
      final startWordId = 43003016000;
      final endWordId = 43003017005;

      final adjusted = computeAdjustedReference(
        originalReference: origRef,
        startWordId: startWordId,
        endWordId: endWordId,
        allWords: allWords,
      );

      expect(adjusted.toString(), 'John 3:16–17');
    });

    test('trimPassageLines suppresses verse number when first word of verse is trimmed', () {
      // Trim verse 16 from word index 1 ("God"), omitting word index 0 ("For")
      final trimmed = trimPassageLines(sampleLines, 43003016001, 43003017003);

      expect(trimmed.length, 2); // v16 and v17
      // Verse 16: verse is set to 0 so UsfmParser skips verse number
      expect(trimmed[0].verse, 0);
      expect(trimmed[0].text, startsWith(r'\wj God so loved'));
      expect(trimmed[0].text, endsWith(r'Son, \wj*'));

      // Verse 17: started at word 0, so verse is preserved as 17
      expect(trimmed[1].verse, 17);
      expect(trimmed[1].text, startsWith(r'\wj For God did'));
    });

    test('trimPassageLines preserves verse number when start is untrimmed (word index 0)', () {
      final trimmed = trimPassageLines(sampleLines, 43003016000, 43003016004);

      expect(trimmed.length, 1);
      expect(trimmed[0].verse, 16);
      expect(trimmed[0].text, r'\wj For God so loved the \wj*');
    });
  });
}
