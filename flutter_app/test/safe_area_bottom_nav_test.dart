import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/about.dart';
import 'package:bsb/ui/help.dart';
import 'package:bsb/ui/home/drawer.dart';
import 'package:bsb/ui/settings/settings_page.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:bsb/ui/text/chapter/chapter_text.dart';
import 'package:bsb/ui/text/note_editor_sheet.dart';
import 'package:bsb/ui/text/note_viewer_sheet.dart';
import 'package:bsb/ui/text/text_screen.dart';
import 'package:scripture/scripture.dart';

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
    await getIt.reset();

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

  tearDown(() async {
    await getIt.reset();
  });

  group('SafeArea Bottom Navigation Tests', () {
    testWidgets('NoteEditorSheet respects bottom safe area insets', (tester) async {
      const bottomInset = 48.0;
      const screenHeight = 800.0;
      const screenWidth = 400.0;

      await tester.binding.setSurfaceSize(const Size(screenWidth, screenHeight));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(screenWidth, screenHeight),
            viewPadding: EdgeInsets.only(bottom: bottomInset),
            padding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: NoteEditorSheet(
                title: 'Genesis 1:1',
                onSave: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final safeAreaFinder = find.descendant(
        of: find.byType(NoteEditorSheet),
        matching: find.byType(SafeArea),
      );
      expect(safeAreaFinder, findsOneWidget);
      final safeArea = tester.widget<SafeArea>(safeAreaFinder);
      expect(safeArea.top, isFalse);
      expect(safeArea.bottom, isTrue);

      final saveButtonFinder = find.text('Save');
      expect(saveButtonFinder, findsOneWidget);

      final saveButtonBottom = tester.getBottomRight(saveButtonFinder).dy;
      expect(saveButtonBottom, lessThanOrEqualTo(screenHeight - bottomInset));
    });

    testWidgets('NoteViewerSheet respects bottom safe area insets', (tester) async {
      const bottomInset = 48.0;
      const screenHeight = 800.0;
      const screenWidth = 400.0;

      await tester.binding.setSurfaceSize(const Size(screenWidth, screenHeight));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(screenWidth, screenHeight),
            viewPadding: EdgeInsets.only(bottom: bottomInset),
            padding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: NoteViewerSheet(
                title: 'Genesis 1:1',
                content: 'Test note',
                onSave: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final safeAreaFinder = find.descendant(
        of: find.byType(NoteViewerSheet),
        matching: find.byType(SafeArea),
      );
      expect(safeAreaFinder, findsOneWidget);
      final safeArea = tester.widget<SafeArea>(safeAreaFinder);
      expect(safeArea.top, isFalse);
      expect(safeArea.bottom, isTrue);
    });

    testWidgets('TextScreen BottomNavigationBar is wrapped in SafeArea(top: false)', (tester) async {
      const bottomInset = 48.0;
      const screenHeight = 800.0;
      const screenWidth = 400.0;

      await tester.binding.setSurfaceSize(const Size(screenWidth, screenHeight));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(screenWidth, screenHeight),
            viewPadding: EdgeInsets.only(bottom: bottomInset),
            padding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: const MaterialApp(
            home: Scaffold(
              body: TextScreen(
                bookId: 19,
                chapter: 23,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger text selection to show the bottom menu bar
      final chapterTextFinder = find.byType(ChapterText).first;
      final chapterText = tester.widget<ChapterText>(chapterTextFinder);
      final controller = ScriptureSelectionController();
      controller.selectWord(19023004001);
      chapterText.onSelectionChanged?.call(controller);
      await tester.pumpAndSettle();

      final navBarFinder = find.byType(BottomNavigationBar);
      expect(navBarFinder, findsOneWidget);

      final safeAreaFinder = find.ancestor(
        of: navBarFinder,
        matching: find.byType(SafeArea),
      );
      expect(safeAreaFinder, findsWidgets);

      final safeArea = tester.widget<SafeArea>(safeAreaFinder.first);
      expect(safeArea.top, isFalse);
      expect(safeArea.bottom, isTrue);
    });

    testWidgets('SettingsPage body uses SafeArea(top: false)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldFinder = find.byType(Scaffold);
      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      expect(scaffold.body, isA<SafeArea>());
      final safeArea = scaffold.body as SafeArea;
      expect(safeArea.top, isFalse);
      expect(safeArea.bottom, isTrue);
    });

    testWidgets('HelpPage body uses SafeArea(top: false)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpPage(),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldFinder = find.byType(Scaffold);
      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      expect(scaffold.body, isA<SafeArea>());
      final safeArea = scaffold.body as SafeArea;
      expect(safeArea.top, isFalse);
      expect(safeArea.bottom, isTrue);
    });

    testWidgets('AboutPage body uses SafeArea(top: false)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutPage(),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldFinder = find.byType(Scaffold);
      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      expect(scaffold.body, isA<SafeArea>());
      final safeArea = scaffold.body as SafeArea;
      expect(safeArea.top, isFalse);
      expect(safeArea.bottom, isTrue);
    });

    testWidgets('AppDrawer contains SafeArea(top: false)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            drawer: AppDrawer(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open drawer
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      final drawerFinder = find.byType(Drawer);
      expect(drawerFinder, findsOneWidget);

      final safeAreaFinder = find.descendant(
        of: drawerFinder,
        matching: find.byType(SafeArea),
      );
      // The direct child of Drawer is a SafeArea with top: false, bottom: true
      final safeArea = tester.widget<SafeArea>(safeAreaFinder.first);
      expect(safeArea.top, isFalse);
      expect(safeArea.bottom, isTrue);
    });
  });
}
