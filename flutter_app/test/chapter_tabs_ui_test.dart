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

    testWidgets('close button hit target spans full height of active chip without encroaching on label', (tester) async {
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

      final iconRect = tester.getRect(find.byIcon(Icons.close));
      final chipRect = tester.getRect(find.byType(ChapterChip));

      // Tap near top edge of chip in close button column
      await tester.tapAt(Offset(iconRect.center.dx, chipRect.top + 3.0));
      expect(closed, isTrue);
      expect(tapped, isFalse);

      closed = false;
      // Tap near bottom edge of chip in close button column
      await tester.tapAt(Offset(iconRect.center.dx, chipRect.bottom - 3.0));
      expect(closed, isTrue);
      expect(tapped, isFalse);

      closed = false;
      // Tap label
      await tester.tap(find.text('GEN 1'));
      expect(tapped, isTrue);
      expect(closed, isFalse);
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

    testWidgets('has the same height (36.0) as normal ChapterChip', (tester) async {
      final tab = BibleTab(bookId: 45, chapter: 8);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ChapterChip(tab: tab, isActive: true, onTap: () {}),
                CompositeChapterChip(activeTab: tab, otherTabsCount: 3, onTap: () {}),
              ],
            ),
          ),
        ),
      );

      final chipSize = tester.getSize(find.byType(ChapterChip));
      final compositeSize = tester.getSize(find.byType(CompositeChapterChip));

      expect(chipSize.height, equals(36.0));
      expect(compositeSize.height, equals(36.0));
      expect(compositeSize.height, equals(chipSize.height));
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
      expect(tester.getSize(find.byType(CompositeChapterChip)).height, equals(36.0));
    });

    testWidgets('tapping invisible button in large space triggers onEmptySpaceTapped', (tester) async {
      await tabManager.init();
      tabManager.openTab(1, 1); // GEN 1

      bool emptyTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: SizedBox(
                width: 400,
                height: 56,
                child: ChapterTabsBar(
                  tabManager: tabManager,
                  onActiveTabTapped: (_) {},
                  onEmptySpaceTapped: () => emptyTapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      // Tap far to the right in the empty space
      await tester.tapAt(const Offset(350, 28));
      expect(emptyTapped, isTrue);
    });

    testWidgets('tapping within 8px dead zone does not trigger onEmptySpaceTapped', (tester) async {
      await tabManager.init();
      tabManager.openTab(1, 1); // GEN 1

      bool emptyTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: SizedBox(
                width: 400,
                height: 56,
                child: ChapterTabsBar(
                  tabManager: tabManager,
                  onActiveTabTapped: (_) {},
                  onEmptySpaceTapped: () => emptyTapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      final chipFinder = find.byType(ChapterChip);
      final chipRect = tester.getRect(chipFinder);

      // Tap 4px to the right of the chip (inside the 8px dead zone)
      await tester.tapAt(Offset(chipRect.right + 4.0, chipRect.center.dy));
      expect(emptyTapped, isFalse);

      // Tap 20px to the right of the chip (past the 8px dead zone, in the invisible button)
      await tester.tapAt(Offset(chipRect.right + 20.0, chipRect.center.dy));
      expect(emptyTapped, isTrue);
    });

    testWidgets('tapping above or below chips does not trigger onEmptySpaceTapped', (tester) async {
      await tabManager.init();
      tabManager.openTab(1, 1); // GEN 1

      bool emptyTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: SizedBox(
                width: 400,
                height: 56,
                child: ChapterTabsBar(
                  tabManager: tabManager,
                  onActiveTabTapped: (_) {},
                  onEmptySpaceTapped: () => emptyTapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      final chipFinder = find.byType(ChapterChip);
      final chipRect = tester.getRect(chipFinder);

      // Tap 5px above the chip
      await tester.tapAt(Offset(chipRect.center.dx, chipRect.top - 5.0));
      expect(emptyTapped, isFalse);

      // Tap 5px below the chip
      await tester.tapAt(Offset(chipRect.center.dx, chipRect.bottom + 5.0));
      expect(emptyTapped, isFalse);
    });

    testWidgets('dead zone does not cause relayout to composite chip when chips fit', (tester) async {
      await tabManager.init();
      tabManager.openTab(1, 1); // GEN 1

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: SizedBox(
                // Wide enough for the chip (~97px), with only small space remaining
                width: 110,
                height: 56,
                child: ChapterTabsBar(
                  tabManager: tabManager,
                  onActiveTabTapped: (_) {},
                  onEmptySpaceTapped: () {},
                ),
              ),
            ),
          ),
        ),
      );

      // Still renders ChapterChip, does not collapse to CompositeChapterChip
      expect(find.byType(ChapterChip), findsOneWidget);
      expect(find.byType(CompositeChapterChip), findsNothing);
    });

    testWidgets('empty space is tappable as long as it is wider than 8px dead area', (tester) async {
      await tabManager.init();
      tabManager.openTab(1, 1); // GEN 1

      bool emptyTapped = false;

      // Chip estimated width is ~97px. Total width 120px leaves ~23px space (> 8px dead zone)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: SizedBox(
                width: 120,
                height: 56,
                child: ChapterTabsBar(
                  tabManager: tabManager,
                  onActiveTabTapped: (_) {},
                  onEmptySpaceTapped: () => emptyTapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      final chipRect = tester.getRect(find.byType(ChapterChip));
      final barRect = tester.getRect(find.byType(ChapterTabsBar));

      // 4px right of chip: within 8px dead zone -> not tapped
      await tester.tapAt(Offset(chipRect.right + 4.0, barRect.center.dy));
      expect(emptyTapped, isFalse);

      // Tap near right edge of the bar (beyond 8px dead zone) -> tapped
      await tester.tapAt(Offset(barRect.right - 4.0, barRect.center.dy));
      expect(emptyTapped, isTrue);
    });

    testWidgets('swiping down on invisible button area animates and closes all tabs', (tester) async {
      await tabManager.init();
      tabManager.openTab(1, 1); // GEN 1
      tabManager.openTab(45, 8); // ROM 8

      bool closedAll = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: SizedBox(
                width: 400,
                height: 56,
                child: ChapterTabsBar(
                  tabManager: tabManager,
                  onActiveTabTapped: (_) {},
                  onEmptySpaceTapped: () {},
                  onCloseAll: () => closedAll = true,
                ),
              ),
            ),
          ),
        ),
      );

      final barRect = tester.getRect(find.byType(ChapterTabsBar));
      final tapX = barRect.right - 20.0;

      // Swipe down in the empty space
      await tester.timedDragFrom(
        Offset(tapX, 10),
        const Offset(0, 100),
        const Duration(milliseconds: 100),
      );

      // Verify the slide animation is progressing
      await tester.pump(const Duration(milliseconds: 50));
      // Animation in progress
      expect(closedAll, isFalse);

      // Settle the animation
      await tester.pumpAndSettle();
      expect(closedAll, isTrue);
    });

    testWidgets('swiping down on invisible button when composite chip is active closes all tabs', (tester) async {
      await tabManager.init();
      tabManager.openTab(1, 1);
      tabManager.openTab(45, 8);
      tabManager.openTab(19, 23);
      tabManager.openTab(43, 3);

      bool closedAll = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: SizedBox(
                width: 250,
                height: 56,
                child: ChapterTabsBar(
                  tabManager: tabManager,
                  onActiveTabTapped: (_) {},
                  onEmptySpaceTapped: () {},
                  onCloseAll: () => closedAll = true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CompositeChapterChip), findsOneWidget);

      final barRect = tester.getRect(find.byType(ChapterTabsBar));
      final tapX = barRect.right - 20.0;

      await tester.timedDragFrom(
        Offset(tapX, 10),
        const Offset(0, 100),
        const Duration(milliseconds: 100),
      );

      await tester.pumpAndSettle();
      expect(closedAll, isTrue);
    });

    testWidgets('swiping up on invisible button does not close tabs', (tester) async {
      await tabManager.init();
      tabManager.openTab(1, 1);

      bool closedAll = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: SizedBox(
                width: 400,
                height: 56,
                child: ChapterTabsBar(
                  tabManager: tabManager,
                  onActiveTabTapped: (_) {},
                  onEmptySpaceTapped: () {},
                  onCloseAll: () => closedAll = true,
                ),
              ),
            ),
          ),
        ),
      );

      final barRect = tester.getRect(find.byType(ChapterTabsBar));
      final tapX = barRect.right - 20.0;

      // Swipe up
      await tester.timedDragFrom(
        Offset(tapX, 40),
        const Offset(0, -100),
        const Duration(milliseconds: 100),
      );

      await tester.pumpAndSettle();
      expect(closedAll, isFalse);
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

    testWidgets('allows reordering via long press in sheet without drag handle icon', (tester) async {
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

      // No explicit drag handle icon
      expect(find.byIcon(Icons.drag_handle), findsNothing);
      // Wrapped with ReorderableDelayedDragStartListener for long-press drag
      expect(find.byType(ReorderableDelayedDragStartListener), findsNWidgets(2));
    });

    testWidgets('tapping active tab in sheet triggers onActiveTabTapped', (tester) async {
      await tabManager.init();
      tabManager.openTab(1, 1); // Genesis 1
      tabManager.openTab(45, 8); // Romans 8 (active)

      BibleTab? tappedActiveTab;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ChapterTabsSheet.show(
                  context,
                  tabManager,
                  onActiveTabTapped: (tab) => tappedActiveTab = tab,
                ),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Romans 8 is active
      expect(find.text('Romans 8'), findsOneWidget);

      // Tap active tab Romans 8
      await tester.tap(find.text('Romans 8'));
      await tester.pumpAndSettle();

      expect(tappedActiveTab, isNotNull);
      expect(tappedActiveTab?.bookId, equals(45));
      expect(tappedActiveTab?.chapter, equals(8));
      // Sheet should be dismissed
      expect(find.text('Open Chapters'), findsNothing);
    });
  });
}
