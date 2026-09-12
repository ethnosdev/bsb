import 'package:bsb/app_state.dart';
import 'package:bsb/core/strings.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/about.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      appName: 'Berean Standard Bible',
      packageName: 'dev.ethnos.bsb',
      version: '2.0.0',
      buildNumber: '28',
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

  testWidgets('AboutPage displays top elements in correct order and buttons work', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AboutPage(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. App logo at top
    expect(find.byType(Image), findsOneWidget);

    // 2. App version
    expect(find.text('App version: 2.0.0'), findsOneWidget);

    // 3. BSB version
    expect(find.text('BSB version: 3rd printing (7-31-2026)'), findsOneWidget);

    // 4. Website link
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is Text && widget.textSpan != null) {
          final span = widget.textSpan!;
          final text = span.toPlainText();
          return text.contains('Website: https://ethnos.dev');
        }
        return false;
      }),
      findsOneWidget,
    );

    // 5. 'Bible Hub: What is the BSB?' button
    final whatIsBsbButtonFinder = find.widgetWithText(OutlinedButton, 'Bible Hub: What is the BSB?');
    expect(whatIsBsbButtonFinder, findsOneWidget);

    // 6. 'Copy contact email' button
    final copyEmailButtonFinder = find.widgetWithText(OutlinedButton, 'Copy contact email');
    expect(copyEmailButtonFinder, findsOneWidget);

    // Verify 'App information' heading is not present at the bottom
    expect(find.text('App information'), findsNothing);

    // Tap 'Copy contact email' button
    String clipboardText = '';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.setData') {
        clipboardText = (methodCall.arguments as Map)['text'] as String;
        return null;
      } else if (methodCall.method == 'Clipboard.getData') {
        return {'text': clipboardText};
      }
      return null;
    });

    await tester.ensureVisible(copyEmailButtonFinder);
    await tester.tap(copyEmailButtonFinder);
    await tester.pump();

    // Verify clipboard content and SnackBar
    expect(clipboardText, equals('contact@ethnos.dev'));
    expect(find.text('Copied contact@ethnos.dev to clipboard'), findsOneWidget);
  });
}
