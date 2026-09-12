import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
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

    getIt.registerSingleton<AppState>(AppState());
  });

  tearDown(() {
    getIt.reset();
  });

  testWidgets('BottomNavigationBar shows More instead of Compare', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TextScreen(
            bookId: 19, // Psalm
            chapter: 23,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify BottomNavigationBar has 'More' item with more_horiz icon, and NOT 'Compare'
    expect(find.text('More'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    expect(find.text('Compare'), findsNothing);
  });

  testWidgets('Tapping More opens overflow menu with Compare and Cross Reference', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TextScreen(
            bookId: 19, // Psalm
            chapter: 23,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Trigger selection callback on ChapterText
    final chapterTextFinder = find.byType(ChapterText).first;
    expect(chapterTextFinder, findsOneWidget);
    final chapterText = tester.widget<ChapterText>(chapterTextFinder);

    // Psalm 23:4 packed wordId = 19023004001
    const packedWordId = 19023004001;
    final controller = ScriptureSelectionController();
    controller.selectWord(packedWordId);

    chapterText.onSelectionChanged!(controller);
    await tester.pumpAndSettle();

    // Tap More in bottom bar
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    // Verify popup menu shows Compare and Cross Reference
    expect(find.text('Compare'), findsOneWidget);
    expect(find.text('Cross Reference'), findsOneWidget);

    // Tap outside (barrier) to dismiss menu
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Menu is dismissed, but selection is NOT cleared because user cancelled
    expect(find.text('Cross Reference'), findsNothing);
    expect(controller.hasSelection, isTrue);
  });

  testWidgets('Selecting Compare or Cross Reference clears the selection', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TextScreen(
            bookId: 19, // Psalm
            chapter: 23,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chapterTextFinder = find.byType(ChapterText).first;
    final chapterText = tester.widget<ChapterText>(chapterTextFinder);

    const packedWordId = 19023004001;
    final controller = ScriptureSelectionController();
    controller.selectWord(packedWordId);

    chapterText.onSelectionChanged!(controller);
    await tester.pumpAndSettle();

    // Tap More in bottom bar
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    // Tap Compare
    await tester.tap(find.text('Compare'));
    await tester.pumpAndSettle();

    // Controller should now have selection cleared
    expect(controller.hasSelection, isFalse);
  });

  testWidgets('Selecting Cross Reference clears the selection', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TextScreen(
            bookId: 19, // Psalm
            chapter: 23,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chapterTextFinder = find.byType(ChapterText).first;
    final chapterText = tester.widget<ChapterText>(chapterTextFinder);

    const packedWordId = 19023004001;
    final controller = ScriptureSelectionController();
    controller.selectWord(packedWordId);

    chapterText.onSelectionChanged!(controller);
    await tester.pumpAndSettle();

    // Tap More in bottom bar
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    // Tap Cross Reference
    await tester.tap(find.text('Cross Reference'));
    await tester.pumpAndSettle();

    // Controller should now have selection cleared
    expect(controller.hasSelection, isFalse);
  });
}
