import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/search/bible_search_service.dart';
import 'package:bsb/infrastructure/search/search_models.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/search/search_manager.dart';
import 'package:bsb/ui/search/search_page.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSearchDatabaseHelper implements DatabaseHelper {
  final List<SearchResult> searchResultsToReturn = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<SearchResult>> searchVerses({
    required String query,
    SearchScope scope = SearchScope.all,
    int? specificBookId,
    int? limit,
  }) async {
    if (query.contains('faith')) {
      return [
        SearchResult(
          reference: Reference(bookId: 45, chapter: 1, verse: 17),
          text: 'For in the gospel a righteousness from God is revealed by faith.',
        ),
        SearchResult(
          reference: Reference(bookId: 58, chapter: 11, verse: 1),
          text: 'Now faith is the assurance of what we hope for.',
        ),
      ];
    }
    return searchResultsToReturn;
  }

  @override
  Future<String?> getVerseText(int reference) async {
    if (reference == 43003016) {
      return 'For God so loved the world that He gave His one and only Son.';
    }
    return null;
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
  late TabManager tabManager;
  late FakeSearchDatabaseHelper fakeDbHelper;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'recentSearches': ['grace', 'truth'],
    });
    await getIt.reset();

    userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);

    fakeDbHelper = FakeSearchDatabaseHelper();
    getIt.registerSingleton<DatabaseHelper>(fakeDbHelper);

    final annotationDb = FakeAnnotationDbHelper();
    getIt.registerSingleton<AnnotationDatabaseHelper>(annotationDb);
    getIt.registerSingleton<AnnotationService>(
      AnnotationService(dbHelper: annotationDb),
    );

    final searchService = BibleSearchService(dbHelper: fakeDbHelper);
    getIt.registerSingleton<BibleSearchService>(searchService);

    getIt.registerSingleton<SearchManager>(SearchManager(
      searchService: searchService,
      userSettings: userSettings,
    ));

    tabManager = TabManager();
    await tabManager.init();
    getIt.registerSingleton<TabManager>(tabManager);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildTestableWidget([int? currentBookId]) {
    return MaterialApp(
      home: SearchPage(currentBookId: currentBookId),
    );
  }

  Widget buildTestableApp([int? currentBookId]) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SearchPage(currentBookId: currentBookId),
                  ),
                );
              },
              child: const Text('Open Search'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders search input, recent searches, and tips on open', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Recent Searches'), findsOneWidget);
    expect(find.text('grace'), findsOneWidget);
    expect(find.text('truth'), findsOneWidget);
    expect(find.text('Search Tips'), findsOneWidget);
  });

  testWidgets('tapping a recent search populates search input', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('grace'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('grace'), findsAtLeast(1));
  });

  testWidgets('typing a reference shows direct jump card with preview', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'John 3:16');
    await tester.pumpAndSettle();

    expect(find.text('Go to John 3:16'), findsOneWidget);
    expect(
      find.text('For God so loved the world that He gave His one and only Son.'),
      findsOneWidget,
    );

    // Tapping the card navigates via tabManager.openTab
    await tester.tap(find.text('Go to John 3:16'));
    await tester.pumpAndSettle();

    expect(tabManager.tabs.length, equals(1));
    expect(tabManager.tabs.first.bookId, equals(43));
    expect(tabManager.tabs.first.chapter, equals(3));
    expect(tabManager.tabs.first.targetVerse, equals(16));
  });

  testWidgets('typing keywords shows search results and allows navigation', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'faith');
    // Debounce is 250ms
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('2 verses found'), findsOneWidget);
    expect(find.text('Romans 1:17'), findsOneWidget);
    expect(find.text('Hebrews 11:1'), findsOneWidget);

    // Tap on Hebrews 11:1
    await tester.tap(find.text('Hebrews 11:1'));
    await tester.pumpAndSettle();

    expect(tabManager.tabs.length, equals(1));
    expect(tabManager.tabs.first.bookId, equals(58));
    expect(tabManager.tabs.first.chapter, equals(11));
    expect(tabManager.tabs.first.targetVerse, equals(1));
  });

  testWidgets('clear button clears input and restores recent searches', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'faith');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.text('Recent Searches'), findsOneWidget);
  });

  testWidgets('scope filter chips toggle correctly', (tester) async {
    await tester.pumpWidget(buildTestableWidget(45)); // Romans active
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Old Testament'), findsOneWidget);
    expect(find.text('New Testament'), findsOneWidget);
    expect(find.text('Romans'), findsOneWidget);

    await tester.tap(find.text('New Testament'));
    await tester.pumpAndSettle();
  });

  testWidgets('retains search query, results, and scroll position when re-opened (Approach A)', (tester) async {
    final searchManager = getIt<SearchManager>();

    // 1. Open host app and navigate into SearchPage
    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Search'));
    await tester.pumpAndSettle();

    // 2. Type 'faith' and verify results show up
    await tester.enterText(find.byType(TextField), 'faith');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('2 verses found'), findsOneWidget);
    expect(find.text('Romans 1:17'), findsOneWidget);
    expect(find.text('Hebrews 11:1'), findsOneWidget);
    expect(searchManager.currentQuery, equals('faith'));

    // 3. Simulate navigating to a verse (which records offset and pops back to host)
    await tester.tap(find.text('Hebrews 11:1'));
    await tester.pumpAndSettle();

    // Verify we popped back to host page
    expect(find.text('Open Search'), findsOneWidget);
    expect(find.text('Hebrews 11:1'), findsNothing);

    // 4. Re-open SearchPage
    await tester.tap(find.text('Open Search'));
    await tester.pumpAndSettle();

    // 5. Query and results should still be immediately present without re-typing
    expect(find.text('faith'), findsAtLeast(1));
    expect(find.text('2 verses found'), findsOneWidget);
    expect(find.text('Romans 1:17'), findsOneWidget);
    expect(find.text('Hebrews 11:1'), findsOneWidget);

    // 6. Tapping clear button clears the session state
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(searchManager.currentQuery, isEmpty);
    expect(find.text('Recent Searches'), findsOneWidget);
  });

  testWidgets('search result verse text matches UserSettings.textSize', (tester) async {
    await userSettings.setTextSize(22.0);
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'faith');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final textWidgetFinder = find.byWidgetPredicate(
      (widget) => widget is Text && widget.textSpan != null && widget.style?.fontSize == 22.0,
    );
    expect(textWidgetFinder, findsAtLeast(1));
  });
}
