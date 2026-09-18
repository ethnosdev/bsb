import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/text/chapter/chapter_text.dart';
import 'package:bsb/ui/text/chapter/verse_scrubber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeChapterScrollDbHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async {
    if (chapter == 119) {
      return List.generate(
        50,
        (i) => UsfmLine(
          bookChapterVerse: bookId * 1000000 + chapter * 1000 + (i + 1),
          text:
              'This is verse ${i + 1} with lots of words to ensure the text extends well past the viewport and creates scrollable content. ' *
              4,
          format: (i % 2 == 0) ? ParagraphFormat.m : ParagraphFormat.p,
        ),
      );
    }
    return [
      UsfmLine(
        bookChapterVerse: 1001001,
        text: 'In the beginning God created the heavens and the earth.',
        format: ParagraphFormat.p,
      ),
      UsfmLine(
        bookChapterVerse: 1001002,
        text: 'Now the earth was formless and void, and darkness was over the surface of the deep.',
        format: ParagraphFormat.p,
      ),
      UsfmLine(
        bookChapterVerse: 1001003,
        text: 'And God said, “Let there be light,” and there was light.',
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

  late UserSettings userSettings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    getIt.reset();

    userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);

    getIt.registerSingleton<DatabaseHelper>(FakeChapterScrollDbHelper());

    final annotationDb = FakeAnnotationDbHelper();
    getIt.registerSingleton<AnnotationDatabaseHelper>(annotationDb);
    getIt.registerSingleton<AnnotationService>(
      AnnotationService(dbHelper: annotationDb),
    );
  });

  tearDown(() {
    getIt.reset();
  });

  testWidgets('ChapterText renders and mounts with targetVerse without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChapterText(
            bookId: 1,
            chapter: 1,
            targetVerse: 3,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChapterText), findsOneWidget);
    expect(find.byType(UsfmWidget), findsOneWidget);
    expect(find.byType(SelectableScripture), findsOneWidget);
  });

  testWidgets('ChapterText invokes onTargetVerseScrolled when targetVerse is reached and does not re-trigger on rebuild', (tester) async {
    int targetScrolledCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return ChapterText(
                bookId: 1,
                chapter: 1,
                targetVerse: 3,
                onTargetVerseScrolled: () {
                  targetScrolledCount++;
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(targetScrolledCount, equals(1));

    // Rebuild ChapterText (e.g. simulating parent setState or selection change)
    await tester.pump();
    await tester.pumpAndSettle();

    // Must not trigger again
    expect(targetScrolledCount, equals(1));
  });

  testWidgets(
    'Using verse scrubber does not cause ChapterText to scroll back to initial targetVerse when scrubber auto hides',
    (tester) async {
      int targetScrolledCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChapterText(
              bookId: 19,
              chapter: 119,
              targetVerse: 40,
              onTargetVerseScrolled: () {
                targetScrolledCount++;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(targetScrolledCount, equals(1));

      final scrollableFinder = find.byType(SingleChildScrollView);
      final scrollPosition = tester.state<ScrollableState>(
        find.descendant(of: scrollableFinder, matching: find.byType(Scrollable)),
      ).position;
      final initialScrollOffset = scrollPosition.pixels;

      final scrubberFinder = find.byType(VerseScrubber);
      expect(scrubberFinder, findsOneWidget);

      final scrubberWidget = tester.widget<VerseScrubber>(scrubberFinder);
      scrubberWidget.onVerseSelected(1);
      await tester.pumpAndSettle();

      final scrubbedOffset = tester.state<ScrollableState>(
        find.descendant(of: scrollableFinder, matching: find.byType(Scrollable)),
      ).position.pixels;

      // Scrolling to verse 1 should move scroll position to 0 (top)
      expect(scrubbedOffset, equals(0.0));
      expect(scrubbedOffset, isNot(equals(initialScrollOffset)));

      // Auto-hide timeout for verse scrubber is 3 seconds
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // targetScrolledCount must not have incremented
      expect(targetScrolledCount, equals(1));

      // Scroll position must remain at 0, not jump back down to verse 10
      final offsetAfterAutoHide = tester.state<ScrollableState>(
        find.descendant(of: scrollableFinder, matching: find.byType(Scrollable)),
      ).position.pixels;
      expect(offsetAfterAutoHide, equals(0.0));
    },
  );
}
