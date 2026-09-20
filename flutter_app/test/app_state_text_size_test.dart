import 'package:bsb/app_state.dart';
import 'package:bsb/core/font_scale.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserSettings userSettings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'textSize': 18.0,
    });
    await getIt.reset();
    userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('AppState text size management', () {
    test('init loads text size from UserSettings', () async {
      final appState = AppState();
      expect(appState.textSizeNotifier.value, equals(FontScale.defaultBaseSize));

      await appState.init();
      expect(appState.textSizeNotifier.value, equals(18.0));
      expect(appState.textSize, equals(18.0));
    });

    test('setTextSize updates notifier and persists to UserSettings', () async {
      final appState = AppState();
      await appState.init();

      await appState.setTextSize(24.0);
      expect(appState.textSizeNotifier.value, equals(24.0));
      expect(appState.textSize, equals(24.0));
      expect(userSettings.textSize, equals(24.0));
    });

    test('updateTextSizePreview updates notifier without persisting to UserSettings', () async {
      final appState = AppState();
      await appState.init();

      appState.updateTextSizePreview(22.0);
      expect(appState.textSizeNotifier.value, equals(22.0));
      expect(appState.textSize, equals(22.0));
      expect(userSettings.textSize, equals(18.0)); // UserSettings remains unmutated
    });

    test('setTextSize clamps values outside allowed range', () async {
      final appState = AppState();
      await appState.init();

      await appState.setTextSize(5.0);
      expect(appState.textSizeNotifier.value, equals(FontScale.minBaseSize));
      expect(userSettings.textSize, equals(FontScale.minBaseSize));

      await appState.setTextSize(55.0);
      expect(appState.textSizeNotifier.value, equals(FontScale.maxBaseSize));
      expect(userSettings.textSize, equals(FontScale.maxBaseSize));
    });

    test('AppState notifies listeners when text size or settings change', () async {
      final appState = AppState();
      await appState.init();

      int notifyCount = 0;
      appState.addListener(() {
        notifyCount++;
      });

      await appState.setTextSize(21.0);
      expect(notifyCount, greaterThan(0));

      final prevCount = notifyCount;
      appState.updateTextSizePreview(23.0);
      expect(notifyCount, greaterThan(prevCount));
    });
  });
}
