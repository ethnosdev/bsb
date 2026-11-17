import 'dart:convert';

import 'package:bsb/core/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('AppThemePreset Tests', () {
    test('contains all 7 curated presets in expected order', () {
      expect(AppThemePreset.all.length, equals(7));
      expect(AppThemePreset.all.first.id, equals('sepia'));
      final ids = AppThemePreset.all.map((p) => p.id).toList();
      expect(
        ids,
        equals([
          'sepia',
          'charcoal',
          'oled',
          'paper',
          'ocean',
          'stone',
          'purple',
        ]),
      );
    });

    test('findById returns correct preset or defaults to sepia', () {
      final sepia = AppThemePreset.findById('sepia');
      expect(sepia.name, equals('Sepia Parchment'));

      final unknown = AppThemePreset.findById('non_existent');
      expect(unknown.id, equals('sepia'));
    });

    test(
      'all presets have high contrast text in both light and dark modes',
      () {
        for (final preset in AppThemePreset.all) {
          final lightContrast = CustomThemeConfig.calculateContrastRatio(
            preset.lightScheme.onSurface,
            preset.lightScheme.surface,
          );
          expect(
            lightContrast,
            greaterThanOrEqualTo(4.5),
            reason:
                '${preset.name} light mode contrast too low ($lightContrast:1)',
          );

          final darkContrast = CustomThemeConfig.calculateContrastRatio(
            preset.darkScheme.onSurface,
            preset.darkScheme.surface,
          );
          expect(
            darkContrast,
            greaterThanOrEqualTo(4.5),
            reason:
                '${preset.name} dark mode contrast too low ($darkContrast:1)',
          );

          expect(preset.lightScheme.brightness, equals(Brightness.light));
          expect(preset.darkScheme.brightness, equals(Brightness.dark));
        }
      },
    );
  });

  group('CustomThemeConfig Tests', () {
    test('harmonizes dark text and high contrast for light backgrounds', () {
      final config = CustomThemeConfig.harmonizeFromBackground(
        const Color(0xFFFAF0E6),
      );

      expect(config.isDark, isFalse);
      expect(config.textColor.computeLuminance(), lessThan(0.2));
      expect(config.contrastRatio, greaterThanOrEqualTo(7.0));
      expect(
        CustomThemeConfig.calculateContrastRatio(
          config.primaryColor,
          config.backgroundColor,
        ),
        greaterThanOrEqualTo(3.0),
      );

      final scheme = config.toColorScheme();
      expect(scheme.brightness, equals(Brightness.light));
      expect(scheme.surface, equals(const Color(0xFFFAF0E6)));
      expect(scheme.onSurface, equals(config.textColor));
    });

    test('harmonizes light text and high contrast for dark backgrounds', () {
      final config = CustomThemeConfig.harmonizeFromBackground(
        const Color(0xFF121A14),
      );

      expect(config.isDark, isTrue);
      expect(config.textColor.computeLuminance(), greaterThan(0.6));
      expect(config.contrastRatio, greaterThanOrEqualTo(7.0));

      final scheme = config.toColorScheme();
      expect(scheme.brightness, equals(Brightness.dark));
      expect(scheme.surface, equals(const Color(0xFF121A14)));
      expect(scheme.onSurface, equals(config.textColor));
    });

    test('classifies mid-light backgrounds (~0.40 luminance) as light via WCAG crossover', () {
      // #AAAAAA has relative luminance ~0.401 (below old 0.45, above ~0.179)
      const midGray = Color(0xFFAAAAAA);
      final config = CustomThemeConfig.harmonizeFromBackground(midGray);
      expect(config.isDark, isFalse);
      expect(config.contrastRatio, greaterThanOrEqualTo(4.5));
    });

    test('computes dynamic onPrimaryContainer contrast for bright accents on dark bg', () {
      const config = CustomThemeConfig(
        backgroundColor: Color(0xFF121212),
        textColor: Color(0xFFE8E8EC),
        wordsOfJesusColor: Color(0xFFFF8A80),
        verseNumberColor: Color(0xFF9E9E9E),
        primaryColor: Color(0xFFFFFF00), // Bright yellow accent
      );

      final scheme = config.toColorScheme();
      final containerContrast = CustomThemeConfig.calculateContrastRatio(
        scheme.onPrimaryContainer,
        scheme.primaryContainer,
      );
      expect(containerContrast, greaterThanOrEqualTo(4.5));
    });

    test('serializes and deserializes 5 concrete colors correctly', () {
      const config = CustomThemeConfig(
        backgroundColor: Color(0xFFFFF0F5),
        textColor: Color(0xFF1A1A1A),
        wordsOfJesusColor: Color(0xFFE91E63),
        verseNumberColor: Color(0xFF6A1B9A),
        primaryColor: Color(0xFF880E4F),
      );

      final jsonStr = config.toJsonString();
      final restored = CustomThemeConfig.fromJsonString(jsonStr);

      expect(restored, equals(config));
      expect(restored.backgroundColor, equals(config.backgroundColor));
      expect(restored.textColor, equals(config.textColor));
      expect(restored.wordsOfJesusColor, equals(config.wordsOfJesusColor));
      expect(restored.verseNumberColor, equals(config.verseNumberColor));
      expect(restored.primaryColor, equals(config.primaryColor));
    });

    test('migrates legacy map with secondaryTextColor, null fields, and dropped keys', () {
      final legacyJson = jsonEncode({
        'backgroundColor': const Color(0xFF121A14).toARGB32(),
        'secondaryTextColor': const Color(0xFF80CBC4).toARGB32(),
        'surfaceContainerColor': const Color(0xFF222222).toARGB32(),
        'outlineColor': const Color(0xFF444444).toARGB32(),
        'isBackgroundAutoDerived': true,
      });

      final restored = CustomThemeConfig.fromJsonString(legacyJson);
      expect(restored.backgroundColor, equals(const Color(0xFF121A14)));
      expect(restored.verseNumberColor, equals(const Color(0xFF80CBC4)));
      expect(restored.contrastRatio, greaterThanOrEqualTo(4.5));
      expect(restored.toMap().containsKey('surfaceContainerColor'), isFalse);
      expect(restored.toMap().containsKey('outlineColor'), isFalse);
      expect(restored.toMap().containsKey('secondaryTextColor'), isFalse);
    });

    test('fromJsonString falls back to defaultConfig on malformed JSON', () {
      final restored = CustomThemeConfig.fromJsonString('{not valid json');
      expect(restored, equals(CustomThemeConfig.defaultConfig()));
    });

    test('fromPreset captures all 5 colors for light and dark variants', () {
      final preset = AppThemePreset.findById('stone');

      final light = CustomThemeConfig.fromPreset(preset, isDark: false);
      expect(light.backgroundColor, equals(preset.lightScheme.surface));
      expect(light.textColor, equals(preset.lightScheme.onSurface));
      expect(light.primaryColor, equals(preset.lightScheme.primary));
      expect(
        light.verseNumberColor,
        equals(preset.lightScheme.onSurfaceVariant),
      );
      expect(light.wordsOfJesusColor, equals(const Color(0xFFB71C1C)));

      final dark = CustomThemeConfig.fromPreset(preset, isDark: true);
      expect(dark.backgroundColor, equals(preset.darkScheme.surface));
      expect(dark.textColor, equals(preset.darkScheme.onSurface));
      expect(dark.primaryColor, equals(preset.darkScheme.primary));
      expect(dark.verseNumberColor, equals(preset.darkScheme.onSurfaceVariant));
      expect(dark.wordsOfJesusColor, equals(const Color(0xFFFF8A80)));
      expect(dark.basePresetId, equals('stone'));
      expect(dark.basePresetIsDark, isTrue);
    });

    test(
      'preserves Clean Paper exact ColorScheme tokens across serialization when only verseNumberColor changes',
      () {
        final paperPreset = AppThemePreset.findById('paper');
        final edited = CustomThemeConfig.fromPreset(
          paperPreset,
          isDark: false,
        ).copyWith(verseNumberColor: paperPreset.lightScheme.primary);

        final restored = CustomThemeConfig.fromJsonString(
          edited.toJsonString(),
        );
        expect(restored.basePresetId, equals('paper'));
        expect(restored.basePresetIsDark, isFalse);

        final scheme = restored.toColorScheme();
        expect(
          scheme.primaryContainer,
          equals(paperPreset.lightScheme.primaryContainer),
        );
        expect(
          scheme.onPrimaryContainer,
          equals(paperPreset.lightScheme.onPrimaryContainer),
        );
        expect(
          scheme.surfaceContainerHighest,
          equals(paperPreset.lightScheme.surfaceContainerHighest),
        );
        expect(
          scheme.onSurfaceVariant,
          equals(paperPreset.lightScheme.onSurfaceVariant),
        );

        // Editing primaryColor overrides chip container tokens while keeping surface tokens
        final customAccent = restored.copyWith(
          primaryColor: const Color(0xFF386646),
        );
        final accentScheme = customAccent.toColorScheme();
        expect(
          accentScheme.primaryContainer,
          isNot(equals(paperPreset.lightScheme.primaryContainer)),
        );
        expect(
          accentScheme.surfaceContainerHighest,
          equals(paperPreset.lightScheme.surfaceContainerHighest),
        );
      },
    );
  });
}
