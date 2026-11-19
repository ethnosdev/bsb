import 'package:bsb/app_state.dart';
import 'package:bsb/core/font_scale.dart';
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final header = Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      const SizedBox(height: 12),

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
                        textSize: FontScale.themePreview(_appState.textSize),
                      ),
                    ],
                  ),
                );

                final listItems = [
                  // Section: Preset Themes
                  _buildSectionHeader(context, 'Preset Themes'),
                  const SizedBox(height: 4),

                  ...AppThemePreset.all.map((preset) {
                    return _buildThemeTile(
                      context,
                      leading: ThemeSwatchTrio.preset(preset),
                      title: preset.name,
                      isSelected: _draftThemeId == preset.id,
                      onTap: () {
                        setState(() {
                          _draftThemeId = preset.id;
                        });
                      },
                    );
                  }),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),

                  // Section: Custom Theme
                  _buildSectionHeader(context, 'Personalized Theme'),
                  const SizedBox(height: 4),

                  _buildThemeTile(
                    context,
                    leading: ThemeSwatchTrio(
                      firstColor: custom.backgroundColor,
                      secondColor: custom.textColor,
                      accentColor: custom.primaryColor,
                    ),
                    title: 'Custom Theme',
                    isSelected: _isCustomSelected,
                    onTap: () {
                      setState(() {
                        _draftThemeId = AppThemePreset.customPresetId;
                      });
                    },
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: _openCustomThemeEditor,
                        icon: const Icon(Icons.palette_outlined, size: 18),
                        label: const Text('Customize Colors'),
                      ),
                    ),
                  ),
                ];

                if (constraints.maxHeight >= 520) {
                  return Column(
                    children: [
                      header,
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                          children: listItems,
                        ),
                      ),
                    ],
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    header,
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: listItems,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required Widget leading,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: isSelected,
      selectedColor: colorScheme.onSurface,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
      leading: leading,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      trailing: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
