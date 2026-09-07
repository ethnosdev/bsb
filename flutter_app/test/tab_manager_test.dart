import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserSettings userSettings;
  late TabManager tabManager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    if (getIt.isRegistered<UserSettings>()) {
      getIt.unregister<UserSettings>();
    }
    userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);

    tabManager = TabManager();
  });

  tearDown(() {
    getIt.reset();
  });

  group('TabManager', () {
    test('initial state is empty', () async {
      await tabManager.init();
      expect(tabManager.tabs, isEmpty);
      expect(tabManager.activeTab, isNull);
      expect(tabManager.activeTabId, isNull);
      expect(tabManager.isAddingTab, isFalse);
    });

    test('openTab adds a tab and sets it active', () async {
      await tabManager.init();
      tabManager.openTab(1, 1); // Genesis 1

      expect(tabManager.tabs.length, 1);
      expect(tabManager.activeTab?.bookId, 1);
      expect(tabManager.activeTab?.chapter, 1);
      expect(tabManager.activeTab?.label, 'GEN 1');
    });

    test('openTab with existing book and chapter focuses existing without duplicate', () async {
      await tabManager.init();
      tabManager.openTab(1, 1); // GEN 1
      tabManager.openTab(45, 8); // ROM 8

      expect(tabManager.tabs.length, 2);
      expect(tabManager.activeTab?.label, 'ROM 8');

      // Re-open GEN 1
      tabManager.openTab(1, 1);
      expect(tabManager.tabs.length, 2);
      expect(tabManager.activeTab?.label, 'GEN 1');
    });

    test('updateActiveChapter updates the current tab in place', () async {
      await tabManager.init();
      tabManager.openTab(1, 1); // GEN 1
      expect(tabManager.activeTab?.label, 'GEN 1');

      tabManager.updateActiveChapter(1, 2); // Swipe to GEN 2
      expect(tabManager.activeTab?.label, 'GEN 2');
      expect(tabManager.tabs.length, 1);
    });

    test('closeTab on active tab falls back to most recently visited tab (LRU)', () async {
      await tabManager.init();
      tabManager.openTab(1, 1); // GEN 1
      tabManager.openTab(19, 23); // PSA 23
      tabManager.openTab(45, 8); // ROM 8

      // Visit order: GEN 1 -> PSA 23 -> ROM 8 (active)
      // Switch to GEN 1
      final gen1Id = tabManager.tabs[0].id;
      tabManager.selectTab(gen1Id);
      // Visit order: PSA 23 -> ROM 8 -> GEN 1 (active)

      // Close GEN 1 -> should fall back to ROM 8
      tabManager.closeTab(gen1Id);
      expect(tabManager.tabs.length, 2);
      expect(tabManager.activeTab?.label, 'ROM 8');

      // Close ROM 8 -> should fall back to PSA 23
      final rom8Id = tabManager.tabs.firstWhere((t) => t.label == 'ROM 8').id;
      tabManager.closeTab(rom8Id);
      expect(tabManager.tabs.length, 1);
      expect(tabManager.activeTab?.label, 'PSA 23');

      // Close PSA 23 -> should be empty
      final psa23Id = tabManager.tabs.first.id;
      tabManager.closeTab(psa23Id);
      expect(tabManager.tabs, isEmpty);
      expect(tabManager.activeTab, isNull);
    });

    test('isAddingTab toggles correctly', () async {
      await tabManager.init();
      expect(tabManager.isAddingTab, isFalse);

      tabManager.startAddingTab();
      expect(tabManager.isAddingTab, isTrue);

      tabManager.cancelAddingTab();
      expect(tabManager.isAddingTab, isFalse);

      tabManager.startAddingTab();
      tabManager.openTab(43, 3); // JHN 3
      expect(tabManager.isAddingTab, isFalse);
    });

    test('persistence restores tabs and active tab, deduplicating on save', () async {
      await tabManager.init();
      tabManager.openTab(1, 1); // GEN 1
      tabManager.openTab(45, 8); // ROM 8

      // Simulate swiping ROM 8 to GEN 1 so temporary duplicate exists in session
      tabManager.updateActiveChapter(1, 1);
      expect(tabManager.tabs.length, 2);

      // Now create a new TabManager instance loading from the same userSettings
      final newManager = TabManager();
      await newManager.init();

      // Should have deduplicated to 1 unique tab
      expect(newManager.tabs.length, 1);
      expect(newManager.tabs.first.label, 'GEN 1');
    });

    test('reorderTabs moves tab properly', () async {
      await tabManager.init();
      tabManager.openTab(1, 1); // GEN 1
      tabManager.openTab(2, 1); // EXO 1
      tabManager.openTab(3, 1); // LEV 1

      expect(tabManager.tabs.map((t) => t.label).toList(), ['GEN 1', 'EXO 1', 'LEV 1']);

      tabManager.reorderTabs(0, 3);
      expect(tabManager.tabs.map((t) => t.label).toList(), ['EXO 1', 'LEV 1', 'GEN 1']);
    });

    test('reorderItem moves tab properly', () async {
      await tabManager.init();
      tabManager.openTab(1, 1); // GEN 1
      tabManager.openTab(2, 1); // EXO 1
      tabManager.openTab(3, 1); // LEV 1

      expect(tabManager.tabs.map((t) => t.label).toList(), ['GEN 1', 'EXO 1', 'LEV 1']);

      // Move index 0 to index 2
      tabManager.reorderItem(0, 2);
      expect(tabManager.tabs.map((t) => t.label).toList(), ['EXO 1', 'LEV 1', 'GEN 1']);

      // Move index 2 back to index 0
      tabManager.reorderItem(2, 0);
      expect(tabManager.tabs.map((t) => t.label).toList(), ['GEN 1', 'EXO 1', 'LEV 1']);
    });
  });
}
