import 'package:bsb/app_state.dart';
import 'package:bsb/core/font_scale.dart';
import 'package:bsb/core/theme.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/theme/app_color_picker.dart';
import 'package:bsb/ui/settings/theme/scripture_theme_preview_card.dart';
import 'package:bsb/ui/settings/theme/theme_swatch_trio.dart';
import 'package:material_ui/material_ui.dart';

/// Custom theme editor for a single 5-color palette with a live scripture preview,
/// preset starter picker, readability guardrail, and 2D color picker.
class CustomThemeEditorPage extends StatefulWidget {
  final CustomThemeConfig initialConfig;

  const CustomThemeEditorPage({super.key, required this.initialConfig});

  @override
  State<CustomThemeEditorPage> createState() => _CustomThemeEditorPageState();
}

class _CustomThemeEditorPageState extends State<CustomThemeEditorPage> {
  static const double _hardMinContrast = 3.0;
  static const double _softMinContrast = 4.5;

  late CustomThemeConfig _config;
  late bool _wordsOfJesusInRed;
  late final bool _initiallyHadWordsOfJesusOff;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    final appState = getIt.isRegistered<AppState>() ? getIt<AppState>() : null;
    _wordsOfJesusInRed = appState?.wordsOfJesusInRed ?? false;
    _initiallyHadWordsOfJesusOff = !_wordsOfJesusInRed;
  }

  Future<Color?> _pickColor({
    required String title,
    required Color currentColor,
  }) {
    return AppColorPicker.show(
      context: context,
      initialColor: currentColor,
      title: title,
    );
  }

  Future<void> _onBackgroundColorTap() async {
    final selected = await _pickColor(
      title: 'Background Color',
      currentColor: _config.backgroundColor,
    );
    if (selected == null || !mounted) return;
    if (selected.toARGB32() == _config.backgroundColor.toARGB32()) return;

    final shouldGenerate = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update other colors?'),
        content: const Text(
          'Generate matching Text, Words of Jesus, Verse Number, and Accent colors for this background, or keep your current colors?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Current'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Generate Matching'),
          ),
        ],
      ),
    );

    if (shouldGenerate == null || !mounted) return;
    setState(() {
      _config = shouldGenerate
          ? CustomThemeConfig.harmonizeFromBackground(selected)
          : _config.copyWith(backgroundColor: selected);
    });
  }

  Future<void> _showPresetPickerSheet() async {
    bool sheetIsDark = _config.isDark;

    final result =
        await showModalBottomSheet<({AppThemePreset preset, bool isDark})>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (sheetContext) {
            return StatefulBuilder(
              builder: (ctx, setSheetState) {
                return SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(sheetContext)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Text(
                            'Start from a Preset',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment<bool>(
                                value: false,
                                icon: Icon(Icons.light_mode_outlined),
                                label: Text('Light'),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                icon: Icon(Icons.dark_mode_outlined),
                                label: Text('Dark'),
                              ),
                            ],
                            selected: {sheetIsDark},
                            onSelectionChanged: (set) {
                              setSheetState(() {
                                sheetIsDark = set.first;
                              });
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: AppThemePreset.all.length,
                            itemBuilder: (itemCtx, index) {
                              final preset = AppThemePreset.all[index];
                              final scheme = sheetIsDark
                                  ? preset.darkScheme
                                  : preset.lightScheme;
                              return ListTile(
                                leading: ThemeSwatchTrio(
                                  firstColor: scheme.surface,
                                  secondColor: scheme.onSurface,
                                  accentColor: scheme.primary,
                                ),
                                title: Text(
                                  preset.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onTap: () => Navigator.of(sheetContext)
                                    .pop((preset: preset, isDark: sheetIsDark)),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );

    if (result == null || !mounted) return;
    setState(() {
      _config = CustomThemeConfig.fromPreset(
        result.preset,
        isDark: result.isDark,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Loaded "${result.preset.name}" (${result.isDark ? 'Dark' : 'Light'}).',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _applyAndSave() async {
    final appState = getIt<AppState>();
    if (_wordsOfJesusInRed != appState.wordsOfJesusInRed) {
      await appState.setWordsOfJesusInRed(_wordsOfJesusInRed);
    }
    await appState.applyThemeSelection(
      themeId: AppThemePreset.customPresetId,
      customConfig: _config,
    );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = getIt<AppState>();
    final activeScheme = _config.toColorScheme();
    final ratio = _config.contrastRatio;
    final isUnreadable = ratio < _hardMinContrast;
    final isLowContrast = ratio >= _hardMinContrast && ratio < _softMinContrast;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Theme Editor'),
        actions: [
          TextButton.icon(
            onPressed: isUnreadable ? null : _applyAndSave,
            icon: const Icon(Icons.check),
            label: const Text('Apply'),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previewHeader = Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: ScriptureThemePreviewCard(
                colorScheme: activeScheme,
                wordsOfJesusInRed: true,
                wordsOfJesusColor: _config.wordsOfJesusColor,
                verseNumberColor: _config.verseNumberColor,
                textSize: FontScale.themePreview(appState.textSize),
              ),
            );

            final editorItems = [
              // Inline cue + staged toggle when Words of Jesus in Color was off
              if (_initiallyHadWordsOfJesusOff) ...[
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: SwitchListTile(
                    dense: true,
                    title: const Text(
                      'Show Words of Jesus in color while reading',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      _wordsOfJesusInRed
                          ? 'Will be enabled when you tap Apply'
                          : 'Currently off in Settings (preview only)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _wordsOfJesusInRed,
                    onChanged: (value) {
                      setState(() {
                        _wordsOfJesusInRed = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Readability Contrast Banners
              if (isUnreadable) ...[
                _ContrastWarningBanner(
                  isError: true,
                  message:
                      'Text and background colors are too close to read (${ratio.toStringAsFixed(1)}:1). Adjust Text or Background Color to apply.',
                  onGenerateMatching: () {
                    setState(() {
                      _config = CustomThemeConfig.harmonizeFromBackground(
                        _config.backgroundColor,
                      );
                    });
                  },
                ),
                const SizedBox(height: 12),
              ] else if (isLowContrast) ...[
                _ContrastWarningBanner(
                  isError: false,
                  message:
                      'Low contrast (${ratio.toStringAsFixed(1)}:1) — may be harder to read.',
                ),
                const SizedBox(height: 12),
              ],

              // Start from a Preset Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: ThemeSwatchTrio(
                    firstColor: _config.backgroundColor,
                    secondColor: _config.textColor,
                    accentColor: _config.primaryColor,
                  ),
                  title: const Text(
                    'Start from a Preset',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showPresetPickerSheet,
                ),
              ),
              const SizedBox(height: 16),

              // Five Ordered Color Slots
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    _buildColorRow(
                      title: 'Background Color',
                      color: _config.backgroundColor,
                      onTap: _onBackgroundColorTap,
                    ),
                    const Divider(height: 1),
                    _buildColorRow(
                      title: 'Text Color',
                      color: _config.textColor,
                      onTap: () async {
                        final selected = await _pickColor(
                          title: 'Text Color',
                          currentColor: _config.textColor,
                        );
                        if (selected != null && mounted) {
                          setState(() {
                            _config = _config.copyWith(textColor: selected);
                          });
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _buildColorRow(
                      title: 'Words of Jesus Color',
                      color: _config.wordsOfJesusColor,
                      onTap: () async {
                        final selected = await _pickColor(
                          title: 'Words of Jesus Color',
                          currentColor: _config.wordsOfJesusColor,
                        );
                        if (selected != null && mounted) {
                          setState(() {
                            _config = _config.copyWith(
                              wordsOfJesusColor: selected,
                            );
                          });
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _buildColorRow(
                      title: 'Verse Number Color',
                      color: _config.verseNumberColor,
                      onTap: () async {
                        final selected = await _pickColor(
                          title: 'Verse Number Color',
                          currentColor: _config.verseNumberColor,
                        );
                        if (selected != null && mounted) {
                          setState(() {
                            _config = _config.copyWith(
                              verseNumberColor: selected,
                            );
                          });
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _buildColorRow(
                      title: 'Accent Color',
                      subtitle: 'Buttons, tabs, links, and selection',
                      color: _config.primaryColor,
                      onTap: () async {
                        final selected = await _pickColor(
                          title: 'Accent Color',
                          currentColor: _config.primaryColor,
                        );
                        if (selected != null && mounted) {
                          setState(() {
                            _config = _config.copyWith(primaryColor: selected);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ];

            if (constraints.maxHeight >= 520) {
              return Column(
                children: [
                  previewHeader,
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: editorItems,
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                previewHeader,
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: editorItems,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildColorRow({
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 30,
        height: 30,
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
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: const Icon(Icons.colorize, size: 20),
      onTap: onTap,
    );
  }
}

class _ContrastWarningBanner extends StatelessWidget {
  final bool isError;
  final String message;
  final VoidCallback? onGenerateMatching;

  const _ContrastWarningBanner({
    required this.isError,
    required this.message,
    this.onGenerateMatching,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isError
        ? colorScheme.errorContainer
        : colorScheme.surfaceContainerHigh;
    final fgColor = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? colorScheme.error : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.warning_amber_rounded,
            color: isError ? colorScheme.error : colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: TextStyle(color: fgColor, fontSize: 13)),
                if (onGenerateMatching != null) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: onGenerateMatching,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Generate Matching'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
