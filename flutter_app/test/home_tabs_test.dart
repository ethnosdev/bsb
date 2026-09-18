import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/home/book_chooser.dart';
import 'package:bsb/ui/home/chapter_chooser.dart';
import 'package:bsb/ui/home/home.dart';
import 'package:bsb/ui/home/list_book_chooser.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/chapter_chip.dart';
import 'package:bsb/ui/tabs/composite_chip.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:bsb/ui/tabs/chapter_tabs_sheet.dart';
import 'package:bsb/infrastructure/section_heading.dart';
import 'package:bsb/ui/text/chapter/chapter_text.dart';
import 'package:bsb/ui/text/text_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeDatabaseHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async => [];

  @override
  Future<List<SectionHeading>> getSectionHeadings(int bookId) async => [
        const SectionHeading(
          bookId: 43,
          chapter: 2,
          verse: 12,
          text: 'Jesus Cleanses the Temple',
          format: 's1',
        ),
        const SectionHeading(
          bookId: 43,
          chapter: 3,
          verse: 22,
          text: "John's Testimony about Jesus",
          format: 's1',
        ),
      ];
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
  late TabManager tabManager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    getIt.reset();

    userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);

    final dbHelper = FakeDatabaseHelper();
    getIt.registerSingleton<DatabaseHelper>(dbHelper);

    final annotationDb = FakeAnnotationDbHelper();
    getIt.registerSingleton<AnnotationDatabaseHelper>(annotationDb);
    getIt.registerSingleton<AnnotationService>(
      AnnotationService(dbHelper: annotationDb),
    );

    tabManager = TabManager();
    await tabManager.init();
    getIt.registerSingleton<TabManager>(tabManager);
  });

  tearDown(() {
    getIt.reset();
  });

  testWidgets('shows BookChooser and default title when no tabs are open', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pump();

    expect(find.text('Berean Standard Bible'), findsOneWidget);
    expect(find.byType(BookChooser), findsOneWidget);
    expect(find.byType(ChapterChip), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('shows ListBookChooser when setting is set to list', (tester) async {
    await userSettings.setBookChooserStyle(BookChooserStyle.list);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pump();

    expect(find.text('Berean Standard Bible'), findsOneWidget);
    expect(find.byType(ListBookChooser), findsOneWidget);
    expect(find.byType(BookChooser), findsNothing);
    expect(find.text('Genesis'), findsOneWidget);
    expect(find.text('Matthew'), findsOneWidget);
    expect(find.text('Old Testament'), findsNothing);
    expect(find.text('New Testament'), findsNothing);
  });

  testWidgets('shows ChapterChip and TextScreen when a tab is opened', (tester) async {
    tabManager.openTab(1, 1); // GEN 1

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Berean Standard Bible'), findsNothing);
    expect(find.text('GEN 1'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget); // active chip has close icon
    expect(find.byIcon(Icons.add), findsOneWidget); // + button is available
    expect(find.byType(TextScreen), findsOneWidget);
  });

  testWidgets('tapping + switches to BookChooser with cancel button', (tester) async {
    tabManager.openTab(1, 1); // GEN 1

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the + button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(tabManager.isAddingTab, isTrue);
    expect(find.byType(BookChooser), findsOneWidget);

    // Cancel using the cancel button in app bar
    final cancelButton = find.byTooltip('Cancel').first;
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(tabManager.isAddingTab, isFalse);
    expect(find.byType(TextScreen), findsOneWidget);
  });

  testWidgets('closing active chip falls back to previous tab', (tester) async {
    tabManager.openTab(1, 1); // GEN 1
    tabManager.openTab(45, 8); // ROM 8

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ROM 8'), findsOneWidget);
    expect(find.text('GEN 1'), findsOneWidget);

    // Only the active chip (ROM 8) has the close button
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Tap close on active chip
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // GEN 1 is now active
    expect(tabManager.activeTab?.label, 'GEN 1');
    expect(find.text('GEN 1'), findsOneWidget);
    expect(find.text('ROM 8'), findsNothing);
  });

  testWidgets('closing the final tab returns to BookChooser and default title', (tester) async {
    tabManager.openTab(1, 1); // GEN 1

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Close GEN 1
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(tabManager.tabs, isEmpty);
    expect(find.text('Berean Standard Bible'), findsOneWidget);
    expect(find.byType(BookChooser), findsOneWidget);
  });

  testWidgets('appBar uses titleSpacing: 0 to reduce padding for chapter chips', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pump();

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.titleSpacing, equals(0));
  });

  testWidgets('tapping current tab in composite sheet opens ChapterChooser', (tester) async {
    tabManager.openTab(1, 1); // Genesis 1
    tabManager.openTab(45, 8); // Romans 8
    tabManager.openTab(19, 23); // Psalms 23
    tabManager.openTab(43, 3); // John 3

    // Set screen size narrow enough so that 4 tabs collapse into composite chip
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Composite chip should be visible
    expect(find.byType(CompositeChapterChip), findsOneWidget);

    // Tap composite chip to open sheet
    await tester.tap(find.byType(CompositeChapterChip));
    await tester.pumpAndSettle();

    expect(find.text('Open Chapters'), findsOneWidget);
    final sheetItem = find.descendant(
      of: find.byType(ChapterTabsSheet),
      matching: find.text('John 3'),
    );
    expect(sheetItem, findsOneWidget);

    // Tap the current tab (John 3)
    await tester.tap(sheetItem);
    await tester.pumpAndSettle();

    // ChapterChooser dialog should now be visible for John!
    expect(find.byType(ChapterChooser), findsOneWidget);
  });

  testWidgets('three-dot menu shows Search and Play Audio, and does not contain Distraction free', (tester) async {
    tabManager.openTab(43, 3); // John 3

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar and 3-dot menu are visible
    expect(find.byType(AppBar), findsOneWidget);
    final moreButton = find.byIcon(Icons.more_vert);
    expect(moreButton, findsOneWidget);

    // Tap 3-dot menu
    await tester.tap(moreButton);
    await tester.pumpAndSettle();

    // Verify options
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Play Audio'), findsOneWidget);
    expect(find.text('Distraction free'), findsNothing);
  });

  testWidgets('tapping text screen enters and exits distraction free mode and pop route exits it', (tester) async {
    tabManager.openTab(43, 3); // John 3

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    final slideFinder = find.byKey(const Key('app_bar_animated_slide'));
    expect(tester.widget<AnimatedSlide>(slideFinder).offset, equals(Offset.zero));

    // Tap text screen to enter distraction free mode
    await tester.tapAt(const Offset(200, 300));
    await tester.pumpAndSettle();

    expect(tester.widget<AnimatedSlide>(slideFinder).offset, equals(const Offset(0, -1)));

    // Tap text screen again to exit distraction free mode
    await tester.tapAt(const Offset(200, 300));
    await tester.pumpAndSettle();

    expect(tester.widget<AnimatedSlide>(slideFinder).offset, equals(Offset.zero));

    // Enter distraction free mode again
    await tester.tapAt(const Offset(200, 300));
    await tester.pumpAndSettle();

    expect(tester.widget<AnimatedSlide>(slideFinder).offset, equals(const Offset(0, -1)));

    // Back gesture / PopScope should exit distraction free mode
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();

    expect(tester.widget<AnimatedSlide>(slideFinder).offset, equals(Offset.zero));
  });

  testWidgets('text position does not jump when entering or exiting distraction free mode', (tester) async {
    tabManager.openTab(43, 3); // John 3

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Find the UsfmWidget in the active chapter and record its initial vertical position
    final activeChapter = find.byKey(const ValueKey('chapter_43_3'));
    final usfmFinder = find.descendant(
      of: activeChapter,
      matching: find.byType(UsfmWidget),
    );
    expect(usfmFinder, findsOneWidget);
    final initialTop = tester.getTopLeft(usfmFinder).dy;

    // Enter distraction free mode by tapping text screen
    await tester.tapAt(const Offset(200, 300));
    await tester.pumpAndSettle();

    // Verify UsfmWidget is at the exact same vertical position (no jump!)
    final distractionFreeTop = tester.getTopLeft(usfmFinder).dy;
    expect(distractionFreeTop, equals(initialTop));

    // Exit distraction free mode
    await tester.tapAt(const Offset(200, 300));
    await tester.pumpAndSettle();

    // Verify UsfmWidget is still at the exact same vertical position
    final restoredTop = tester.getTopLeft(usfmFinder).dy;
    expect(restoredTop, equals(initialTop));
  });

  testWidgets('text starts 16px below app bar and does not jump on iOS (with status bar)', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    tester.view.padding = const FakeViewPadding(top: 47.0 * 3);
    tester.view.viewPadding = const FakeViewPadding(top: 47.0 * 3);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    tabManager.openTab(43, 3); // John 3

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    final appBarFinder = find.byType(AppBar);
    final appBarBottom = tester.getBottomLeft(appBarFinder).dy;
    expect(appBarBottom, equals(103.0)); // 47 status bar + 56 toolbar

    final activeChapter = find.byKey(const ValueKey('chapter_43_3'));
    final headerFinder = find.descendant(
      of: activeChapter,
      matching: find.byKey(const ValueKey('chapter_header_43_3')),
    );
    expect(headerFinder, findsOneWidget);
    final initialTop = tester.getTopLeft(headerFinder).dy;
    expect(initialTop, equals(119.0)); // 103 + 16px margin

    // Enter distraction free mode by tapping text screen
    await tester.tapAt(const Offset(200, 300));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(headerFinder).dy, equals(119.0)); // No jump

    // Exit distraction free mode
    await tester.tapAt(const Offset(200, 300));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(headerFinder).dy, equals(119.0)); // No jump
  });

  testWidgets(
      'tapping tab, opening section headings, and selecting heading in different chapter navigates and preserves section heading (Issue #39)',
      (tester) async {
    tabManager.openTab(43, 2); // John 2

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChapterChip), findsOneWidget);
    expect(find.text('JHN 2'), findsOneWidget);

    // Tap active tab to open ChapterChooser
    await tester.tap(find.text('JHN 2'));
    await tester.pumpAndSettle();

    expect(find.byType(ChapterChooser), findsOneWidget);

    // Tap section headings button
    await tester.tap(find.byKey(const ValueKey('keypad_sections')));
    await tester.pumpAndSettle();

    // Section headings dialog should be open with John 2 and John 3 headings
    expect(find.text("John's Testimony about Jesus"), findsOneWidget);

    // Tap heading in chapter 3
    await tester.tap(find.text("John's Testimony about Jesus"));
    await tester.pump();

    // Active tab is now John 3
    expect(tabManager.activeTab?.chapter, equals(3));
    expect(tabManager.activeTab?.label, equals('JHN 3'));

    // ChapterText for John 3 received the targetSection
    final chapterTextFinder = find.byWidgetPredicate((w) =>
        w is ChapterText &&
        w.bookId == 43 &&
        w.chapter == 3 &&
        w.targetSection == "John's Testimony about Jesus");
    expect(chapterTextFinder, findsOneWidget);
  });

  testWidgets(
      'tapping tab, opening section headings, and selecting heading in same chapter preserves section heading',
      (tester) async {
    tabManager.openTab(43, 2); // John 2

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('JHN 2'), findsOneWidget);

    // Tap active tab to open ChapterChooser
    await tester.tap(find.text('JHN 2'));
    await tester.pumpAndSettle();

    // Tap section headings button
    await tester.tap(find.byKey(const ValueKey('keypad_sections')));
    await tester.pumpAndSettle();

    // Tap heading in chapter 2
    await tester.tap(find.text('Jesus Cleanses the Temple'));
    await tester.pump();

    // Active tab remains John 2
    expect(tabManager.activeTab?.chapter, equals(2));
    expect(tabManager.activeTab?.label, equals('JHN 2'));

    // ChapterText for John 2 received the targetSection
    final chapterTextFinder = find.byWidgetPredicate((w) =>
        w is ChapterText &&
        w.bookId == 43 &&
        w.chapter == 2 &&
        w.targetSection == 'Jesus Cleanses the Temple');
    expect(chapterTextFinder, findsOneWidget);
  });

  testWidgets(
      'closing active tab dismisses chapter chooser so it does not persist when opening another book',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Start with no tabs, showing BookChooser
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // 1) Select Genesis from BookChooser: chapter selection menu appears
    await tester.tap(find.text('Gen'));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterChooser), findsOneWidget);
    expect(find.text('Genesis'), findsOneWidget);

    // 2) Select chapter 9: goes to Genesis 9
    await tester.tap(find.byKey(const ValueKey('keypad_9')));
    await tester.pumpAndSettle();
    expect(tabManager.activeTab?.label, equals('GEN 9'));
    expect(find.byType(ChapterChooser), findsNothing);

    // 3) Select active tab chip ("GEN 9"): chapter selection menu appears
    await tester.tap(find.text('GEN 9'));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterChooser), findsOneWidget);
    expect(find.text('Genesis'), findsOneWidget);

    // 4) Select "X" in the active tab chip to close tab: goes to 66 books selection screen
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(tabManager.tabs, isEmpty);
    expect(find.byType(ChapterChooser), findsNothing);

    // 5) Select another book (ex: "Exo"): chapter selection menu appears
    await tester.tap(find.text('Exo'));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterChooser), findsOneWidget);
    expect(find.text('Exodus'), findsOneWidget);

    // 6) Select "1" and "Go"
    await tester.tap(find.byKey(const ValueKey('keypad_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('keypad_go')));
    await tester.pumpAndSettle();

    // Exodus chapter chooser disappears and Exodus 1 is shown; Genesis chooser is NOT underneath!
    expect(tabManager.activeTab?.label, equals('EXO 1'));
    expect(find.byType(ChapterChooser), findsNothing);
    expect(find.text('Genesis'), findsNothing);
  });

  testWidgets('tapping active tab again toggles chapter chooser closed',
      (tester) async {
    tabManager.openTab(43, 2); // John 2

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('JHN 2'), findsOneWidget);
    expect(find.byType(ChapterChooser), findsNothing);

    // Tap active tab to open ChapterChooser
    await tester.tap(find.text('JHN 2'));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterChooser), findsOneWidget);

    // Tap active tab again to toggle it off
    await tester.tap(find.text('JHN 2'));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterChooser), findsNothing);
  });

  testWidgets(
      'closing active tab when multiple tabs exist dismisses chapter chooser',
      (tester) async {
    tabManager.openTab(43, 2); // John 2
    tabManager.openTab(45, 8); // Romans 8 (active)

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tabManager.activeTab?.label, equals('ROM 8'));

    // Open ChapterChooser on ROM 8
    await tester.tap(find.text('ROM 8'));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterChooser), findsOneWidget);

    // Close ROM 8 tab by tapping its close icon
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Active tab switches to JHN 2, and chapter chooser is dismissed
    expect(tabManager.activeTab?.label, equals('JHN 2'));
    expect(find.byType(ChapterChooser), findsNothing);
  });

  testWidgets(
      'switching to a different tab dismisses chapter chooser',
      (tester) async {
    tabManager.openTab(43, 2); // John 2
    tabManager.openTab(45, 8); // Romans 8 (active)

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Open ChapterChooser on ROM 8
    await tester.tap(find.text('ROM 8'));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterChooser), findsOneWidget);

    // Tap JHN 2 tab
    await tester.tap(find.text('JHN 2'));
    await tester.pumpAndSettle();

    // Active tab switches to JHN 2, chapter chooser is dismissed
    expect(tabManager.activeTab?.label, equals('JHN 2'));
    expect(find.byType(ChapterChooser), findsNothing);
  });

  testWidgets(
      'tapping add tab button (+) dismisses chapter chooser',
      (tester) async {
    tabManager.openTab(43, 2); // John 2

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Open ChapterChooser on JHN 2
    await tester.tap(find.text('JHN 2'));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterChooser), findsOneWidget);

    // Tap + button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // BookChooser is shown, ChapterChooser is gone
    expect(tabManager.isAddingTab, isTrue);
    expect(find.byType(BookChooser), findsOneWidget);
    expect(find.byType(ChapterChooser), findsNothing);
  });

  testWidgets(
      'tapping active tab when showVerseGrid is true opens verse grid directly for active chapter',
      (tester) async {
    await userSettings.setShowVerseGrid(true);
    tabManager.openTab(43, 2); // John 2

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap JHN 2 active tab chip
    await tester.tap(find.text('JHN 2'));
    await tester.pumpAndSettle();

    // Directly opens GridVerseChooser for John 2
    expect(find.byType(GridVerseChooser), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GridVerseChooser),
        matching: find.text('John 2'),
      ),
      findsOneWidget,
    );

    // Tap back button returns to chapter chooser
    await tester.tap(find.byKey(const ValueKey('verse_grid_back')));
    await tester.pumpAndSettle();

    expect(find.byType(GridVerseChooser), findsNothing);
    expect(find.byType(ChapterChooser), findsOneWidget);
  });
}
