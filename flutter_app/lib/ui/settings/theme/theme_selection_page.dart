import 'package:bsb/app_state.dart';
import 'package:bsb/core/app_theme_presets.dart';
import 'package:bsb/core/custom_theme_config.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/theme/custom_theme_editor_page.dart';
import 'package:bsb/ui/settings/theme/scripture_theme_preview_card.dart';
import 'package:flutter/material.dart';

/// The theme selection screen featuring a live scripture preview,
/// curated reading presets, mode selection, and custom theme entry.
class ThemeSelectionPage extends StatefulWidget {
  const ThemeSelectionPage({super.key});

  @override
  State<ThemeSelectionPage> createState() => _ThemeSelectionPageState();
}

class _ThemeSelectionPageState extends State<ThemeSelectionPage> {
  late final AppState _appState;
  late String _draftThemeId;
  late ThemeMode _draftMode;
  late CustomThemeConfig _customLight;
  late CustomThemeConfig _customDark;

  @override
  void initState() {
    super.initState();
    _appState = getIt<AppState>();
    _draftThemeId = _appState.appThemeId;
    final isSystemDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    _draftMode = _appState.themeMode == ThemeMode.dark
        ? ThemeMode.dark
        : _appState.themeMode == ThemeMode.light
            ? ThemeMode.light
            : (isSystemDark ? ThemeMode.dark : ThemeMode.light);
    _customLight = _appState.customThemeLight;
    _customDark = _appState.customThemeDark;
  }

  bool get _resolveIsDark => _draftMode == ThemeMode.dark;

  ColorScheme _resolvePreviewScheme(BuildContext context) {
    if (_draftThemeId == AppThemePreset.customPresetId) {
      return _resolveIsDark
          ? _customDark.toColorScheme()
          : _customLight.toColorScheme();
    }
    final preset = AppThemePreset.findById(_draftThemeId);
    return _resolveIsDark ? preset.darkScheme : preset.lightScheme;
  }

  bool get _hasChanges =>
      _draftThemeId != _appState.appThemeId ||
      (_appState.themeMode != ThemeMode.system &&
          _draftMode != _appState.themeMode) ||
      _customLight != _appState.customThemeLight ||
      _customDark != _appState.customThemeDark;

  Future<void> _applyTheme() async {
    await _appState.applyThemeSelection(
      themeId: _draftThemeId,
      mode: _appState.themeMode == ThemeMode.system ? null : _draftMode,
      lightConfig: _customLight,
      darkConfig: _customDark,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Theme applied successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _openCustomThemeEditor() async {
    final currentScheme = _resolvePreviewScheme(context);
    final applied = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CustomThemeEditorPage(
          initialLightConfig: _customLight,
          initialDarkConfig: _customDark,
          initialIsDark: _resolveIsDark,
          currentThemeBackgroundColor: currentScheme.surface,
        ),
      ),
    );

    if (applied == true && mounted) {
      setState(() {
        _draftThemeId = AppThemePreset.customPresetId;
        _customLight = _appState.customThemeLight;
        _customDark = _appState.customThemeDark;
        if (_appState.themeMode != ThemeMode.system) {
          _draftMode = _appState.themeMode;
        } else {
          final isDark =
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark;
          _draftMode = isDark ? ThemeMode.dark : ThemeMode.light;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewScheme = _resolvePreviewScheme(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Theme'),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _applyTheme,
              icon: const Icon(Icons.check),
              label: const Text('Apply'),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Mode Selector: Light / Dark only
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {_draftMode},
              onSelectionChanged: (set) {
                setState(() {
                  _draftMode = set.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // Live Scripture Preview
            ScriptureThemePreviewCard(
              colorScheme: previewScheme,
              wordsOfJesusInRed: _appState.wordsOfJesusInRed,
              textSize: _appState.textSize,
            ),
            const SizedBox(height: 20),

            // Section: Preset Themes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'Reading Themes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 8),

            ...AppThemePreset.all.map((preset) {
              final isSelected = _draftThemeId == preset.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: _buildSwatchTrio(
                      lightBg: preset.previewLightBackground,
                      darkBg: preset.previewDarkBackground,
                      accent: preset.previewAccent,
                    ),
                    title: Text(
                      preset.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      setState(() {
                        _draftThemeId = preset.id;
                      });
                    },
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            // Section: Custom Theme
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'Personalized Theme',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: _draftThemeId == AppThemePreset.customPresetId
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  width: _draftThemeId == AppThemePreset.customPresetId ? 2.0 : 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      leading: _buildSwatchTrio(
                        lightBg: _customLight.backgroundColor,
                        darkBg: _customDark.backgroundColor,
                        accent: _customLight.effectivePrimaryColor,
                      ),
                      title: const Text(
                        'Custom Theme',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Icon(
                        _draftThemeId == AppThemePreset.customPresetId
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _draftThemeId == AppThemePreset.customPresetId
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onTap: () {
                        setState(() {
                          _draftThemeId = AppThemePreset.customPresetId;
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _openCustomThemeEditor,
                            icon: const Icon(Icons.palette_outlined, size: 18),
                            label: const Text('Customize Colors'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Apply Theme Button
            FilledButton.icon(
              onPressed: _hasChanges ? _applyTheme : null,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(_hasChanges ? 'Apply Theme' : 'Current Theme Applied'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwatchTrio({
    required Color lightBg,
    required Color darkBg,
    required Color accent,
  }) {
    return Container(
      width: 48,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(child: Container(color: lightBg)),
          Expanded(child: Container(color: darkBg)),
          Container(width: 8, color: accent),
        ],
      ),
    );
  }
}
