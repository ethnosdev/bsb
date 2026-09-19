import 'package:bsb/app_state.dart';
import 'package:bsb/infrastructure/annotation_database.dart';
import 'package:bsb/infrastructure/annotation_models.dart';
import 'package:bsb/infrastructure/annotation_service.dart';
import 'package:bsb/infrastructure/database.dart';
import 'package:bsb/infrastructure/reference.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:bsb/ui/text/chapter/chapter_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeWordsOfJesusDbHelper implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UsfmLine>> getChapter(int bookId, int chapter) async {
    return [
      UsfmLine(
        bookChapterVerse: 40005013,
        text:
            r'Jesus said: \wj You are the salt of the earth.\wj*\f + \fr 5:13 \ft See John 3:16\f*',
        format: ParagraphFormat.p,
      ),
    ];
  }

  @override
  Future<List<UsfmLine>> getRange(Reference reference) async {
    return [
      UsfmLine(
        bookChapterVerse: 43003016,
        text: r'\wj For God so loved the world...\wj*',
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

  late UserSettings userSettings;
  late AppState appState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();

    userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);

    appState = AppState();
    await appState.init();
    getIt.registerSingleton<AppState>(appState);

    getIt.registerSingleton<DatabaseHelper>(FakeWordsOfJesusDbHelper());
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

  testWidgets('Words of Jesus are styled in red only when setting is enabled (Light Mode)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const Scaffold(
          body: ChapterText(
            bookId: 40,
            chapter: 5,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Default: wordsOfJesusInRed is false
    final saltFinder = find.byWidgetPredicate(
      (w) => w is WordWidget && w.text == 'salt',
    );
    expect(saltFinder, findsOneWidget);

    WordWidget saltWidget = tester.widget<WordWidget>(saltFinder);
    // Style shouldn't have red color (defaults to black)
    expect(saltWidget.style.color, isNot(equals(const Color(0xFFB71C1C))));

    final saidFinder = find.byWidgetPredicate(
      (w) => w is WordWidget && w.text == 'said:',
    );
    expect(saidFinder, findsOneWidget);
    WordWidget saidWidget = tester.widget<WordWidget>(saidFinder);
    expect(saidWidget.style.color, isNot(equals(const Color(0xFFB71C1C))));

    // Enable Words of Jesus in Red
    await appState.setWordsOfJesusInRed(true);
    await tester.pumpAndSettle();

    saltWidget = tester.widget<WordWidget>(saltFinder);
    expect(saltWidget.style.color, equals(const Color(0xFFB71C1C)));

    saidWidget = tester.widget<WordWidget>(saidFinder);
    expect(saidWidget.style.color, isNot(equals(const Color(0xFFB71C1C))));

    // Disable again
    await appState.setWordsOfJesusInRed(false);
    await tester.pumpAndSettle();

    saltWidget = tester.widget<WordWidget>(saltFinder);
    expect(saltWidget.style.color, isNot(equals(const Color(0xFFB71C1C))));
  });

  testWidgets('Words of Jesus are styled in soft coral when setting is enabled in Dark Mode', (tester) async {
    await appState.setWordsOfJesusInRed(true);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(
          body: ChapterText(
            bookId: 40,
            chapter: 5,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final saltFinder = find.byWidgetPredicate(
      (w) => w is WordWidget && w.text == 'salt',
    );
    expect(saltFinder, findsOneWidget);

    final saltWidget = tester.widget<WordWidget>(saltFinder);
    expect(saltWidget.style.color, equals(const Color(0xFFFF8A80)));
  });

  testWidgets('Footnote reference preview dialog renders Words of Jesus in red when enabled', (tester) async {
    await appState.setWordsOfJesusInRed(true);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const Scaffold(
          body: ChapterText(
            bookId: 40,
            chapter: 5,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(FootnoteWidget), findsOneWidget);
    await tester.tap(find.byType(FootnoteWidget));
    await tester.pumpAndSettle();

    // Footnote popup open
    expect(find.byType(AlertDialog), findsOneWidget);

    final selectableFinder = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(SelectableText),
    );
    final selectableWidget = tester.widget<SelectableText>(selectableFinder);
    final textSpan = selectableWidget.textSpan!;
    final johnSpan = textSpan.children!.firstWhere(
      (child) => (child as TextSpan).text == 'John 3:16',
    ) as TextSpan;
    (johnSpan.recognizer as TapGestureRecognizer).onTap!();

    await tester.pumpAndSettle();

    // Details preview Dialog open
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('John 3:16'), findsOneWidget);

    final worldFinder = find.descendant(
      of: find.byType(Dialog),
      matching: find.byWidgetPredicate(
        (w) => w is WordWidget && w.text == 'world...',
      ),
    );
    expect(worldFinder, findsOneWidget);
    final worldWidget = tester.widget<WordWidget>(worldFinder);
    expect(worldWidget.style.color, equals(const Color(0xFFB71C1C)));
  });
}
