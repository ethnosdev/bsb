import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:bsb/infrastructure/word_cluster.dart';
import 'package:bsb/ui/hebrew_greek/hebrew_greek_screen.dart';
import 'package:bsb/ui/hebrew_greek/passage_cards.dart';
import 'package:bsb/ui/hebrew_greek/reference_modal_sheet.dart';
import 'package:bsb/ui/hebrew_greek/similar_verses/similar_verse_manager.dart';
import 'package:bsb/ui/hebrew_greek/similar_verses/similar_verses_page.dart';
import 'package:bsb/ui/hebrew_greek/verse_page_manager.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeHebrewGreekDatabaseHelper implements DatabaseHelper {
  final Map<int, String> lexicons = {};
  final Map<int, String> verseTexts = {};
  final Map<String, String> lemmaLexicons = {};
  final List<OriginalWord> words = [];
  final List<Reference> exactMatches = [];
  final List<Reference> strongMatches = [];

  @override
  Future<String?> getVerseText(int reference) async {
    return verseTexts[reference] ?? 'Verse text for $reference';
  }

  @override
  Future<String?> getLexiconContentByLemma(
    Language? language,
    String lemma,
  ) async {
    return lemmaLexicons[lemma];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<int> getVerseCount(int bookId, int chapter) async {
    return 1;
  }

  @override
  Future<List<VerseElement>> getOriginalLanguageData(
    Reference reference,
  ) async {
    return resolveWordClusters(words);
  }

  @override
  Future<String?> getLexiconContent(
    Language language,
    int strongsNumber,
  ) async {
    return lexicons[strongsNumber];
  }

  @override
  Future<int> getExactWordCount(int originalId) async {
    return exactMatches.length;
  }

  @override
  Future<int> getStrongNumberCount(
    Language language,
    int strongsNumber,
  ) async {
    return strongMatches.length;
  }

  @override
  Future<List<Reference>> getVersesWithExactWord(int originalId) async {
    return exactMatches;
  }

  @override
  Future<List<Reference>> getVersesWithStrongNumber(
    Language language,
    int strongsNumber,
  ) async {
    return strongMatches;
  }
}

void main() {
  late FakeHebrewGreekDatabaseHelper fakeDb;
  late UserSettings userSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    if (getIt.isRegistered<DatabaseHelper>()) {
      getIt.unregister<DatabaseHelper>();
    }
    if (getIt.isRegistered<UserSettings>()) {
      getIt.unregister<UserSettings>();
    }
    fakeDb = FakeHebrewGreekDatabaseHelper();
    getIt.registerSingleton<DatabaseHelper>(fakeDb);
    userSettings = UserSettings();
    getIt.registerSingleton<UserSettings>(userSettings);
  });

  tearDown(() {
    if (getIt.isRegistered<DatabaseHelper>()) {
      getIt.unregister<DatabaseHelper>();
    }
    if (getIt.isRegistered<UserSettings>()) {
      getIt.unregister<UserSettings>();
    }
  });

  group('VersePageManager & Dual Passage Alignment', () {
    test('OriginalWord distinguishes untranslated placeholders and vvv clusters', () {
      OriginalWord makeWord(String gloss) => OriginalWord(
            language: Language.greek,
            word: 'test',
            transliteration: 'test',
            englishGloss: gloss,
            strongsNumber: 1,
            partOfSpeech: '',
          );

      expect(makeWord('-').isUntranslated, isTrue);
      expect(makeWord('').isUntranslated, isTrue);
      expect(makeWord('   ').isUntranslated, isTrue);
      expect(makeWord('. . .').isUntranslated, isTrue);
      expect(makeWord('...').isUntranslated, isTrue);
      expect(makeWord('( -').isUntranslated, isTrue);
      expect(makeWord('God').isUntranslated, isFalse);

      expect(makeWord('vvv').isVvv, isTrue);
      expect(makeWord(' vvv ').isVvv, isTrue);
      expect(makeWord('vvv').isUntranslated, isFalse);
      expect(makeWord('vvv').hasEnglishChip, isFalse);
      expect(makeWord('God').hasEnglishChip, isTrue);
    });

    test('correctly orders English words by bsbSort and omits untranslated words',
        () async {
      fakeDb.words.addAll([
        OriginalWord(
          id: 1,
          originalId: 101,
          language: Language.hebrew,
          word: 'בְּרֵאשִׁ֖ית',
          transliteration: '',
          englishGloss: 'In the beginning',
          strongsNumber: 7225,
          partOfSpeech: 'Prep-b | N-fs',
          bsbSort: 1,
        ),
        OriginalWord(
          id: 2,
          originalId: 102,
          language: Language.hebrew,
          word: 'בָּרָ֣א',
          transliteration: '',
          englishGloss: 'created',
          strongsNumber: 1254,
          partOfSpeech: 'V-Qal',
          bsbSort: 4,
        ),
        OriginalWord(
          id: 3,
          originalId: 103,
          language: Language.hebrew,
          word: 'אֱלֹהִ֑ים',
          transliteration: '',
          englishGloss: 'God',
          strongsNumber: 430,
          partOfSpeech: 'N-mp',
          bsbSort: 2,
        ),
        OriginalWord(
          id: 4,
          originalId: 104,
          language: Language.hebrew,
          word: 'אֵ֥ת',
          transliteration: '',
          englishGloss: '-',
          strongsNumber: 853,
          partOfSpeech: 'DirObjM',
          bsbSort: 3,
        ),
        OriginalWord(
          id: 5,
          originalId: 105,
          language: Language.hebrew,
          word: 'הַשָּׁמַ֖יִם',
          transliteration: '',
          englishGloss: 'the heavens',
          strongsNumber: 8064,
          partOfSpeech: 'Art | N-mp',
          bsbSort: 5,
        ),
        OriginalWord(
          id: 6,
          originalId: 106,
          language: Language.hebrew,
          word: 'וְאֵ֥ת',
          transliteration: '',
          englishGloss: 'and',
          strongsNumber: 853,
          partOfSpeech: 'Conj-w',
          bsbSort: 6,
        ),
        OriginalWord(
          id: 7,
          originalId: 107,
          language: Language.hebrew,
          word: 'הָאָֽרֶץ׃',
          transliteration: '',
          englishGloss: 'the earth',
          strongsNumber: 776,
          partOfSpeech: 'Art | N-fs',
          punctuation: '.',
          bsbSort: 7,
        ),
      ]);

      fakeDb.lexicons[7225] = '**רֵאשִׁית** *beginning, chief*';
      fakeDb.exactMatches.addAll([
        Reference(bookId: 1, chapter: 1, verse: 1),
        Reference(bookId: 1, chapter: 10, verse: 10),
      ]);
      fakeDb.strongMatches.addAll([
        Reference(bookId: 1, chapter: 1, verse: 1),
        Reference(bookId: 1, chapter: 10, verse: 10),
        Reference(bookId: 49, chapter: 1, verse: 1),
      ]);

      final manager = VersePageManager(Language.hebrew);
      await manager.requestVerseContent(bookId: 1, chapter: 1, verse: 1);

      expect(manager.originalWords.length, equals(7));
      expect(manager.originalWords[0].word, equals('בְּרֵאשִׁ֖ית'));
      expect(manager.originalWords[1].word, equals('בָּרָ֣א'));
      expect(manager.originalWords[2].word, equals('אֱלֹהִ֑ים'));
      expect(manager.originalWords[3].word, equals('אֵ֥ת'));

      expect(manager.englishWords.length, equals(6));
      expect(manager.englishWords[0].englishGloss, equals('In the beginning'));
      expect(manager.englishWords[1].englishGloss, equals('God'));
      expect(manager.englishWords[2].englishGloss, equals('created'));
      expect(manager.englishWords[3].englishGloss, equals('the heavens'));
      expect(manager.englishWords[4].englishGloss, equals('and'));
      expect(manager.englishWords[5].englishGloss, equals('the earth'));

      expect(manager.selectedWord?.id, equals(1));
      expect(manager.lexiconContent, contains('רֵאשִׁית'));
      expect(manager.exactCount, equals(2));
      expect(manager.strongsCount, equals(3));
    });

    test('selecting word updates selection and loads lexicon', () async {
      final wordGod = OriginalWord(
        id: 3,
        originalId: 103,
        language: Language.hebrew,
        word: 'אֱלֹהִ֑ים',
        transliteration: '',
        englishGloss: 'God',
        strongsNumber: 430,
        partOfSpeech: 'N-mp',
        bsbSort: 2,
      );

      fakeDb.words.add(wordGod);
      fakeDb.lexicons[430] = '**אֱלֹהִים** *God, deity*';
      fakeDb.exactMatches.addAll([
        Reference(bookId: 1, chapter: 1, verse: 1),
      ]);
      fakeDb.strongMatches.addAll([
        Reference(bookId: 1, chapter: 1, verse: 1),
        Reference(bookId: 1, chapter: 1, verse: 2),
      ]);

      final manager = VersePageManager(Language.hebrew);
      await manager.requestVerseContent(bookId: 1, chapter: 1, verse: 1);

      await manager.selectWord(wordGod);

      expect(manager.selectedWord?.id, equals(3));
      expect(manager.lexiconContent, contains('אֱלֹהִים'));
      expect(manager.exactCount, equals(1));
      expect(manager.strongsCount, equals(2));
    });

    test(
        'initial selection highlights first word in English and corresponding original word even when original order differs',
        () async {
      fakeDb.words.clear();
      fakeDb.words.addAll([
        OriginalWord(
          id: 1,
          originalId: 101,
          language: Language.hebrew,
          word: 'וַיֹּ֥אמֶר',
          transliteration: 'way·yō·mer',
          englishGloss: 'said',
          strongsNumber: 559,
          partOfSpeech: 'V-Qal',
          bsbSort: 2,
        ),
        OriginalWord(
          id: 2,
          originalId: 102,
          language: Language.hebrew,
          word: 'אֱלֹהִ֖ים',
          transliteration: '’ĕ·lō·hîm',
          englishGloss: 'God',
          strongsNumber: 430,
          partOfSpeech: 'N-mp',
          bsbSort: 1,
        ),
      ]);
      fakeDb.lexicons[430] = '**אֱלֹהִים** *God, deity*';
      fakeDb.lexicons[559] = '**אָמַר** *to say*';

      final manager = VersePageManager(Language.hebrew);
      await manager.requestVerseContent(bookId: 1, chapter: 1, verse: 3);

      expect(manager.selectedWord?.id, equals(2));
      expect(manager.selectedWord?.englishGloss, equals('God'));
      expect(manager.selectedWord?.word, equals('אֱלֹהִ֖ים'));
    });
  });

  group('Word Cluster Resolution (\'vvv\' Multi-word Translation)', () {
    test('clusters vvv companion word with forward anchor word', () {
      final words = [
        OriginalWord(
          id: 1,
          originalId: 101,
          language: Language.hebrew,
          word: 'זֹרֵ֣עַ',
          transliteration: 'zō·rê·a‘',
          englishGloss: 'vvv',
          strongsNumber: 2232,
          partOfSpeech: 'V-Qal',
          bsbSort: 659,
        ),
        OriginalWord(
          id: 2,
          originalId: 102,
          language: Language.hebrew,
          word: 'זֶ֗רַע',
          transliteration: 'ze·ra‘',
          englishGloss: 'seed-bearing',
          strongsNumber: 2233,
          partOfSpeech: 'N-ms',
          bsbSort: 660,
        ),
      ];

      final clustered = resolveWordClusters(words).whereType<OriginalWord>().toList();
      expect(clustered[0].isVvv, isTrue);
      expect(clustered[0].partOfTranslation, equals('seed-bearing'));
      expect(clustered[0].clusterWordIds, equals({1, 2}));
      expect(clustered[0].hasEnglishChip, isFalse);

      expect(clustered[1].isVvv, isFalse);
      expect(clustered[1].clusterWordIds, equals({1, 2}));
      expect(clustered[1].hasEnglishChip, isTrue);
    });

    test('clusters multiple consecutive vvv words with single anchor', () {
      final words = [
        OriginalWord(
          id: 1,
          originalId: 101,
          language: Language.hebrew,
          word: 'בַּעֲבוּר֙',
          transliteration: '',
          englishGloss: 'vvv',
          strongsNumber: 5668,
          partOfSpeech: '',
          bsbSort: 12579,
        ),
        OriginalWord(
          id: 2,
          originalId: 102,
          language: Language.hebrew,
          word: 'תִּֽהְיֶה־',
          transliteration: '',
          englishGloss: 'vvv',
          strongsNumber: 1961,
          partOfSpeech: '',
          bsbSort: 12580,
        ),
        OriginalWord(
          id: 3,
          originalId: 103,
          language: Language.hebrew,
          word: 'לִּ֣י',
          transliteration: '',
          englishGloss: 'vvv',
          strongsNumber: 0,
          partOfSpeech: '',
          bsbSort: 12581,
        ),
        OriginalWord(
          id: 4,
          originalId: 104,
          language: Language.hebrew,
          word: 'לְעֵדָ֔ה',
          transliteration: '',
          englishGloss: 'as my witness',
          strongsNumber: 5713,
          partOfSpeech: '',
          bsbSort: 12582,
        ),
      ];

      final clustered = resolveWordClusters(words).whereType<OriginalWord>().toList();
      for (int i = 0; i < 3; i++) {
        expect(clustered[i].isVvv, isTrue);
        expect(clustered[i].partOfTranslation, equals('as my witness'));
        expect(clustered[i].clusterWordIds, equals({1, 2, 3, 4}));
        expect(clustered[i].hasEnglishChip, isFalse);
      }
      expect(clustered[3].clusterWordIds, equals({1, 2, 3, 4}));
      expect(clustered[3].hasEnglishChip, isTrue);
    });

    test('clusters discontinuous words using BSB sort when subject intervenes', () {
      final words = [
        OriginalWord(
          id: 1,
          originalId: 101,
          language: Language.hebrew,
          word: 'וַיִּקְרָ֧א',
          transliteration: '',
          englishGloss: 'vvv',
          strongsNumber: 7121,
          partOfSpeech: '',
          bsbSort: 1791,
        ),
        OriginalWord(
          id: 2,
          originalId: 102,
          language: Language.hebrew,
          word: 'הָֽאָדָ֛ם',
          transliteration: '',
          englishGloss: 'And Adam',
          strongsNumber: 120,
          partOfSpeech: '',
          bsbSort: 1790,
        ),
        OriginalWord(
          id: 3,
          originalId: 103,
          language: Language.hebrew,
          word: 'שֵׁ֥ם',
          transliteration: '',
          englishGloss: 'named',
          strongsNumber: 8034,
          partOfSpeech: '',
          bsbSort: 1792,
        ),
      ];

      final clustered = resolveWordClusters(words).whereType<OriginalWord>().toList();
      expect(clustered[0].partOfTranslation, equals('named'));
      expect(clustered[0].clusterWordIds, equals({1, 3}));
      expect(clustered[1].clusterWordIds, isEmpty);
      expect(clustered[2].clusterWordIds, equals({1, 3}));
    });
  });

  group('SimilarVerseManager', () {
    test('switches between exact form and strongs modes', () async {
      final word = OriginalWord(
        id: 1,
        originalId: 200,
        language: Language.greek,
        word: 'ἀγαπᾷ',
        transliteration: 'agapa',
        englishGloss: 'loves',
        strongsNumber: 25,
        partOfSpeech: 'V-PIA-3S',
      );

      fakeDb.exactMatches.addAll([
        Reference(bookId: 43, chapter: 3, verse: 35),
      ]);
      fakeDb.strongMatches.addAll([
        Reference(bookId: 43, chapter: 3, verse: 16),
        Reference(bookId: 43, chapter: 3, verse: 35),
        Reference(bookId: 45, chapter: 8, verse: 37),
      ]);

      final similarManager = SimilarVerseManager();
      await similarManager.init(word, initialMode: WordSearchMode.strongs);

      expect(similarManager.searchModeNotifier.value, equals(WordSearchMode.strongs));
      expect(similarManager.similarVersesNotifier.value.length, equals(3));
      expect(similarManager.strongsCount, equals(3));
      expect(similarManager.exactCount, equals(1));

      await similarManager.switchMode(WordSearchMode.exactForm);

      expect(similarManager.searchModeNotifier.value, equals(WordSearchMode.exactForm));
      expect(similarManager.similarVersesNotifier.value.length, equals(1));
      expect(similarManager.similarVersesNotifier.value.first.chapter, equals(3));
      expect(similarManager.similarVersesNotifier.value.first.verse, equals(35));
    });

    test('countsNotifier updates and getVerseContent formats English with highlight', () async {
      final word = OriginalWord(
        id: 1,
        originalId: 200,
        language: Language.greek,
        word: 'ἀγαπᾷ',
        transliteration: 'agapa',
        englishGloss: 'loves',
        strongsNumber: 25,
        partOfSpeech: 'V-PIA-3S',
        bsbSort: 2,
      );

      final wordOther = OriginalWord(
        id: 2,
        originalId: 201,
        language: Language.greek,
        word: 'ὁ',
        transliteration: 'ho',
        englishGloss: 'the',
        strongsNumber: 3588,
        partOfSpeech: 'Art',
        bsbSort: 1,
      );

      fakeDb.words.clear();
      fakeDb.words.addAll([wordOther, word]);
      fakeDb.exactMatches.clear();
      fakeDb.exactMatches.add(Reference(bookId: 43, chapter: 3, verse: 35));
      fakeDb.strongMatches.clear();
      fakeDb.strongMatches.add(Reference(bookId: 43, chapter: 3, verse: 35));

      final similarManager = SimilarVerseManager();
      await similarManager.init(
        word,
        initialMode: WordSearchMode.exactForm,
        initialExactCount: 1,
        initialStrongsCount: 1,
      );

      expect(similarManager.countsNotifier.value.exact, equals(1));
      expect(similarManager.countsNotifier.value.strongs, equals(1));

      const highlightColor = Colors.amber;
      final content = await similarManager.getVerseContent(
        Reference(bookId: 43, chapter: 3, verse: 35),
        highlightColor,
      );

      // English spans: "the " (not highlighted) then "loves" (highlighted)
      final englishSpans = content.english.children!.cast<TextSpan>();
      expect(englishSpans.length, equals(2));
      expect(englishSpans[0].text, equals('the '));
      expect(englishSpans[0].style?.color, isNull);
      expect(englishSpans[1].text, equals('loves'));
      expect(englishSpans[1].style?.color, equals(highlightColor));
      expect(englishSpans[1].style?.fontWeight, equals(FontWeight.bold));

      // Original spans: "ὁ " (not highlighted) then "ἀγαπᾷ" (highlighted)
      final originalSpans = content.original.children!.cast<TextSpan>();
      expect(originalSpans.length, equals(2));
      expect(originalSpans[0].text, equals('ὁ '));
      expect(originalSpans[0].style?.color, isNull);
      expect(originalSpans[1].text, equals('ἀγαπᾷ'));
      expect(originalSpans[1].style?.color, equals(highlightColor));
      expect(originalSpans[1].style?.fontWeight, equals(FontWeight.bold));

      similarManager.dispose();
    });
  });

  group('HebrewGreekScreen Widget Tests', () {
    testWidgets('renders dual passages, word details, and responds to taps',
        (tester) async {
      fakeDb.words.addAll([
        OriginalWord(
          id: 1,
          originalId: 101,
          language: Language.greek,
          word: 'Ἐν',
          transliteration: 'En',
          englishGloss: 'In',
          strongsNumber: 1722,
          partOfSpeech: 'Prep',
          bsbSort: 1,
        ),
        OriginalWord(
          id: 2,
          originalId: 102,
          language: Language.greek,
          word: 'ἀρχῇ',
          transliteration: 'archē',
          englishGloss: 'the beginning',
          strongsNumber: 746,
          partOfSpeech: 'N-DFS',
          bsbSort: 2,
        ),
      ]);
      fakeDb.lexicons[1722] = '**ἐν** *in, on, at*';
      fakeDb.lexicons[746] = '**ἀρχή** *beginning, origin*';
      fakeDb.exactMatches.add(Reference(bookId: 43, chapter: 1, verse: 1));
      fakeDb.strongMatches.add(Reference(bookId: 43, chapter: 1, verse: 1));

      await tester.pumpWidget(
        const MaterialApp(
          home: HebrewGreekScreen(
            bookId: 43,
            chapter: 1,
            verse: 1,
            language: Language.greek,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify dual passage cards are displayed
      expect(find.text('English (BSB)'), findsOneWidget);
      expect(find.text('Greek'), findsOneWidget);
      expect(find.text('In'), findsWidgets);
      expect(find.text('Ἐν'), findsWidgets);

      // Verify Lexicon header and content
      expect(find.text('Abbott-Smith Greek Lexicon'), findsOneWidget);
      expect(find.textContaining('ἐν'), findsWidgets);
      expect(find.text('Bible Hub'), findsOneWidget);

      // Tap second word in English
      await tester.tap(find.text('the beginning'));
      await tester.pumpAndSettle();

      // Word details should now update to archē
      expect(find.text('archē'), findsOneWidget);
      expect(find.textContaining('ἀρχή'), findsWidgets);

      // Verify both English and Greek highlighted words have consistent primary outline border
      final screenTheme =
          Theme.of(tester.element(find.byType(HebrewGreekScreen)));
      final highlightedEnglishChip = tester.widget<Container>(
        find
            .ancestor(
              of: find.descendant(
                of: find.byType(EnglishPassageCard),
                matching: find.text('the beginning'),
              ),
              matching: find.byType(Container),
            )
            .first,
      );
      final englishBorder =
          (highlightedEnglishChip.decoration as BoxDecoration).border
              as Border;
      expect(englishBorder.top.color, equals(screenTheme.colorScheme.primary));

      final highlightedGreekChip = tester.widget<Container>(
        find
            .ancestor(
              of: find.descendant(
                of: find.byType(OriginalPassageCard),
                matching: find.text('ἀρχῇ'),
              ),
              matching: find.byType(Container),
            )
            .first,
      );
      final greekBorder =
          (highlightedGreekChip.decoration as BoxDecoration).border as Border;
      expect(greekBorder.top.color, equals(screenTheme.colorScheme.primary));
    });

    testWidgets('displays Occurrences button and navigates to SimilarVersesPage',
        (tester) async {
      fakeDb.words.add(
        OriginalWord(
          id: 1,
          originalId: 101,
          language: Language.greek,
          word: 'Ἐν',
          transliteration: 'En',
          englishGloss: 'In',
          strongsNumber: 1722,
          partOfSpeech: 'Prep',
          bsbSort: 1,
        ),
      );
      fakeDb.lexicons[1722] = '**ἐν** *in, on, at*';
      fakeDb.exactMatches.add(Reference(bookId: 43, chapter: 1, verse: 1));
      fakeDb.strongMatches.add(Reference(bookId: 43, chapter: 1, verse: 1));

      await tester.pumpWidget(
        const MaterialApp(
          home: HebrewGreekScreen(
            bookId: 43,
            chapter: 1,
            verse: 1,
            language: Language.greek,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Occurrences and Bible Hub buttons are present and aligned on the same row without wrapping
      final occurrencesBtn = find.widgetWithText(ActionChip, 'Occurrences');
      final bibleHubBtn = find.widgetWithText(ActionChip, 'Bible Hub');
      expect(occurrencesBtn, findsOneWidget);
      expect(bibleHubBtn, findsOneWidget);
      expect(tester.getTopLeft(occurrencesBtn).dy, equals(tester.getTopLeft(bibleHubBtn).dy));

      // Tap Occurrences button
      await tester.tap(occurrencesBtn);
      await tester.pumpAndSettle();

      // Verify SimilarVersesPage is shown with Exact Form and Lexical Form segmented buttons with counts
      expect(find.byType(SimilarVersesPage), findsOneWidget);
      expect(
        find.descendant(
          of: find.descendant(
            of: find.byType(SimilarVersesPage),
            matching: find.byType(AppBar),
          ),
          matching: find.text('Ἐν'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('G1722'), findsNothing);
      expect(find.text('Exact Form (1)'), findsOneWidget);
      expect(find.text('Lexical Form (1)'), findsOneWidget);

      // Verify custom icons are removed, exactly one visible check mark is displayed
      expect(find.byIcon(Icons.spellcheck), findsNothing);
      expect(find.byIcon(Icons.tag), findsNothing);
      final visibleCheck = find.byWidgetPredicate(
        (w) =>
            w is Icon &&
            w.icon == Icons.check &&
            w.color != Colors.transparent,
      );
      expect(visibleCheck, findsOneWidget);

      // Verify segment widths and text positions do not change when selection toggles
      final exactButtonFinder = find.widgetWithText(TextButton, 'Exact Form (1)');
      final lexicalButtonFinder = find.widgetWithText(TextButton, 'Lexical Form (1)');
      final initialExactWidth = tester.getSize(exactButtonFinder).width;
      final initialLexicalWidth = tester.getSize(lexicalButtonFinder).width;
      expect(initialExactWidth, equals(initialLexicalWidth));

      final initialExactTextPos = tester.getTopLeft(find.text('Exact Form (1)'));
      final initialLexicalTextPos =
          tester.getTopLeft(find.text('Lexical Form (1)'));

      // Switch selection to Lexical Form
      await tester.tap(lexicalButtonFinder);
      await tester.pumpAndSettle();

      expect(tester.getSize(exactButtonFinder).width, equals(initialExactWidth));
      expect(tester.getSize(lexicalButtonFinder).width, equals(initialLexicalWidth));
      expect(
        tester.getTopLeft(find.text('Exact Form (1)')),
        equals(initialExactTextPos),
      );
      expect(
        tester.getTopLeft(find.text('Lexical Form (1)')),
        equals(initialLexicalTextPos),
      );
      expect(visibleCheck, findsOneWidget);

      // Verify occurrence item displays both English and Greek text
      expect(find.textContaining('In'), findsWidgets);
      expect(find.textContaining('Ἐν'), findsWidgets);

      // Tap occurrence item in SimilarVersesPage
      final verseResultFinder = find.widgetWithText(ListTile, 'John 1:1');
      expect(verseResultFinder, findsOneWidget);
      await tester.tap(verseResultFinder);
      await tester.pumpAndSettle();

      // Verify VerseReferenceModal is displayed with lexicon and highlighted words
      expect(find.byType(VerseReferenceModal), findsOneWidget);
      expect(find.text('Abbott-Smith Lexicon'), findsOneWidget);
      expect(find.textContaining('in, on, at'), findsWidgets);

      // Verify the word is highlighted in English and Greek in the modal
      final BuildContext modalContext = tester.element(find.byType(VerseReferenceModal));
      final modalTheme = Theme.of(modalContext);

      final highlightedEnglishContainer = tester.widget<Container>(
        find.ancestor(
          of: find.descendant(
            of: find.byType(VerseReferenceModal),
            matching: find.text('In'),
          ),
          matching: find.byType(Container),
        ).first,
      );
      final englishBoxDecoration = highlightedEnglishContainer.decoration as BoxDecoration;
      expect(englishBoxDecoration.color, equals(modalTheme.colorScheme.primaryContainer));

      final highlightedGreekContainer = tester.widget<Container>(
        find.ancestor(
          of: find.descendant(
            of: find.byType(VerseReferenceModal),
            matching: find.text('Ἐν'),
          ),
          matching: find.byType(Container),
        ).first,
      );
      final greekBoxDecoration = highlightedGreekContainer.decoration as BoxDecoration;
      expect(greekBoxDecoration.color, equals(modalTheme.colorScheme.primaryContainer));
    });

    testWidgets('sanitizes HTML artifacts such as </span> in word punctuation',
        (tester) async {
      fakeDb.words.clear();
      fakeDb.words.add(
        OriginalWord(
          id: 1,
          originalId: 101,
          language: Language.greek,
          word: 'ὑμῖν',
          transliteration: 'hymin',
          englishGloss: 'for you',
          strongsNumber: 4771,
          partOfSpeech: 'PPro-D2P',
          punctuation: '.”</span>'.replaceAll(RegExp(r'<[^>]+>'), ''),
          bsbSort: 1,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HebrewGreekScreen(
            bookId: 40,
            chapter: 17,
            verse: 20,
            language: Language.greek,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('</span>'), findsNothing);
      expect(find.text('for you.”'), findsOneWidget);
    });

    testWidgets(
        'highlights first word in English and its corresponding Hebrew word on initial load when word orders differ',
        (tester) async {
      fakeDb.words.clear();
      fakeDb.words.addAll([
        OriginalWord(
          id: 1,
          originalId: 101,
          language: Language.hebrew,
          word: 'וַיֹּ֥אמֶר',
          transliteration: 'way·yō·mer',
          englishGloss: 'said',
          strongsNumber: 559,
          partOfSpeech: 'V-Qal',
          bsbSort: 2,
        ),
        OriginalWord(
          id: 2,
          originalId: 102,
          language: Language.hebrew,
          word: 'אֱלֹהִ֖ים',
          transliteration: '’ĕ·lō·hîm',
          englishGloss: 'God',
          strongsNumber: 430,
          partOfSpeech: 'N-mp',
          bsbSort: 1,
        ),
      ]);
      fakeDb.lexicons[430] = '**אֱלֹהִים** *God, deity*';
      fakeDb.lexicons[559] = '**אָמַר** *to say*';

      await tester.pumpWidget(
        const MaterialApp(
          home: HebrewGreekScreen(
            bookId: 1,
            chapter: 1,
            verse: 3,
            language: Language.hebrew,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final screenTheme =
          Theme.of(tester.element(find.byType(HebrewGreekScreen)));

      // Verify the first English word 'God' is highlighted with primary outline border
      final godChip = tester.widget<Container>(
        find.ancestor(
          of: find.descendant(
            of: find.byType(EnglishPassageCard),
            matching: find.text('God'),
          ),
          matching: find.byType(Container),
        ).first,
      );
      final godBorder = (godChip.decoration as BoxDecoration).border as Border;
      expect(godBorder.top.color, equals(screenTheme.colorScheme.primary));

      // Verify the corresponding Hebrew word 'אֱלֹהִ֖ים' (not the first Hebrew word 'וַיֹּ֥אמֶר') is highlighted
      final elohimChip = tester.widget<Container>(
        find.ancestor(
          of: find.descendant(
            of: find.byType(OriginalPassageCard),
            matching: find.text('אֱלֹהִ֖ים'),
          ),
          matching: find.byType(Container),
        ).first,
      );
      final elohimBorder =
          (elohimChip.decoration as BoxDecoration).border as Border;
      expect(elohimBorder.top.color, equals(screenTheme.colorScheme.primary));

      // The unselected first Hebrew word 'וַיֹּ֥אמֶר' should NOT have primary border
      final saidChip = tester.widget<Container>(
        find.ancestor(
          of: find.descendant(
            of: find.byType(OriginalPassageCard),
            matching: find.text('וַיֹּ֥אמֶר'),
          ),
          matching: find.byType(Container),
        ).first,
      );
      final saidBorder =
          (saidChip.decoration as BoxDecoration).border as Border;
      expect(saidBorder.top.color, isNot(equals(screenTheme.colorScheme.primary)));

      // Verify Hebrew transliteration pronunciation is rendered
      expect(find.text('’ĕ·lō·hîm'), findsOneWidget);
    });

    testWidgets(
        'bidirectional multi-word cluster highlighting and Translated as part of display',
        (tester) async {
      fakeDb.words.addAll([
        OriginalWord(
          id: 1,
          originalId: 101,
          language: Language.hebrew,
          word: 'זֹרֵ֣עַ',
          transliteration: 'zō·rê·a‘',
          englishGloss: 'vvv',
          strongsNumber: 2232,
          partOfSpeech: 'V-Qal-Ptc-ms',
          bsbSort: 659,
        ),
        OriginalWord(
          id: 2,
          originalId: 102,
          language: Language.hebrew,
          word: 'זֶ֗רַע',
          transliteration: 'ze·ra‘',
          englishGloss: 'seed-bearing',
          strongsNumber: 2233,
          partOfSpeech: 'N-ms',
          bsbSort: 660,
        ),
        OriginalWord(
          id: 3,
          originalId: 103,
          language: Language.hebrew,
          word: 'עֵ֥שֶׂב',
          transliteration: '‘ê·śeḇ',
          englishGloss: 'plant',
          strongsNumber: 6212,
          partOfSpeech: 'N-ms',
          bsbSort: 661,
        ),
      ]);
      fakeDb.lexicons[2232] = '**זָרַע** *to sow, scatter seed*';
      fakeDb.lexicons[2233] = '**זֶרַע** *seed, sowing, offspring*';
      fakeDb.lexicons[6212] = '**עֵשֶׂב** *herb, plant, grass*';

      await tester.pumpWidget(
        const MaterialApp(
          home: HebrewGreekScreen(
            bookId: 1,
            chapter: 1,
            verse: 29,
            language: Language.hebrew,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final screenTheme =
          Theme.of(tester.element(find.byType(HebrewGreekScreen)));

      // 1. English passage card does not show 'vvv', but shows 'seed-bearing' and 'plant'
      expect(
        find.descendant(
          of: find.byType(EnglishPassageCard),
          matching: find.text('vvv'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(EnglishPassageCard),
          matching: find.text('seed-bearing'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(EnglishPassageCard),
          matching: find.text('plant'),
        ),
        findsOneWidget,
      );

      // Helper to check highlight border
      Border getBorder(Finder finder) {
        final container = tester.widget<Container>(
          find.ancestor(of: finder, matching: find.byType(Container)).first,
        );
        return (container.decoration as BoxDecoration).border as Border;
      }

      final seedEnglishFinder = find.descendant(
        of: find.byType(EnglishPassageCard),
        matching: find.text('seed-bearing'),
      );
      final zoreaFinder = find.descendant(
        of: find.byType(OriginalPassageCard),
        matching: find.text('זֹרֵ֣עַ'),
      );
      final zeraFinder = find.descendant(
        of: find.byType(OriginalPassageCard),
        matching: find.text('זֶ֗רַע'),
      );
      final esevFinder = find.descendant(
        of: find.byType(OriginalPassageCard),
        matching: find.text('עֵ֥שֶׂב'),
      );

      // Initially, the first English word ("seed-bearing") is selected.
      // Both Hebrew words in the cluster (זֹרֵ֣עַ and זֶ֗רַע) should be highlighted.
      expect(
        getBorder(seedEnglishFinder).top.color,
        equals(screenTheme.colorScheme.primary),
      );
      expect(
        getBorder(zoreaFinder).top.color,
        equals(screenTheme.colorScheme.primary),
      );
      expect(
        getBorder(zeraFinder).top.color,
        equals(screenTheme.colorScheme.primary),
      );
      expect(
        getBorder(esevFinder).top.color,
        isNot(equals(screenTheme.colorScheme.primary)),
      );

      // 2. Now tap the vvv Hebrew word 'זֹרֵ֣עַ'
      await tester.tap(zoreaFinder);
      await tester.pumpAndSettle();

      // Both Hebrew words in cluster and English seed-bearing remain highlighted
      expect(
        getBorder(seedEnglishFinder).top.color,
        equals(screenTheme.colorScheme.primary),
      );
      expect(
        getBorder(zoreaFinder).top.color,
        equals(screenTheme.colorScheme.primary),
      );
      expect(
        getBorder(zeraFinder).top.color,
        equals(screenTheme.colorScheme.primary),
      );
      expect(
        getBorder(esevFinder).top.color,
        isNot(equals(screenTheme.colorScheme.primary)),
      );

      // Word details card shows 'Translated as part of "seed-bearing"' and word 1's details
      expect(find.text('Translated as part of "seed-bearing"'), findsOneWidget);
      expect(find.text('V-Qal-Ptc-ms'), findsOneWidget);
      expect(find.textContaining('to sow, scatter seed'), findsWidgets);

      // 3. Tap 'עֵ֥שֶׂב'
      await tester.tap(esevFinder);
      await tester.pumpAndSettle();

      expect(
        getBorder(seedEnglishFinder).top.color,
        isNot(equals(screenTheme.colorScheme.primary)),
      );
      expect(
        getBorder(zoreaFinder).top.color,
        isNot(equals(screenTheme.colorScheme.primary)),
      );
      expect(
        getBorder(zeraFinder).top.color,
        isNot(equals(screenTheme.colorScheme.primary)),
      );
      expect(
        getBorder(esevFinder).top.color,
        equals(screenTheme.colorScheme.primary),
      );
      expect(find.text('Translated as part of "seed-bearing"'), findsNothing);

      // 4. Tap English 'seed-bearing' again
      await tester.tap(seedEnglishFinder);
      await tester.pumpAndSettle();

      // Cluster is re-highlighted
      expect(
        getBorder(seedEnglishFinder).top.color,
        equals(screenTheme.colorScheme.primary),
      );
      expect(
        getBorder(zoreaFinder).top.color,
        equals(screenTheme.colorScheme.primary),
      );
      expect(
        getBorder(zeraFinder).top.color,
        equals(screenTheme.colorScheme.primary),
      );
      expect(
        getBorder(esevFinder).top.color,
        isNot(equals(screenTheme.colorScheme.primary)),
      );
      expect(find.text('N-ms'), findsOneWidget);
      expect(find.textContaining('seed, sowing, offspring'), findsWidgets);
    });
  });

  group('Reference Resolution & Modal Sheets', () {
    test('resolveReferenceString resolves packed integers correctly', () {
      final refJob = resolveReferenceString('18008012');
      expect(refJob, isNotNull);
      expect(refJob!.bookId, equals(18));
      expect(refJob.chapter, equals(8));
      expect(refJob.verse, equals(12));
      expect(refJob.toString(), equals('Job 8:12'));

      final refNum = resolveReferenceString('4021030');
      expect(refNum, isNotNull);
      expect(refNum!.bookId, equals(4));
      expect(refNum.chapter, equals(21));
      expect(refNum.verse, equals(30));
      expect(refNum.toString(), equals('Numbers 21:30'));
    });

    test('resolveReferenceString resolves OSIS book strings', () {
      final refLuke = resolveReferenceString('Luke.1.5');
      expect(refLuke, isNotNull);
      expect(refLuke!.bookId, equals(42));
      expect(refLuke.chapter, equals(1));
      expect(refLuke.verse, equals(5));

      final refExod = resolveReferenceString('Exod.4.14');
      expect(refExod, isNotNull);
      expect(refExod!.bookId, equals(2));
      expect(refExod.chapter, equals(4));
      expect(refExod.verse, equals(14));
    });

    test('resolveReferenceString resolves canonical human strings', () {
      final refGen = resolveReferenceString('Genesis 1:1');
      expect(refGen, isNotNull);
      expect(refGen!.bookId, equals(1));
      expect(refGen.chapter, equals(1));
      expect(refGen.verse, equals(1));
    });

    testWidgets('VerseReferenceModal renders English, original words, and lexicon', (tester) async {
      final ref = Reference(bookId: 18, chapter: 8, verse: 12);
      fakeDb.verseTexts[ref.packedVerse] = 'While yet in its freshness, it is cut down.';
      fakeDb.words.clear();
      fakeDb.words.addAll([
        OriginalWord(
          id: 10,
          originalId: 1001,
          language: Language.hebrew,
          word: 'עֹדֶנּוּ',
          transliteration: "'ō·ḏen·nū",
          englishGloss: 'While yet',
          strongsNumber: 5750,
          partOfSpeech: 'Adv',
          bsbSort: 1,
        ),
        OriginalWord(
          id: 11,
          originalId: 1002,
          language: Language.hebrew,
          word: 'בְאִבּוֺ',
          transliteration: 'ḇə·’ib·bōw',
          englishGloss: 'in its freshness',
          strongsNumber: 3,
          partOfSpeech: 'Prep-b | N-msc',
          bsbSort: 2,
        ),
      ]);
      fakeDb.lexicons[3] = '[אֵב] **freshness, fresh green**';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseReferenceModal(
              reference: ref,
              initialStrongs: 3,
              dbHelper: fakeDb,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Job 8:12'), findsOneWidget);

      // Verify English words are displayed as interactive spans
      expect(find.text('While yet'), findsOneWidget);
      expect(find.text('in its freshness'), findsWidgets);

      // Verify Hebrew words
      expect(find.text('עֹדֶנּוּ'), findsWidgets);
      expect(find.text('בְאִבּוֺ'), findsWidgets);

      // Verify initial selected word (H3: בְאִבּוֺ / in its freshness) lexicon content
      expect(find.textContaining('freshness, fresh green'), findsWidgets);
      expect(find.text('H3'), findsOneWidget);

      // Tap first English word ('While yet')
      await tester.tap(find.text('While yet'));
      await tester.pumpAndSettle();

      // Should now show word details for עֹדֶנּוּ (H5750)
      expect(find.text("'ō·ḏen·nū"), findsOneWidget);
      expect(find.text('H5750'), findsOneWidget);

      // Verify that selecting words does not apply bold font weight (avoids layout shift)
      final selectedEnglish =
          tester.widget<Text>(find.text('While yet').first);
      expect(selectedEnglish.style?.fontWeight, equals(FontWeight.normal));
      final selectedHebrew = tester.widget<Text>(find.text('עֹדֶנּוּ').first);
      expect(selectedHebrew.style?.fontWeight, equals(FontWeight.normal));

      // Tap second Hebrew word ('בְאִבּוֺ')
      await tester.tap(find.text('בְאִבּוֺ').first);
      await tester.pumpAndSettle();

      // Should switch back to H3
      expect(find.text('ḇə·’ib·bōw'), findsOneWidget);
      expect(find.text('H3'), findsOneWidget);
      final unselectedEnglish =
          tester.widget<Text>(find.text('While yet').first);
      expect(unselectedEnglish.style?.fontWeight, equals(FontWeight.normal));

      // Verify Occurrences button is present and navigates to SimilarVersesPage
      final occurrencesBtn = find.widgetWithText(ActionChip, 'Occurrences');
      expect(occurrencesBtn, findsOneWidget);
      await tester.ensureVisible(occurrencesBtn);
      await tester.pumpAndSettle();
      await tester.tap(occurrencesBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SimilarVersesPage), findsOneWidget);
      expect(find.textContaining('Exact Form'), findsOneWidget);
      expect(find.textContaining('Lexical Form'), findsOneWidget);
    });

    testWidgets('LexiconEntryModal renders lemma content', (tester) async {
      fakeDb.lemmaLexicons['אִנְבֵּהּ'] = '**אִנְבֵּהּ** *fruit (Aramaic)*';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LexiconEntryModal(
              lemma: 'אִנְבֵּהּ',
              language: Language.aramaic,
              dbHelper: fakeDb,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('אִנְבֵּהּ'), findsOneWidget);
      expect(find.textContaining('fruit (Aramaic)'), findsWidgets);
    });

    testWidgets(
        'Lexicon Markdown links are styled with theme primary color',
        (tester) async {
      const customPrimary = Color(0xFF8B1E3F);
      fakeDb.lemmaLexicons['בֵּין'] =
          '**בֵּין** between; see [Job 8:12](ref://18008012)';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: customPrimary).copyWith(
              primary: customPrimary,
            ),
          ),
          home: Scaffold(
            body: LexiconEntryModal(
              lemma: 'בֵּין',
              language: Language.hebrew,
              dbHelper: fakeDb,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final markdownWidget =
          tester.widget<MarkdownBody>(find.byType(MarkdownBody));
      expect(markdownWidget.styleSheet?.a?.color, equals(customPrimary));
      expect(markdownWidget.styleSheet?.a?.decorationColor,
          equals(customPrimary));
    });
  });
}
