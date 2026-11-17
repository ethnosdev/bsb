import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/settings/user_settings.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

/// A pure Flutter color picker designed for reader theme customization.
///
/// Provides starter swatches, user color history, a 2D Saturation-Value square,
/// a rainbow Hue slider, and direct hex input without HSV jargon labels.
class AppColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  final String title;
  final List<Color> recentColors;
  final VoidCallback? onClearRecentColors;

  /// Predefined swatches suited for Bible backgrounds, text, and accents.
  static const List<Color> starterColors = [
    Color(0xFFFFFFFF), // Clean White
    Color(0xFFF7F1E5), // Sepia Parchment
    Color(0xFFFAF0E6), // Soft Linen
    Color(0xFFEDF2EC), // Quiet Sage
    Color(0xFFE8EEF2), // Cool Paper
    Color(0xFF1E1E22), // Night Charcoal
    Color(0xFF1E1813), // Dark Sepia
    Color(0xFF000000), // Pure Black
    Color(0xFF1B1B1F), // Ink Black
    Color(0xFFE8E8EC), // Soft White
    Color(0xFFB71C1C), // Crimson
    Color(0xFFFF8A80), // Soft Coral
    Color(0xFF1A5A96), // Deep Navy
    Color(0xFF386646), // Forest Green
    Color(0xFF6B5778), // Royal Plum
    Color(0xFF865328), // Warm Terracotta
  ];

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
      enableDrag: false,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        Color selectedColor = initialColor;
        List<Color> currentRecentColors = List<Color>.from(
          effectiveRecentColors,
        );
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.88,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              child: const Text('Cancel'),
                            ),
                            Expanded(
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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
  late final FocusNode _hexFocusNode;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(text: _formatHex(_currentColor));
    _hexFocusNode = FocusNode()..addListener(_handleHexFocusChange);
  }

  @override
  void dispose() {
    _hexFocusNode.removeListener(_handleHexFocusChange);
    _hexFocusNode.dispose();
    _hexController.dispose();
    super.dispose();
  }

  void _handleHexFocusChange() {
    if (!_hexFocusNode.hasFocus && mounted) {
      _hexController.text = _formatHex(_currentColor);
    }
  }

  Color get _currentColor => _hsvColor.toColor();

  String _formatHex(Color c) {
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  void _updateHsv(
    HSVColor newHsv, {
    bool updateHexField = true,
    bool unfocusHex = true,
  }) {
    if (unfocusHex && _hexFocusNode.hasFocus) {
      _hexFocusNode.unfocus();
    }
    setState(() {
      _hsvColor = newHsv;
      if (updateHexField) {
        _hexController.text = _formatHex(_currentColor);
      }
    });
    widget.onColorChanged(_currentColor);
  }

  void _selectColorPreservingHue(Color color, {bool updateHexField = true}) {
    final parsed = HSVColor.fromColor(color);
    // Preserve prior hue on white/gray/black so moving into color keeps the user's hue.
    final resolved = (parsed.saturation == 0.0 || parsed.value == 0.0)
        ? parsed.withHue(_hsvColor.hue)
        : parsed;
    _updateHsv(
      resolved,
      updateHexField: updateHexField,
      unfocusHex: updateHexField,
    );
  }

  void _onHexChanged(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final value = int.tryParse('FF$clean', radix: 16);
      if (value != null) {
        _selectColorPreservingHue(Color(value), updateHexField: false);
      }
    } else if (clean.length == 8) {
      final value = int.tryParse(clean, radix: 16);
      if (value != null) {
        _selectColorPreservingHue(
          Color(value).withAlpha(255),
          updateHexField: false,
        );
      }
    }
  }

  Widget _buildSwatch(Color color) {
    final isSelected = color.toARGB32() == _currentColor.toARGB32();
    return GestureDetector(
      key: ValueKey(color.toARGB32()),
      onTap: () => _selectColorPreservingHue(color),
      child: Container(
        width: 36,
        height: 36,
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
                size: 18,
                color:
                    ThemeData.estimateBrightnessForColor(color) ==
                        Brightness.light
                    ? Colors.black
                    : Colors.white,
              )
            : null,
      ),
    );
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
            Expanded(
              child: TextField(
                controller: _hexController,
                focusNode: _hexFocusNode,
                decoration: InputDecoration(
                  labelText: 'Hex Color',
                  hintText: '#RRGGBB',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.tag, size: 20),
                ),
                onSubmitted: _onHexChanged,
                onChanged: _onHexChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 2D Color Square
        _SaturationValueSquare(
          key: const ValueKey('color_picker_2d_square'),
          hsvColor: _hsvColor,
          onChanged: (s, v) {
            _updateHsv(_hsvColor.withSaturation(s).withValue(v));
          },
        ),
        const SizedBox(height: 14),

        // Hue Spectrum Bar (accessible standard Slider)
        Container(
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
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
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Semantics(
              label: 'Hue',
              child: Slider(
                value: _hsvColor.hue,
                min: 0.0,
                max: 360.0,
                onChanged: (val) {
                  _updateHsv(_hsvColor.withHue(val));
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Starter Colors
        const Text(
          'Starter Colors',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppColorPicker.starterColors.map(_buildSwatch).toList(),
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
              'No recent colors yet.',
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
            children: widget.recentColors.map(_buildSwatch).toList(),
          ),
      ],
    );
  }
}

class _SaturationValueSquare extends StatelessWidget {
  final HSVColor hsvColor;
  final void Function(double saturation, double value) onChanged;

  const _SaturationValueSquare({
    super.key,
    required this.hsvColor,
    required this.onChanged,
  });

  void _handleLocalOffset(Offset localPosition, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final saturation = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final value = (1.0 - localPosition.dy / size.height).clamp(0.0, 1.0);
    onChanged(saturation, value);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 280.0;
        const height = 180.0;
        final size = Size(width, height);

        return SizedBox(
          width: width,
          height: height,
          child: RawGestureDetector(
            gestures: {
              _EagerPanGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    _EagerPanGestureRecognizer
                  >(() => _EagerPanGestureRecognizer(), (
                    _EagerPanGestureRecognizer instance,
                  ) {
                    instance
                      ..onStart = (details) {
                        _handleLocalOffset(details.localPosition, size);
                      }
                      ..onUpdate = (details) {
                        _handleLocalOffset(details.localPosition, size);
                      };
                  }),
              TapGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                    () => TapGestureRecognizer(),
                    (TapGestureRecognizer instance) {
                      instance.onTapDown = (details) {
                        _handleLocalOffset(details.localPosition, size);
                      };
                    },
                  ),
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                size: size,
                painter: _SaturationValuePainter(hsvColor: hsvColor),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _SaturationValuePainter extends CustomPainter {
  final HSVColor hsvColor;

  _SaturationValuePainter({required this.hsvColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1.0, hsvColor.hue, 1.0, 1.0).toColor();

    final saturationPaint = Paint()
      ..shader = LinearGradient(colors: [Colors.white, hueColor])
          .createShader(rect);
    canvas.drawRect(rect, saturationPaint);

    final valuePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black],
      ).createShader(rect);
    canvas.drawRect(rect, valuePaint);

    final thumbOffset = Offset(
      hsvColor.saturation.clamp(0.0, 1.0) * size.width,
      (1.0 - hsvColor.value.clamp(0.0, 1.0)) * size.height,
    );

    canvas.drawCircle(
      thumbOffset,
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      thumbOffset,
      8,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) {
    return oldDelegate.hsvColor != hsvColor;
  }
}
