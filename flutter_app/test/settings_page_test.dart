import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    getIt.registerSingleton<AnnotationService>(
      AnnotationService(dbHelper: FakeAnnotationDbHelper()),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('SettingsPage renders backup & annotation options', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Light-Dark Theme'), findsOneWidget);
    expect(find.text('Text Size'), findsOneWidget);
    expect(find.text('Words of Jesus in Red'), findsOneWidget);
    expect(find.text('Navigation'), findsOneWidget);
    expect(find.text('Book Chooser'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Import Annotations'), 200);
    expect(find.text('Backup & Annotations'), findsOneWidget);
    expect(find.text('Export Annotations'), findsOneWidget);
    expect(find.text('Import Annotations'), findsOneWidget);

    // Tapping Export Annotations opens the format choice sheet
    await tester.tap(find.text('Export Annotations'));
    await tester.pumpAndSettle();

    expect(find.text('Export Backup (JSON)'), findsOneWidget);
    expect(find.text('Export as Markdown (.md)'), findsOneWidget);
  });

  testWidgets('SettingsPage allows changing Book Chooser between Grid and List', (tester) async {
    final userSettings = getIt<UserSettings>();
    expect(userSettings.bookChooserStyle, equals(BookChooserStyle.grid));

    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPage(),
      ),
    );
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
  });

  testWidgets('SettingsPage allows changing Chapter Chooser between Keypad and Grid', (tester) async {
    final userSettings = getIt<UserSettings>();
    expect(userSettings.chapterChooserStyle, equals(ChapterChooserStyle.keypad));

    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPage(),
      ),
    );
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

    expect(userSettings.chapterChooserStyle, equals(ChapterChooserStyle.grid));
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Chapter Chooser'),
        matching: find.text('Grid'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('SettingsPage allows changing Verse Chooser between Sidebar and Grid', (tester) async {
    final userSettings = getIt<UserSettings>();
    expect(userSettings.verseChooserStyle, equals(VerseChooserStyle.sidebar));
    expect(userSettings.showVerseGrid, isFalse);

    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPage(),
      ),
    );
    await tester.pumpAndSettle();

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
  });

  testWidgets('SettingsPage allows toggling Words of Jesus in Red', (tester) async {
    final userSettings = getIt<UserSettings>();
    expect(userSettings.wordsOfJesusInRed, isFalse);

    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Words of Jesus in Red'), findsOneWidget);
    final switchFinder = find.widgetWithText(SwitchListTile, 'Words of Jesus in Red');
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
}
