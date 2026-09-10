import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bsb/infrastructure/annotation_database.dart';
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
    expect(find.text('Backup & Annotations'), findsOneWidget);
    expect(find.text('Export Annotations'), findsOneWidget);
    expect(find.text('Import Annotations'), findsOneWidget);

    // Tapping Export Annotations opens the format choice sheet
    await tester.tap(find.text('Export Annotations'));
    await tester.pumpAndSettle();

    expect(find.text('Export Backup (JSON)'), findsOneWidget);
    expect(find.text('Export as Markdown (.md)'), findsOneWidget);
  });
}
