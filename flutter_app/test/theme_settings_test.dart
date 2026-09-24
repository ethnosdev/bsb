import 'package:bsb/app_state.dart';
import 'package:bsb/core/app_theme_presets.dart';
import 'package:bsb/core/custom_theme_config.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/theme/app_color_picker.dart';
import 'package:bsb/ui/settings/theme/custom_theme_editor_page.dart';
import 'package:bsb/ui/settings/theme/scripture_theme_preview_card.dart';
import 'package:bsb/ui/settings/theme/theme_selection_page.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('ScriptureThemePreviewCard renders title and passage', (tester) async {
    final scheme = AppThemePreset.findById('sepia').lightScheme;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScriptureThemePreviewCard(
            colorScheme: scheme,
            wordsOfJesusInRed: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('John 1:1–3'), findsOneWidget);
    expect(find.text('The Word Became Flesh'), findsOneWidget);
  });

  testWidgets('ThemeSelectionPage renders all presets and custom theme card', (tester) async {
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

    expect(find.text('Color Theme'), findsOneWidget);
    expect(find.text('Sepia Parchment'), findsOneWidget);
    expect(find.text('Clean Paper'), findsOneWidget);
    expect(find.text('Quiet Sage'), findsOneWidget);
    expect(find.text('Royal Purple'), findsOneWidget);
    expect(find.text('Night Charcoal'), findsOneWidget);
    expect(find.text('OLED Pure Black'), findsOneWidget);
    expect(find.text('Midnight Ocean'), findsOneWidget);
    expect(find.text('Custom Theme'), findsOneWidget);
  });

  testWidgets('Selecting a preset and tapping Apply updates AppState', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = getIt<AppState>();
    expect(appState.appThemeId, equals('sepia'));

    await tester.pumpWidget(
      const MaterialApp(
        home: ThemeSelectionPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Clean Paper'
    await tester.tap(find.text('Clean Paper'));
    await tester.pumpAndSettle();

    // Tap 'Apply'
    final applyButton = find.widgetWithText(FilledButton, 'Apply Theme');
    expect(applyButton, findsOneWidget);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(appState.appThemeId, equals('paper'));
    final userSettings = getIt<UserSettings>();
    expect(userSettings.appThemeId, equals('paper'));
  });

  testWidgets('CustomThemeEditorPage renders background color on primary screen and mode/accent in Customize All Colors', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = getIt<AppState>();
    final initialLight = CustomThemeConfig.defaultLight();
    final initialDark = CustomThemeConfig.defaultDark();

    await tester.pumpWidget(
      MaterialApp(
        home: CustomThemeEditorPage(
          initialLightConfig: initialLight,
          initialDarkConfig: initialDark,
          initialIsDark: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Custom Theme Editor'), findsOneWidget);
    expect(find.text('Background Color'), findsOneWidget);
    expect(find.text('Customize All Colors'), findsOneWidget);

    // Primary screen should NOT have edit mode buttons or accent color
    expect(find.text('Edit Light Mode'), findsNothing);
    expect(find.text('Edit Dark Mode'), findsNothing);
    expect(find.text('Accent Color'), findsNothing);

    // Expand fine-tune section
    await tester.tap(find.text('Customize All Colors'));
    await tester.pumpAndSettle();

    // Mode toggle and accent color are now inside Customize All Colors
    expect(find.text('Light Mode'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Accent Color'), findsOneWidget);
    expect(find.text('Scripture Text Color'), findsOneWidget);
    expect(find.text('Verse Numbers & Secondary Text'), findsOneWidget);
    expect(find.text('Cards & Panels Surface'), findsOneWidget);
    expect(find.text('Dividers & Outlines'), findsOneWidget);

    // Tap Apply Custom Theme
    await tester.tap(find.text('Apply Custom Theme'));
    await tester.pumpAndSettle();

    expect(appState.appThemeId, equals('custom'));
  });

  testWidgets('CustomThemeEditorPage selecting background auto-harmonizes theme', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final userSettings = getIt<UserSettings>();
    // Pre-populate color history with a distinct color (dark navy)
    const darkNavy = Color(0xFF0B131E);
    await userSettings.addCustomColorToHistory(darkNavy);

    await tester.pumpWidget(
      MaterialApp(
        home: CustomThemeEditorPage(
          initialLightConfig: CustomThemeConfig.defaultLight(),
          initialDarkConfig: CustomThemeConfig.defaultDark(),
          initialIsDark: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Background Color' to open picker
    await tester.tap(find.text('Background Color'));
    await tester.pumpAndSettle();

    // In the picker, recent colors contains darkNavy. Tap it.
    final swatchFinder = find.byKey(ValueKey(darkNavy.toARGB32()));
    await tester.tap(swatchFinder);
    await tester.pumpAndSettle();

    // Tap Select
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    // Apply the custom theme
    await tester.tap(find.text('Apply Custom Theme'));
    await tester.pumpAndSettle();

    // The dialog asks if user wants to switch to Dark Mode since darkNavy was chosen in Light Mode
    expect(find.text('Switch to Dark Mode?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Switch to Dark Mode'));
    await tester.pumpAndSettle();

    // Active dark config should have darkNavy background and harmonized accent (Sky Cyan 0xFF88C9FA)
    final savedDark = userSettings.customThemeDark;
    expect(savedDark.backgroundColor, equals(darkNavy));
    expect(savedDark.primaryColor, isNull);
    expect(savedDark.effectivePrimaryColor, equals(const Color(0xFF88C9FA)));
    expect(savedDark.isBackgroundAutoDerived, isFalse);

    final savedLight = userSettings.customThemeLight;
    expect(savedLight.primaryColor, isNull);
    expect(savedLight.isBackgroundAutoDerived, isTrue);
  });

  testWidgets('AppColorPicker renders recent colors and sliders', (tester) async {
    Color selected = Colors.black;

    // Test with empty recent colors
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppColorPicker(
            initialColor: const Color(0xFFFFFFFF),
            recentColors: const [],
            onColorChanged: (c) {
              selected = c;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent Colors'), findsOneWidget);
    expect(find.textContaining('No previous colors yet'), findsOneWidget);
    expect(find.text('Fine-Tune Tone'), findsOneWidget);
    expect(find.text('Hue'), findsOneWidget);
    expect(find.text('Saturation'), findsOneWidget);
    expect(find.text('Brightness'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(3));

    // Test with user recent colors
    const recentSample = [
      Color(0xFFF7F1E5),
      Color(0xFF1E1813),
      Color(0xFF1A5A96),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppColorPicker(
            initialColor: const Color(0xFFFFFFFF),
            recentColors: recentSample,
            onColorChanged: (c) {
              selected = c;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No previous colors yet'), findsNothing);
    // Tap the first recent color swatch
    final swatchFinder = find.byType(GestureDetector).first;
    await tester.tap(swatchFinder);
    await tester.pumpAndSettle();
    expect(selected, equals(const Color(0xFFF7F1E5)));
  });

  testWidgets('AppColorPicker.show saves selected color to UserSettings history', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final userSettings = getIt<UserSettings>();
    expect(userSettings.customColorHistory, isEmpty);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppColorPicker.show(
                    context: context,
                    initialColor: const Color(0xFF865328),
                  );
                },
                child: const Text('Open Picker'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open the color picker modal
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    expect(find.text('Select'), findsOneWidget);
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    expect(userSettings.customColorHistory, contains(const Color(0xFF865328)));
  });

  testWidgets('AppColorPicker renders Clear all button and invokes callback', (tester) async {
    bool cleared = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppColorPicker(
            initialColor: const Color(0xFFFFFFFF),
            recentColors: const [Color(0xFFF7F1E5)],
            onClearRecentColors: () {
              cleared = true;
            },
            onColorChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Clear all'), findsOneWidget);
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(cleared, isTrue);

    // Empty recent colors should not show Clear all
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppColorPicker(
            initialColor: const Color(0xFFFFFFFF),
            recentColors: const [],
            onClearRecentColors: () {},
            onColorChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Clear all'), findsNothing);
  });

  testWidgets('AppColorPicker.show Clear all button clears UserSettings history and updates sheet UI', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final userSettings = getIt<UserSettings>();
    await userSettings.addCustomColorToHistory(const Color(0xFF112233));
    expect(userSettings.customColorHistory, isNotEmpty);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppColorPicker.show(
                    context: context,
                    initialColor: const Color(0xFF865328),
                  );
                },
                child: const Text('Open Picker'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    expect(find.text('Clear all'), findsOneWidget);
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    // Verify history in UserSettings is cleared
    expect(userSettings.customColorHistory, isEmpty);

    // Verify sheet UI updated: Clear all button gone, empty prompt shown
    expect(find.text('Clear all'), findsNothing);
    expect(find.textContaining('No previous colors yet'), findsOneWidget);
  });

  testWidgets('choosing a light background marks only light background as custom and all other colors as auto-derived', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final userSettings = getIt<UserSettings>();
    const lightParchment = Color(0xFFFAF0E6);
    await userSettings.addCustomColorToHistory(lightParchment);

    await tester.pumpWidget(
      MaterialApp(
        home: CustomThemeEditorPage(
          initialLightConfig: CustomThemeConfig.defaultLight(),
          initialDarkConfig: CustomThemeConfig.defaultDark(),
          initialIsDark: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Background Color' to open picker
    await tester.tap(find.text('Background Color'));
    await tester.pumpAndSettle();

    // Select lightParchment swatch and tap Select
    final swatchFinder = find.byKey(ValueKey(lightParchment.toARGB32()));
    await tester.tap(swatchFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    // Open Customize All Colors
    await tester.tap(find.text('Customize All Colors'));
    await tester.pumpAndSettle();

    // In Light Mode:
    // ONLY Background Color should say 'Custom color'
    expect(find.text('Custom color'), findsOneWidget);
    // 5 other colors (Accent, Scripture Text, Verse Numbers, Cards, Outlines) should say 'Auto-derived'
    expect(find.text('Auto-derived'), findsNWidgets(5));

    // Switch to Dark Mode
    await tester.tap(find.text('Dark Mode'));
    await tester.pumpAndSettle();

    // In Dark Mode:
    // ALL 6 colors (including Background Color and Accent Color) should say 'Auto-derived'
    expect(find.text('Custom color'), findsNothing);
    expect(find.text('Auto-derived'), findsNWidgets(6));

    // Now customize Accent Color in Dark Mode
    await tester.tap(find.text('Accent Color'));
    await tester.pumpAndSettle();
    expect(find.text('Select'), findsOneWidget);
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    // Accent Color should now say 'Custom color'
    expect(find.text('Custom color'), findsOneWidget);
    expect(find.text('Auto-derived'), findsNWidgets(5));

    // Reset Accent Color via the reset icon button
    final resetAccentFinder = find.byTooltip('Reset to auto-derived');
    expect(resetAccentFinder, findsOneWidget);
    await tester.tap(resetAccentFinder);
    await tester.pumpAndSettle();

    // Accent Color reverts to 'Auto-derived'
    expect(find.text('Custom color'), findsNothing);
    expect(find.text('Auto-derived'), findsNWidgets(6));
  });

  testWidgets('choosing a dark background marks only dark background as custom and all other colors as auto-derived', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final userSettings = getIt<UserSettings>();
    const darkNavy = Color(0xFF0B131E);
    await userSettings.addCustomColorToHistory(darkNavy);

    await tester.pumpWidget(
      MaterialApp(
        home: CustomThemeEditorPage(
          initialLightConfig: CustomThemeConfig.defaultLight(),
          initialDarkConfig: CustomThemeConfig.defaultDark(),
          initialIsDark: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Background Color' to open picker
    await tester.tap(find.text('Background Color'));
    await tester.pumpAndSettle();

    // Select darkNavy swatch and tap Select
    final swatchFinder = find.byKey(ValueKey(darkNavy.toARGB32()));
    await tester.tap(swatchFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    // Open Customize All Colors
    await tester.tap(find.text('Customize All Colors'));
    await tester.pumpAndSettle();

    // Because darkNavy is dark, the editor switched to Dark Mode:
    // ONLY Background Color should say 'Custom color'
    expect(find.text('Custom color'), findsOneWidget);
    expect(find.text('Auto-derived'), findsNWidgets(5));

    // Switch to Light Mode
    await tester.tap(find.text('Light Mode'));
    await tester.pumpAndSettle();

    // In Light Mode:
    // ALL 6 colors (including Background Color) should say 'Auto-derived'
    expect(find.text('Custom color'), findsNothing);
    expect(find.text('Auto-derived'), findsNWidgets(6));
  });

  testWidgets('CustomThemeEditorPage defaults background to current theme background color when not chosen', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final userSettings = getIt<UserSettings>();
    await userSettings.clearCustomColorHistory();
    expect(userSettings.lastSelectedCustomColor, isNull);

    const currentPaperBg = Color(0xFFFFFFFF);
    await tester.pumpWidget(
      MaterialApp(
        home: CustomThemeEditorPage(
          initialLightConfig: CustomThemeConfig.defaultLight(),
          initialDarkConfig: CustomThemeConfig.defaultDark(),
          initialIsDark: false,
          currentThemeBackgroundColor: currentPaperBg,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify circular color indicator in the Background Color card displays current theme background color #FFFFFF
    final bgTileFinder = find.ancestor(
      of: find.text('Background Color'),
      matching: find.byType(ListTile),
    ).first;
    final bgTile = tester.widget<ListTile>(bgTileFinder);
    final indicator = bgTile.leading as Container;
    final decoration = indicator.decoration as BoxDecoration;
    expect(decoration.color, equals(currentPaperBg));

    // Tap 'Background Color' to open picker
    await tester.tap(find.text('Background Color'));
    await tester.pumpAndSettle();

    // Verify hex field in the picker defaults to the current theme background color #FFFFFF
    final hexField = tester.widget<TextField>(find.byType(TextField));
    expect(hexField.controller?.text, equals('#FFFFFF'));
  });

  testWidgets('CustomThemeEditorPage defaults background to last selected color if previously chosen', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final userSettings = getIt<UserSettings>();
    const lastChosenColor = Color(0xFFE5D5C5);
    await userSettings.addCustomColorToHistory(lastChosenColor);
    expect(userSettings.lastSelectedCustomColor, equals(lastChosenColor));

    // Even if current theme background is dark or white, the last chosen color should take priority!
    const currentPaperBg = Color(0xFFFFFFFF);
    await tester.pumpWidget(
      MaterialApp(
        home: CustomThemeEditorPage(
          initialLightConfig: CustomThemeConfig.defaultLight(),
          initialDarkConfig: CustomThemeConfig.defaultDark(),
          // Even if opening from dark mode, user's light chosen color should be respected!
          initialIsDark: true,
          currentThemeBackgroundColor: currentPaperBg,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify circular color indicator in the Background Color card displays the user's chosen light color
    final bgTileFinder = find.ancestor(
      of: find.text('Background Color'),
      matching: find.byType(ListTile),
    ).first;
    final bgTile = tester.widget<ListTile>(bgTileFinder);
    final indicator = bgTile.leading as Container;
    final decoration = indicator.decoration as BoxDecoration;
    expect(decoration.color, equals(lastChosenColor));

    // Tap 'Background Color' to open picker
    await tester.tap(find.text('Background Color'));
    await tester.pumpAndSettle();

    // Verify hex field in the picker defaults to the last selected color #E5D5C5
    final hexField = tester.widget<TextField>(find.byType(TextField));
    expect(hexField.controller?.text, equals('#E5D5C5'));
  });

  testWidgets('CustomThemeEditorPage prompts to switch to Light Mode when applying light theme while app is in dark mode', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = getIt<AppState>();
    await appState.setThemeMode(ThemeMode.dark);
    expect(appState.themeMode, equals(ThemeMode.dark));

    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData.dark(),
        home: CustomThemeEditorPage(
          initialLightConfig: CustomThemeConfig.defaultLight(),
          initialDarkConfig: CustomThemeConfig.defaultDark(),
          initialIsDark: false, // Light mode active
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Apply' in AppBar
    await tester.tap(find.widgetWithText(TextButton, 'Apply'));
    await tester.pumpAndSettle();

    // Verify dialog appears asking to switch to Light Mode
    expect(find.text('Switch to Light Mode?'), findsOneWidget);
    expect(find.text('Keep Dark Mode'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Switch to Light Mode'), findsOneWidget);

    // Tap 'Switch to Light Mode' in dialog
    await tester.tap(find.widgetWithText(FilledButton, 'Switch to Light Mode'));
    await tester.pumpAndSettle();

    // Verify AppState was updated to Light Mode and custom theme
    expect(appState.themeMode, equals(ThemeMode.light));
    expect(appState.isCustomTheme, isTrue);
  });

  testWidgets('CustomThemeEditorPage respects Keep Dark Mode when user declines mode switch', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = getIt<AppState>();
    await appState.setThemeMode(ThemeMode.dark);
    expect(appState.themeMode, equals(ThemeMode.dark));

    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData.dark(),
        home: CustomThemeEditorPage(
          initialLightConfig: CustomThemeConfig.defaultLight(),
          initialDarkConfig: CustomThemeConfig.defaultDark(),
          initialIsDark: false, // Light mode active
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Apply' in AppBar
    await tester.tap(find.widgetWithText(TextButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Switch to Light Mode?'), findsOneWidget);

    // Tap 'Keep Dark Mode'
    await tester.tap(find.widgetWithText(TextButton, 'Keep Dark Mode'));
    await tester.pumpAndSettle();

    // Verify AppState remained in Dark Mode and custom theme applied
    expect(appState.themeMode, equals(ThemeMode.dark));
    expect(appState.isCustomTheme, isTrue);
  });

  testWidgets('CustomThemeEditorPage prompts to switch to Dark Mode when applying dark theme while app is in light mode', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = getIt<AppState>();
    await appState.setThemeMode(ThemeMode.light);
    expect(appState.themeMode, equals(ThemeMode.light));

    // Prepare dark background custom color
    final userSettings = getIt<UserSettings>();
    const darkBgColor = Color(0xFF101820);
    await userSettings.addCustomColorToHistory(darkBgColor);

    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.light,
        theme: ThemeData.light(),
        home: CustomThemeEditorPage(
          initialLightConfig: CustomThemeConfig.defaultLight(),
          initialDarkConfig: CustomThemeConfig.defaultDark(),
          initialIsDark: true, // Dark mode active
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Apply' in AppBar
    await tester.tap(find.widgetWithText(TextButton, 'Apply'));
    await tester.pumpAndSettle();

    // Verify dialog appears asking to switch to Dark Mode
    expect(find.text('Switch to Dark Mode?'), findsOneWidget);
    expect(find.text('Keep Light Mode'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Switch to Dark Mode'), findsOneWidget);

    // Tap 'Switch to Dark Mode'
    await tester.tap(find.widgetWithText(FilledButton, 'Switch to Dark Mode'));
    await tester.pumpAndSettle();

    expect(appState.themeMode, equals(ThemeMode.dark));
    expect(appState.isCustomTheme, isTrue);
  });

  testWidgets('CustomThemeEditorPage applies directly without dialog when mode matches', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = getIt<AppState>();
    await appState.setThemeMode(ThemeMode.light);
    expect(appState.themeMode, equals(ThemeMode.light));

    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.light,
        theme: ThemeData.light(),
        home: CustomThemeEditorPage(
          initialLightConfig: CustomThemeConfig.defaultLight(),
          initialDarkConfig: CustomThemeConfig.defaultDark(),
          initialIsDark: false, // Light mode matches appState light mode
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Apply' in AppBar
    await tester.tap(find.widgetWithText(TextButton, 'Apply'));
    await tester.pumpAndSettle();

    // No dialog shown
    expect(find.text('Switch to Dark Mode?'), findsNothing);
    expect(find.text('Switch to Light Mode?'), findsNothing);
    expect(appState.themeMode, equals(ThemeMode.light));
    expect(appState.isCustomTheme, isTrue);
  });
}

