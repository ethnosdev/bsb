import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/home/book_chooser.dart';
import 'package:bsb/ui/home/home.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/chapter_chip.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
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
}
