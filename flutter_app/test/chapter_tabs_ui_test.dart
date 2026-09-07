import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/bible_tab.dart';
import 'package:bsb/ui/tabs/chapter_chip.dart';
import 'package:bsb/ui/tabs/chapter_tabs_bar.dart';
import 'package:bsb/ui/tabs/chapter_tabs_sheet.dart';
import 'package:bsb/ui/tabs/composite_chip.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:flutter/material.dart';
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

  group('ChapterChip', () {
    testWidgets('active chip displays label and close icon; triggers callbacks', (tester) async {
      bool tapped = false;
      bool closed = false;

      final tab = BibleTab(bookId: 1, chapter: 1); // GEN 1

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChapterChip(
                tab: tab,
                isActive: true,
                onTap: () => tapped = true,
                onClose: () => closed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('GEN 1'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.text('GEN 1'));
      expect(tapped, isTrue);

      await tester.tap(find.byIcon(Icons.close));
      expect(closed, isTrue);
    });

    testWidgets('inactive chip displays label without close icon', (tester) async {
      final tab = BibleTab(bookId: 45, chapter: 8); // ROM 8

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChapterChip(
                tab: tab,
                isActive: false,
                onTap: () {},
                onClose: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('ROM 8'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  group('CompositeChapterChip', () {
    testWidgets('displays active label, badge with count, and dropdown icon', (tester) async {
      bool tapped = false;
      final tab = BibleTab(bookId: 45, chapter: 8); // ROM 8

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CompositeChapterChip(
                activeTab: tab,
                otherTabsCount: 4,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('ROM 8'), findsOneWidget);
      expect(find.text('+4'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);

      await tester.tap(find.byType(CompositeChapterChip));
      expect(tapped, isTrue);
    });
  });

  group('ChapterTabsBar', () {
    testWidgets('renders individual chips when width is sufficient', (tester) async {
      await tabManager.init();
      tabManager.openTab(1, 1); // GEN 1
      tabManager.openTab(45, 8); // ROM 8

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: SizedBox(
                width: 600,
                child: ChapterTabsBar(
                  tabManager: tabManager,
                  onActiveTabTapped: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ChapterChip), findsNWidgets(2));
      expect(find.byType(CompositeChapterChip), findsNothing);
    });

    testWidgets('collapses into CompositeChapterChip when width is constrained', (tester) async {
      await tabManager.init();
      tabManager.openTab(1, 1); // GEN 1
      tabManager.openTab(45, 8); // ROM 8
      tabManager.openTab(19, 23); // PSA 23
      tabManager.openTab(43, 3); // JHN 3

      // Active is JHN 3, 3 other tabs
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: SizedBox(
                width: 120, // Too narrow for 4 chips
                child: ChapterTabsBar(
                  tabManager: tabManager,
                  onActiveTabTapped: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CompositeChapterChip), findsOneWidget);
      expect(find.text('JHN 3'), findsOneWidget);
      expect(find.text('+3'), findsOneWidget);
    });
  });

  group('ChapterTabsSheet', () {
    testWidgets('displays all tabs with full titles and permits selection', (tester) async {
      await tabManager.init();
      tabManager.openTab(1, 1); // Genesis 1
      tabManager.openTab(45, 8); // Romans 8

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ChapterTabsSheet.show(context, tabManager),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Open Chapters'), findsOneWidget);
      expect(find.text('Genesis 1'), findsOneWidget);
      expect(find.text('Romans 8'), findsOneWidget);

      // Tap Genesis 1 to select it
      await tester.tap(find.text('Genesis 1'));
      await tester.pumpAndSettle();

      expect(tabManager.activeTab?.label, 'GEN 1');
    });
  });
}
