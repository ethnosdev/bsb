import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart' hide RenderParagraph;
import 'package:scripture/scripture_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bsb/app_state.dart';
import 'package:bsb/core/theme.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/search/bible_search_service.dart';
import 'package:bsb/infrastructure/search/search_models.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/search/search_manager.dart';
import 'package:bsb/ui/settings/settings_page.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/text/chapter/chapter_manager.dart';

import 'annotation_service_test.dart';

class _FakeChapterDatabaseHelper extends DatabaseHelper {
  Completer<List<UsfmLine>>? pendingChapterCompleter;
  int getChapterCallCount = 0;

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async {
    getChapterCallCount++;
    if (pendingChapterCompleter != null) {
      return pendingChapterCompleter!.future;
    }
    return [
      UsfmLine(
        bookChapterVerse: bookId * 1000000 + chapter * 1000 + 1,
        text: useBritishSpelling ? 'favour' : 'favor',
        format: ParagraphFormat.p,
      ),
    ];
  }
}

class _CountingSearchService extends BibleSearchService {
  _CountingSearchService({required super.dbHelper});

  int searchCallCount = 0;

  @override
  Future<List<SearchResult>> searchVerses({
    required String query,
    SearchScope scope = SearchScope.all,
    int? specificBookId,
    int? limit,
    bool isExact = false,
  }) async {
    searchCallCount++;
    return const [];
  }
}

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    final userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);
    final appState = AppState(userSettings: userSettings);
    await appState.init();
    getIt.registerSingleton<AppState>(appState);
    getIt.registerSingleton<AnnotationService>(
      AnnotationService(dbHelper: FakeAnnotationDbHelper()),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('SettingsPage renders backup options', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Light-Dark Mode'), findsOneWidget);
    expect(find.text('Color Theme'), findsOneWidget);
    expect(find.text('Text Size'), findsOneWidget);
    expect(find.text('Words of Jesus in Color'), findsOneWidget);
    expect(find.text('Navigation'), findsOneWidget);
    expect(find.text('Book Chooser'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Import Backup'), 200);
    expect(find.text('Backup'), findsOneWidget);
    expect(find.text('Export Backup'), findsOneWidget);
    expect(find.text('Import Backup'), findsOneWidget);

    // Tapping Export Backup opens the format choice sheet
    await tester.tap(find.text('Export Backup'));
    await tester.pumpAndSettle();

    expect(find.text('Export Backup (JSON)'), findsOneWidget);
    expect(find.text('Export as Markdown (.md)'), findsOneWidget);
  });

  testWidgets(
    'SettingsPage allows changing Book Chooser between Grid and List',
    (tester) async {
      final userSettings = getIt<UserSettings>();
      expect(userSettings.bookChooserStyle, equals(BookChooserStyle.grid));

      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Book Chooser'), findsOneWidget);
      expect(find.text('Grid'), findsOneWidget);

      // Tap to open choice dialog
      await tester.tap(find.text('Book Chooser'));
      await tester.pumpAndSettle();

      // Tap 'List' segment
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle();

      expect(userSettings.bookChooserStyle, equals(BookChooserStyle.list));
      expect(find.text('List'), findsOneWidget);
    },
  );

  testWidgets(
    'SettingsPage allows changing Chapter Chooser between Keypad and Grid',
    (tester) async {
      final userSettings = getIt<UserSettings>();
      expect(
        userSettings.chapterChooserStyle,
        equals(ChapterChooserStyle.keypad),
      );

      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Chapter Chooser'), findsOneWidget);
      expect(find.text('Keypad'), findsOneWidget);

      // Tap to open choice dialog
      await tester.tap(find.text('Chapter Chooser'));
      await tester.pumpAndSettle();

      // Tap 'Grid' segment in dialog
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Grid'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        userSettings.chapterChooserStyle,
        equals(ChapterChooserStyle.grid),
      );
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Chapter Chooser'),
          matching: find.text('Grid'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'SettingsPage allows changing Verse Chooser between Sidebar and Grid',
    (tester) async {
      final userSettings = getIt<UserSettings>();
      expect(userSettings.verseChooserStyle, equals(VerseChooserStyle.sidebar));
      expect(userSettings.showVerseGrid, isFalse);

      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Verse Chooser'), 100);
      expect(find.text('Verse Chooser'), findsOneWidget);
      expect(find.text('Sidebar'), findsOneWidget);

      // Tap to open choice dialog
      await tester.tap(find.text('Verse Chooser'));
      await tester.pumpAndSettle();

      // Tap 'Grid' segment in dialog
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Grid'),
        ),
      );
      await tester.pumpAndSettle();

      expect(userSettings.verseChooserStyle, equals(VerseChooserStyle.grid));
      expect(userSettings.showVerseGrid, isTrue);
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Verse Chooser'),
          matching: find.text('Grid'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('SettingsPage allows toggling Words of Jesus in Color', (
    tester,
  ) async {
    final userSettings = getIt<UserSettings>();
    expect(userSettings.wordsOfJesusInRed, isFalse);

    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Words of Jesus in Color'), findsOneWidget);
    final switchFinder = find.widgetWithText(
      SwitchListTile,
      'Words of Jesus in Color',
    );
    expect(switchFinder, findsOneWidget);

    final switchWidget = tester.widget<SwitchListTile>(switchFinder);
    expect(switchWidget.value, isFalse);

    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(userSettings.wordsOfJesusInRed, isTrue);
    final updatedSwitch = tester.widget<SwitchListTile>(switchFinder);
    expect(updatedSwitch.value, isTrue);
  });

  testWidgets('SettingsPage allows toggling Keep Screen Awake', (tester) async {
    final userSettings = getIt<UserSettings>();
    final appState = getIt<AppState>();
    expect(userSettings.keepScreenAwake, isTrue);
    expect(appState.keepScreenAwake, isTrue);

    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Keep Screen Awake'), findsOneWidget);
    expect(
      find.text('Prevent screen from turning off while reading'),
      findsOneWidget,
    );
    final switchFinder = find.widgetWithText(
      SwitchListTile,
      'Keep Screen Awake',
    );
    expect(switchFinder, findsOneWidget);

    final switchWidget = tester.widget<SwitchListTile>(switchFinder);
    expect(switchWidget.value, isTrue);

    // Tap to turn off
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(userSettings.keepScreenAwake, isFalse);
    expect(appState.keepScreenAwake, isFalse);
    final updatedSwitch = tester.widget<SwitchListTile>(switchFinder);
    expect(updatedSwitch.value, isFalse);

    // Tap to turn back on
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(userSettings.keepScreenAwake, isTrue);
    expect(appState.keepScreenAwake, isTrue);
  });

  testWidgets(
    'SettingsPage allows changing Light-Dark Mode between Light, Device, and Dark',
    (tester) async {
      final appState = getIt<AppState>();
      expect(appState.themeMode, equals(ThemeMode.system));

      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Light-Dark Mode'), findsOneWidget);
      expect(find.text('Match device settings'), findsOneWidget);

      // Tap to open choice dialog
      await tester.tap(find.text('Light-Dark Mode'));
      await tester.pumpAndSettle();

      // Verify all 3 options exist
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Device'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      // Tap 'Dark' segment in dialog
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Dark'),
        ),
      );
      await tester.pumpAndSettle();

      expect(appState.themeMode, equals(ThemeMode.dark));
      expect(find.text('Dark'), findsOneWidget);

      // Tap again to switch back to Device
      await tester.tap(find.text('Light-Dark Mode'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Device'),
        ),
      );
      await tester.pumpAndSettle();

      expect(appState.themeMode, equals(ThemeMode.system));
      expect(find.text('Match device settings'), findsOneWidget);
    },
  );

  testWidgets(
    'SettingsPage disables Light-Dark Mode with note when Custom Theme is active and restores it on preset',
    (tester) async {
      final appState = getIt<AppState>();
      await appState.setThemeMode(ThemeMode.dark);
      await appState.applyThemeSelection(
        themeId: AppThemePreset.customPresetId,
        customConfig: CustomThemeConfig.defaultConfig(),
      );

      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Disabled for custom theme'), findsOneWidget);
      final lightDarkTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Light-Dark Mode'),
          matching: find.byType(ListTile),
        ),
      );
      expect(lightDarkTile.enabled, isFalse);

      // Tapping disabled tile does not open dialog
      await tester.tap(find.text('Light-Dark Mode'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      // Switching back to preset restores saved Light-Dark Mode
      await appState.applyThemeSelection(themeId: 'sepia');
      await tester.pumpAndSettle();

      expect(find.text('Disabled for custom theme'), findsNothing);
      expect(find.text('Dark'), findsOneWidget);
    },
  );

  testWidgets('SettingsPage allows navigating to ThemeSelectionPage', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Color Theme'), findsOneWidget);
    await tester.tap(find.text('Color Theme'));
    await tester.pumpAndSettle();

    expect(find.text('Reading Themes'), findsOneWidget);
  });

  testWidgets(
    'Light-Dark Mode selector fits on narrow screen without wrapping Device',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Light-Dark Mode'));
      await tester.pumpAndSettle();

      final textFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Device'),
      );
      expect(textFinder, findsOneWidget);

      final renderParagraph = tester.renderObject<RenderParagraph>(textFinder);
      final textPainter = TextPainter(
        text: renderParagraph.text,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: renderParagraph.size.width);
      expect(textPainter.computeLineMetrics().length, 1);
    },
  );

  group('British English Spelling settings & state coordination', () {
    testWidgets(
      'SettingsPage displays Bible Text section, caption, and persists toggle cleanly',
      (tester) async {
        final userSettings = getIt<UserSettings>();
        final appState = getIt<AppState>();
        expect(userSettings.useBritishSpelling, isFalse);
        expect(appState.useBritishSpelling, isFalse);

        await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('British English Spelling'),
          150,
        );
        expect(find.text('Bible Text'), findsOneWidget);
        expect(find.text('British English Spelling'), findsOneWidget);
        expect(
          find.text(
            'The Berean Standard Bible text uses American spelling. This setting replaces the American spellings with their British equivalents within the app.',
          ),
          findsOneWidget,
        );

        final switchFinder = find.widgetWithText(
          SwitchListTile,
          'British English Spelling',
        );
        expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);

        // Turn ON
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        expect(userSettings.useBritishSpelling, isTrue);
        expect(appState.useBritishSpelling, isTrue);
        expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('useBritishSpelling'), isTrue);

        // Turn OFF: removes SharedPreferences key cleanly
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        expect(userSettings.useBritishSpelling, isFalse);
        expect(appState.useBritishSpelling, isFalse);
        expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);
        expect(prefs.containsKey('useBritishSpelling'), isFalse);
      },
    );

    test('AppState syncs DatabaseHelper on cold start and clears chapter cache before notifying listeners', () async {
      sqfliteFfiInit();
      SharedPreferences.setMockInitialValues({'useBritishSpelling': true});
      final settings = UserSettings();
      await settings.init();

      final dbPath = '${Directory.current.path}/assets/database/database.db';
      final db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      final dbHelper = DatabaseHelper()..setDatabaseForTesting(db);

      final coldStartState = AppState(
        userSettings: settings,
        dbHelper: dbHelper,
      );
      await coldStartState.init();

      expect(coldStartState.useBritishSpelling, isTrue);
      expect(dbHelper.useBritishSpelling, isTrue);

      await dbHelper.getChapterWords(1, 6);
      expect(dbHelper.chapterWordsCacheLength, greaterThan(0));

      var observedDbStateInListener = true;
      var observedCacheLengthInListener = -1;
      coldStartState.useBritishSpellingNotifier.addListener(() {
        observedDbStateInListener = dbHelper.useBritishSpelling;
        observedCacheLengthInListener = dbHelper.chapterWordsCacheLength;
      });

      await coldStartState.setUseBritishSpelling(false);
      expect(observedDbStateInListener, isFalse);
      expect(observedCacheLengthInListener, equals(0));

      coldStartState.dispose();
      await db.close();
    });

    test('ChapterManager reloads active chapter on spelling toggle and guards disposal', () async {
      await getIt.reset();
      SharedPreferences.setMockInitialValues({});
      final settings = UserSettings();
      await settings.init();
      final fakeDb = _FakeChapterDatabaseHelper();
      final appState = AppState(userSettings: settings, dbHelper: fakeDb);
      await appState.init();

      getIt.registerSingleton<UserSettings>(settings);
      getIt.registerSingleton<DatabaseHelper>(fakeDb);
      getIt.registerSingleton<AppState>(appState);
      getIt.registerSingleton<AnnotationService>(
        AnnotationService(dbHelper: FakeAnnotationDbHelper()),
      );

      final manager = ChapterManager();
      // Before any chapter is loaded, toggling must not issue a 0/0 read
      await appState.setUseBritishSpelling(true);
      expect(fakeDb.getChapterCallCount, equals(0));

      await appState.setUseBritishSpelling(false);
      await manager.requestText(bookId: 1, chapter: 6);
      expect(fakeDb.getChapterCallCount, equals(1));
      expect(manager.textParagraphNotifier.value.single.text, equals('favor'));

      await appState.setUseBritishSpelling(true);
      await Future<void>.delayed(Duration.zero);
      expect(fakeDb.getChapterCallCount, equals(2));
      expect(manager.textParagraphNotifier.value.single.text, equals('favour'));

      // Pending async read completed after dispose() must not throw
      final completer = Completer<List<UsfmLine>>();
      fakeDb.pendingChapterCompleter = completer;
      final pendingFuture = manager.requestText(bookId: 1, chapter: 7);
      manager.dispose();
      completer.complete([
        UsfmLine(
          bookChapterVerse: 1007001,
          text: 'late',
          format: ParagraphFormat.p,
        ),
      ]);
      await pendingFuture;
      appState.dispose();
    });

    test('SearchManager.init refreshes stale query only when spelling setting changed', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = UserSettings();
      await settings.init();
      final fakeDb = _FakeChapterDatabaseHelper();
      final searchService = _CountingSearchService(dbHelper: fakeDb);
      final searchManager = SearchManager(
        searchService: searchService,
        userSettings: settings,
      );

      searchManager.init();
      expect(searchService.searchCallCount, equals(0));

      searchManager.onQueryChanged('favour');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(searchService.searchCallCount, equals(1));

      // Toggling spelling does not execute a background query before init()
      fakeDb.setUseBritishSpelling(true);
      expect(searchService.searchCallCount, equals(1));

      // Re-entering SearchTab runs init() and refreshes stale results
      searchManager.init();
      await Future<void>.delayed(Duration.zero);
      expect(searchService.searchCallCount, equals(2));

      // Calling init() again with unchanged spelling does not re-query
      searchManager.init();
      await Future<void>.delayed(Duration.zero);
      expect(searchService.searchCallCount, equals(2));

      searchManager.dispose();
    });
  });
}
