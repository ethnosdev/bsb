import 'dart:io';

import 'package:bsb/infrastructure/bsb_text_localizer.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/search/bible_search_service.dart';
import 'package:bsb/infrastructure/search/search_models.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  group('DatabaseHelper.buildFtsCandidateClauses & strict boundary matching', () {
    test('never emits parentheses and formats exact vs expanded clauses', () {
      expect(
        DatabaseHelper.buildFtsCandidateClauses(
          'favour',
          isExact: true,
          useBritishSpelling: true,
        ),
        equals(['favor']),
      );
      expect(
        DatabaseHelper.buildFtsCandidateClauses(
          'burnt',
          isExact: true,
          useBritishSpelling: true,
        ),
        equals(['burnt OR burned']),
      );
      expect(
        DatabaseHelper.buildFtsCandidateClauses(
          'in the',
          isExact: true,
          useBritishSpelling: true,
        ),
        equals(['"in the"']),
      );
      expect(
        DatabaseHelper.buildFtsCandidateClauses(
          'burnt offering',
          isExact: true,
          useBritishSpelling: true,
        ),
        equals(['burnt OR burned', 'offering']),
      );
      expect(
        DatabaseHelper.buildFtsCandidateClauses(
          "King's favour",
          isExact: true,
          useBritishSpelling: true,
        ),
        equals(['king*', 'favor']),
      );
      expect(
        DatabaseHelper.buildFtsCandidateClauses(
          '???',
          isExact: true,
          useBritishSpelling: true,
        ),
        isEmpty,
      );
      expect(
        DatabaseHelper.buildFtsCandidateClauses(
          '???',
          isExact: false,
          useBritishSpelling: true,
        ),
        isEmpty,
      );
      expect(
        DatabaseHelper.buildFtsCandidateClauses(
          'AND OR NOT NEAR',
          isExact: false,
          useBritishSpelling: true,
        ),
        isEmpty,
      );

      for (final query in [
        'burnt offering',
        '"his favour" kingdom',
        'honou',
        "King's favour",
      ]) {
        final clauses = DatabaseHelper.buildFtsCandidateClauses(
          query,
          useBritishSpelling: true,
        );
        for (final clause in clauses) {
          expect(clause.contains('('), isFalse);
          expect(clause.contains(')'), isFalse);
        }
      }
    });

    test('strict exact boundary rejects substring matches and empty tokens', () {
      expect(
        BibleSearchService.matchesLocalizedText(
          'All this favour was shown.',
          'his favour',
          isExact: true,
        ),
        isFalse,
      );
      expect(
        BibleSearchService.computeMatchSpans(
          'All this favour was shown.',
          'his favour',
          isExact: true,
          strictExactBoundary: true,
        ),
        isEmpty,
      );
      expect(
        BibleSearchService.matchesLocalizedText(
          'All this favour was shown.',
          '"his favour"',
          isExact: false,
        ),
        isFalse,
      );
      expect(
        BibleSearchService.matchesLocalizedText(
          'He brought dishonour upon them.',
          'honou',
          isExact: false,
        ),
        isFalse,
      );
      expect(
        BibleSearchService.matchesLocalizedText(
          'To Him be honour and glory.',
          'honou',
          isExact: false,
        ),
        isTrue,
      );
      expect(
        BibleSearchService.matchesLocalizedText(
          'Any text',
          '???',
          isExact: true,
        ),
        isFalse,
      );
    });
  });

  group('SQLite FTS4 British English search & database localization', () {
    late Database db;
    late DatabaseHelper dbHelper;
    late BibleSearchService searchService;

    setUpAll(() async {
      final dbPath = '${Directory.current.path}/assets/database/database.db';
      db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      dbHelper = DatabaseHelper()..setDatabaseForTesting(db);
      searchService = BibleSearchService(dbHelper: dbHelper);
    });

    tearDownAll(() async {
      await db.close();
    });

    setUp(() {
      dbHelper.setUseBritishSpelling(true);
    });

    test('localizes read methods and clears chapter words cache on toggle', () async {
      dbHelper.setUseBritishSpelling(false);
      // Genesis 6:8 (Noah found favor in the eyes of the LORD)
      final usVerse = await dbHelper.getVerseText(1006008);
      expect(usVerse, contains('favor'));
      await dbHelper.getChapterWords(1, 6);
      expect(dbHelper.chapterWordsCacheLength, greaterThan(0));

      dbHelper.setUseBritishSpelling(true);
      expect(dbHelper.chapterWordsCacheLength, equals(0));
      final ukVerse = await dbHelper.getVerseText(1006008);
      expect(ukVerse, contains('favour'));
      expect(ukVerse, isNot(contains('favor')));

      final chapterLines = await dbHelper.getChapter(1, 6);
      expect(
        chapterLines.any(
          (l) => l.bookChapterVerse == 1006008 && l.text.contains('favour'),
        ),
        isTrue,
      );

      final rangeLines = await dbHelper.getRange(
        Reference.fromVerseId(packedInt: 1006008),
      );
      expect(rangeLines.any((l) => l.text.contains('favour')), isTrue);

      final headings = await dbHelper.getSectionHeadings(1);
      expect(headings, isNotEmpty);

      final interlinear = await dbHelper.getOriginalLanguageData(
        Reference.fromVerseId(packedInt: 1006008),
      );
      final words = interlinear.whereType<OriginalWord>();
      expect(words.any((w) => w.englishGloss.contains('favour')), isTrue);
    });

    test('single 1:1 British query returns converted rows and excludes American', () async {
      final ukResults = await searchService.searchVerses(query: 'favour');
      expect(ukResults, isNotEmpty);
      for (final result in ukResults) {
        expect(result.matchSpans, isNotEmpty);
        final matched = result.matchSpans
            .map((s) => result.text.substring(s.$1, s.$2).toLowerCase())
            .toList();
        expect(matched.every((m) => m.startsWith('favour')), isTrue);
      }

      final judgementResults = await searchService.searchVerses(
        query: 'judgements',
      );
      expect(judgementResults, isNotEmpty);
      expect(
        judgementResults.every((r) => r.matchSpans.isNotEmpty),
        isTrue,
      );

      // Replaced American form is excluded when British mode is active
      final replacedAmericanResults = await searchService.searchVerses(
        query: 'favor',
      );
      expect(replacedAmericanResults, isEmpty);
    });

    test('collision queries return both canonical and converted rows via OR/INTERSECT', () async {
      final burntResults = await searchService.searchVerses(
        query: 'burnt',
        isExact: true,
      );
      // 265 canonical burnt + 157 burned -> burnt verses (count DISTINCT verses >= 350)
      expect(burntResults.length, greaterThan(350));

      final burntOfferingResults = await searchService.searchVerses(
        query: 'burnt offering',
        isExact: true,
      );
      expect(burntOfferingResults, isNotEmpty);
      expect(
        burntOfferingResults.every(
          (r) => r.text.toLowerCase().contains('burnt offering'),
        ),
        isTrue,
      );

      final burntOtBook1 = await searchService.searchVerses(
        query: 'burnt offering',
        scope: SearchScope.book,
        specificBookId: 1,
        isExact: true,
      );
      expect(burntOtBook1, isNotEmpty);
      expect(
        burntOtBook1.every((r) => r.reference.bookId == 1),
        isTrue,
      );

      final dweltResults = await searchService.searchVerses(
        query: 'dwelt',
        isExact: true,
      );
      // Must include Numbers 13:22 (4013022: canonical "dwelled") and canonical "dwelt"
      expect(
        dweltResults.any((r) => r.reference.packedVerse == 4013022),
        isTrue,
      );
      expect(
        dweltResults.length,
        greaterThanOrEqualTo(15),
      );
    });

    test('partial prefix queries return British-localized results', () async {
      final honouResults = await searchService.searchVerses(query: 'honou');
      expect(honouResults, isNotEmpty);
      expect(
        honouResults.every(
          (r) =>
              r.matchSpans.isNotEmpty &&
              RegExp(r'\bhonou', caseSensitive: false).hasMatch(r.text),
        ),
        isTrue,
      );

      final enquiResults = await searchService.searchVerses(query: 'enqui');
      expect(enquiResults, isNotEmpty);
      expect(
        enquiResults.every((r) => r.matchSpans.isNotEmpty),
        isTrue,
      );
    });

    test('contextual disambiguation excludes false positives in search', () async {
      final storeyResults = await searchService.searchVerses(query: 'storey');
      final storeyRefs = storeyResults
          .map((r) => r.reference.packedVerse)
          .toSet();
      expect(storeyRefs, equals(BsbTextLocalizer.storeyVerses));

      final practiseResults = await searchService.searchVerses(
        query: 'practise',
        isExact: true,
      );
      expect(practiseResults, isNotEmpty);
      final practiseRefs = practiseResults
          .map((r) => r.reference.packedVerse)
          .toSet();
      for (final nounRef in BsbTextLocalizer.nounPracticeVerses) {
        expect(practiseRefs.contains(nounRef), isFalse);
      }

      // Searching American "practice" in British mode returns only the 9 noun verses
      final nounPracticeResults = await searchService.searchVerses(
        query: 'practice',
        isExact: true,
      );
      expect(
        nounPracticeResults.map((r) => r.reference.packedVerse).toSet(),
        equals(BsbTextLocalizer.nounPracticeVerses),
      );
    });

    test('handles exact, mixed, apostrophe, and punctuation-only queries plus Dart limit', () async {
      final exactHisFavour = await searchService.searchVerses(
        query: 'his favour',
        isExact: true,
      );
      expect(exactHisFavour, isNotEmpty);
      for (final result in exactHisFavour) {
        expect(
          RegExp(r'\bhis\s+favour\b', caseSensitive: false)
              .hasMatch(result.text),
          isTrue,
        );
      }

      final quotedInNonExact = await searchService.searchVerses(
        query: '"his favour"',
        isExact: false,
      );
      expect(quotedInNonExact.length, equals(exactHisFavour.length));

      final mixed = await searchService.searchVerses(
        query: '"his favour" kingdom',
        isExact: false,
      );
      for (final result in mixed) {
        expect(
          RegExp(r'\bhis\s+favour\b', caseSensitive: false)
              .hasMatch(result.text),
          isTrue,
        );
        expect(
          RegExp(r'\bkingdom', caseSensitive: false).hasMatch(result.text),
          isTrue,
        );
      }

      // Apostrophe phrase inside canonical BSB ("God’s favour" -> Mal 1:9 = 39001009)
      final godsFavour = await searchService.searchVerses(
        query: 'God’s favour',
        isExact: true,
      );
      expect(
        godsFavour.any((r) => r.reference.packedVerse == 39001009),
        isTrue,
      );

      // ASCII apostrophe query does not throw SQL syntax error
      final kingsFavour = await searchService.searchVerses(
        query: "King's favour",
        isExact: true,
      );
      expect(kingsFavour, isEmpty);

      // Punctuation-only query returns empty without error
      expect(
        await searchService.searchVerses(query: '???', isExact: true),
        isEmpty,
      );
      expect(
        await searchService.searchVerses(query: '???', isExact: false),
        isEmpty,
      );

      // Dart post-filter enforces limit accurately after filtering false positives
      final limited = await searchService.searchVerses(
        query: 'storey',
        limit: 2,
      );
      expect(limited.length, equals(2));
    });
  });
}
