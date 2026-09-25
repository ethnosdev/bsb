import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/settings_page.dart';
import 'package:bsb/ui/settings/user_settings.dart';

import 'annotation_service_test.dart';

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
    expect(find.text('Words of Jesus in Red'), findsOneWidget);
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

  testWidgets('SettingsPage allows toggling Words of Jesus in Red', (
    tester,
  ) async {
    final userSettings = getIt<UserSettings>();
    expect(userSettings.wordsOfJesusInRed, isFalse);

    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Words of Jesus in Red'), findsOneWidget);
    final switchFinder = find.widgetWithText(
      SwitchListTile,
      'Words of Jesus in Red',
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
}
