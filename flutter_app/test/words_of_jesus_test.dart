import 'package:bsb/app_state.dart';
import 'package:bsb/core/theme.dart';
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
import 'package:bsb/core/app_theme_presets.dart';
import 'package:bsb/core/custom_theme_config.dart';
import 'package:bsb/ui/settings/theme/scripture_theme_preview_card.dart';
import 'package:bsb/ui/settings/theme/theme_selection_page.dart';
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

  testWidgets('Words of Jesus use customized color from custom theme when enabled', (tester) async {
    await appState.setWordsOfJesusInRed(true);
    await appState.applyThemeSelection(
      themeId: AppThemePreset.customPresetId,
      lightConfig: const CustomThemeConfig(
        backgroundColor: Color(0xFFF7F1E5),
        wordsOfJesusColor: Color(0xFF9C27B0), // Custom Purple
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: appState.lightThemeData,
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
    expect(saltWidget.style.color, equals(const Color(0xFF9C27B0)));
  });

  testWidgets('ScriptureThemePreviewCard shows Words of Jesus in body text color when disabled in settings', (tester) async {
    // Default: wordsOfJesusInRed is false
    final scheme = AppThemePreset.findById('sepia').lightScheme;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScriptureThemePreviewCard(
            colorScheme: scheme,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final richTextFinder = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('“I am willing,”'),
    );
    expect(richTextFinder, findsOneWidget);
    final richText = tester.widget<RichText>(richTextFinder);
    final rootSpan = richText.text as TextSpan;
    final willingSpan = rootSpan.children!.firstWhere(
      (span) => span is TextSpan && span.text == '“I am willing,”',
    ) as TextSpan;

    // Disabled in actual settings: should match onSurface (not red or colored)
    expect(willingSpan.style?.color, equals(scheme.onSurface));
  });

  testWidgets('ScriptureThemePreviewCard shows Words of Jesus in custom color when explicitly provided', (tester) async {
    final scheme = AppThemePreset.findById('sepia').lightScheme;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScriptureThemePreviewCard(
            colorScheme: scheme,
            wordsOfJesusInRed: true,
            wordsOfJesusColor: const Color(0xFF00897B), // Teal
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final richTextFinder = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('“I am willing,”'),
    );
    final richText = tester.widget<RichText>(richTextFinder);
    final rootSpan = richText.text as TextSpan;
    final willingSpan = rootSpan.children!.firstWhere(
      (span) => span is TextSpan && span.text == '“I am willing,”',
    ) as TextSpan;

    expect(willingSpan.style?.color, equals(const Color(0xFF00897B)));
  });

  testWidgets('ThemeSelectionPage demo shows Words of Jesus in standard red for preset themes and custom color for custom theme', (tester) async {
    await appState.setWordsOfJesusInRed(true);
    await appState.applyThemeSelection(
      themeId: AppThemePreset.customPresetId,
      lightConfig: const CustomThemeConfig(
        backgroundColor: Color(0xFFF7F1E5),
        wordsOfJesusColor: Color(0xFF1E88E5), // Blue
      ),
    );

    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ThemeSelectionPage(),
      ),
    );
    await tester.pumpAndSettle();

    // In Custom Theme: demo shows custom blue
    final richTextFinder = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('“I am willing,”'),
    );
    RichText richText = tester.widget<RichText>(richTextFinder);
    TextSpan rootSpan = richText.text as TextSpan;
    TextSpan willingSpan = rootSpan.children!.firstWhere(
      (span) => span is TextSpan && span.text == '“I am willing,”',
    ) as TextSpan;
    expect(willingSpan.style?.color, equals(const Color(0xFF1E88E5)));

    // Tap on a preset (e.g. Sepia Parchment)
    await tester.tap(find.text('Sepia Parchment'));
    await tester.pumpAndSettle();

    // For all preset themes, words of Jesus are shown in the standard red used before
    richText = tester.widget<RichText>(richTextFinder);
    rootSpan = richText.text as TextSpan;
    willingSpan = rootSpan.children!.firstWhere(
      (span) => span is TextSpan && span.text == '“I am willing,”',
    ) as TextSpan;
    expect(willingSpan.style?.color, equals(const Color(0xFFB71C1C)));
  });
}
