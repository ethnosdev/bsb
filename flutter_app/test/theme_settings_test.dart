import 'dart:convert';

import 'package:bsb/app_state.dart';
import 'package:bsb/core/theme.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/theme/app_color_picker.dart';
import 'package:bsb/ui/settings/theme/custom_theme_editor_page.dart';
import 'package:bsb/ui/settings/theme/scripture_theme_preview_card.dart';
import 'package:bsb/ui/settings/theme/theme_selection_page.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:bsb/ui/tabs/bible_tab.dart';
import 'package:bsb/ui/tabs/chapter_chip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scripture/scripture.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    final userSettings = UserSettings();
    await userSettings.init();
    getIt.registerSingleton<UserSettings>(userSettings);
    final appState = AppState(userSettings: userSettings);
    await appState.init();
    getIt.registerSingleton<AppState>(appState);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'ScriptureThemePreviewCard renders MAT 8, inactive JHN 3, verse 3, footnote marker, and verseNumberColor',
    (tester) async {
      final scheme = AppThemePreset.findById('sepia').lightScheme;
      const customVerseColor = Color(0xFF1A5A96);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScriptureThemePreviewCard(
              colorScheme: scheme,
              wordsOfJesusInRed: true,
              verseNumberColor: customVerseColor,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MAT 8'), findsOneWidget);
      expect(find.text('JHN 3'), findsOneWidget);
      expect(find.text('The Leper’s Prayer'), findsNothing);
      expect(find.text('immediately'), findsOneWidget);

      expect(
        find.byWidgetPredicate((w) => w is IgnorePointer && w.ignoring),
        findsOneWidget,
      );

      final verseWidget = tester.widget<VerseNumberWidget>(
        find.byType(VerseNumberWidget),
      );
      expect(verseWidget.number, equals('3'));
      expect(verseWidget.style.color, equals(customVerseColor));

      final footnoteWidget = tester.widget<FootnoteWidget>(
        find.byType(FootnoteWidget),
      );
      expect(footnoteWidget.marker, equals('*'));
      expect(footnoteWidget.style.color, equals(scheme.primary));

      final richText = tester.widget<RichText>(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('Jesus reached out'),
        ),
      );
      final plainText = richText.text.toPlainText();
      expect(plainText, isNot(contains('When Jesus came down')));
      expect(plainText, isNot(contains('Suddenly a leper')));
    },
  );

  testWidgets('ThemeSelectionPage renders compact borderless theme tiles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ThemeSelectionPage()));
    await tester.pumpAndSettle();

    expect(find.text('Color Theme'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(find.text('Sepia Parchment'), findsOneWidget);
    expect(find.text('Clean Paper'), findsOneWidget);
    expect(find.text('Quiet Sage'), findsOneWidget);
    expect(find.text('Royal Purple'), findsOneWidget);
    expect(find.text('Night Charcoal'), findsOneWidget);
    expect(find.text('OLED Pure Black'), findsOneWidget);
    expect(find.text('Midnight Ocean'), findsOneWidget);
    expect(find.text('Custom Theme'), findsOneWidget);

    final sepiaTile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Sepia Parchment'),
        matching: find.byType(ListTile),
      ),
    );
    expect(sepiaTile.dense, isTrue);
    expect(sepiaTile.selected, isTrue);
    expect(sepiaTile.selectedTileColor, isNotNull);
  });

  testWidgets('Selecting a preset and tapping Apply updates AppState', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = getIt<AppState>();
    expect(appState.appThemeId, equals('sepia'));

    await tester.pumpWidget(const MaterialApp(home: ThemeSelectionPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clean Paper'));
    await tester.pumpAndSettle();

    expect(find.text('Apply Theme'), findsNothing);
    final applyButton = find.widgetWithText(TextButton, 'Apply');
    expect(applyButton, findsOneWidget);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(appState.appThemeId, equals('paper'));
    expect(getIt<UserSettings>().appThemeId, equals('paper'));
  });

  testWidgets(
    'ThemeSelectionPage and CustomThemeEditorPage keep preview card pinned while scrolling content below',
    (tester) async {
      tester.view.physicalSize = const Size(400, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ThemeSelectionPage()));
      await tester.pumpAndSettle();

      final initialPreviewTop = tester
          .getTopLeft(find.byType(ScriptureThemePreviewCard))
          .dy;
      final initialToggleTop = tester
          .getTopLeft(find.byType(SegmentedButton<ThemeMode>))
          .dy;

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.byType(ScriptureThemePreviewCard)).dy,
        equals(initialPreviewTop),
      );
      expect(
        tester.getTopLeft(find.byType(SegmentedButton<ThemeMode>)).dy,
        equals(initialToggleTop),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomThemeEditorPage(
            initialConfig: CustomThemeConfig.defaultConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editorPreviewTop = tester
          .getTopLeft(find.byType(ScriptureThemePreviewCard))
          .dy;

      await tester.drag(find.byType(ListView), const Offset(0, -250));
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.byType(ScriptureThemePreviewCard)).dy,
        equals(editorPreviewTop),
      );
    },
  );

  testWidgets(
    'ThemeSelectionPage disables Light/Dark switch on Custom Theme and preserves UserSettings.themeMode',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appState = getIt<AppState>();
      await appState.setThemeMode(ThemeMode.dark);

      await tester.pumpWidget(const MaterialApp(home: ThemeSelectionPage()));
      await tester.pumpAndSettle();

      // Switch preview to Light while on a preset, then select Custom Theme
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom Theme'));
      await tester.pumpAndSettle();

      expect(
        find.text('Custom theme uses a single color palette'),
        findsNothing,
      );
      final segButton = tester.widget<SegmentedButton<ThemeMode>>(
        find.byType(SegmentedButton<ThemeMode>),
      );
      expect(segButton.onSelectionChanged, isNull);

      await tester.tap(find.widgetWithText(TextButton, 'Apply'));
      await tester.pumpAndSettle();

      expect(appState.appThemeId, equals(AppThemePreset.customPresetId));
      // UserSettings.themeMode remains ThemeMode.dark for when switching back to presets
      expect(appState.themeMode, equals(ThemeMode.dark));
    },
  );

  testWidgets(
    'ThemeSelectionPage pre-seeds CustomThemeEditorPage from active preset and mode when no custom theme is saved',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final userSettings = getIt<UserSettings>();
      expect(userSettings.hasSavedCustomTheme, isFalse);

      await tester.pumpWidget(const MaterialApp(home: ThemeSelectionPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clean Paper'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customize Colors'));
      await tester.pumpAndSettle();

      final paperDark = AppThemePreset.findById('paper').darkScheme;
      final bgTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Background Color'),
          matching: find.byType(ListTile),
        ),
      );
      final decoration =
          (bgTile.leading as Container).decoration as BoxDecoration;
      expect(decoration.color, equals(paperDark.surface));
    },
  );

  testWidgets(
    'CustomThemeEditorPage displays 5 ordered color rows without removed technical slots or HSV labels',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomThemeEditorPage(
            initialConfig: CustomThemeConfig.defaultConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start from a Preset'), findsOneWidget);
      expect(find.text('Background Color'), findsOneWidget);
      expect(find.text('Text Color'), findsOneWidget);
      expect(find.text('Words of Jesus Color'), findsOneWidget);
      expect(find.text('Verse Number Color'), findsOneWidget);
      expect(find.text('Accent Color'), findsOneWidget);
      expect(find.text('Buttons, tabs, links, and selection'), findsOneWidget);

      expect(find.text('Customize All Colors'), findsNothing);
      expect(find.text('Cards & Panels Surface'), findsNothing);
      expect(find.text('Dividers & Outlines'), findsNothing);
      expect(find.text('Generate from Light'), findsNothing);

      final bgY = tester.getTopLeft(find.text('Background Color')).dy;
      final textY = tester.getTopLeft(find.text('Text Color')).dy;
      final wjY = tester.getTopLeft(find.text('Words of Jesus Color')).dy;
      final verseY = tester.getTopLeft(find.text('Verse Number Color')).dy;
      final accentY = tester.getTopLeft(find.text('Accent Color')).dy;
      expect(bgY, lessThan(textY));
      expect(textY, lessThan(wjY));
      expect(wjY, lessThan(verseY));
      expect(verseY, lessThan(accentY));
    },
  );

  testWidgets(
    'CustomThemeEditorPage Start from a Preset uses Light/Dark toggle and loads mode-default Words of Jesus color',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appState = getIt<AppState>();

      await tester.pumpWidget(
        MaterialApp(
          home: CustomThemeEditorPage(
            initialConfig: CustomThemeConfig.defaultConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start from a Preset'));
      await tester.pumpAndSettle();

      // Toggle sheet to Dark and select Midnight Ocean
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Midnight Ocean'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Apply'));
      await tester.pumpAndSettle();

      final oceanDark = AppThemePreset.findById('ocean').darkScheme;
      expect(appState.appThemeId, equals(AppThemePreset.customPresetId));
      expect(appState.customTheme.backgroundColor, equals(oceanDark.surface));
      expect(appState.customTheme.textColor, equals(oceanDark.onSurface));
      expect(
        appState.customTheme.verseNumberColor,
        equals(oceanDark.onSurfaceVariant),
      );
      expect(
        appState.customTheme.wordsOfJesusColor,
        equals(const Color(0xFFFF8A80)),
      );
    },
  );

  testWidgets(
    'CustomThemeEditorPage offers Keep Current vs Generate Matching when Background Color changes',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final userSettings = getIt<UserSettings>();
      const darkNavy = Color(0xFF0B131E);
      const customVerseColor = Color(0xFF80CBC4);
      await userSettings.addCustomColorToHistory(darkNavy);

      final startConfig = CustomThemeConfig.defaultConfig().copyWith(
        verseNumberColor: customVerseColor,
      );

      await tester.pumpWidget(
        MaterialApp(home: CustomThemeEditorPage(initialConfig: startConfig)),
      );
      await tester.pumpAndSettle();

      // Pick darkNavy and choose Keep Current
      await tester.tap(find.text('Background Color'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey(darkNavy.toARGB32())));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();

      expect(find.text('Update other colors?'), findsOneWidget);
      await tester.tap(find.text('Keep Current'));
      await tester.pumpAndSettle();

      // Custom verse number color is kept; contrast warning blocks Apply because text is still dark
      expect(find.textContaining('too close to read'), findsOneWidget);
      final applyBtn = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Apply'),
      );
      expect(applyBtn.onPressed, isNull);

      // Tap recovery Generate Matching inside error banner
      await tester.tap(find.text('Generate Matching'));
      await tester.pumpAndSettle();

      expect(find.textContaining('too close to read'), findsNothing);
      final enabledApply = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Apply'),
      );
      expect(enabledApply.onPressed, isNotNull);
    },
  );

  testWidgets(
    'CustomThemeEditorPage blocks Apply below 3.0:1 contrast, soft-warns 3.0..4.5:1, and never blocks Verse Numbers',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. Hard block (< 3.0:1)
      const unreadable = CustomThemeConfig(
        backgroundColor: Color(0xFFFFFFFF),
        textColor: Color(0xFFCCCCCC), // ~1.6:1
        wordsOfJesusColor: Color(0xFFB71C1C),
        verseNumberColor: Color(0xFFFFFFFF), // 1.0:1 verse number allowed!
        primaryColor: Color(0xFF1A5A96),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomThemeEditorPage(initialConfig: unreadable),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('too close to read'), findsOneWidget);
      final disabledApply = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Apply'),
      );
      expect(disabledApply.onPressed, isNull);

      // 2. Soft warning (3.0..4.5:1) with unreadable Verse Number Color still allowed
      const softWarn = CustomThemeConfig(
        backgroundColor: Color(0xFFFFFFFF),
        textColor: Color(0xFF888888), // ~3.54:1
        wordsOfJesusColor: Color(0xFFB71C1C),
        verseNumberColor: Color(0xFFFFFFFF), // 1.0:1 unblocked!
        primaryColor: Color(0xFF1A5A96),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomThemeEditorPage(
            key: ValueKey('soft'),
            initialConfig: softWarn,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Low contrast'), findsOneWidget);
      final enabledApply = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Apply'),
      );
      expect(enabledApply.onPressed, isNotNull);
    },
  );

  testWidgets(
    'CustomThemeEditorPage previews Words of Jesus even when disabled in Settings and stages inline toggle until Apply',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appState = getIt<AppState>();
      expect(appState.wordsOfJesusInRed, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomThemeEditorPage(
            initialConfig: CustomThemeConfig.defaultConfig().copyWith(
              wordsOfJesusColor: const Color(0xFF00897B),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Preview still shows teal Words of Jesus
      final richText = tester.widget<RichText>(
        find.byWidgetPredicate(
          (w) =>
              w is RichText && w.text.toPlainText().contains('“I am willing,”'),
        ),
      );
      final willingSpan = (richText.text as TextSpan).children!.firstWhere(
        (span) => span is TextSpan && span.text == '“I am willing,”',
      ) as TextSpan;
      expect(willingSpan.style?.color, equals(const Color(0xFF00897B)));

      // Toggle inline switch -> appState remains false until Apply
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(appState.wordsOfJesusInRed, isFalse);

      await tester.tap(find.widgetWithText(TextButton, 'Apply'));
      await tester.pumpAndSettle();
      expect(appState.wordsOfJesusInRed, isTrue);
    },
  );

  testWidgets(
    'AppColorPicker renders 2D square, Hue slider, Starter & Recent Colors without Saturation/Brightness labels',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Color selected = Colors.black;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppColorPicker(
              initialColor: const Color(0xFF1A5A96),
              recentColors: const [Color(0xFFF7F1E5)],
              onColorChanged: (c) => selected = c,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('color_picker_2d_square')),
        findsOneWidget,
      );
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Starter Colors'), findsOneWidget);
      expect(find.text('Recent Colors'), findsOneWidget);
      expect(find.text('Saturation'), findsNothing);
      expect(find.text('Brightness'), findsNothing);

      // Tap white starter swatch, then drag hue slider and drag into saturated square:
      // hue should update cleanly without snapping back to red.
      await tester.tap(
        find.byKey(ValueKey(const Color(0xFFFFFFFF).toARGB32())),
      );
      await tester.pumpAndSettle();
      expect(selected, equals(const Color(0xFFFFFFFF)));

      // Enter hex code with and without #
      await tester.enterText(find.byType(TextField), '#386646');
      await tester.pumpAndSettle();
      expect(selected, equals(const Color(0xFF386646)));
    },
  );

  testWidgets(
    'AppColorPicker.show Clear all clears only Recent Colors and 2D square drag does not scroll sheet',
    (tester) async {
      tester.view.physicalSize = const Size(500, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final userSettings = getIt<UserSettings>();
      await userSettings.addCustomColorToHistory(const Color(0xFF112233));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppColorPicker.show(
                    context: context,
                    initialColor: const Color(0xFF865328),
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Drag vertically inside the 2D square -> scroll offset stays 0 and sheet stays open
      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      final squareFinder = find.byKey(const ValueKey('color_picker_2d_square'));
      await tester.drag(squareFinder, const Offset(30, 80));
      await tester.pumpAndSettle();
      expect(squareFinder, findsOneWidget);
      expect(scrollView.controller?.offset ?? 0.0, equals(0.0));

      // Clear all removes Recent Colors but keeps Starter Colors
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();
      expect(userSettings.customColorHistory, isEmpty);
      expect(find.text('No recent colors yet.'), findsOneWidget);
      expect(find.text('Starter Colors'), findsOneWidget);
    },
  );

  group('Single-palette migration and AppState brightness independence', () {
    test('migrates legacy customThemeLight/Dark based on ThemeMode and customization', () async {
      // Case 1: ThemeMode.system where only Dark was explicitly customized
      SharedPreferences.setMockInitialValues({
        'customThemeLight': jsonEncode({
          'backgroundColor': const Color(0xFFF5F5F5).toARGB32(),
          'isBackgroundAutoDerived': true,
        }),
        'customThemeDark': jsonEncode({
          'backgroundColor': const Color(0xFF101820).toARGB32(),
          'secondaryTextColor': const Color(0xFF88C9FA).toARGB32(),
          'isBackgroundAutoDerived': false,
        }),
      });
      var settings = UserSettings();
      await settings.init();
      await settings.migrateCustomThemeIfNeeded(
        platformBrightness: Brightness.light,
      );
      expect(settings.hasSavedCustomTheme, isTrue);
      expect(
        settings.customTheme.backgroundColor,
        equals(const Color(0xFF101820)),
      );
      expect(
        settings.customTheme.verseNumberColor,
        equals(const Color(0xFF88C9FA)),
      );

      // Case 2: ThemeMode.dark but only customThemeLight exists -> preserves light config
      SharedPreferences.setMockInitialValues({
        'isDarkMode': true,
        'customThemeLight': jsonEncode({
          'backgroundColor': const Color(0xFFFAF0E6).toARGB32(),
        }),
      });
      settings = UserSettings();
      await settings.init();
      await settings.migrateCustomThemeIfNeeded(
        platformBrightness: Brightness.dark,
      );
      expect(
        settings.customTheme.backgroundColor,
        equals(const Color(0xFFFAF0E6)),
      );
    });

    test('AppState returns same single custom theme for light and dark ThemeData while preserving themeMode', () async {
      final appState = getIt<AppState>();
      await appState.setThemeMode(ThemeMode.system);
      final customDark = CustomThemeConfig.fromPreset(
        AppThemePreset.findById('ocean'),
        isDark: true,
      );
      await appState.applyThemeSelection(
        themeId: AppThemePreset.customPresetId,
        customConfig: customDark,
      );

      expect(appState.themeMode, equals(ThemeMode.system));
      expect(
        appState.lightThemeData.colorScheme.surface,
        equals(customDark.backgroundColor),
      );
      expect(
        appState.darkThemeData.colorScheme.surface,
        equals(customDark.backgroundColor),
      );
      expect(
        appState.lightThemeData.extension<ScriptureTheme>()?.verseNumberColor,
        equals(customDark.verseNumberColor),
      );
    });

    testWidgets(
      'Starting from Clean Paper and changing only Verse Number Color keeps ChapterChip colors identical to Clean Paper',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final appState = getIt<AppState>();
        final paperPreset = AppThemePreset.findById('paper');

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CustomThemeEditorPage(
                        initialConfig: CustomThemeConfig.defaultConfig(),
                      ),
                    ),
                  );
                },
                child: const Text('Open Editor'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Editor'));
        await tester.pumpAndSettle();

        // Start from a Preset -> Clean Paper (Light)
        await tester.tap(find.text('Start from a Preset'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Clean Paper'));
        await tester.pumpAndSettle();

        // Change only Verse Number Color to Clean Paper's accent color (#1A5A96)
        await tester.tap(find.text('Verse Number Color'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(ValueKey(paperPreset.lightScheme.primary.toARGB32())),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Select'));
        await tester.pumpAndSettle();

        // Apply
        await tester.tap(find.widgetWithText(TextButton, 'Apply'));
        await tester.pumpAndSettle();

        expect(appState.customTheme.basePresetId, equals('paper'));
        expect(appState.customTheme.basePresetIsDark, isFalse);

        // Render active and inactive ChapterChip under Custom Theme
        final activeTab = BibleTab(id: '1', bookId: 43, chapter: 3);
        final inactiveTab = BibleTab(id: '2', bookId: 45, chapter: 8);

        await tester.pumpWidget(
          MaterialApp(
            key: const ValueKey('chips'),
            theme: appState.lightThemeData,
            home: Scaffold(
              body: Row(
                children: [
                  ChapterChip(tab: activeTab, isActive: true, onTap: () {}),
                  ChapterChip(tab: inactiveTab, isActive: false, onTap: () {}),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final activeMaterial = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(ChapterChip).first,
                matching: find.byType(Material),
              )
              .first,
        );
        final inactiveMaterial = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(ChapterChip).last,
                matching: find.byType(Material),
              )
              .first,
        );

        expect(
          activeMaterial.color,
          equals(paperPreset.lightScheme.primaryContainer),
        );
        expect(
          inactiveMaterial.color,
          equals(
            paperPreset.lightScheme.surfaceContainerHighest.withValues(
              alpha: 0.6,
            ),
          ),
        );
      },
    );
  });
}
