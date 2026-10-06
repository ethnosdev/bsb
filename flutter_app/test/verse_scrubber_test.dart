import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/home/chapter_chooser.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:bsb/ui/text/chapter/chapter_text.dart';
import 'package:bsb/ui/text/chapter/verse_scrubber.dart';
import 'package:bsb/ui/text/text_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeTenVerseDbHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async {
    return List.generate(
      10,
      (i) => UsfmLine(
        bookChapterVerse: bookId * 1000000 + chapter * 1000 + (i + 1),
        text:
            'This is verse text ${i + 1}. In the beginning God created the heavens and the earth. Now the earth was formless and void, and darkness was over the surface of the deep.',
        format: ParagraphFormat.p,
      ),
    );
  }
}

class FakeThreeVerseDbHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async {
    return List.generate(
      3,
      (i) => UsfmLine(
        bookChapterVerse: bookId * 1000000 + chapter * 1000 + (i + 1),
        text:
            'Long verse text ${i + 1} that overflows the screen vertically. In the beginning God created the heavens and the earth.',
        format: ParagraphFormat.p,
      ),
    );
  }
}

class FakeFiveVerseShortDbHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async {
    return List.generate(
      5,
      (i) => UsfmLine(
        bookChapterVerse: bookId * 1000000 + chapter * 1000 + (i + 1),
        text: 'V${i + 1}.',
        format: ParagraphFormat.p,
      ),
    );
  }
}

class FakeFiveVerseLongDbHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async {
    return List.generate(
      5,
      (i) => UsfmLine(
        bookChapterVerse: bookId * 1000000 + chapter * 1000 + (i + 1),
        text:
            'This is verse text ${i + 1} with extensive content so that 5 verses comfortably overflow the visible viewport on screen. In the beginning was the Word, and the Word was with God, and the Word was God. He was with God in the beginning.',
        format: ParagraphFormat.p,
      ),
    );
  }
}

class FakeFootnoteDbHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async {
    return List.generate(
      10,
      (i) => UsfmLine(
        bookChapterVerse: bookId * 1000000 + chapter * 1000 + (i + 1),
        text:
            'This is long verse text ${i + 1} with a footnote \\f + \\ft Test footnote details\\f* here.',
        format: ParagraphFormat.p,
      ),
    );
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

  group('VerseScrubber Widget Tests', () {
    testWidgets('does not render when verses length < 4 (3 or fewer)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseScrubber(
              verses: List.generate(3, (i) => i + 1),
              isVisible: true,
              onVerseSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(VerseScrubber), findsOneWidget);
      expect(find.byKey(const ValueKey('verse_scrubber_gesture_area')), findsNothing);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('does not render when canScroll is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseScrubber(
              verses: List.generate(10, (i) => i + 1),
              isVisible: true,
              canScroll: false,
              onVerseSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(VerseScrubber), findsOneWidget);
      expect(find.byKey(const ValueKey('verse_scrubber_gesture_area')), findsNothing);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('renders all numbers when verses length is between 4 and 30 and canScroll is true', (tester) async {
      final verses = List.generate(6, (i) => i + 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseScrubber(
              verses: verses,
              isVisible: true,
              canScroll: true,
              onVerseSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('verse_scrubber_gesture_area')), findsOneWidget);
      for (var i = 1; i <= 6; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
    });

    testWidgets('renders all numbers for 40 verses without overflow', (tester) async {
      final verses = List.generate(40, (i) => i + 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseScrubber(
              verses: verses,
              isVisible: true,
              onVerseSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('verse_scrubber_gesture_area')), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders Psalm 119 (176 verses) without overflow', (tester) async {
      final verses = List.generate(176, (i) => i + 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseScrubber(
              verses: verses,
              isVisible: true,
              onVerseSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('verse_scrubber_gesture_area')), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('160'), findsOneWidget);
      expect(find.text('176'), findsOneWidget);
      // Intermediate verses like 2 or 3 are skipped to keep numbers crisp and legible
      expect(find.text('2'), findsNothing);
      expect(find.text('3'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('when app bar is showing, Psalm 119 scrubber bar is placed strictly below app bar and above bottom safe area', (tester) async {
      final verses = List.generate(176, (i) => i + 1);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              padding: EdgeInsets.only(top: 40, bottom: 34),
            ),
            child: Scaffold(
              extendBodyBehindAppBar: true,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: AppBar(title: const Text('App Bar')),
              ),
              body: VerseScrubber(
                verses: verses,
                isVisible: true,
                isDistractionFree: false,
                onVerseSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final bar = find.byKey(const ValueKey('verse_scrubber_gesture_area'));
      final barRect = tester.getRect(bar);

      // App bar ends at top: 40 + kToolbarHeight (56) = 96.0
      // Scrubber top must be strictly below the app bar (> 96.0)
      expect(barRect.top, greaterThanOrEqualTo(96.0 + 12.0));
      // Scrubber bottom must be strictly above bottom safe area (800 - 34 = 766.0)
      expect(barRect.bottom, lessThanOrEqualTo(800.0 - 34.0 - 8.0));
    });

    testWidgets('when in full screen mode (isDistractionFree: true), scrubber bar expands towards top', (tester) async {
      final verses = List.generate(176, (i) => i + 1);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              padding: EdgeInsets.only(top: 40, bottom: 34),
            ),
            child: Scaffold(
              extendBodyBehindAppBar: true,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: AppBar(title: const Text('App Bar')),
              ),
              body: VerseScrubber(
                verses: verses,
                isVisible: true,
                isDistractionFree: true,
                onVerseSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final bar = find.byKey(const ValueKey('verse_scrubber_gesture_area'));
      final barRect = tester.getRect(bar);

      // In distraction-free mode, scrubber top expands up above kToolbarHeight boundary
      expect(barRect.top, lessThan(96.0));
    });

    testWidgets('edge detector does not exist and scrubber animates out when isVisible is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseScrubber(
              verses: List.generate(15, (i) => i + 1),
              isVisible: false,
              onVerseSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('verse_scrubber_edge_detector')), findsNothing);
      expect(find.byKey(const ValueKey('verse_scrubber_edge_drag_detector')), findsNothing);
      expect(find.byKey(const ValueKey('verse_scrubber_animated_slide')), findsOneWidget);
    });

    testWidgets('swiping right on the scrubber bar triggers onDismiss', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseScrubber(
              verses: List.generate(15, (i) => i + 1),
              isVisible: true,
              onVerseSelected: (_) {},
              onDismiss: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );

      final bar = find.byKey(const ValueKey('verse_scrubber_gesture_area'));
      await tester.drag(bar, const Offset(15, 0));
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets('tap on scrubber bar selects verse', (tester) async {
      int? selectedVerse;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseScrubber(
              verses: List.generate(10, (i) => i + 1),
              isVisible: true,
              onVerseSelected: (v) {
                selectedVerse = v;
              },
            ),
          ),
        ),
      );

      // Tap near top of the bar (verse 1)
      final bar = find.byKey(const ValueKey('verse_scrubber_gesture_area'));
      await tester.tapAt(tester.getTopLeft(bar) + const Offset(10, 10));
      await tester.pump();

      expect(selectedVerse, equals(1));
    });

    testWidgets('dragging shows overlay bubble and only selects verse on release', (tester) async {
      int? selectedVerse;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseScrubber(
              verses: List.generate(20, (i) => i + 1),
              isVisible: true,
              onVerseSelected: (v) {
                selectedVerse = v;
              },
            ),
          ),
        ),
      );

      final bar = find.byKey(const ValueKey('verse_scrubber_gesture_area'));
      final startPos = tester.getTopLeft(bar) + const Offset(10, 10);

      final gesture = await tester.startGesture(startPos);
      await tester.pump();

      // Bubble should appear while dragging
      expect(find.byKey(const ValueKey('verse_scrubber_overlay_bubble')), findsOneWidget);
      // Not yet selected during drag
      expect(selectedVerse, isNull);

      // Move down halfway
      final barHeight = tester.getSize(bar).height;
      await gesture.moveTo(startPos + Offset(0, barHeight * 0.5));
      await tester.pump();

      // Still dragging: bubble visible, no selection callback yet
      expect(find.byKey(const ValueKey('verse_scrubber_overlay_bubble')), findsOneWidget);
      expect(selectedVerse, isNull);

      // Release
      await gesture.up();
      await tester.pump();

      // After release, selection callback is called with the verse
      expect(selectedVerse, isNotNull);
      expect(selectedVerse, inInclusiveRange(9, 12));
      // Bubble disappears after drag ends
      expect(find.byKey(const ValueKey('verse_scrubber_overlay_bubble')), findsNothing);
    });

    test('computeDisplayVerses returns all verses when they fit within maxLabels', () {
      final verses = List.generate(30, (i) => i + 1);
      final result = VerseScrubber.computeDisplayVerses(verses, 35);
      expect(result, equals(verses));
    });

    test('computeDisplayVerses selects step 5 for Psalm 119 (176 verses) when maxLabels is 40', () {
      final verses = List.generate(176, (i) => i + 1);
      final result = VerseScrubber.computeDisplayVerses(verses, 40);
      expect(result.first, equals(1));
      expect(result.last, equals(176));
      expect(result.contains(5), isTrue);
      expect(result.contains(10), isTrue);
      expect(result.contains(170), isTrue);
      expect(result.contains(2), isFalse);
      expect(result.contains(3), isFalse);
      expect(result.length, inInclusiveRange(30, 40));
    });

    test('computeDisplayVerses selects step 10 for Psalm 119 when maxLabels is 25', () {
      final verses = List.generate(176, (i) => i + 1);
      final result = VerseScrubber.computeDisplayVerses(verses, 25);
      expect(result.first, equals(1));
      expect(result.last, equals(176));
      expect(result.contains(10), isTrue);
      expect(result.contains(20), isTrue);
      expect(result.contains(5), isFalse);
      expect(result.length, inInclusiveRange(15, 25));
    });

    test('computeDisplayVerses selects step 2 for 80 verses when maxLabels is 45', () {
      final verses = List.generate(80, (i) => i + 1);
      final result = VerseScrubber.computeDisplayVerses(verses, 45);
      expect(result.first, equals(1));
      expect(result.last, equals(80));
      expect(result.contains(3), isTrue);
      expect(result.contains(5), isTrue);
      expect(result.length, inInclusiveRange(40, 45));
    });
  });

  group('ChapterText VerseScrubber Integration Tests', () {
    late UserSettings userSettings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      getIt.reset();

      userSettings = UserSettings();
      await userSettings.init();
      getIt.registerSingleton<UserSettings>(userSettings);

      final annotationDb = FakeAnnotationDbHelper();
      getIt.registerSingleton<AnnotationDatabaseHelper>(annotationDb);
      getIt.registerSingleton<AnnotationService>(
        AnnotationService(dbHelper: annotationDb),
      );
    });

    tearDown(() {
      getIt.reset();
    });

    testWidgets('does not show scrubber for chapter with < 4 verses even if overflowing', (tester) async {
      getIt.registerSingleton<DatabaseHelper>(FakeThreeVerseDbHelper());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChapterText(
              bookId: 1,
              chapter: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('verse_scrubber_gesture_area')), findsNothing);
    });

    testWidgets('does not show scrubber for chapter with >= 4 verses if content fits entirely on screen', (tester) async {
      getIt.registerSingleton<DatabaseHelper>(FakeFiveVerseShortDbHelper());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChapterText(
              bookId: 1,
              chapter: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('verse_scrubber_gesture_area')), findsNothing);
    });

    testWidgets('shows scrubber for chapter with 5 verses (< 10) when content overflows screen and auto-hides', (tester) async {
      getIt.registerSingleton<DatabaseHelper>(FakeFiveVerseLongDbHelper());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChapterText(
              bookId: 1,
              chapter: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrubberFinder = find.byType(VerseScrubber);
      expect(scrubberFinder, findsOneWidget);

      final scrubberWidget = tester.widget<VerseScrubber>(scrubberFinder);
      expect(scrubberWidget.isVisible, isTrue);

      // Advance clock by 3 seconds
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      final hiddenScrubber = tester.widget<VerseScrubber>(scrubberFinder);
      expect(hiddenScrubber.isVisible, isFalse);
    });

    testWidgets('shows scrubber on initial load for chapter with >= 10 verses and auto-hides after 3s', (tester) async {
      getIt.registerSingleton<DatabaseHelper>(FakeTenVerseDbHelper());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChapterText(
              bookId: 1,
              chapter: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrubberFinder = find.byType(VerseScrubber);
      expect(scrubberFinder, findsOneWidget);

      final scrubberWidget = tester.widget<VerseScrubber>(scrubberFinder);
      expect(scrubberWidget.isVisible, isTrue);

      // Advance clock by 3 seconds
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      final hiddenScrubber = tester.widget<VerseScrubber>(scrubberFinder);
      expect(hiddenScrubber.isVisible, isFalse);
    });

    testWidgets('verse scrubber does not show when showVerseGrid is true in settings', (tester) async {
      getIt.registerSingleton<DatabaseHelper>(FakeTenVerseDbHelper());
      final userSettings = getIt<UserSettings>();
      await userSettings.setShowVerseGrid(true);

      final appState = AppState();
      await appState.init();
      getIt.registerSingleton<AppState>(appState);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChapterText(
              bookId: 1,
              chapter: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VerseScrubber), findsNothing);

      // Now toggle showVerseGrid to false
      await appState.setShowVerseGrid(false);
      await tester.pumpAndSettle();

      // Scrubber should now appear
      expect(find.byType(VerseScrubber), findsOneWidget);
    });

    testWidgets('showScrubberNotifier makes scrubber reappear on active page', (tester) async {
      getIt.registerSingleton<DatabaseHelper>(FakeTenVerseDbHelper());
      final showScrubberNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChapterText(
              bookId: 1,
              chapter: 1,
              showScrubberNotifier: showScrubberNotifier,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Wait 3s so it hides
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      final scrubberFinder = find.byType(VerseScrubber);
      expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);

      // Trigger the notifier (simulating swipe towards next chapter and sliding back into place)
      showScrubberNotifier.value++;
      await tester.pump();

      // It becomes visible again
      expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isTrue);

      // Auto-hides again after 3 seconds
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);
    });

    testWidgets('scrolling text directly immediately hides the scrubber', (tester) async {
      getIt.registerSingleton<DatabaseHelper>(FakeTenVerseDbHelper());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChapterText(
              bookId: 1,
              chapter: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrubberFinder = find.byType(VerseScrubber);
      expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isTrue);

      // Scroll the chapter text
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -50));
      await tester.pump();

      // Scrubber immediately hides on scroll
      expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);
    });

    testWidgets('overlay bubble matches touch location vertically and is clamped', (tester) async {
      final verses = List.generate(20, (i) => i + 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              width: 400,
              child: VerseScrubber(
                verses: verses,
                isVisible: true,
                onVerseSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final bar = find.byKey(const ValueKey('verse_scrubber_gesture_area'));
      final barRect = tester.getRect(bar);

      // Touch at Y = 250
      final touchPos = Offset(barRect.center.dx, 250);
      final gesture = await tester.startGesture(touchPos);
      await tester.pump();

      final bubbleFinder = find.byKey(const ValueKey('verse_scrubber_overlay_bubble'));
      expect(bubbleFinder, findsOneWidget);

      // Bubble center Y should match the touch Y (250)
      final bubbleRect = tester.getRect(bubbleFinder);
      expect(bubbleRect.center.dy, closeTo(250.0, 2.0));

      // Move touch way up past the top (Y = -50)
      await gesture.moveTo(Offset(barRect.center.dx, -50));
      await tester.pump();

      // Bubble should be clamped to the top bounds, not offscreen
      final topClampedRect = tester.getRect(bubbleFinder);
      expect(topClampedRect.top, greaterThanOrEqualTo(12.0));

      // Move touch way down past the bottom (Y = 800)
      await gesture.moveTo(Offset(barRect.center.dx, 800));
      await tester.pump();

      // Bubble should be clamped to the bottom bounds, not offscreen
      final bottomClampedRect = tester.getRect(bubbleFinder);
      expect(bottomClampedRect.bottom, lessThanOrEqualTo(600.0 - 12.0));

      await gesture.up();
    });

    testWidgets('inactive page does not render VerseScrubber (prevents left-side scrubber)', (tester) async {
      getIt.registerSingleton<DatabaseHelper>(FakeTenVerseDbHelper());
      final activeIndexNotifier = ValueNotifier<int>(1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: ChapterText(
                    bookId: 1,
                    chapter: 1,
                    pageIndex: 0,
                    activePageIndexListenable: activeIndexNotifier,
                  ),
                ),
                Expanded(
                  child: ChapterText(
                    bookId: 1,
                    chapter: 2,
                    pageIndex: 1,
                    activePageIndexListenable: activeIndexNotifier,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Page 0 is inactive, Page 1 is active
      final scrubbers =
          tester.widgetList<VerseScrubber>(find.byType(VerseScrubber)).toList();
      expect(scrubbers.length, equals(2));
      expect(scrubbers[0].isActive, isFalse);
      expect(scrubbers[1].isActive, isTrue);
    });

    testWidgets('verse bar smoothly slides out of view over animation duration', (tester) async {
      final verses = List.generate(10, (i) => i + 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseScrubber(
              verses: verses,
              isVisible: true,
              onVerseSelected: (_) {},
            ),
          ),
        ),
      );

      final slideFinder = find.byKey(const ValueKey('verse_scrubber_animated_slide'));
      expect(slideFinder, findsOneWidget);

      AnimatedSlide slideWidget = tester.widget<AnimatedSlide>(slideFinder);
      expect(slideWidget.offset, equals(Offset.zero));

      // Rebuild with isVisible = false
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseScrubber(
              verses: verses,
              isVisible: false,
              onVerseSelected: (_) {},
            ),
          ),
        ),
      );

      // Advance by 150ms (halfway through 300ms animation)
      await tester.pump(const Duration(milliseconds: 150));

      // Target offset in the updated widget
      slideWidget = tester.widget<AnimatedSlide>(slideFinder);
      expect(slideWidget.offset, equals(const Offset(1.2, 0)));

      // Complete animation
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
    });
  });

  group('TextScreen chapter swipe and slide-back verse scrubber tests', () {
    late TabManager tabManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final userSettings = UserSettings();
      await userSettings.init();
      getIt.registerSingleton<UserSettings>(userSettings);

      getIt.registerSingleton<DatabaseHelper>(FakeTenVerseDbHelper());

      final annotationDb = FakeAnnotationDbHelper();
      getIt.registerSingleton<AnnotationDatabaseHelper>(annotationDb);
      getIt.registerSingleton<AnnotationService>(
        AnnotationService(dbHelper: annotationDb),
      );

      tabManager = TabManager();
      await tabManager.init();
      getIt.registerSingleton<TabManager>(tabManager);

      getIt.registerSingleton<AppState>(AppState());
    });

    tearDown(() {
      getIt.reset();
    });

    testWidgets(
        'starting swipe towards next chapter and letting chapter slide back shows scrubber again',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextScreen(
              bookId: 1,
              chapter: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      VerseScrubber getActiveScrubber() {
        return tester
            .widgetList<VerseScrubber>(find.byType(VerseScrubber))
            .firstWhere((s) => s.isActive);
      }

      expect(getActiveScrubber().isVisible, isTrue);

      // Auto-hides after 3 seconds
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(getActiveScrubber().isVisible, isFalse);

      // Start swiping towards next chapter (finger drags left) by 50px and release
      final gesture = await tester.startGesture(const Offset(300, 300));
      await gesture.moveBy(const Offset(-25, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-25, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Scrubber should be visible again after sliding back into place
      expect(getActiveScrubber().isVisible, isTrue);

      // And auto-hides after 3s
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(getActiveScrubber().isVisible, isFalse);
    });

    testWidgets(
        'swiping towards previous chapter and sliding back does not show scrubber',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextScreen(
              bookId: 1,
              chapter: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      VerseScrubber getActiveScrubber() {
        return tester
            .widgetList<VerseScrubber>(find.byType(VerseScrubber))
            .firstWhere((s) => s.isActive);
      }

      // Auto-hides after 3 seconds
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(getActiveScrubber().isVisible, isFalse);

      // Swipe towards previous chapter (finger drags right) by 40px and release
      final gesture = await tester.startGesture(const Offset(300, 300));
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Scrubber should NOT be visible
      expect(getActiveScrubber().isVisible, isFalse);
    });

    testWidgets(
      'TextScreen with initialTargetVerse: selecting a verse in VerseScrubber does not scroll back to initialTargetVerse when scrubber auto hides',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TextScreen(
                bookId: 1,
                chapter: 1,
                initialTargetVerse: 10,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final chapterTextFinder = find.byKey(const ValueKey('chapter_1_1'));
        expect(chapterTextFinder, findsOneWidget);
        final chapterText = tester.widget<ChapterText>(chapterTextFinder);
        // ChapterText should have received targetVerse: null after onTargetVerseScrolled ran
        expect(chapterText.targetVerse, isNull);

        final scrollableFinder = find.descendant(
          of: chapterTextFinder,
          matching: find.byType(Scrollable),
        );
        final scrollPosition = tester.state<ScrollableState>(scrollableFinder).position;

        VerseScrubber getActiveScrubber() {
          return tester
              .widgetList<VerseScrubber>(find.byType(VerseScrubber))
              .firstWhere((s) => s.isActive);
        }

        final scrubber = getActiveScrubber();
        scrubber.onVerseSelected(1);
        await tester.pumpAndSettle();

        expect(scrollPosition.pixels, equals(0.0));

        // Wait 3 seconds for scrubber auto-hide
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        expect(scrollPosition.pixels, equals(0.0));
      },
    );

    testWidgets(
      'when showVerseGrid is true, swiping towards next chapter and sliding back does not summon GridVerseChooser or VerseScrubber',
      (tester) async {
        getIt<AppState>().setShowVerseGrid(true);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TextScreen(
                bookId: 1,
                chapter: 1,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially, neither verse grid chooser nor scrubber is open
        expect(find.byType(GridVerseChooser), findsNothing);
        expect(find.byType(VerseScrubber), findsNothing);

        // Start swiping towards next chapter (drag left) by 50px and release to settle back
        final gesture = await tester.startGesture(const Offset(300, 300));
        await gesture.moveBy(const Offset(-25, 0));
        await tester.pump();
        await gesture.moveBy(const Offset(-25, 0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        // Neither GridVerseChooser nor VerseScrubber should be summoned
        expect(find.byType(GridVerseChooser), findsNothing);
        expect(find.byType(VerseScrubber), findsNothing);
      },
    );
  });

  group('Right edge vertical swipe scrubber removal tests', () {
    late UserSettings userSettings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      getIt.reset();

      userSettings = UserSettings();
      await userSettings.init();
      getIt.registerSingleton<UserSettings>(userSettings);

      final annotationDb = FakeAnnotationDbHelper();
      getIt.registerSingleton<AnnotationDatabaseHelper>(annotationDb);
      getIt.registerSingleton<AnnotationService>(
        AnnotationService(dbHelper: annotationDb),
      );
    });

    tearDown(() {
      getIt.reset();
    });

    testWidgets(
      'in VerseScrubber: when isVisible is false, edge drag detector does not exist',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: VerseScrubber(
                  verses: List.generate(20, (i) => i + 1),
                  isVisible: false,
                  canScroll: true,
                  onVerseSelected: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('verse_scrubber_edge_drag_detector')), findsNothing);
        expect(find.byKey(const ValueKey('verse_scrubber_edge_drag_detector_positioned')), findsNothing);
      },
    );

    testWidgets(
      'in ChapterText: vertical drag on right edge when scrubber is hidden does not summon scrubber and scrolls text',
      (tester) async {
        getIt.registerSingleton<DatabaseHelper>(FakeTenVerseDbHelper());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: ChapterText(
                  bookId: 1,
                  chapter: 1,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scrubberFinder = find.byType(VerseScrubber);
        expect(scrubberFinder, findsOneWidget);

        // Auto-hides after 3 seconds
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);

        final scrollableFinder = find.descendant(
          of: find.byType(ChapterText),
          matching: find.byType(Scrollable),
        );
        final initialOffset = tester.state<ScrollableState>(scrollableFinder).position.pixels;

        // Vertical drag on right edge (width 400 => x = 385)
        await tester.dragFrom(const Offset(385, 400), const Offset(0, -80));
        await tester.pumpAndSettle();

        // Scrubber remains hidden and text scrolled
        expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);
        expect(find.byKey(const ValueKey('verse_scrubber_overlay_bubble')), findsNothing);
        final finalOffset = tester.state<ScrollableState>(scrollableFinder).position.pixels;
        expect(finalOffset, greaterThan(initialOffset));
      },
    );

    testWidgets(
      'in ChapterText: slow vertical drag or flick on right edge does not summon scrubber',
      (tester) async {
        getIt.registerSingleton<DatabaseHelper>(FakeTenVerseDbHelper());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: ChapterText(
                  bookId: 1,
                  chapter: 1,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scrubberFinder = find.byType(VerseScrubber);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);

        final gesture = await tester.startGesture(const Offset(380, 500));
        for (int i = 0; i < 15; i++) {
          await gesture.moveBy(const Offset(0, -5));
          await tester.pump(const Duration(milliseconds: 20));
        }

        expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);
        expect(find.byKey(const ValueKey('verse_scrubber_overlay_bubble')), findsNothing);

        await gesture.up();
        await tester.pumpAndSettle();

        expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);
        expect(find.byKey(const ValueKey('verse_scrubber_overlay_bubble')), findsNothing);
      },
    );

    testWidgets(
      'in ChapterText: tapping on right edge when scrubber is hidden does not make scrubber appear',
      (tester) async {
        getIt.registerSingleton<DatabaseHelper>(FakeTenVerseDbHelper());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: ChapterText(
                  bookId: 1,
                  chapter: 1,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scrubberFinder = find.byType(VerseScrubber);
        // Auto-hides after 3 seconds
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);

        // Tap in right strip (x = 385, y = 300)
        await tester.tapAt(const Offset(385, 300));
        await tester.pumpAndSettle();

        // Scrubber should NOT appear
        expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);
      },
    );

    testWidgets(
      'in ChapterText: horizontal swipe in right edge does not activate scrubber and allows page scrolling',
      (tester) async {
        getIt.registerSingleton<DatabaseHelper>(FakeTenVerseDbHelper());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: ChapterText(
                  bookId: 1,
                  chapter: 1,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scrubberFinder = find.byType(VerseScrubber);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);

        // Swipe horizontally towards left from right edge (dx = -40, dy = 5)
        final gesture = await tester.startGesture(const Offset(385, 300));
        await gesture.moveBy(const Offset(-40, 5));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        // Bubble should NOT have appeared and scrubber should still be hidden
        expect(find.byKey(const ValueKey('verse_scrubber_overlay_bubble')), findsNothing);
        expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);
      },
    );

    testWidgets(
      'in ChapterText: tapping on footnote when scrubber is hidden opens footnote dialog',
      (tester) async {
        getIt.registerSingleton<DatabaseHelper>(FakeFootnoteDbHelper());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: ChapterText(
                  bookId: 1,
                  chapter: 1,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scrubberFinder = find.byType(VerseScrubber);
        // Auto-hides after 3 seconds
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);

        // Find the footnote widget and tap it
        final footnoteFinder = find.byType(FootnoteWidget).first;
        expect(footnoteFinder, findsOneWidget);
        await tester.tap(footnoteFinder);
        await tester.pumpAndSettle();

        // Footnote alert dialog is open
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.textContaining('Test footnote details'), findsOneWidget);
      },
    );

    testWidgets(
      'in ChapterText: long pressing verse when scrubber is hidden triggers selection and does not summon scrubber',
      (tester) async {
        getIt.registerSingleton<DatabaseHelper>(FakeTenVerseDbHelper());
        ScriptureSelectionController? selectionController;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: ChapterText(
                  bookId: 1,
                  chapter: 1,
                  onSelectionChanged: (c) {
                    selectionController = c;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scrubberFinder = find.byType(VerseScrubber);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);

        // Long press on a word
        final wordFinder = find.byType(WordWidget).first;
        expect(wordFinder, findsOneWidget);
        await tester.longPress(wordFinder);
        await tester.pumpAndSettle();

        // Selection should be active
        expect(selectionController?.hasSelection, isTrue);
        // Scrubber should NOT appear
        expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);
        expect(find.byKey(const ValueKey('verse_scrubber_overlay_bubble')), findsNothing);
      },
    );

    testWidgets(
      'in ChapterText: dragging selection handle does not summon scrubber',
      (tester) async {
        getIt.registerSingleton<DatabaseHelper>(FakeTenVerseDbHelper());
        ScriptureSelectionController? selectionController;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 800,
                child: ChapterText(
                  bookId: 1,
                  chapter: 1,
                  onSelectionChanged: (c) {
                    selectionController = c;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scrubberFinder = find.byType(VerseScrubber);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);

        // Long press on a word to create selection
        final wordFinder = find.byType(WordWidget).first;
        await tester.longPress(wordFinder);
        await tester.pumpAndSettle();

        expect(selectionController?.hasSelection, isTrue);

        // Drag starting from near the word/handle
        final wordPos = tester.getCenter(wordFinder);
        final gesture = await tester.startGesture(wordPos);
        await gesture.moveBy(const Offset(0, 40));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        // Scrubber should NOT appear
        expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);
        expect(find.byKey(const ValueKey('verse_scrubber_overlay_bubble')), findsNothing);
      },
    );
  });
}

