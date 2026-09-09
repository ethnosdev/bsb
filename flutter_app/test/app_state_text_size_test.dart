import 'package:bsb/app_state.dart';
import 'package:bsb/core/font_scale.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/settings_manager.dart';
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
    });

    test('setTextSize updates notifier and persists to UserSettings', () async {
      final appState = AppState();
      await appState.init();

      await appState.setTextSize(24.0);
      expect(appState.textSizeNotifier.value, equals(24.0));
      expect(userSettings.textSize, equals(24.0));
    });

    test('setTextSize clamps values outside allowed range', () async {
      final appState = AppState();
      await appState.init();

      await appState.setTextSize(5.0);
      expect(appState.textSizeNotifier.value, equals(FontScale.minBaseSize));
      expect(userSettings.textSize, equals(FontScale.minBaseSize));

      await appState.setTextSize(35.0);
      expect(appState.textSizeNotifier.value, equals(FontScale.maxBaseSize));
      expect(userSettings.textSize, equals(FontScale.maxBaseSize));
    });
  });

  group('SettingsManager integration with AppState', () {
    test('reads from and updates AppState when registered', () async {
      final appState = AppState();
      await appState.init();
      getIt.registerSingleton<AppState>(appState);

      final settingsManager = SettingsManager();
      expect(settingsManager.textSize, equals(18.0));

      bool notified = false;
      settingsManager.addListener(() {
        notified = true;
      });

      await settingsManager.setTextSize(22.0);
      expect(notified, isTrue);
      expect(settingsManager.textSize, equals(22.0));
      expect(appState.textSizeNotifier.value, equals(22.0));
      expect(userSettings.textSize, equals(22.0));
    });

    test('falls back to UserSettings when AppState is not registered', () async {
      final settingsManager = SettingsManager();
      expect(settingsManager.textSize, equals(18.0));

      await settingsManager.setTextSize(16.0);
      expect(settingsManager.textSize, equals(16.0));
      expect(userSettings.textSize, equals(16.0));
    });
  });
}
