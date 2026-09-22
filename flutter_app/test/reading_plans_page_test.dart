import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/reading_plan_models.dart';
import 'package:bsb/infrastructure/reading_plan_service.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/home/drawer.dart';
import 'package:bsb/ui/reading_plans/reading_plans_page.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'annotation_service_test.dart';

class TrackingTabManager extends TabManager {
  int? openedBookId;
  int? openedChapter;
  int? openedVerse;

  @override
  Future<void> openTab(int bookId, int chapter, [String? title, int? targetVerse]) async {
    openedBookId = bookId;
    openedChapter = chapter;
    openedVerse = targetVerse;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAnnotationDbHelper fakeDb;
  late ReadingPlanService planService;
  late TrackingTabManager trackingTabManager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();

    final userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);

    fakeDb = FakeAnnotationDbHelper();
    planService = ReadingPlanService(dbHelper: fakeDb);
    trackingTabManager = TrackingTabManager();

    getIt.registerSingleton<AnnotationDatabaseHelper>(fakeDb);
    getIt.registerSingleton<ReadingPlanService>(planService);
    getIt.registerSingleton<TabManager>(trackingTabManager);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('AppDrawer contains Reading Plans tile and navigates to ReadingPlansPage', (tester) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          drawer: const AppDrawer(),
          body: const Center(child: Text('Home')),
        ),
      ),
    );

    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Reading Plans'), findsOneWidget);

    await tester.tap(find.text('Reading Plans'));
    await tester.pumpAndSettle();

    expect(find.byType(ReadingPlansPage), findsOneWidget);
    expect(find.text('Available Plans'), findsOneWidget);
  });

  testWidgets('Catalog view shows 3 tracks and starts Through the Bible plan', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: ReadingPlansPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Available Plans'), findsOneWidget);
    expect(find.text('Through the Bible'), findsOneWidget);
    expect(find.text('Chronological Bible'), findsOneWidget);
    expect(find.text('New Testament'), findsOneWidget);

    final startButton = find.widgetWithText(FilledButton, 'Start').first;
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(find.text('Finish in a year'), findsOneWidget);
    expect(find.text('One chapter a day'), findsOneWidget);

    await tester.tap(find.text('Finish in a year'));
    await tester.pumpAndSettle();

    // Now in ActivePlanDashboard
    expect(find.text('Reading Plans'), findsOneWidget);
    expect(find.text('Through the Bible'), findsWidgets);
    expect(find.text('0 of 365 days completed'), findsOneWidget);
    expect(find.text('Next Up'), findsOneWidget);
  });

  testWidgets('Checking off reading updates progress and marks day complete', (tester) async {
    await planService.startOrResumePlan(PlanTrack.throughTheBible, PlanPace.finishInYear);

    await tester.pumpWidget(
      const MaterialApp(
        home: ReadingPlansPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 of 365 days completed'), findsOneWidget);

    // Day 1 has individual readings: Genesis 1, Genesis 2, Genesis 3, Matthew 1.
    // Checking one reading tracks sub-day progress without completing the entire day.
    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsWidgets);

    await tester.tap(checkboxes.first);
    await tester.pumpAndSettle();
    expect(find.text('0 of 365 days completed'), findsOneWidget);

    // Marking the entire day complete updates progress to 1
    final dayCompleteBtn = find.byTooltip('Mark day as complete').first;
    await tester.tap(dayCompleteBtn);
    await tester.pumpAndSettle();

    expect(find.text('1 of 365 days completed'), findsOneWidget);
  });

  testWidgets('Tapping Read button invokes TabManager with correct book and chapter', (tester) async {
    await planService.startOrResumePlan(PlanTrack.throughTheBible, PlanPace.finishInYear);

    await tester.pumpWidget(
      const MaterialApp(
        home: ReadingPlansPage(),
      ),
    );
    await tester.pumpAndSettle();

    final readButtons = find.widgetWithText(TextButton, 'Read');
    expect(readButtons, findsWidgets);

    await tester.tap(readButtons.first);
    await tester.pumpAndSettle();

    // Day 1 first reading is Genesis 1 -> bookId: 1, chapter: 1
    expect(trackingTabManager.openedBookId, 1);
    expect(trackingTabManager.openedChapter, 1);
    expect(trackingTabManager.openedVerse, 1);
  });

  testWidgets('Switching plan switches active view and preserves progress', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Start Through the Bible and mark day 1 complete
    await planService.startOrResumePlan(PlanTrack.throughTheBible, PlanPace.finishInYear);
    await planService.toggleDayComplete(1);

    await tester.pumpWidget(
      const MaterialApp(
        home: ReadingPlansPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 of 365 days completed'), findsOneWidget);

    // Tap Switch button
    await tester.tap(find.widgetWithText(OutlinedButton, 'Switch'));
    await tester.pumpAndSettle();

    expect(find.text('Available Plans'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'View'), findsOneWidget);

    // Start New Testament
    final ntStartButton = find.widgetWithText(FilledButton, 'Start').last;
    await tester.tap(ntStartButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finish in 90 days'));
    await tester.pumpAndSettle();

    // New Testament active
    expect(find.text('New Testament'), findsWidgets);

    // Switch back
    await tester.tap(find.widgetWithText(OutlinedButton, 'Switch'));
    await tester.pumpAndSettle();

    final resumeBtn = find.widgetWithText(FilledButton, 'Resume').first;
    await tester.tap(resumeBtn);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finish in a year'));
    await tester.pumpAndSettle();

    // Progress preserved: 1 of 365 days completed!
    expect(find.text('1 of 365 days completed'), findsOneWidget);
  });

  testWidgets('Reset plan shows confirmation dialog and clears progress', (tester) async {
    await planService.startOrResumePlan(PlanTrack.throughTheBible, PlanPace.finishInYear);
    await planService.toggleDayComplete(1);

    await tester.pumpWidget(
      const MaterialApp(
        home: ReadingPlansPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 of 365 days completed'), findsOneWidget);

    // Tap popup menu
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset Progress'));
    await tester.pumpAndSettle();

    // Dialog appears
    expect(find.text('Reset Reading Plan?'), findsOneWidget);

    // Confirm
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    // Now no active plan, returns to catalog view
    expect(find.text('Available Plans'), findsOneWidget);
  });
}
