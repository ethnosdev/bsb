import 'package:bsb/core/app_theme_presets.dart';
import 'package:material_ui/material_ui.dart';

/// Compact 3-band swatch previewing three theme colors.
class ThemeSwatchTrio extends StatelessWidget {
  final Color firstColor;
  final Color secondColor;
  final Color accentColor;

  const ThemeSwatchTrio({
    super.key,
    required this.firstColor,
    required this.secondColor,
    required this.accentColor,
  });

  ThemeSwatchTrio.preset(AppThemePreset preset, {super.key})
    : firstColor = preset.previewLightBackground,
      secondColor = preset.previewDarkBackground,
      accentColor = preset.previewAccent;

  @override
  Widget build(BuildContext context) {
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
          Expanded(child: Container(color: firstColor)),
          Expanded(child: Container(color: secondColor)),
          Container(width: 8, color: accentColor),
        ],
      ),
    );
  }
}
