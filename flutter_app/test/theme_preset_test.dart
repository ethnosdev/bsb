import 'package:bsb/core/app_theme_presets.dart';
import 'package:bsb/core/custom_theme_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppThemePreset Tests', () {
    test('contains all 7 curated presets with Sepia Parchment first', () {
      expect(AppThemePreset.all.length, equals(7));
      expect(AppThemePreset.all.first.id, equals('sepia'));
      final ids = AppThemePreset.all.map((p) => p.id).toList();
      expect(
        ids,
        containsAll([
          'sepia',
          'paper',
          'stone',
          'purple',
          'charcoal',
          'oled',
          'ocean',
        ]),
      );
    });

    test('findById returns correct preset or defaults to sepia', () {
      final sepia = AppThemePreset.findById('sepia');
      expect(sepia.name, equals('Sepia Parchment'));

      final unknown = AppThemePreset.findById('non_existent');
      expect(unknown.id, equals('sepia'));
    });

    test('all presets have high contrast text in both light and dark modes', () {
      for (final preset in AppThemePreset.all) {
        // Light mode contrast check (at least WCAG AA 4.5:1, typically AAA > 7:1)
        final lightContrast = CustomThemeConfig.calculateContrastRatio(
          preset.lightScheme.onSurface,
          preset.lightScheme.surface,
        );
        expect(
          lightContrast,
          greaterThanOrEqualTo(4.5),
          reason: '${preset.name} light mode contrast too low ($lightContrast:1)',
        );

        // Dark mode contrast check
        final darkContrast = CustomThemeConfig.calculateContrastRatio(
          preset.darkScheme.onSurface,
          preset.darkScheme.surface,
        );
        expect(
          darkContrast,
          greaterThanOrEqualTo(4.5),
          reason: '${preset.name} dark mode contrast too low ($darkContrast:1)',
        );

        // Verify brightness flags
        expect(preset.lightScheme.brightness, equals(Brightness.light));
        expect(preset.darkScheme.brightness, equals(Brightness.dark));
      }
    });
  });

  group('CustomThemeConfig Tests', () {
    test('auto-derives dark text and high contrast for light backgrounds', () {
      final config = const CustomThemeConfig(
        backgroundColor: Color(0xFFFAF0E6), // Linen / light cream
      );

      expect(config.isDark, isFalse);
      expect(config.effectiveTextColor.computeLuminance(), lessThan(0.2));
      expect(config.contrastRatio, greaterThanOrEqualTo(7.0));

      final scheme = config.toColorScheme();
      expect(scheme.brightness, equals(Brightness.light));
      expect(scheme.surface, equals(const Color(0xFFFAF0E6)));
      expect(scheme.onSurface, equals(config.effectiveTextColor));
    });

    test('auto-derives light text and high contrast for dark backgrounds', () {
      final config = const CustomThemeConfig(
        backgroundColor: Color(0xFF121A14), // Dark forest green
      );

      expect(config.isDark, isTrue);
      expect(config.effectiveTextColor.computeLuminance(), greaterThan(0.6));
      expect(config.contrastRatio, greaterThanOrEqualTo(7.0));

      final scheme = config.toColorScheme();
      expect(scheme.brightness, equals(Brightness.dark));
      expect(scheme.surface, equals(const Color(0xFF121A14)));
      expect(scheme.onSurface, equals(config.effectiveTextColor));
    });

    test('serializes and deserializes correctly', () {
      final config = const CustomThemeConfig(
        backgroundColor: Color(0xFFFFF0F5),
        textColor: Color(0xFF1A1A1A),
        primaryColor: Color(0xFF880E4F),
        surfaceContainerColor: Color(0xFFFCE4EC),
        secondaryTextColor: Color(0xFF6A1B9A),
        outlineColor: Color(0xFFBDBDBD),
      );

      final jsonStr = config.toJsonString();
      final restored = CustomThemeConfig.fromJsonString(
        jsonStr,
        isDarkFallback: false,
      );

      expect(restored, equals(config));
      expect(restored.backgroundColor, equals(config.backgroundColor));
      expect(restored.textColor, equals(config.textColor));
      expect(restored.primaryColor, equals(config.primaryColor));
      expect(restored.surfaceContainerColor, equals(config.surfaceContainerColor));
      expect(restored.secondaryTextColor, equals(config.secondaryTextColor));
      expect(restored.outlineColor, equals(config.outlineColor));
    });

    test('copyWith allows overriding and clearing individual color slots', () {
      final base = const CustomThemeConfig(
        backgroundColor: Color(0xFFFFFFFF),
        textColor: Color(0xFF000000),
      );

      final updated = base.copyWith(
        backgroundColor: const Color(0xFF000000),
        clearTextColor: true,
      );

      expect(updated.backgroundColor, equals(const Color(0xFF000000)));
      expect(updated.textColor, isNull);
      expect(updated.isDark, isTrue);
      // Effective text color should automatically flip to light
      expect(updated.effectiveTextColor.computeLuminance(), greaterThan(0.6));
    });
  });
}
