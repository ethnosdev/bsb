import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/material.dart';

/// A pure Flutter color picker designed for reader theme customization.
///
/// Provides user color history swatches, HSV sliders, and direct hex input.
class AppColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  final String title;
  final List<Color> recentColors;
  final VoidCallback? onClearRecentColors;

  const AppColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.title = 'Choose Color',
    this.recentColors = const [],
    this.onClearRecentColors,
  });

  /// Shows the color picker in a bottom modal sheet.
  static Future<Color?> show({
    required BuildContext context,
    required Color initialColor,
    String title = 'Choose Color',
    List<Color>? recentColors,
    VoidCallback? onClearRecentColors,
  }) {
    final effectiveRecentColors = List<Color>.from(
      recentColors ??
          (getIt.isRegistered<UserSettings>()
              ? getIt<UserSettings>().customColorHistory
              : const <Color>[]),
    );
    return showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        Color selectedColor = initialColor;
        List<Color> currentRecentColors =
            List<Color>.from(effectiveRecentColors);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle and Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Cancel'),
                          ),
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          FilledButton(
                            onPressed: () async {
                              if (getIt.isRegistered<UserSettings>()) {
                                await getIt<UserSettings>()
                                    .addCustomColorToHistory(selectedColor);
                              }
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop(selectedColor);
                              }
                            },
                            child: const Text('Select'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: AppColorPicker(
                          initialColor: initialColor,
                          title: title,
                          recentColors: currentRecentColors,
                          onClearRecentColors: () async {
                            if (onClearRecentColors != null) {
                              onClearRecentColors();
                            } else if (getIt.isRegistered<UserSettings>()) {
                              await getIt<UserSettings>()
                                  .clearCustomColorHistory();
                            }
                            setSheetState(() {
                              currentRecentColors.clear();
                            });
                          },
                          onColorChanged: (c) {
                            setSheetState(() {
                              selectedColor = c;
                            });
                          },
                        ),
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
  }

  @override
  State<AppColorPicker> createState() => _AppColorPickerState();
}

class _AppColorPickerState extends State<AppColorPicker> {
  late HSVColor _hsvColor;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(text: _formatHex(_currentColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color get _currentColor => _hsvColor.toColor();

  String _formatHex(Color c) {
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  void _updateColor(HSVColor newHsv, {bool updateHexField = true}) {
    setState(() {
      _hsvColor = newHsv;
      if (updateHexField) {
        _hexController.text = _formatHex(_currentColor);
      }
    });
    widget.onColorChanged(_currentColor);
  }

  void _onHexSubmitted(String hex) {
    String clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final value = int.tryParse('FF$clean', radix: 16);
      if (value != null) {
        _updateColor(HSVColor.fromColor(Color(value)), updateHexField: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Swatch preview & Hex field
        Row(
          children: [
            // Color preview circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Hex field
            Expanded(
              child: TextField(
                controller: _hexController,
                decoration: InputDecoration(
                  labelText: 'Hex Color',
                  hintText: '#RRGGBB',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.tag, size: 20),
                ),
                onSubmitted: _onHexSubmitted,
                onChanged: (val) {
                  if (val.length >= 6) {
                    _onHexSubmitted(val);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Recent Colors
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Colors',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            if (widget.recentColors.isNotEmpty &&
                widget.onClearRecentColors != null)
              TextButton(
                onPressed: widget.onClearRecentColors,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Clear all'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.recentColors.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No previous colors yet. Use the sliders or hex code below to choose a color.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.recentColors.map((color) {
              final isSelected = color.toARGB32() == _currentColor.toARGB32();
              return GestureDetector(
                key: ValueKey(color.toARGB32()),
                onTap: () {
                  _updateColor(HSVColor.fromColor(color));
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade400,
                      width: isSelected ? 3.0 : 1.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 20,
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 20),

        // Sliders
        const Text(
          'Fine-Tune Tone',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 12),

        // Hue Slider with Rainbow Track
        Row(
          children: [
            const SizedBox(
              width: 75,
              child: Text('Hue', style: TextStyle(fontSize: 12)),
            ),
            Expanded(
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF0000),
                      Color(0xFFFFFF00),
                      Color(0xFF00FF00),
                      Color(0xFF00FFFF),
                      Color(0xFF0000FF),
                      Color(0xFFFF00FF),
                      Color(0xFFFF0000),
                    ],
                  ),
                ),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 0,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 10),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: _hsvColor.hue,
                    min: 0.0,
                    max: 360.0,
                    onChanged: (val) {
                      _updateColor(_hsvColor.withHue(val));
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Saturation Slider
        Row(
          children: [
            const SizedBox(
              width: 75,
              child: Text('Saturation', style: TextStyle(fontSize: 12)),
            ),
            Expanded(
              child: Slider(
                value: _hsvColor.saturation,
                min: 0.0,
                max: 1.0,
                onChanged: (val) {
                  _updateColor(_hsvColor.withSaturation(val));
                },
              ),
            ),
          ],
        ),

        // Brightness / Value Slider
        Row(
          children: [
            const SizedBox(
              width: 75,
              child: Text('Brightness', style: TextStyle(fontSize: 12)),
            ),
            Expanded(
              child: Slider(
                value: _hsvColor.value,
                min: 0.0,
                max: 1.0,
                onChanged: (val) {
                  _updateColor(_hsvColor.withValue(val));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
