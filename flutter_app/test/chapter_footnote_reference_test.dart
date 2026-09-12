import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:bsb/ui/text/chapter/chapter_manager.dart';
import 'package:bsb/ui/text/chapter/chapter_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeDatabaseHelper implements DatabaseHelper {
  Reference? lastRequestedReference;
  List<UsfmLine> returnLines = [];
  List<UsfmLine>? chapterLines;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async {
    return chapterLines ??
        [
          UsfmLine(
            bookChapterVerse: 2004006,
            text:
                r'his hand was leprous,\f + \fr 4:6 \ft The Hebrew word traditionally translated as \fqa leprous\fqa* was used for various skin diseases; see Leviticus 13.\f* white as snow.',
            format: ParagraphFormat.p,
          ),
        ];
  }

  @override
  Future<List<UsfmLine>> getRange(Reference reference) async {
    lastRequestedReference = reference;
    return returnLines.isNotEmpty
        ? returnLines
        : [
            UsfmLine(
              bookChapterVerse: 3013001,
              text: 'The LORD said to Moses and Aaron...',
              format: ParagraphFormat.p,
            ),
          ];
  }
}

class FakeAnnotationDbHelper implements AnnotationDatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Highlight>> getHighlightsForChapter(int bookId, int chapter) async => [];

  @override
  Future<List<Note>> getNotesForChapter(int bookId, int chapter) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDatabaseHelper fakeDb;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    getIt.reset();

    final userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);

    fakeDb = FakeDatabaseHelper();
    getIt.registerSingleton<DatabaseHelper>(fakeDb);
    final annotationDb = FakeAnnotationDbHelper();
    getIt.registerSingleton<AnnotationDatabaseHelper>(annotationDb);
    getIt.registerSingleton<AnnotationService>(
      AnnotationService(dbHelper: annotationDb),
    );

    final tabManager = TabManager();
    await tabManager.init();
    getIt.registerSingleton<TabManager>(tabManager);
  });

  tearDown(() {
    getIt.reset();
  });

  group('Reference.tryParse', () {
    test('parses chapter and verse', () {
      final ref = Reference.tryParse('John 3:16');
      expect(ref, isNotNull);
      expect(ref!.bookId, equals(43));
      expect(ref.chapter, equals(3));
      expect(ref.verse, equals(16));
      expect(ref.endVerse, isNull);
      expect(ref.endChapter, isNull);
    });

    test('parses verse range with en-dash', () {
      final ref = Reference.tryParse('Romans 1:1–3');
      expect(ref, isNotNull);
      expect(ref!.bookId, equals(45));
      expect(ref.chapter, equals(1));
      expect(ref.verse, equals(1));
      expect(ref.endVerse, equals(3));
      expect(ref.endChapter, isNull);
    });

    test('parses verse range with hyphen', () {
      final ref = Reference.tryParse('Romans 1:1-3');
      expect(ref, isNotNull);
      expect(ref!.bookId, equals(45));
      expect(ref.chapter, equals(1));
      expect(ref.verse, equals(1));
      expect(ref.endVerse, equals(3));
      expect(ref.endChapter, isNull);
    });

    test('parses single chapter without verse', () {
      final ref = Reference.tryParse('Leviticus 13');
      expect(ref, isNotNull);
      expect(ref!.bookId, equals(3));
      expect(ref.chapter, equals(13));
      expect(ref.verse, isNull);
      expect(ref.endVerse, isNull);
      expect(ref.endChapter, isNull);
    });

    test('parses Psalm and Psalms chapter without verse', () {
      final psalm16 = Reference.tryParse('Psalm 16');
      expect(psalm16, isNotNull);
      expect(psalm16!.bookId, equals(19));
      expect(psalm16.chapter, equals(16));
      expect(psalm16.verse, isNull);

      final psalms81 = Reference.tryParse('Psalms 81');
      expect(psalms81, isNotNull);
      expect(psalms81!.bookId, equals(19));
      expect(psalms81.chapter, equals(81));
      expect(psalms81.verse, isNull);
    });

    test('parses chapter range with en-dash', () {
      final ref = Reference.tryParse('1 Samuel 21–29');
      expect(ref, isNotNull);
      expect(ref!.bookId, equals(9));
      expect(ref.chapter, equals(21));
      expect(ref.verse, isNull);
      expect(ref.endVerse, isNull);
      expect(ref.endChapter, equals(29));
    });

    test('parses chapter range with hyphen', () {
      final ref = Reference.tryParse('1 Samuel 21-29');
      expect(ref, isNotNull);
      expect(ref!.bookId, equals(9));
      expect(ref.chapter, equals(21));
      expect(ref.verse, isNull);
      expect(ref.endVerse, isNull);
      expect(ref.endChapter, equals(29));
    });

    test('parses Psalms range', () {
      final ref = Reference.tryParse('Psalms 56–60');
      expect(ref, isNotNull);
      expect(ref!.bookId, equals(19));
      expect(ref.chapter, equals(56));
      expect(ref.verse, isNull);
      expect(ref.endChapter, equals(60));
    });

    test('parses multi-word books with chapter and chapter range', () {
      final ch = Reference.tryParse('Song of Solomon 2');
      expect(ch, isNotNull);
      expect(ch!.bookId, equals(22));
      expect(ch.chapter, equals(2));
      expect(ch.verse, isNull);

      final range = Reference.tryParse('Song of Solomon 2–4');
      expect(range, isNotNull);
      expect(range!.bookId, equals(22));
      expect(range.chapter, equals(2));
      expect(range.endChapter, equals(4));
    });

    test('parses numbered books with single chapter', () {
      final ref = Reference.tryParse('2 Kings 18');
      expect(ref, isNotNull);
      expect(ref!.bookId, equals(12));
      expect(ref.chapter, equals(18));
      expect(ref.verse, isNull);
    });

    test('returns null for invalid references', () {
      expect(Reference.tryParse(''), isNull);
      expect(Reference.tryParse('John'), isNull);
      expect(Reference.tryParse('John 999'), isNull);
      expect(Reference.tryParse('Leviticus 999'), isNull);
      expect(Reference.tryParse('1 Samuel 29–21'), isNull);
      expect(Reference.tryParse('Romans 1:5–2'), isNull);
      expect(Reference.tryParse('NonexistentBook 1:1'), isNull);
    });
  });

  group('Reference packed bounds and toString', () {
    test('single chapter packed bounds', () {
      final ref = Reference(bookId: 3, chapter: 13);
      expect(ref.packedVerse, equals(3013000));
      expect(ref.packedEndVerse, equals(3013999));
      expect(ref.toString(), equals('Leviticus 13'));
    });

    test('chapter range packed bounds', () {
      final ref = Reference(bookId: 9, chapter: 21, endChapter: 29);
      expect(ref.packedVerse, equals(9021000));
      expect(ref.packedEndVerse, equals(9029999));
      expect(ref.toString(), equals('1 Samuel 21–29'));
    });

    test('psalms chapter range toString uses Psalms', () {
      final ref = Reference(bookId: 19, chapter: 56, endChapter: 60);
      expect(ref.toString(), equals('Psalms 56–60'));
    });

    test('single verse packed bounds', () {
      final ref = Reference(bookId: 43, chapter: 3, verse: 16);
      expect(ref.packedVerse, equals(43003016));
      expect(ref.packedEndVerse, isNull);
      expect(ref.toString(), equals('John 3:16'));
    });

    test('verse range packed bounds', () {
      final ref = Reference(bookId: 43, chapter: 3, verse: 16, endVerse: 18);
      expect(ref.packedVerse, equals(43003016));
      expect(ref.packedEndVerse, equals(43003018));
      expect(ref.toString(), equals('John 3:16–18'));
    });
  });

  group('ChapterManager footnote keywords and lookup', () {
    test('footnoteKeywords regex matches single chapter and chapter ranges', () {
      final manager = ChapterManager();

      final regex = manager.footnoteKeywords();

      expect(regex.hasMatch('Leviticus 13'), isTrue);
      expect(regex.hasMatch('Job 1'), isTrue);
      expect(regex.hasMatch('Psalm 16'), isTrue);
      expect(regex.hasMatch('Psalms 56–60'), isTrue);
      expect(regex.hasMatch('Psalms 56-60'), isTrue);
      expect(regex.hasMatch('1 Samuel 21–29'), isTrue);
      expect(regex.hasMatch('Ezekiel 40–48'), isTrue);
      expect(regex.hasMatch('2 Kings 18'), isTrue);

      // Book name alone should not match
      expect(regex.hasMatch('In John we see'), isFalse);
      manager.dispose();
    });

    test('lookupFootnoteDetails retrieves correct range for single chapter', () async {
      final manager = ChapterManager();

      await manager.lookupFootnoteDetails('Leviticus 13');
      expect(fakeDb.lastRequestedReference, isNotNull);
      expect(fakeDb.lastRequestedReference!.bookId, equals(3));
      expect(fakeDb.lastRequestedReference!.chapter, equals(13));
      expect(fakeDb.lastRequestedReference!.verse, isNull);
      expect(fakeDb.lastRequestedReference!.packedVerse, equals(3013000));
      expect(fakeDb.lastRequestedReference!.packedEndVerse, equals(3013999));
      manager.dispose();
    });

    test('lookupFootnoteDetails retrieves correct range for chapter range', () async {
      final manager = ChapterManager();

      await manager.lookupFootnoteDetails('1 Samuel 21–29');
      expect(fakeDb.lastRequestedReference, isNotNull);
      expect(fakeDb.lastRequestedReference!.bookId, equals(9));
      expect(fakeDb.lastRequestedReference!.chapter, equals(21));
      expect(fakeDb.lastRequestedReference!.endChapter, equals(29));
      expect(fakeDb.lastRequestedReference!.packedVerse, equals(9021000));
      expect(fakeDb.lastRequestedReference!.packedEndVerse, equals(9029999));
      manager.dispose();
    });
  });

  group('formatFootnote with chapter references', () {
    test('renders single chapter reference as clickable span', () {
      final manager = ChapterManager();

      String? tappedKeyword;
      int? tappedCount;

      final span = formatFootnote(
        footnote:
            r'A \fqa leper\fqa* was one afflicted with a skin disease; see Leviticus 13.',
        highlightColor: Colors.blue,
        keywords: manager.footnoteKeywords(),
        onTapKeyword: (kw, count) {
          tappedKeyword = kw;
          tappedCount = count;
        },
      );

      final plainText = span.toPlainText();
      expect(plainText, contains('Leviticus 13'));

      // Find the span for Leviticus 13
      final levSpan = span.children!.firstWhere(
        (child) => (child as TextSpan).text == 'Leviticus 13',
      ) as TextSpan;

      expect(levSpan.style?.color, equals(Colors.blue));
      expect(levSpan.recognizer, isA<TapGestureRecognizer>());

      // Simulate tap
      (levSpan.recognizer as TapGestureRecognizer).onTap!();
      expect(tappedKeyword, equals('Leviticus 13'));
      expect(tappedCount, equals(1));
      manager.dispose();
    });

    test('renders chapter range reference as clickable span', () {
      final manager = ChapterManager();

      final tappedKeywords = <String>[];

      final span = formatFootnote(
        footnote:
            r'\fqa Abimelech\fqa* is another name for \fqa Achish\fqa*; see 1 Samuel 21–29 and 1 Kings 2:39.',
        highlightColor: Colors.blue,
        keywords: manager.footnoteKeywords(),
        onTapKeyword: (kw, count) {
          tappedKeywords.add(kw);
        },
      );

      // Verify both references are present as clickable spans
      final samuelSpan = span.children!.firstWhere(
        (child) => (child as TextSpan).text == '1 Samuel 21–29',
      ) as TextSpan;
      expect(samuelSpan.style?.color, equals(Colors.blue));
      (samuelSpan.recognizer as TapGestureRecognizer).onTap!();

      final kingsSpan = span.children!.firstWhere(
        (child) => (child as TextSpan).text == '1 Kings 2:39',
      ) as TextSpan;
      expect(kingsSpan.style?.color, equals(Colors.blue));
      (kingsSpan.recognizer as TapGestureRecognizer).onTap!();

      expect(tappedKeywords, equals(['1 Samuel 21–29', '1 Kings 2:39']));
      manager.dispose();
    });

    test('renders multiple chapter references including Psalm and Psalms range', () {
      final manager = ChapterManager();

      final tappedKeywords = <String>[];

      final span = formatFootnote(
        footnote:
            r'\fqa Miktam\fqa* is probably a musical or liturgical term; used for Psalm 16 and Psalms 56–60.',
        highlightColor: Colors.blue,
        keywords: manager.footnoteKeywords(),
        onTapKeyword: (kw, count) {
          tappedKeywords.add(kw);
        },
      );

      final psalmSpan = span.children!.firstWhere(
        (child) => (child as TextSpan).text == 'Psalm 16',
      ) as TextSpan;
      (psalmSpan.recognizer as TapGestureRecognizer).onTap!();

      final psalmsRangeSpan = span.children!.firstWhere(
        (child) => (child as TextSpan).text == 'Psalms 56–60',
      ) as TextSpan;
      (psalmsRangeSpan.recognizer as TapGestureRecognizer).onTap!();

      expect(tappedKeywords, equals(['Psalm 16', 'Psalms 56–60']));
      manager.dispose();
    });

    testWidgets('ChapterText footnote dialog allows tapping chapter-only reference', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChapterText(
              bookId: 2,
              chapter: 4,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find footnote marker and tap it
      expect(find.byType(FootnoteWidget), findsOneWidget);
      await tester.tap(find.byType(FootnoteWidget));
      await tester.pumpAndSettle();

      // Footnote dialog is now visible
      expect(find.byType(AlertDialog), findsOneWidget);

      // Verify SelectableText.rich contains Leviticus 13
      final selectableFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(SelectableText),
      );
      expect(selectableFinder, findsOneWidget);

      final selectableWidget = tester.widget<SelectableText>(selectableFinder);
      final textSpan = selectableWidget.textSpan!;
      final plainText = textSpan.toPlainText();
      expect(plainText, contains('Leviticus 13'));

      // Find the Leviticus 13 span and trigger its onTap
      final levSpan = textSpan.children!.firstWhere(
        (child) => (child as TextSpan).text == 'Leviticus 13',
      ) as TextSpan;
      expect(levSpan.recognizer, isA<TapGestureRecognizer>());
      (levSpan.recognizer as TapGestureRecognizer).onTap!();

      await tester.pumpAndSettle();

      // The original dialog should be dismissed and details dialog is shown
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Leviticus 13'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Dialog), matching: find.byType(UsfmWidget)),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => w is WordWidget && w.text == 'Moses'),
        findsOneWidget,
      );

      // Verify database helper was called with the correct Reference
      expect(fakeDb.lastRequestedReference, isNotNull);
      expect(fakeDb.lastRequestedReference!.bookId, equals(3));
      expect(fakeDb.lastRequestedReference!.chapter, equals(13));
      expect(fakeDb.lastRequestedReference!.verse, isNull);
      expect(fakeDb.lastRequestedReference!.packedVerse, equals(3013000));
      expect(fakeDb.lastRequestedReference!.packedEndVerse, equals(3013999));

      // Verify open-in-new-tab icon is shown and tap it
      final openInNewButton = find.descendant(
        of: find.byType(Dialog),
        matching: find.byIcon(Icons.open_in_new),
      );
      expect(openInNewButton, findsOneWidget);

      await tester.tap(openInNewButton);
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);

      // Verify TabManager opened Leviticus 13 with no target verse
      final tabManager = getIt<TabManager>();
      expect(tabManager.tabs.length, equals(1));
      expect(tabManager.activeTab?.bookId, equals(3));
      expect(tabManager.activeTab?.chapter, equals(13));
      expect(tabManager.activeTab?.targetVerse, isNull);
    });

    testWidgets('Footnote reference with verse shows open-in-new-tab icon and opens tab with target verse', (tester) async {
      fakeDb.chapterLines = [
        UsfmLine(
          bookChapterVerse: 40001001,
          text: r'The record of the genealogy of Jesus.\f + \fr 1:1 \ft For details see John 3:16.\f*',
          format: ParagraphFormat.p,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChapterText(
              bookId: 40,
              chapter: 1,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FootnoteWidget), findsOneWidget);
      await tester.tap(find.byType(FootnoteWidget));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      final selectableFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(SelectableText),
      );
      final selectableWidget = tester.widget<SelectableText>(selectableFinder);
      final textSpan = selectableWidget.textSpan!;
      final johnSpan = textSpan.children!.firstWhere(
        (child) => (child as TextSpan).text == 'John 3:16',
      ) as TextSpan;
      (johnSpan.recognizer as TapGestureRecognizer).onTap!();

      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('John 3:16'), findsOneWidget);

      final openInNewButton = find.descendant(
        of: find.byType(Dialog),
        matching: find.byIcon(Icons.open_in_new),
      );
      expect(openInNewButton, findsOneWidget);

      await tester.tap(openInNewButton);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      final tabManager = getIt<TabManager>();
      expect(tabManager.tabs.length, equals(1));
      expect(tabManager.activeTab?.bookId, equals(43));
      expect(tabManager.activeTab?.chapter, equals(3));
      expect(tabManager.activeTab?.targetVerse, equals(16));
    });

    testWidgets('Footnote details dialog does not show open-in-new-tab icon for non-biblical keyword', (tester) async {
      fakeDb.chapterLines = [
        UsfmLine(
          bookChapterVerse: 40001001,
          text: r'The record.\f + \fr 1:1 \ft Compare with LXX.\f*',
          format: ParagraphFormat.p,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChapterText(
              bookId: 40,
              chapter: 1,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FootnoteWidget), findsOneWidget);
      await tester.tap(find.byType(FootnoteWidget));
      await tester.pumpAndSettle();

      final selectableFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(SelectableText),
      );
      final selectableWidget = tester.widget<SelectableText>(selectableFinder);
      final textSpan = selectableWidget.textSpan!;
      final lxxSpan = textSpan.children!.firstWhere(
        (child) => (child as TextSpan).text == 'LXX',
      ) as TextSpan;
      (lxxSpan.recognizer as TapGestureRecognizer).onTap!();

      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('LXX'), findsOneWidget);

      final openInNewButton = find.descendant(
        of: find.byType(Dialog),
        matching: find.byIcon(Icons.open_in_new),
      );
      expect(openInNewButton, findsNothing);
    });
  });
}

