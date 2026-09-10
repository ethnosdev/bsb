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

class FakeTenVerseDbHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async {
    return List.generate(
      10,
      (i) => UsfmLine(
        bookChapterVerse: bookId * 1000000 + chapter * 1000 + (i + 1),
        text: 'Verse text ${i + 1}.',
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
        text: 'Short verse text ${i + 1}.',
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
    testWidgets('does not render when verses length < 10 (9 or fewer)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseScrubber(
              verses: List.generate(9, (i) => i + 1),
              isVisible: true,
              onVerseSelected: (_) {},
              onSwipeIn: () {},
            ),
          ),
        ),
      );

      expect(find.byType(VerseScrubber), findsOneWidget);
      expect(find.byKey(const ValueKey('verse_scrubber_gesture_area')), findsNothing);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('renders all numbers when verses length is between 10 and 30', (tester) async {
      final verses = List.generate(10, (i) => i + 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseScrubber(
              verses: verses,
              isVisible: true,
              onVerseSelected: (_) {},
              onSwipeIn: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('verse_scrubber_gesture_area')), findsOneWidget);
      for (var i = 1; i <= 10; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
    });

    testWidgets('renders landmark numbers for 40 verses without overflow', (tester) async {
      final verses = List.generate(40, (i) => i + 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseScrubber(
              verses: verses,
              isVisible: true,
              onVerseSelected: (_) {},
              onSwipeIn: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('verse_scrubber_gesture_area')), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      // Unlabeled numbers like 3 should not have a separate Text widget
      expect(find.text('3'), findsNothing);
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
              onSwipeIn: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('verse_scrubber_gesture_area')), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('160'), findsOneWidget);
      expect(find.text('176'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('edge detector appears when isVisible is false and responds to swipe in', (tester) async {
      bool swipedIn = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VerseScrubber(
              verses: List.generate(15, (i) => i + 1),
              isVisible: false,
              onVerseSelected: (_) {},
              onSwipeIn: () {
                swipedIn = true;
              },
            ),
          ),
        ),
      );

      final edgeDetector = find.byKey(const ValueKey('verse_scrubber_edge_detector'));
      expect(edgeDetector, findsOneWidget);

      // Drag to the left from the right edge
      await tester.drag(edgeDetector, const Offset(-10, 0));
      await tester.pump();

      expect(swipedIn, isTrue);
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
              onSwipeIn: () {},
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
              onSwipeIn: () {},
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
              onSwipeIn: () {},
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

    testWidgets('does not show scrubber for chapter with < 10 verses', (tester) async {
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

    testWidgets('swiping in from right edge makes scrubber reappear', (tester) async {
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

      // Wait 3s so it hides
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      final scrubberFinder = find.byType(VerseScrubber);
      expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isFalse);

      // Find the edge detector
      final edgeDetector = find.byKey(const ValueKey('verse_scrubber_edge_detector'));
      expect(edgeDetector, findsOneWidget);

      // Swipe left from right edge
      await tester.drag(edgeDetector, const Offset(-15, 0));
      await tester.pump();

      // It becomes visible again
      expect(tester.widget<VerseScrubber>(scrubberFinder).isVisible, isTrue);
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
                onSwipeIn: () {},
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
              onSwipeIn: () {},
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
              onSwipeIn: () {},
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
}
