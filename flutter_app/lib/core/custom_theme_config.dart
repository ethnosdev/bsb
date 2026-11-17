import 'dart:convert';

import 'package:bsb/core/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Configuration for a single-palette custom user-defined theme.
class CustomThemeConfig {
  final Color backgroundColor;
  final Color textColor;
  final Color wordsOfJesusColor;
  final Color verseNumberColor;
  final Color primaryColor;
  final String? basePresetId;
  final bool? basePresetIsDark;

  const CustomThemeConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.wordsOfJesusColor,
    required this.verseNumberColor,
    required this.primaryColor,
    this.basePresetId,
    this.basePresetIsDark,
  });

  /// Default custom theme seeded from the default reading preset.
  factory CustomThemeConfig.defaultConfig() {
    return CustomThemeConfig.fromPreset(
      AppThemePreset.findById(AppThemePreset.defaultPresetId),
      isDark: false,
    );
  }

  /// Creates a custom theme config initialized from a Material [ColorScheme].
  factory CustomThemeConfig.fromColorScheme(
    ColorScheme scheme, {
    Color? wordsOfJesusColor,
    String? basePresetId,
    bool? basePresetIsDark,
  }) {
    return CustomThemeConfig(
      backgroundColor: scheme.surface,
      textColor: scheme.onSurface,
      wordsOfJesusColor:
          wordsOfJesusColor ??
          ScriptureTheme.defaultWordsOfJesusColor(scheme.brightness),
      verseNumberColor: scheme.onSurfaceVariant,
      primaryColor: scheme.primary,
      basePresetId: basePresetId,
      basePresetIsDark: basePresetIsDark,
    );
  }

  /// Creates a custom theme config initialized from a [preset] in Light or Dark mode.
  factory CustomThemeConfig.fromPreset(
    AppThemePreset preset, {
    required bool isDark,
  }) {
    final scheme = isDark ? preset.darkScheme : preset.lightScheme;
    return CustomThemeConfig.fromColorScheme(
      scheme,
      basePresetId: preset.id,
      basePresetIsDark: isDark,
    );
  }

  /// Whether this theme represents a dark palette based on Flutter's brightness estimate.
  bool get isDark =>
      ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark;

  /// Generates a complete, high-contrast palette harmonized from [bg].
  static CustomThemeConfig harmonizeFromBackground(Color bg) {
    final dark = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark;

    Color text = Color.lerp(
      dark ? const Color(0xFFE8E8EC) : const Color(0xFF1B1B1F),
      bg,
      0.05,
    )!;
    if (calculateContrastRatio(text, bg) < 4.5) {
      final whiteContrast = calculateContrastRatio(Colors.white, bg);
      final blackContrast = calculateContrastRatio(Colors.black, bg);
      text = whiteContrast >= blackContrast ? Colors.white : Colors.black;
    }

    Color wordsOfJesus = ScriptureTheme.defaultWordsOfJesusColor(
      dark ? Brightness.dark : Brightness.light,
    );
    if (calculateContrastRatio(wordsOfJesus, bg) < 3.0) {
      final target = dark ? Colors.white : Colors.black;
      for (int i = 1; i <= 10; i++) {
        final candidate = Color.lerp(wordsOfJesus, target, i * 0.1)!;
        if (calculateContrastRatio(candidate, bg) >= 3.5) {
          wordsOfJesus = candidate;
          break;
        }
      }
    }

    final verseNumber = Color.lerp(text, bg, 0.38)!;

    final (lightAccent, darkAccent) = _deriveAccentPair(HSVColor.fromColor(bg));
    Color accent = dark ? darkAccent : lightAccent;
    if (calculateContrastRatio(accent, bg) < 3.0) {
      final target = dark ? Colors.white : Colors.black;
      for (int i = 1; i <= 10; i++) {
        final candidate = Color.lerp(accent, target, i * 0.1)!;
        if (calculateContrastRatio(candidate, bg) >= 3.0) {
          accent = candidate;
          break;
        }
      }
    }

    return CustomThemeConfig(
      backgroundColor: bg,
      textColor: text,
      wordsOfJesusColor: wordsOfJesus,
      verseNumberColor: verseNumber,
      primaryColor: accent,
    );
  }

  static (Color light, Color dark) _deriveAccentPair(HSVColor hsv) {
    if (hsv.saturation < 0.05) {
      return (const Color(0xFF1A5A96), const Color(0xFFE5B869));
    }

    final hue = hsv.hue;
    if (hue >= 15 && hue < 70) {
      return (const Color(0xFF865328), const Color(0xFFFFB68C));
    }
    if (hue >= 70 && hue < 165) {
      return (const Color(0xFF386646), const Color(0xFF9FD0AA));
    }
    if (hue >= 165 && hue < 255) {
      return (const Color(0xFF1A5A96), const Color(0xFF88C9FA));
    }
    if (hue >= 255 && hue < 330) {
      return (const Color(0xFF6B5778), const Color(0xFFD6BEE4));
    }
    return (const Color(0xFF8D3C3C), const Color(0xFFFF9E9E));
  }

  /// Contrast ratio between [textColor] and [backgroundColor] using W3C WCAG formula.
  double get contrastRatio =>
      calculateContrastRatio(textColor, backgroundColor);

  /// Calculates the W3C WCAG 2.1 contrast ratio between two colors (1.0 to 21.0).
  static double calculateContrastRatio(Color c1, Color c2) {
    final l1 = c1.computeLuminance();
    final l2 = c2.computeLuminance();
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Converts this configuration to a complete Material 3 [ColorScheme].
  ///
  /// When [basePresetId] matches a preset of the same brightness, its full
  /// tonal palette is preserved and only groups whose source slot changed are
  /// overridden.
  ColorScheme toColorScheme() {
    final derived = _buildDerivedColorScheme();
    if (basePresetId == null) return derived;

    final preset = AppThemePreset.all
        .where((p) => p.id == basePresetId)
        .firstOrNull;
    if (preset == null) return derived;

    final baseScheme = (basePresetIsDark ?? isDark)
        ? preset.darkScheme
        : preset.lightScheme;
    if (isDark != (baseScheme.brightness == Brightness.dark)) {
      return derived;
    }

    final bgChanged =
        backgroundColor.toARGB32() != baseScheme.surface.toARGB32();
    final textChanged = textColor.toARGB32() != baseScheme.onSurface.toARGB32();
    final primaryChanged =
        primaryColor.toARGB32() != baseScheme.primary.toARGB32();

    return baseScheme.copyWith(
      primary: primaryChanged ? derived.primary : null,
      surfaceTint: primaryChanged ? derived.surfaceTint : null,
      onPrimary: primaryChanged ? derived.onPrimary : null,
      primaryContainer: primaryChanged ? derived.primaryContainer : null,
      onPrimaryContainer: primaryChanged ? derived.onPrimaryContainer : null,
      secondary: primaryChanged ? derived.secondary : null,
      onSecondary: primaryChanged ? derived.onSecondary : null,
      tertiary: primaryChanged ? derived.tertiary : null,
      onTertiary: primaryChanged ? derived.onTertiary : null,
      inversePrimary: primaryChanged ? derived.inversePrimary : null,
      surface: bgChanged ? derived.surface : null,
      surfaceDim: bgChanged ? derived.surfaceDim : null,
      surfaceBright: bgChanged ? derived.surfaceBright : null,
      surfaceContainerLowest: bgChanged ? derived.surfaceContainerLowest : null,
      surfaceContainerLow: bgChanged ? derived.surfaceContainerLow : null,
      surfaceContainer: bgChanged ? derived.surfaceContainer : null,
      surfaceContainerHigh: bgChanged ? derived.surfaceContainerHigh : null,
      surfaceContainerHighest: bgChanged
          ? derived.surfaceContainerHighest
          : null,
      secondaryContainer: bgChanged ? derived.secondaryContainer : null,
      tertiaryContainer: bgChanged ? derived.tertiaryContainer : null,
      outline: bgChanged ? derived.outline : null,
      outlineVariant: bgChanged ? derived.outlineVariant : null,
      onSurface: textChanged ? derived.onSurface : null,
      inverseSurface: textChanged ? derived.inverseSurface : null,
      onSecondaryContainer: textChanged ? derived.onSecondaryContainer : null,
      onTertiaryContainer: textChanged ? derived.onTertiaryContainer : null,
      onSurfaceVariant: (bgChanged || textChanged)
          ? derived.onSurfaceVariant
          : null,
    );
  }

  ColorScheme _buildDerivedColorScheme() {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final primary = primaryColor;
    final onPrimary =
        ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final surface = backgroundColor;
    final onSurface = textColor;

    Color onSurfaceVariant = Color.lerp(onSurface, surface, 0.30)!;
    if (calculateContrastRatio(onSurfaceVariant, surface) < 3.0) {
      onSurfaceVariant = onSurface;
    }

    final surfaceContainer = isDark
        ? Color.lerp(surface, Colors.white, 0.12)!
        : Color.lerp(surface, Colors.black, 0.08)!;
    final outline = isDark
        ? Color.lerp(surface, Colors.white, 0.18)!
        : Color.lerp(surface, Colors.black, 0.15)!;
    final primaryContainer = isDark
        ? Color.lerp(surface, primary, 0.35)!
        : Color.lerp(surface, primary, 0.15)!;
    final onPrimaryContainer =
        ThemeData.estimateBrightnessForColor(primaryContainer) ==
            Brightness.dark
        ? Colors.white
        : Colors.black;
    final inversePrimary = isDark
        ? Color.lerp(primary, Colors.black, 0.4)!
        : Color.lerp(primary, Colors.white, 0.4)!;

    return ColorScheme(
      brightness: brightness,
      primary: primary,
      surfaceTint: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: primary,
      onSecondary: onPrimary,
      secondaryContainer: surfaceContainer,
      onSecondaryContainer: onSurface,
      tertiary: primary,
      onTertiary: onPrimary,
      tertiaryContainer: surfaceContainer,
      onTertiaryContainer: onSurface,
      error: isDark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A),
      onError: isDark ? const Color(0xFF690005) : Colors.white,
      errorContainer: isDark
          ? const Color(0xFF93000A)
          : const Color(0xFFFFDAD6),
      onErrorContainer: isDark
          ? const Color(0xFFFFDAD6)
          : const Color(0xFF410002),
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: Color.lerp(surface, outline, 0.5)!,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: onSurface,
      inversePrimary: inversePrimary,
      surfaceDim: isDark
          ? Color.lerp(surface, Colors.black, 0.1)!
          : Color.lerp(surface, Colors.black, 0.03)!,
      surfaceBright: isDark
          ? Color.lerp(surface, Colors.white, 0.05)!
          : surface,
      surfaceContainerLowest: isDark
          ? Color.lerp(surface, Colors.black, 0.3)!
          : Colors.white,
      surfaceContainerLow: isDark
          ? Color.lerp(surface, Colors.white, 0.03)!
          : Color.lerp(surface, Colors.black, 0.02)!,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: isDark
          ? Color.lerp(surface, Colors.white, 0.12)!
          : Color.lerp(surface, Colors.black, 0.08)!,
      surfaceContainerHighest: isDark
          ? Color.lerp(surface, Colors.white, 0.16)!
          : Color.lerp(surface, Colors.black, 0.12)!,
    );
  }

  CustomThemeConfig copyWith({
    Color? backgroundColor,
    Color? textColor,
    Color? wordsOfJesusColor,
    Color? verseNumberColor,
    Color? primaryColor,
    String? basePresetId,
    bool? basePresetIsDark,
    bool clearBasePreset = false,
  }) {
    return CustomThemeConfig(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      wordsOfJesusColor: wordsOfJesusColor ?? this.wordsOfJesusColor,
      verseNumberColor: verseNumberColor ?? this.verseNumberColor,
      primaryColor: primaryColor ?? this.primaryColor,
      basePresetId: clearBasePreset ? null : (basePresetId ?? this.basePresetId),
      basePresetIsDark: clearBasePreset
          ? null
          : (basePresetIsDark ?? this.basePresetIsDark),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': backgroundColor.toARGB32(),
      'textColor': textColor.toARGB32(),
      'wordsOfJesusColor': wordsOfJesusColor.toARGB32(),
      'verseNumberColor': verseNumberColor.toARGB32(),
      'primaryColor': primaryColor.toARGB32(),
      if (basePresetId != null) 'basePresetId': basePresetId,
      if (basePresetIsDark != null) 'basePresetIsDark': basePresetIsDark,
    };
  }

  String toJsonString() => jsonEncode(toMap());

  factory CustomThemeConfig.fromMap(Map<String, dynamic> map) {
    final bg = Color(map['backgroundColor'] as int);
    final fallback = CustomThemeConfig.harmonizeFromBackground(bg);

    final text = map['textColor'] != null
        ? Color(map['textColor'] as int)
        : fallback.textColor;
    final wordsOfJesus = map['wordsOfJesusColor'] != null
        ? Color(map['wordsOfJesusColor'] as int)
        : fallback.wordsOfJesusColor;
    final verseNumberRaw = map['verseNumberColor'] ?? map['secondaryTextColor'];
    final verseNumber = verseNumberRaw != null
        ? Color(verseNumberRaw as int)
        : Color.lerp(text, bg, 0.38)!;
    final primary = map['primaryColor'] != null
        ? Color(map['primaryColor'] as int)
        : fallback.primaryColor;

    return CustomThemeConfig(
      backgroundColor: bg,
      textColor: text,
      wordsOfJesusColor: wordsOfJesus,
      verseNumberColor: verseNumber,
      primaryColor: primary,
      basePresetId: map['basePresetId'] as String?,
      basePresetIsDark: map['basePresetIsDark'] as bool?,
    );
  }

  factory CustomThemeConfig.fromJsonString(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return CustomThemeConfig.fromMap(map);
    } catch (_) {
      return CustomThemeConfig.defaultConfig();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomThemeConfig &&
          runtimeType == other.runtimeType &&
          backgroundColor.toARGB32() == other.backgroundColor.toARGB32() &&
          textColor.toARGB32() == other.textColor.toARGB32() &&
          wordsOfJesusColor.toARGB32() == other.wordsOfJesusColor.toARGB32() &&
          verseNumberColor.toARGB32() == other.verseNumberColor.toARGB32() &&
          primaryColor.toARGB32() == other.primaryColor.toARGB32() &&
          basePresetId == other.basePresetId &&
          basePresetIsDark == other.basePresetIsDark;

  @override
  int get hashCode => Object.hash(
    backgroundColor.toARGB32(),
    textColor.toARGB32(),
    wordsOfJesusColor.toARGB32(),
    verseNumberColor.toARGB32(),
    primaryColor.toARGB32(),
    basePresetId,
    basePresetIsDark,
  );
}
