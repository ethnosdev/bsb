import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/screen_wake_service.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/main.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:bsb/ui/text/text_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeScreenWakeDbHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async {
    return [
      UsfmLine(
        bookChapterVerse: 1001001,
        text: 'In the beginning God created the heavens and the earth.',
        format: ParagraphFormat.p,
      ),
    ];
  }
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

  group('ScreenWakeService', () {
    test('enable, disable, and setAwake update isAwake safely', () async {
      final service = ScreenWakeService();
      expect(service.isAwake, isFalse);

      await service.enable();
      expect(service.isAwake, isTrue);

      await service.disable();
      expect(service.isAwake, isFalse);

      await service.setAwake(true);
      expect(service.isAwake, isTrue);

      await service.setAwake(false);
      expect(service.isAwake, isFalse);
    });
  });

  group('UserSettings keepScreenAwake', () {
    test('defaults to true and persists changes', () async {
      SharedPreferences.setMockInitialValues({});
      final userSettings = UserSettings();
      await userSettings.init();

      expect(userSettings.keepScreenAwake, isTrue);

      await userSettings.setKeepScreenAwake(false);
      expect(userSettings.keepScreenAwake, isFalse);

      await userSettings.setKeepScreenAwake(true);
      expect(userSettings.keepScreenAwake, isTrue);
    });
  });

  group('AppState keepScreenAwake', () {
    test('initializes and notifies on change', () async {
      SharedPreferences.setMockInitialValues({});
      final userSettings = UserSettings();
      await userSettings.init();
      getIt.reset();
      getIt.registerSingleton<UserSettings>(userSettings);

      final appState = AppState();
      await appState.init();

      expect(appState.keepScreenAwake, isTrue);

      bool notified = false;
      appState.keepScreenAwakeNotifier.addListener(() {
        notified = true;
      });

      await appState.setKeepScreenAwake(false);
      expect(appState.keepScreenAwake, isFalse);
      expect(userSettings.keepScreenAwake, isFalse);
      expect(notified, isTrue);

      await appState.setKeepScreenAwake(true);
      expect(appState.keepScreenAwake, isTrue);
      expect(userSettings.keepScreenAwake, isTrue);
    });
  });

  group('TextScreen ScreenWake integration', () {
    late UserSettings userSettings;
    late AppState appState;
    late ScreenWakeService screenWakeService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await getIt.reset();

      userSettings = UserSettings();
      await userSettings.init();
      getIt.registerSingleton<UserSettings>(userSettings);

      appState = AppState();
      await appState.init();
      getIt.registerSingleton<AppState>(appState);

      screenWakeService = ScreenWakeService();
      getIt.registerSingleton<ScreenWakeService>(screenWakeService);

      getIt.registerSingleton<DatabaseHelper>(FakeScreenWakeDbHelper());
      final annotationDb = FakeAnnotationDbHelper();
      getIt.registerSingleton<AnnotationDatabaseHelper>(annotationDb);
      getIt.registerSingleton<AnnotationService>(
        AnnotationService(dbHelper: annotationDb),
      );

      final tabManager = TabManager();
      await tabManager.init();
      getIt.registerSingleton<TabManager>(tabManager);
    });

    tearDown(() async {
      await getIt.reset();
    });

    testWidgets(
      'enables wakelock while reading, toggles with setting, disables on navigation and dispose',
      (tester) async {
        expect(screenWakeService.isAwake, isFalse);

        await tester.pumpWidget(
          MaterialApp(
            navigatorObservers: [routeObserver],
            home: const TextScreen(
              bookId: 1,
              chapter: 1,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Screen wakelock should be enabled while reading
        expect(screenWakeService.isAwake, isTrue);

        // Disabling setting should turn off wakelock
        await appState.setKeepScreenAwake(false);
        await tester.pumpAndSettle();
        expect(screenWakeService.isAwake, isFalse);

        // Re-enabling setting turns it back on
        await appState.setKeepScreenAwake(true);
        await tester.pumpAndSettle();
        expect(screenWakeService.isAwake, isTrue);

        // Pushing a new route (e.g. Settings) should disable wakelock
        final BuildContext context = tester.element(find.byType(TextScreen));
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Second Page')),
          ),
        );
        await tester.pumpAndSettle();
        expect(screenWakeService.isAwake, isFalse);

        // Popping back to TextScreen should re-enable wakelock
        Navigator.of(tester.element(find.text('Second Page'))).pop();
        await tester.pumpAndSettle();
        expect(screenWakeService.isAwake, isTrue);

        // When TextScreen is replaced / disposed, wakelock should be disabled
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Text('Empty')),
          ),
        );
        await tester.pumpAndSettle();
        expect(screenWakeService.isAwake, isFalse);
      },
    );
  });
}
