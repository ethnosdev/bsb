import 'package:bsb/app_state.dart';
import 'package:bsb/core/font_scale.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/about.dart';
import 'package:bsb/ui/help.dart';
import 'package:bsb/ui/settings/settings_manager.dart';
import 'package:bsb/ui/settings/settings_page.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState appState;
  late UserSettings userSettings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'textSize': 20.0,
      'themeMode': 'system',
    });
    PackageInfo.setMockInitialValues(
      appName: 'BSB',
      packageName: 'com.example.bsb',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await getIt.reset();

    userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);

    appState = AppState();
    await appState.init();
    getIt.registerSingleton<AppState>(appState);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('SettingsPage slider immediately updates AppState.textSizeNotifier', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPage(),
      ),
    );

    expect(find.text('Text Size'), findsWidgets);
    expect(find.text('20.0'), findsOneWidget);

    // Open text size slider dialog
    await tester.tap(find.text('Text Size').first);
    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsOneWidget);

    // Move slider
    final slider = find.byType(Slider);
    await tester.drag(slider, const Offset(100, 0));
    await tester.pumpAndSettle();

    // Verify AppState was updated immediately
    expect(appState.textSizeNotifier.value, isNot(equals(20.0)));
    expect(userSettings.textSize, equals(appState.textSizeNotifier.value));
  });

  testWidgets('AboutPage reactively scales text when AppState text size changes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AboutPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Initial check: gratitude text style font size should be 20.0
    final textFinder = find.text('Gratitude');
    expect(textFinder, findsOneWidget);
    Text textWidget = tester.widget<Text>(textFinder);
    expect(textWidget.style?.fontSize, equals(FontScale.infoTitle(20.0)));

    // Update text size via AppState
    await appState.setTextSize(26.0);
    await tester.pump();

    // Verify that AboutPage text updated immediately without rebuilding or re-navigating
    textWidget = tester.widget<Text>(textFinder);
    expect(textWidget.style?.fontSize, equals(FontScale.infoTitle(26.0)));
  });

  testWidgets('HelpPage reactively scales text when AppState text size changes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HelpPage(),
      ),
    );
    await tester.pumpAndSettle();

    final titleFinder = find.text('Chapter selection');
    expect(titleFinder, findsOneWidget);
    Text textWidget = tester.widget<Text>(titleFinder);
    expect(textWidget.style?.fontSize, equals(FontScale.infoTitle(20.0)));

    // Change text size to 14.0
    await appState.setTextSize(14.0);
    await tester.pump();

    textWidget = tester.widget<Text>(titleFinder);
    expect(textWidget.style?.fontSize, equals(FontScale.infoTitle(14.0)));
  });

  testWidgets('SettingsManager changes propagate to ValueListenableBuilder consumers', (tester) async {
    double? observedSize;

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<double>(
          valueListenable: appState.textSizeNotifier,
          builder: (context, size, _) {
            observedSize = size;
            return Text('Current: $size');
          },
        ),
      ),
    );

    expect(observedSize, equals(20.0));
    expect(find.text('Current: 20.0'), findsOneWidget);

    final manager = SettingsManager();
    await manager.setTextSize(28.0);
    await tester.pump();

    expect(observedSize, equals(28.0));
    expect(find.text('Current: 28.0'), findsOneWidget);
  });
}
