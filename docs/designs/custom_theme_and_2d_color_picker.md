# Custom Theme & 2D Color Picker Redesign

*   **Author:** suragch
*   **Status:** Proposed
*   **Date:** 2026-11-16

--------------------------------------------------------------------------------

## Overview

The Berean Standard Bible (BSB) app lets readers personalize reading colors through a Custom Theme editor and a Color Picker modal. Previously, those screens required navigating a dual Light/Dark configuration model, technical HSV sliders (`Hue`, `Saturation`, `Brightness`), hidden mode controls, and 7 Material color slots whose effects on Bible text were unclear.

This design replaces the dual-mode custom editor with a single custom theme palette, organizes editing around five concrete reading colors (**Background Color**, **Text Color**, **Words of Jesus Color**, **Verse Number Color**, and **Accent Color**), introduces a 2D Saturation-Value square with starter swatches, isolates verse-number coloring from general UI text, and adds readability guardrails before saving.

## The Problem

1. **Confusing Light/Dark interaction for custom themes:** Maintaining separate Light and Dark custom themes, hiding the Light/Dark editor toggle inside a collapsed accordion, and popping modal mode-switch dialogs when a chosen background differs from the app's active `Light-Dark Mode` causes edits made in one brightness to remain unseen under the opposite mode.
2. **Hard-to-use color picker controls:** Three separate 1D sliders labeled `Hue`, `Saturation`, and `Brightness` require users to understand HSV terminology without visual track cues for Saturation or Brightness. On pure white, gray, or black, the Hue slider produces no visible change, and converting `HSV -> Color -> HSV` drops hue and saturation when reopening the picker on achromatic colors.
3. **Unclear and technical color slots:** Exposing `Cards & Panels Surface`, `Dividers & Outlines`, and an unexplained `Accent Color` forces users to guess what each setting changes. Meanwhile, `Verse Numbers & Secondary Text` writes to `ColorScheme.onSurfaceVariant`, coupling Bible verse numbers to Settings subtitles and dialog labels across the app.
4. **Silent feedback gaps and missing safety checks:** When `Words of Jesus in Color` is off in Settings (its default state), changing `Words of Jesus Color` shows nothing in the theme preview. Conversely, the editor allows saving near-invisible Text-on-Background combinations that can make both scripture and navigation menus unreadable.

## Goals

*   **Single custom theme palette:** Make Custom Theme a single, predictable palette independent of `Light-Dark Mode`, while preserving the user's saved `Light-Dark Mode` preference when switching back to a preset.
*   **Clear Settings hierarchy:** Place `Light-Dark Mode` first (showing `"Disabled for custom theme"` when Custom Theme is active), followed immediately by `Color Theme` before `Text Size`.
*   **Five plain-English color slots:** Present **Background Color**, **Text Color**, **Words of Jesus Color**, **Verse Number Color**, and **Accent Color** in that exact order without nested accordions or technical surface/divider slots.
*   **Safe background updates and preset starting points:** Offer to generate compatible colors for the other four slots whenever **Background Color** changes, and support loading either the **Light** or **Dark** variant of any preset via `"Start from a Preset"` (seeding the mode-appropriate default **Words of Jesus Color**: `#B71C1C` for Light, `#FF8A80` for Dark).
*   **Visual 2D color picker:** Replace raw `Saturation` and `Brightness` sliders with predefined starter swatches, recent colors, a 2D Saturation-Value square, an accessible hue bar, and optional hex entry while preserving hue across white, gray, and black.
*   **Reliable preview and readability protection:** Always preview **Words of Jesus Color** (with a staged inline toggle when the reader setting is off), decouple verse-number color from general UI labels (`onSurfaceVariant`), and block **Apply** only when Text-on-Background contrast is below `3.0:1` (showing a soft warning below `4.5:1`).

## Non-Goals

*   Multiple named user-created custom themes (one custom theme slot remains the limit).
*   Per-book, per-chapter, or per-translation theme overrides.
*   Exposing `surfaceContainer` (`Cards & Panels Surface`) or `outline` (`Dividers & Outlines`) as user-editable slots.
*   Blocking **Apply** for low-contrast **Verse Number Color**, **Words of Jesus Color**, or **Accent Color** choices.
*   Exporting or importing custom theme configurations in JSON/Markdown backup files.

## Open Questions

None.

## Critical User Journeys (CUJs)

### CUJ 1: Creating a Custom Theme Starting from a Preset

*   **Given**: A user is on `Settings > Color Theme` and wants a warmer variant of a dark preset.
*   **When**: The user opens `Customize Colors`, taps `Start from a Preset`, sets the preset sheet toggle to `Dark`, selects a preset, adjusts **Background Color** using the 2D Saturation-Value square (choosing `Keep Current` or `Generate Matching`), and taps `Apply` in the editor app bar.
*   **Then**: The custom theme saves as a single palette, the reader displays that exact palette regardless of `Light-Dark Mode`, and `Settings > Light-Dark Mode` displays `"Disabled for custom theme"`.

### CUJ 2: Customizing Verse Numbers Without Breaking App Menus

*   **Given**: A user has `Custom Theme` active and wants very faint or vividly colored verse numbers.
*   **When**: The user sets **Verse Number Color** to a subtle low-contrast tone in the 2D color picker and taps `Apply`.
*   **Then**: `Apply` remains enabled, scripture verse numbers render in the chosen color at full opacity (without `UsfmParagraphStyle.usfmDefaults`'s `0.6` alpha reduction), and Settings subtitles, dialog descriptions, and helper labels remain readable via auto-derived `onSurfaceVariant`.

### CUJ 3: Editing Words of Jesus Color When the Reader Setting Is Off

*   **Given**: `Words of Jesus in Color` is turned off in Settings (the default).
*   **When**: The user opens the Custom Theme Editor and picks a blue **Words of Jesus Color**.
*   **Then**: The live preview immediately shows Jesus' quoted words in blue, and an inline toggle below the preview lets the user stage turning `Words of Jesus in Color` on (persisted only when `Apply` is tapped, or discarded on Back).

### CUJ 4: Preventing an Unreadable Text/Background Combination

*   **Given**: A user is editing their custom theme and picks a **Text Color** whose contrast against **Background Color** is below `3.0:1`.
*   **When**: The user returns from the color picker to the editor screen.
*   **Then**: The preview updates immediately, an inline error banner with a one-tap `Generate Matching` recovery action explains that text and background are too close to read, and the AppBar `Apply` button is disabled until contrast reaches at least `3.0:1`.

### CUJ 5: Switching Back to a Preset Theme

*   **Given**: A user previously had `Light-Dark Mode` set to `Match device settings`, then used `Custom Theme`.
*   **When**: The user returns to `Color Theme`, selects a preset (such as `Sepia Parchment`), and taps `Apply Theme`.
*   **Then**: `Settings > Light-Dark Mode` re-enables and restores `Match device settings` without requiring reconfiguration.

## Technical Plan (Architecture)

### 1. Data Model & Theme Extension (`CustomThemeConfig`, `ScriptureTheme`)

```text
CustomThemeConfig (5 explicit colors)
  ├── backgroundColor  ──┐
  ├── textColor        ──┼─▶ ColorScheme (surface, onSurface, primary, auto-derived surfaceContainer, outline, onSurfaceVariant)
  ├── primaryColor     ──┘
  ├── wordsOfJesusColor ───▶ ScriptureTheme.wordsOfJesusColor ──▶ buildScriptureParagraphStyle / Preview
  └── verseNumberColor  ───▶ ScriptureTheme.verseNumberColor  ──▶ buildScriptureParagraphStyle / Preview
```

*   **Concrete 5-Color Schema (`CustomThemeConfig`):** Store 5 required non-null `Color` fields: `backgroundColor`, `textColor`, `wordsOfJesusColor`, `verseNumberColor`, and `primaryColor` (Accent). Default configuration seeds from the default preset (`Sepia Parchment` light).
*   **Brightness Classification & Auto-Derived Surfaces:**
    *   Determine `isDark` via `ThemeData.estimateBrightnessForColor` (the WCAG `~0.179` perceptual crossover) rather than `<= 0.45`, avoiding treating mid-light tones as dark.
    *   Derive `surfaceContainer`, `outline`, and `onSurfaceVariant` (used for UI subtitles and helper labels) from `backgroundColor` and `textColor`, clamping `onSurfaceVariant` to `textColor` if a blend drops below `3.0:1` against `backgroundColor`.
    *   Compute both `onPrimary` and `onPrimaryContainer` dynamically via `ThemeData.estimateBrightnessForColor`, and compute `inversePrimary` from `primaryColor`, removing hardcoded warm-brown/cream constants.
*   **Compatible Palette Generation & Preset Conversion:**
    *   `harmonizeFromBackground` returns a single `CustomThemeConfig` with contrast-checked `textColor` (`>= 4.5:1`), `wordsOfJesusColor` (`#B71C1C` light / `#FF8A80` dark, blended lighter/darker if `< 3.0:1`), `verseNumberColor` (`0.38` blend toward `backgroundColor`), and `primaryColor` (`>= 3.0:1` against background).
    *   `fromPreset` delegates to `fromColorScheme` for the selected preset's light or dark `ColorScheme`, seeding the mode-appropriate default `wordsOfJesusColor` and setting `verseNumberColor` to `scheme.onSurfaceVariant`.
*   **`ScriptureTheme` Extension & Shared Style Builder:**
    *   Extend `ScriptureTheme` with `verseNumberColor` alongside `wordsOfJesusColor`, defaulting `verseNumberColor` to `colorScheme.onSurfaceVariant` for presets, and centralize default `wordsOfJesusColor` resolution (`ScriptureTheme.defaultWordsOfJesusColor`).
    *   Extract a single shared `buildScriptureParagraphStyle` helper used by all scripture renderers (`ChapterText` main reader and footnote preview, `PlaylistPresentationPage`, and `PassageTrimDialog`) so verse numbers read `ScriptureTheme.verseNumberColor` consistently at full opacity.

### 2. State, Persistence & Migration (`AppState`, `UserSettings`)

*   **Single Custom Theme State (`AppState`):**
    *   Replace separate Light/Dark custom theme notifiers with one `customThemeNotifier` and `setCustomTheme`.
    *   When `isCustomTheme` is true, both `lightThemeData` and `darkThemeData` return the same `ThemeData` built from `customTheme` (passing `wordsOfJesusColor` and `verseNumberColor`), and `getWordsOfJesusColor` returns `customTheme.wordsOfJesusColor`. `UserSettings.themeMode` remains untouched so switching back to a preset restores `Light`, `Dark`, or `Device` mode.
*   **One-Time Storage Migration (`UserSettings`):**
    *   Store the single palette under `customTheme` and expose `hasSavedCustomTheme`. Remove dead `lastSelectedCustomColor` state.
    *   During `AppState.init()`, run a one-time migration when `customTheme` is absent and legacy `customThemeLight` or `customThemeDark` exists:
        1. If only one legacy key exists, migrate that key regardless of `themeMode`.
        2. If both exist, pick Dark for `ThemeMode.dark`, Light for `ThemeMode.light`, and under `ThemeMode.system` pick whichever side does not have `isBackgroundAutoDerived: true` (or fall back to platform brightness if both or neither are customized).
        3. Decode missing legacy slots via `harmonizeFromBackground`, map `secondaryTextColor` to `verseNumberColor`, fall back to the default config on malformed JSON, save `customTheme`, and delete the legacy keys.

### 3. Settings & Theme Selection Flows (`SettingsPage`, `ThemeSelectionPage`)

*   **`SettingsPage`:** Keep `Light-Dark Mode` first, `Color Theme` second, and `Text Size` third. When Custom Theme is active, disable `Light-Dark Mode`, set its subtitle to `'Disabled for custom theme'`, and dim its trailing icon.
*   **`ThemeSelectionPage`:**
    *   Read `AppState.customTheme` directly rather than holding a duplicate shadow copy.
    *   When Custom Theme is selected, disable the top `Light` / `Dark` selector with the helper note `'Custom theme uses a single color palette'`, ignore the preview mode in dirty/apply checks so `UserSettings.themeMode` is never overwritten, and render the Custom Theme swatch as `(backgroundColor, textColor, primaryColor)`.
    *   Pass `verseNumberColor` to `ScriptureThemePreviewCard` only when Custom Theme is selected (otherwise `null` so presets use `previewScheme.onSurfaceVariant`).
    *   When opening the editor, pass the saved custom theme if `hasSavedCustomTheme` is true or Custom Theme is selected; otherwise seed via `fromPreset` from the selected preset and preview mode.

### 4. Start-from-Preset + 5-Row Editor & Readability Guardrail (`CustomThemeEditorPage`, `ScriptureThemePreviewCard`)

*   **Live Preview (`ScriptureThemePreviewCard`):** Accept an optional `verseNumberColor`. In `CustomThemeEditorPage`, always pass `wordsOfJesusInRed: true`, `wordsOfJesusColor`, and `verseNumberColor`. When `Words of Jesus in Color` was off in Settings on entry, show an inline `Switch` row below the preview staged in local editor state and persisted only on `Apply`.
*   **Contrast Guardrail:** Compute `calculateContrastRatio(textColor, backgroundColor)`. Disable the single AppBar `Apply` action and show an error banner (with a `Generate Matching` quick-fix action) when ratio `< 3.0`; show a non-blocking warning banner when `3.0 <= ratio < 4.5`. Leave **Verse Number Color**, **Words of Jesus Color**, and **Accent Color** unblocked.
*   **Start from a Preset + 5 Color Rows:**
    *   **Start from a Preset** card opens a modal sheet with a `Light` / `Dark` selector at top (initialized from the active config's brightness) and all 7 presets below, seeding all 5 slots (including mode-appropriate default `Words of Jesus Color`).
    *   Five ordered rows in one card: **Background Color**, **Text Color**, **Words of Jesus Color**, **Verse Number Color**, and **Accent Color** (subtitle `'Buttons, tabs, links, and selection'`).
    *   Changing **Background Color** opens a 2-action confirmation dialog (`Keep Current` vs. `Generate Matching`), leaving colors unchanged if dismissed.

### 5. 2D Color Picker (`AppColorPicker`)

*   **Layout:** Replace 1D `Hue`, `Saturation`, and `Brightness` sliders with a color preview circle, `#RRGGBB` hex field, a 2D Saturation-Value square, an accessible hue bar `Slider`, predefined **Starter Colors** swatches, and **Recent Colors** with `Clear all` (which clears only Recent Colors).
*   **State & Gesture Integrity:** Disable sheet drag dismissal and claim vertical drags inside the 2D square so scrolling never steals square drags. Maintain `HSVColor` as internal state, preserve prior `hue` whenever `saturation == 0` or `value == 0` (across drags, swatches, and hex input), and synchronize hex field focus with swatch/square updates.

## Alternatives Considered

### Alternative A: Keep Paired Light and Dark Custom Themes With a Top-Level Switch

*   **Pros**: Preserves automatic switching (`Match device settings`) while a custom theme is active, matching the 7 preset themes.
*   **Cons**: Requires managing two palettes under one theme, causes edits in one mode to stay hidden when the device is in the opposite mode, and requires mode-mismatch dialogs on apply.
*   **Reason for Rejection**: A single palette eliminates mode-switching confusion while keeping `UserSettings.themeMode` preserved for presets.

### Alternative B: Silently Auto-Harmonize Colors on Background Change

*   **Pros**: Fewer dialogs on background color edits.
*   **Cons**: Either overwrites user-picked Text, Words of Jesus, Verse Number, and Accent colors without consent, or leaves dark-on-dark text when switching from light to dark.
*   **Reason for Rejection**: Asking via `Keep Current` vs. `Generate Matching` avoids silent overwrites while keeping regeneration one tap away.

### Alternative C: Undoable Snackbar or Threshold-Only Prompt on Background Change

*   **Pros**: Less modal interruption during minor tint adjustments.
*   **Cons**: Snackbars auto-dismiss while text may be invisible; threshold-only prompts miss intentional palette refreshes (e.g., changing from light blue to light green).
*   **Reason for Rejection**: An explicit dialog gives clear choice on every background change, paired with an inline `Generate Matching` action on the `< 3.0:1` error banner if `Keep Current` created low contrast.

### Alternative D: Hard-Block Apply Below WCAG AA `4.5:1`

*   **Pros**: Guarantees strict WCAG AA body-text contrast for every saved custom theme.
*   **Cons**: Blocks intentional low-glare reading themes in the `3.0:1–4.4:1` range.
*   **Reason for Rejection**: Hard-blocking below `3.0:1` prevents unreadable themes and menu lockouts while a soft warning below `4.5:1` informs without policing preference.

### Alternative E: Keep Verse Number Color Mapped to `ColorScheme.onSurfaceVariant`

*   **Pros**: Requires no additions to `ScriptureTheme` or reader `styleBuilder` calls.
*   **Cons**: Exempting **Verse Number Color** from contrast checks would degrade Settings subtitles, dialog helper text, and secondary icons across the app.
*   **Reason for Rejection**: Isolating `verseNumberColor` inside `ScriptureTheme` keeps app-wide UI labels readable while allowing unrestricted verse-number colors.

### Alternative F: Third-Party Picker Package or Swatch-Only Picker Without Hex Input

*   **Pros**: Avoids writing `CustomPaint` 2D square and gesture handling.
*   **Cons**: Adds external dependencies or removes free-form tint selection and exact `#RRGGBB` entry.
*   **Reason for Rejection**: Pure built-in Flutter painting with a `Slider`-backed hue bar and compact hex field preserves offline zero-dependency simplicity, accessibility, and precision.

## Risks & Mitigations

*   **Single-palette migration data loss:** Users who customized both Light and Dark custom themes lose the inactive side on upgrade. *Mitigation:* Under `ThemeMode.system`, check `isBackgroundAutoDerived != true` to prefer the customized side, fall back safely when only one legacy key exists, and wrap JSON parsing with `defaultConfig()` fallback so malformed data cannot crash `AppState.init()`.
*   **2D square accessibility and gesture conflicts:** A raw `CustomPaint` area lacks built-in screen-reader sliders and competes with `SingleChildScrollView` vertical scrolling. *Mitigation:* Keep Hue as an accessible `Semantics`-labeled `Slider` alongside accessible Starter/Recent swatches and `#RRGGBB` text input, disable modal sheet drag, and use an eager pan recognizer on the 2D square.
*   **Low-contrast `Accent Color` (`primaryColor`):** Exempting `Accent Color` from contrast checks lets users set an accent close to `backgroundColor`, reducing link/footnote visibility. *Mitigation:* Compute `onPrimary` and `onPrimaryContainer` dynamically from background luminance so filled buttons and active tab chips remain legible.

## Non-Functional Requirements

*   **Backward Compatibility & Safe Migration:** Upgrading from `customThemeLight` / `customThemeDark` migrates once into `customTheme` without startup crashes on legacy or malformed JSON.
*   **Zero External Picker Dependencies:** `AppColorPicker` uses built-in Flutter painting and gesture primitives with no added packages.
*   **Menu Legibility Floor:** Enforcing `>= 3.0:1` contrast between `textColor` and `backgroundColor`, clamping `onSurfaceVariant` to `>= 3.0:1`, and computing `onPrimary` / `onPrimaryContainer` dynamically maintains baseline contrast for primary text and navigation controls (with `< 4.5:1` soft-warned per WCAG AA guidance).

--------------------------------------------------------------------------------

## Detailed Implementation Plan

### Phase 1: `ScriptureTheme` Extension & Shared Reader Helper

#### 1. `flutter_app/lib/core/theme.dart` (Modify)

*   **Type / Scope**: Material theme builder and `ScriptureTheme` `ThemeExtension`.
*   **Proposed Changes**:
    *   Add `final Color verseNumberColor;` and `static Color defaultWordsOfJesusColor(Brightness brightness)` (`#FF8A80` dark / `#B71C1C` light) to `ScriptureTheme`, updating `copyWith`, `lerp`, `==`, and `hashCode`.
    *   Add `Color? verseNumberColor` to `MaterialTheme.buildTheme(...)` and `MaterialTheme.theme(...)`, defaulting to `colorScheme.onSurfaceVariant`.

#### 2. `flutter_app/lib/ui/shared/scripture_paragraph_style.dart` (Create)

*   **Type / Scope**: Shared scripture `UsfmParagraphStyle` helper.
*   **Proposed Changes**:
    *   Provide `buildScriptureParagraphStyle(BuildContext, {required ParagraphFormat format, required TextStyle baseStyle, required bool wordsOfJesusInRed})` reading `ScriptureTheme.verseNumberColor` (falling back to `colorScheme.onSurfaceVariant`) and `ScriptureTheme.wordsOfJesusColor` (falling back to `AppState.getWordsOfJesusColor` / `ScriptureTheme.defaultWordsOfJesusColor`), overriding `verseNumberStyle` at full opacity.

#### 3. `flutter_app/lib/ui/text/chapter/chapter_text.dart`, `flutter_app/lib/ui/playlists/playlist_presentation_page.dart`, and `flutter_app/lib/ui/playlists/widgets/passage_trim_dialog.dart` (Modify)

*   **Type / Scope**: All USFM scripture renderers (main chapter reader, footnote preview dialog, playlist presentation, and passage trim dialog).
*   **Proposed Changes**:
    *   Replace duplicated `UsfmParagraphStyle.usfmDefaults(...)` and `wordsOfJesusColor` lookup code with `buildScriptureParagraphStyle(...)`.

### Phase 2: 2D Color Picker (`AppColorPicker`)

#### 4. `flutter_app/lib/ui/settings/theme/app_color_picker.dart` (Modify)

*   **Type / Scope**: Modal color picker widget.
*   **Proposed Changes**:
    *   Disable bottom-sheet drag (`enableDrag: false`), add `starterColors` (16 predefined reading/accent colors), a `180`-tall `_SaturationValueSquare` (`x = saturation`, `y = 1 - value`) using an eager pan recognizer (`_EagerPanGestureRecognizer`) plus `TapGestureRecognizer`, and a `Semantics(label: 'Hue')` rainbow `Slider`.
    *   Preserve internal `HSVColor` across drags and keep prior `hue` when picking white, gray, or black (`saturation == 0 || value == 0`) via swatches or hex input (`#RRGGBB` and 8-digit hex pastes).
    *   Attach a `FocusNode` to the hex `TextField` so tapping swatches or dragging the square unfocuses/syncs the field, and blurring reformats to the active color.
    *   Update empty Recent Colors copy (`'No recent colors yet.'`) and keep `Clear all` scoped to Recent Colors.

### Phase 3: Single-Palette Model, Migration & Theme UI

#### 5. `flutter_app/lib/core/custom_theme_config.dart` (Modify)

*   **Type / Scope**: Core 5-color theme model and derivation logic.
*   **Proposed Changes**:
    *   Replace the 7 nullable dual-mode fields with 5 required `Color` fields: `backgroundColor`, `textColor`, `wordsOfJesusColor`, `verseNumberColor`, `primaryColor`.
    *   Add `CustomThemeConfig.defaultConfig()`, `CustomThemeConfig.fromColorScheme`, `CustomThemeConfig.fromPreset(..., {required bool isDark})`, and `ThemeData.estimateBrightnessForColor` for `isDark`.
    *   Update `harmonizeFromBackground(Color bg)` to generate a contrast-checked single `CustomThemeConfig`, and update `toColorScheme()` with dynamic `onPrimary`, `onPrimaryContainer`, `inversePrimary`, and `>= 3.0:1` clamped `onSurfaceVariant`.
    *   Update `toMap()`, `fromMap()`, `fromJsonString(String)`, `copyWith()`, `==`, and `hashCode` to migrate legacy JSON (`secondaryTextColor` -> `verseNumberColor`, missing slots resolved via `harmonizeFromBackground`, removed keys ignored, malformed JSON -> `defaultConfig()`).

#### 6. `flutter_app/lib/ui/settings/user_settings.dart` (Modify)

*   **Type / Scope**: `SharedPreferences` persistence and one-time upgrade migration.
*   **Proposed Changes**:
    *   Replace `customThemeLight` / `customThemeDark` and `lastSelectedCustomColor` with `customTheme`, `setCustomTheme`, `hasSavedCustomTheme`, and `migrateCustomThemeIfNeeded({Brightness platformBrightness})`.

#### 7. `flutter_app/lib/app_state.dart` (Modify)

*   **Type / Scope**: Application theme state manager.
*   **Proposed Changes**:
    *   Replace dual custom notifiers with `customThemeNotifier` / `setCustomTheme`, invoke `migrateCustomThemeIfNeeded` inside `init({Brightness? platformBrightness})`, return the single custom `ThemeData` (with `wordsOfJesusColor` and `verseNumberColor`) from both `lightThemeData` and `darkThemeData` when `isCustomTheme` is true, update `getWordsOfJesusColor`, and simplify `applyThemeSelection`.

#### 8. `flutter_app/lib/ui/settings/settings_page.dart` (Modify)

*   **Type / Scope**: Settings screen appearance section.
*   **Proposed Changes**:
    *   Keep `Light-Dark Mode`, `Color Theme`, `Text Size` order; when `appState.isCustomTheme` is true, disable `Light-Dark Mode`, show `'Disabled for custom theme'`, and use `Theme.of(context).disabledColor` on the trailing icon.

#### 9. `flutter_app/lib/ui/settings/theme/theme_swatch_trio.dart` (Create / Keep)

*   **Type / Scope**: Shared 3-band swatch widget.
*   **Proposed Changes**:
    *   Expose `ThemeSwatchTrio({required firstColor, required secondColor, required accentColor})` and `ThemeSwatchTrio.preset(AppThemePreset)`.

#### 10. `flutter_app/lib/ui/settings/theme/scripture_theme_preview_card.dart` (Modify)

*   **Type / Scope**: Live scripture preview card widget.
*   **Proposed Changes**:
    *   Add optional `Color? verseNumberColor` (defaulting to `colorScheme.onSurfaceVariant`) and reuse `ScriptureTheme.defaultWordsOfJesusColor`.

#### 11. `flutter_app/lib/ui/settings/theme/theme_selection_page.dart` (Modify)

*   **Type / Scope**: Color theme catalog and preset/custom chooser.
*   **Proposed Changes**:
    *   Read `AppState.customTheme` directly without shadow draft state; disable the `Light` / `Dark` `SegmentedButton` with `'Custom theme uses a single color palette'` when Custom Theme is selected; render `(backgroundColor, textColor, primaryColor)` on the Custom Theme swatch; gate preview `verseNumberColor` on Custom Theme selection; pass `mode: null` on custom apply; and seed the editor from the selected preset + preview mode when `!hasSavedCustomTheme`.

#### 12. `flutter_app/lib/ui/settings/theme/custom_theme_editor_page.dart` (Modify)

*   **Type / Scope**: Single-palette custom theme editor screen.
*   **Proposed Changes**:
    *   Take `required CustomThemeConfig initialConfig` and keep a single AppBar `Apply` button.
    *   Always pass `wordsOfJesusInRed: true` to `ScriptureThemePreviewCard`, with a staged inline `Switch` below the preview whenever `Words of Jesus in Color` was off in Settings.
    *   Show the `< 3.0:1` error banner (with a `Generate Matching` button and disabled `Apply`) and `3.0 <= contrast < 4.5` soft warning banner; leave `verseNumberColor`, `wordsOfJesusColor`, and `primaryColor` unblocked.
    *   Include the `"Start from a Preset"` card (opening a bottom sheet with `Light` / `Dark` `SegmentedButton` and all 7 presets) followed by the 5 ordered rows (**Background Color**, **Text Color**, **Words of Jesus Color**, **Verse Number Color**, **Accent Color**) and the `Keep Current` / `Generate Matching` dialog on background changes.

#### 13. `flutter_app/test/theme_preset_test.dart`, `flutter_app/test/theme_settings_test.dart`, `flutter_app/test/words_of_jesus_test.dart`, `flutter_app/test/settings_page_test.dart`, and `flutter_app/test/safe_area_bottom_nav_test.dart` (Modify)

*   **Type / Scope**: Unit and widget test suites.
*   **Proposed Changes**:
    *   Update unit and widget tests for the 5-color schema, WCAG brightness threshold, `onPrimaryContainer` contrast, legacy migration edge cases, single-palette `AppState`, `SettingsPage` disabled state, `ThemeSelectionPage` single-palette UI, `CustomThemeEditorPage` preset/background/contrast/Words-of-Jesus flows, `AppColorPicker` 2D drag/hex/hue persistence, and `ScriptureTheme.verseNumberColor` isolation.

### Verification Plan

*   **Static Analysis & Formatting**: `flutter analyze` and `dart format` pass on all modified/created files in `flutter_app/`.
*   **Unit & Widget Tests**: `flutter test` passes across the entire suite in `flutter_app/` (including `playlist_presentation_test.dart` and `passage_trim_dialog_test.dart` as regression coverage for `buildScriptureParagraphStyle`).

--------------------------------------------------------------------------------

*Drafted with EGM*
