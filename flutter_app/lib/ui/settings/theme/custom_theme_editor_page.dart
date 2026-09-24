import 'package:bsb/app_state.dart';
import 'package:bsb/core/app_theme_presets.dart';
import 'package:bsb/core/custom_theme_config.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/theme/app_color_picker.dart';
import 'package:bsb/ui/settings/theme/scripture_theme_preview_card.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';

/// Full-featured custom theme editor with live scripture preview,
/// simple background picking, and expandable fine-tuning for all colors.
class CustomThemeEditorPage extends StatefulWidget {
  final CustomThemeConfig initialLightConfig;
  final CustomThemeConfig initialDarkConfig;
  final bool initialIsDark;
  final Color? currentThemeBackgroundColor;

  const CustomThemeEditorPage({
    super.key,
    required this.initialLightConfig,
    required this.initialDarkConfig,
    this.initialIsDark = false,
    this.currentThemeBackgroundColor,
  });

  @override
  State<CustomThemeEditorPage> createState() => _CustomThemeEditorPageState();
}

class _CustomThemeEditorPageState extends State<CustomThemeEditorPage> {
  late CustomThemeConfig _lightConfig;
  late CustomThemeConfig _darkConfig;
  late bool _isEditingDark;
  bool _isFineTuneExpanded = false;

  Color get _currentThemeBackgroundColor {
    if (widget.currentThemeBackgroundColor != null) {
      return widget.currentThemeBackgroundColor!;
    }
    if (getIt.isRegistered<AppState>()) {
      final appState = getIt<AppState>();
      final preset = appState.currentThemePreset;
      final scheme = _isEditingDark ? preset.darkScheme : preset.lightScheme;
      return scheme.surface;
    }
    return _activeConfig.backgroundColor;
  }

  @override
  void initState() {
    super.initState();
    _lightConfig = widget.initialLightConfig;
    _darkConfig = widget.initialDarkConfig;
    _isEditingDark = widget.initialIsDark;

    final userSettings = getIt.isRegistered<UserSettings>()
        ? getIt<UserSettings>()
        : null;
    final lastChosen = userSettings?.lastSelectedCustomColor;

    // Use last selected custom color if previously chosen, or current theme background color
    final defaultBg = lastChosen ?? _currentThemeBackgroundColor;
    final (harmonizedLight, harmonizedDark) =
        CustomThemeConfig.harmonizeFromBackground(defaultBg);
    _lightConfig = harmonizedLight;
    _darkConfig = harmonizedDark;
    _isEditingDark = defaultBg.computeLuminance() <= 0.45;
  }

  CustomThemeConfig get _activeConfig =>
      _isEditingDark ? _darkConfig : _lightConfig;

  void _updateActiveConfig(CustomThemeConfig updated) {
    setState(() {
      if (_isEditingDark) {
        _darkConfig = updated;
      } else {
        _lightConfig = updated;
      }
    });
  }

  Future<void> _pickColor({
    required String title,
    required Color currentColor,
    required ValueChanged<Color> onSelected,
  }) async {
    final selected = await AppColorPicker.show(
      context: context,
      initialColor: currentColor,
      title: title,
    );
    if (selected != null) {
      if (getIt.isRegistered<UserSettings>() && mounted) {
        await getIt<UserSettings>().addCustomColorToHistory(selected);
      }
      onSelected(selected);
    }
  }

  void _onPrimaryBackgroundSelected(Color newBg) {
    if (getIt.isRegistered<UserSettings>()) {
      getIt<UserSettings>().setLastSelectedCustomColor(newBg);
    }
    final (harmonizedLight, harmonizedDark) =
        CustomThemeConfig.harmonizeFromBackground(newBg);
    setState(() {
      _lightConfig = harmonizedLight;
      _darkConfig = harmonizedDark;
      _isEditingDark = newBg.computeLuminance() <= 0.45;
    });
  }

  void _autoHarmonizeAll() {
    final bg = _activeConfig.backgroundColor;
    _updateActiveConfig(
      CustomThemeConfig(
        backgroundColor: bg,
        isBackgroundAutoDerived: _activeConfig.isBackgroundAutoDerived,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Auto-harmonized all colors based on background.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyFromOppositeMode() {
    if (_isEditingDark) {
      // Invert light background for dark mode
      final lightBg = _lightConfig.backgroundColor;
      final darkBg = Color.lerp(lightBg, Colors.black, 0.88)!;
      _updateActiveConfig(
        CustomThemeConfig(
          backgroundColor: darkBg,
          isBackgroundAutoDerived: true,
          primaryColor: _lightConfig.primaryColor != null
              ? Color.lerp(_lightConfig.primaryColor, Colors.white, 0.3)
              : null,
        ),
      );
    } else {
      // Invert dark background for light mode
      final darkBg = _darkConfig.backgroundColor;
      final lightBg = Color.lerp(darkBg, Colors.white, 0.93)!;
      _updateActiveConfig(
        CustomThemeConfig(
          backgroundColor: lightBg,
          isBackgroundAutoDerived: true,
          primaryColor: _darkConfig.primaryColor != null
              ? Color.lerp(_darkConfig.primaryColor, Colors.black, 0.3)
              : null,
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditingDark
              ? 'Derived dark theme from light theme.'
              : 'Derived light theme from dark theme.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetToDefault() {
    setState(() {
      if (_isEditingDark) {
        _darkConfig = CustomThemeConfig.defaultDark();
      } else {
        _lightConfig = CustomThemeConfig.defaultLight();
      }
    });
  }

  bool _isEffectiveAppDark() {
    if (getIt.isRegistered<AppState>()) {
      final appState = getIt<AppState>();
      if (appState.themeMode == ThemeMode.dark) return true;
      if (appState.themeMode == ThemeMode.light) return false;
    }
    return Theme.of(context).brightness == Brightness.dark;
  }

  Future<void> _applyAndSave() async {
    final appState = getIt<AppState>();
    final isAppDark = _isEffectiveAppDark();
    final isSystemMode = appState.themeMode == ThemeMode.system;
    ThemeMode? targetMode;

    if (isAppDark && !_isEditingDark) {
      // The user is currently experiencing Dark Mode (either explicitly or via system),
      // but designed/viewed a Light Mode background.
      final message = isSystemMode
          ? 'The background color you selected is a light mode color, but your app is currently matching your device settings (Dark Mode).\n\n'
              'Would you like to switch to Light Mode so your chosen background color is applied immediately?'
          : 'The background color you selected is a light mode color, but your app is currently in Dark Mode.\n\n'
              'Would you like to switch to Light Mode so your chosen background color is applied immediately?';

      final switchMode = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.light_mode_outlined, size: 28),
          title: const Text('Switch to Light Mode?'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(isSystemMode ? 'Keep Device Settings' : 'Keep Dark Mode'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Switch to Light Mode'),
            ),
          ],
        ),
      );

      if (switchMode == null) return; // Dismissed dialog, abort apply
      if (switchMode) {
        targetMode = ThemeMode.light;
      }
    } else if (!isAppDark && _isEditingDark) {
      // The user is currently experiencing Light Mode (either explicitly or via system),
      // but designed/viewed a Dark Mode background.
      final message = isSystemMode
          ? 'The background color you selected is a dark mode color, but your app is currently matching your device settings (Light Mode).\n\n'
              'Would you like to switch to Dark Mode so your chosen background color is applied immediately?'
          : 'The background color you selected is a dark mode color, but your app is currently in Light Mode.\n\n'
              'Would you like to switch to Dark Mode so your chosen background color is applied immediately?';

      final switchMode = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.dark_mode_outlined, size: 28),
          title: const Text('Switch to Dark Mode?'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(isSystemMode ? 'Keep Device Settings' : 'Keep Light Mode'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Switch to Dark Mode'),
            ),
          ],
        ),
      );

      if (switchMode == null) return; // Dismissed dialog, abort apply
      if (switchMode) {
        targetMode = ThemeMode.dark;
      }
    }

    await appState.applyThemeSelection(
      themeId: AppThemePreset.customPresetId,
      lightConfig: _lightConfig,
      darkConfig: _darkConfig,
      mode: targetMode,
    );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = getIt<AppState>();
    final activeScheme = _activeConfig.toColorScheme();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Theme Editor'),
        actions: [
          TextButton.icon(
            onPressed: _applyAndSave,
            icon: const Icon(Icons.check),
            label: const Text('Apply'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Live Scripture Preview Card
            ScriptureThemePreviewCard(
              colorScheme: activeScheme,
              wordsOfJesusInRed: appState.wordsOfJesusInRed,
              textSize: appState.textSize,
            ),
            const SizedBox(height: 16),

            // Primary Background Color Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _buildColorIndicator(
                  _activeConfig.backgroundColor,
                  size: 36,
                ),
                title: const Text(
                  'Background Color',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Text(
                  'Choose a reading background color. Text, accent, and opposing mode automatically harmonize.',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.colorize),
                onTap: () {
                  _pickColor(
                    title: 'Background Color',
                    currentColor: _activeConfig.backgroundColor,
                    onSelected: _onPrimaryBackgroundSelected,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Expandable Fine-Tune Section: "Customize All Colors"
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: _isFineTuneExpanded,
                  onExpansionChanged: (val) {
                    setState(() {
                      _isFineTuneExpanded = val;
                    });
                  },
                  title: const Text(
                    'Customize All Colors',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Override accent color, light or dark mode, text, and containers.',
                    style: TextStyle(fontSize: 12),
                  ),
                  children: [
                    const Divider(height: 1),
                    // Light / Dark Mode Toggle inside Customize All Colors
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Light Mode'),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Dark Mode'),
                          ),
                        ],
                        selected: {_isEditingDark},
                        onSelectionChanged: (set) {
                          setState(() {
                            _isEditingDark = set.first;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Accent Color tile
                    _buildFineTuneTile(
                      title: 'Accent Color',
                      isCustomized: _activeConfig.primaryColor != null,
                      color: _activeConfig.effectivePrimaryColor,
                      onTap: () {
                        _pickColor(
                          title: 'Accent Color',
                          currentColor: _activeConfig.effectivePrimaryColor,
                          onSelected: (c) {
                            _updateActiveConfig(
                              _activeConfig.copyWith(primaryColor: c),
                            );
                          },
                        );
                      },
                      onReset: () {
                        _updateActiveConfig(
                          _activeConfig.copyWith(clearPrimaryColor: true),
                        );
                      },
                    ),

                    // Background Color override for this mode
                    _buildFineTuneTile(
                      title: 'Background Color',
                      isCustomized: !_activeConfig.isBackgroundAutoDerived,
                      color: _activeConfig.backgroundColor,
                      onTap: () {
                        _pickColor(
                          title: 'Background Color',
                          currentColor: _activeConfig.backgroundColor,
                          onSelected: (c) {
                            if (getIt.isRegistered<UserSettings>()) {
                              getIt<UserSettings>().setLastSelectedCustomColor(c);
                            }
                            _updateActiveConfig(
                              _activeConfig.copyWith(
                                backgroundColor: c,
                                isBackgroundAutoDerived: false,
                              ),
                            );
                          },
                        );
                      },
                      onReset: _activeConfig.isBackgroundAutoDerived
                          ? null
                          : () {
                              final oppositeBg = _isEditingDark
                                  ? _lightConfig.backgroundColor
                                  : _darkConfig.backgroundColor;
                              final derived = _isEditingDark
                                  ? Color.lerp(oppositeBg, Colors.black, 0.88)!
                                  : Color.lerp(oppositeBg, Colors.white, 0.93)!;
                              _updateActiveConfig(
                                _activeConfig.copyWith(
                                  backgroundColor: derived,
                                  isBackgroundAutoDerived: true,
                                ),
                              );
                            },
                    ),

                    // Scripture Text Color
                    _buildFineTuneTile(
                      title: 'Scripture Text Color',
                      isCustomized: _activeConfig.textColor != null,
                      color: _activeConfig.effectiveTextColor,
                      onTap: () {
                        _pickColor(
                          title: 'Scripture Text Color',
                          currentColor: _activeConfig.effectiveTextColor,
                          onSelected: (c) {
                            _updateActiveConfig(
                              _activeConfig.copyWith(textColor: c),
                            );
                          },
                        );
                      },
                      onReset: () {
                        _updateActiveConfig(
                          _activeConfig.copyWith(clearTextColor: true),
                        );
                      },
                    ),

                    // Verse Numbers & Secondary Text
                    _buildFineTuneTile(
                      title: 'Verse Numbers & Secondary Text',
                      isCustomized: _activeConfig.secondaryTextColor != null,
                      color: _activeConfig.effectiveSecondaryTextColor,
                      onTap: () {
                        _pickColor(
                          title: 'Verse Numbers & Secondary Text',
                          currentColor:
                              _activeConfig.effectiveSecondaryTextColor,
                          onSelected: (c) {
                            _updateActiveConfig(
                              _activeConfig.copyWith(secondaryTextColor: c),
                            );
                          },
                        );
                      },
                      onReset: () {
                        _updateActiveConfig(
                          _activeConfig.copyWith(clearSecondaryTextColor: true),
                        );
                      },
                    ),

                    // Cards & Panels Surface
                    _buildFineTuneTile(
                      title: 'Cards & Panels Surface',
                      isCustomized: _activeConfig.surfaceContainerColor != null,
                      color: _activeConfig.effectiveSurfaceContainer,
                      onTap: () {
                        _pickColor(
                          title: 'Cards & Panels Surface',
                          currentColor:
                              _activeConfig.effectiveSurfaceContainer,
                          onSelected: (c) {
                            _updateActiveConfig(
                              _activeConfig.copyWith(surfaceContainerColor: c),
                            );
                          },
                        );
                      },
                      onReset: () {
                        _updateActiveConfig(
                          _activeConfig.copyWith(
                              clearSurfaceContainerColor: true),
                        );
                      },
                    ),

                    // Dividers & Outlines
                    _buildFineTuneTile(
                      title: 'Dividers & Outlines',
                      isCustomized: _activeConfig.outlineColor != null,
                      color: _activeConfig.effectiveOutline,
                      onTap: () {
                        _pickColor(
                          title: 'Dividers & Outlines',
                          currentColor: _activeConfig.effectiveOutline,
                          onSelected: (c) {
                            _updateActiveConfig(
                              _activeConfig.copyWith(outlineColor: c),
                            );
                          },
                        );
                      },
                      onReset: () {
                        _updateActiveConfig(
                          _activeConfig.copyWith(clearOutlineColor: true),
                        );
                      },
                    ),

                    const Divider(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _autoHarmonizeAll,
                            icon: const Icon(Icons.auto_fix_high, size: 18),
                            label: const Text('Auto-Harmonize Mode'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _copyFromOppositeMode,
                            icon: const Icon(Icons.sync_alt, size: 18),
                            label: Text(
                              _isEditingDark
                                  ? 'Generate from Light'
                                  : 'Generate from Dark',
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _resetToDefault,
                            icon: const Icon(Icons.restore, size: 18),
                            label: const Text('Reset Mode'),
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
              onPressed: _applyAndSave,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Apply Custom Theme'),
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

  Widget _buildFineTuneTile({
    required String title,
    required bool isCustomized,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onReset,
  }) {
    return ListTile(
      leading: _buildColorIndicator(color, size: 28),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        isCustomized ? 'Custom color' : 'Auto-derived',
        style: TextStyle(
          fontSize: 11,
          color: isCustomized ? Colors.teal : Colors.grey,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCustomized && onReset != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: 'Reset to auto-derived',
              onPressed: onReset,
            ),
          IconButton(
            icon: const Icon(Icons.colorize, size: 18),
            tooltip: 'Select color',
            onPressed: onTap,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildColorIndicator(Color color, {double size = 28}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
