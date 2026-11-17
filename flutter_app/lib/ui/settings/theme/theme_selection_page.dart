import 'package:bsb/app_state.dart';
import 'package:bsb/core/theme.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/theme/custom_theme_editor_page.dart';
import 'package:bsb/ui/settings/theme/scripture_theme_preview_card.dart';
import 'package:bsb/ui/settings/theme/theme_swatch_trio.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:material_ui/material_ui.dart';

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
  }

  bool get _resolveIsDark => _draftMode == ThemeMode.dark;
  bool get _isCustomSelected => _draftThemeId == AppThemePreset.customPresetId;

  ColorScheme _resolvePreviewScheme() {
    if (_isCustomSelected) {
      return _appState.customTheme.toColorScheme();
    }
    final preset = AppThemePreset.findById(_draftThemeId);
    return _resolveIsDark ? preset.darkScheme : preset.lightScheme;
  }

  bool get _hasChanges =>
      _draftThemeId != _appState.appThemeId ||
      (!_isCustomSelected &&
          _appState.themeMode != ThemeMode.system &&
          _draftMode != _appState.themeMode);

  Future<void> _applyTheme() async {
    final modeToApply =
        (_isCustomSelected || _appState.themeMode == ThemeMode.system)
        ? null
        : _draftMode;
    await _appState.applyThemeSelection(
      themeId: _draftThemeId,
      mode: modeToApply,
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
    final userSettings = getIt.isRegistered<UserSettings>()
        ? getIt<UserSettings>()
        : null;
    final hasSavedCustom = userSettings?.hasSavedCustomTheme ?? false;

    final initialConfig = (hasSavedCustom || _isCustomSelected)
        ? _appState.customTheme
        : CustomThemeConfig.fromPreset(
            AppThemePreset.findById(_draftThemeId),
            isDark: _resolveIsDark,
          );

    final applied = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            CustomThemeEditorPage(initialConfig: initialConfig),
      ),
    );

    if (applied == true && mounted) {
      setState(() {
        _draftThemeId = AppThemePreset.customPresetId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        final previewScheme = _resolvePreviewScheme();
        final custom = _appState.customTheme;

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
                // Mode Selector: disabled when Custom Theme is selected
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
                  onSelectionChanged: _isCustomSelected
                      ? null
                      : (set) {
                          setState(() {
                            _draftMode = set.first;
                          });
                        },
                ),
                if (_isCustomSelected) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Custom theme uses a single color palette',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Live Scripture Preview
                ScriptureThemePreviewCard(
                  colorScheme: previewScheme,
                  wordsOfJesusInRed: _appState.wordsOfJesusInRed,
                  wordsOfJesusColor: _isCustomSelected
                      ? custom.wordsOfJesusColor
                      : ScriptureTheme.defaultWordsOfJesusColor(
                          previewScheme.brightness,
                        ),
                  verseNumberColor: _isCustomSelected
                      ? custom.verseNumberColor
                      : null,
                  textSize: _appState.textSize,
                ),
                const SizedBox(height: 20),

                // Section: Preset Themes
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
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
                        leading: ThemeSwatchTrio.preset(preset),
                        title: Text(
                          preset.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
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
                      color: _isCustomSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: _isCustomSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        ListTile(
                          leading: ThemeSwatchTrio(
                            firstColor: custom.backgroundColor,
                            secondColor: custom.textColor,
                            accentColor: custom.primaryColor,
                          ),
                          title: const Text(
                            'Custom Theme',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Icon(
                            _isCustomSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: _isCustomSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
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
                                icon: const Icon(
                                  Icons.palette_outlined,
                                  size: 18,
                                ),
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
                  label: Text(
                    _hasChanges ? 'Apply Theme' : 'Current Theme Applied',
                  ),
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
      },
    );
  }
}
