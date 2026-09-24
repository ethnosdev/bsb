import 'dart:convert';
import 'package:flutter/material.dart';

/// Configuration for a custom user-defined theme.
///
/// If only [backgroundColor] is specified, all other colors are automatically
/// derived with high-contrast, harmonious values to ensure readability.
class CustomThemeConfig {
  final Color backgroundColor;
  final Color? textColor;
  final Color? primaryColor;
  final Color? surfaceContainerColor;
  final Color? secondaryTextColor;
  final Color? outlineColor;
  final bool isBackgroundAutoDerived;

  const CustomThemeConfig({
    required this.backgroundColor,
    this.textColor,
    this.primaryColor,
    this.surfaceContainerColor,
    this.secondaryTextColor,
    this.outlineColor,
    this.isBackgroundAutoDerived = false,
  });

  /// Default light custom theme.
  factory CustomThemeConfig.defaultLight() {
    return const CustomThemeConfig(
      backgroundColor: Color(0xFFF7F1E5),
      isBackgroundAutoDerived: false,
    );
  }

  /// Default dark custom theme.
  factory CustomThemeConfig.defaultDark() {
    return const CustomThemeConfig(
      backgroundColor: Color(0xFF1E1813),
      isBackgroundAutoDerived: true,
    );
  }

  /// Whether this theme represents a dark palette based on background luminance.
  bool get isDark => backgroundColor.computeLuminance() <= 0.45;

  /// Harmonizes both Light and Dark custom theme configurations from a chosen background color.
  /// Selects a tasteful, high-contrast accent color matching the background temperature.
  static (CustomThemeConfig light, CustomThemeConfig dark)
      harmonizeFromBackground(Color bg) {
    final isDark = bg.computeLuminance() <= 0.45;

    if (isDark) {
      final darkConfig = CustomThemeConfig(
        backgroundColor: bg,
        isBackgroundAutoDerived: false,
      );
      // Derive inverted light background carrying the same hue/temperature
      final lightBg = Color.lerp(bg, Colors.white, 0.93)!;
      final lightConfig = CustomThemeConfig(
        backgroundColor: lightBg,
        isBackgroundAutoDerived: true,
      );
      return (lightConfig, darkConfig);
    } else {
      final lightConfig = CustomThemeConfig(
        backgroundColor: bg,
        isBackgroundAutoDerived: false,
      );
      // Derive inverted dark background carrying the same hue/temperature
      final darkBg = Color.lerp(bg, Colors.black, 0.88)!;
      final darkConfig = CustomThemeConfig(
        backgroundColor: darkBg,
        isBackgroundAutoDerived: true,
      );
      return (lightConfig, darkConfig);
    }
  }

  static (Color light, Color dark) _deriveAccentPair(HSVColor hsv) {
    // If neutral / low saturation (grayscale / pure paper tone)
    if (hsv.saturation < 0.05) {
      return (const Color(0xFF1A5A96), const Color(0xFFE5B869)); // Navy & Candle Gold
    }

    final hue = hsv.hue;
    // Warm / Sepia / Orange / Yellow (15° to 70°)
    if (hue >= 15 && hue < 70) {
      return (const Color(0xFF865328), const Color(0xFFFFB68C)); // Terracotta & Peach Gold
    }
    // Green / Sage (70° to 165°)
    if (hue >= 70 && hue < 165) {
      return (const Color(0xFF386646), const Color(0xFF9FD0AA)); // Forest & Mint Sage
    }
    // Blue / Cyan / Teal (165° to 255°)
    if (hue >= 165 && hue < 255) {
      return (const Color(0xFF1A5A96), const Color(0xFF88C9FA)); // Navy & Sky Cyan
    }
    // Purple / Violet (255° to 330°)
    if (hue >= 255 && hue < 330) {
      return (const Color(0xFF6B5778), const Color(0xFFD6BEE4)); // Royal Plum & Lavender
    }
    // Red / Crimson (330° to 360° or 0° to 15°)
    return (const Color(0xFF8D3C3C), const Color(0xFFFF9E9E)); // Burgundy & Coral Rose
  }

  /// Effective text color, derived if not explicitly customized.
  Color get effectiveTextColor {
    if (textColor != null) return textColor!;
    return isDark
        ? Color.lerp(const Color(0xFFE8E8EC), backgroundColor, 0.05)!
        : Color.lerp(const Color(0xFF1B1B1F), backgroundColor, 0.05)!;
  }

  /// Effective primary accent color, derived if not explicitly customized.
  Color get effectivePrimaryColor {
    if (primaryColor != null) return primaryColor!;
    final (lightAccent, darkAccent) =
        _deriveAccentPair(HSVColor.fromColor(backgroundColor));
    return isDark ? darkAccent : lightAccent;
  }

  /// Effective card and container surface color.
  Color get effectiveSurfaceContainer {
    if (surfaceContainerColor != null) return surfaceContainerColor!;
    return isDark
        ? Color.lerp(backgroundColor, Colors.white, 0.12)!
        : Color.lerp(backgroundColor, Colors.black, 0.08)!;
  }

  /// Effective secondary text color (e.g. verse numbers and section subtitles).
  Color get effectiveSecondaryTextColor {
    if (secondaryTextColor != null) return secondaryTextColor!;
    return Color.lerp(effectiveTextColor, backgroundColor, 0.38)!;
  }

  /// Effective outline and divider color.
  Color get effectiveOutline {
    if (outlineColor != null) return outlineColor!;
    return isDark
        ? Color.lerp(backgroundColor, Colors.white, 0.18)!
        : Color.lerp(backgroundColor, Colors.black, 0.15)!;
  }

  /// Contrast ratio between effective text and background using W3C WCAG formula.
  double get contrastRatio =>
      calculateContrastRatio(effectiveTextColor, backgroundColor);

  /// Calculates the W3C WCAG 2.1 contrast ratio between two colors (1.0 to 21.0).
  static double calculateContrastRatio(Color c1, Color c2) {
    final l1 = c1.computeLuminance();
    final l2 = c2.computeLuminance();
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Converts this configuration to a complete Material 3 [ColorScheme].
  ColorScheme toColorScheme() {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final primary = effectivePrimaryColor;
    final onPrimary =
        primary.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final surface = backgroundColor;
    final onSurface = effectiveTextColor;
    final onSurfaceVariant = effectiveSecondaryTextColor;
    final surfaceContainer = effectiveSurfaceContainer;
    final outline = effectiveOutline;

    return ColorScheme(
      brightness: brightness,
      primary: primary,
      surfaceTint: primary,
      onPrimary: onPrimary,
      primaryContainer: isDark
          ? Color.lerp(surface, primary, 0.35)!
          : Color.lerp(surface, primary, 0.15)!,
      onPrimaryContainer:
          isDark ? const Color(0xFFFFF0E6) : const Color(0xFF2E1500),
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
      errorContainer:
          isDark ? const Color(0xFF93000A) : const Color(0xFFFFDAD6),
      onErrorContainer:
          isDark ? const Color(0xFFFFDAD6) : const Color(0xFF410002),
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: Color.lerp(surface, outline, 0.5)!,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: onSurface,
      inversePrimary:
          isDark ? const Color(0xFF88521C) : const Color(0xFFFFB67A),
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
    bool clearTextColor = false,
    Color? primaryColor,
    bool clearPrimaryColor = false,
    Color? surfaceContainerColor,
    bool clearSurfaceContainerColor = false,
    Color? secondaryTextColor,
    bool clearSecondaryTextColor = false,
    Color? outlineColor,
    bool clearOutlineColor = false,
    bool? isBackgroundAutoDerived,
  }) {
    return CustomThemeConfig(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: clearTextColor ? null : (textColor ?? this.textColor),
      primaryColor:
          clearPrimaryColor ? null : (primaryColor ?? this.primaryColor),
      surfaceContainerColor: clearSurfaceContainerColor
          ? null
          : (surfaceContainerColor ?? this.surfaceContainerColor),
      secondaryTextColor: clearSecondaryTextColor
          ? null
          : (secondaryTextColor ?? this.secondaryTextColor),
      outlineColor:
          clearOutlineColor ? null : (outlineColor ?? this.outlineColor),
      isBackgroundAutoDerived:
          isBackgroundAutoDerived ?? this.isBackgroundAutoDerived,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': backgroundColor.toARGB32(),
      if (textColor != null) 'textColor': textColor!.toARGB32(),
      if (primaryColor != null) 'primaryColor': primaryColor!.toARGB32(),
      if (surfaceContainerColor != null)
        'surfaceContainerColor': surfaceContainerColor!.toARGB32(),
      if (secondaryTextColor != null)
        'secondaryTextColor': secondaryTextColor!.toARGB32(),
      if (outlineColor != null) 'outlineColor': outlineColor!.toARGB32(),
      if (isBackgroundAutoDerived) 'isBackgroundAutoDerived': true,
    };
  }

  String toJsonString() => jsonEncode(toMap());

  factory CustomThemeConfig.fromMap(Map<String, dynamic> map) {
    return CustomThemeConfig(
      backgroundColor: Color(map['backgroundColor'] as int),
      textColor:
          map['textColor'] != null ? Color(map['textColor'] as int) : null,
      primaryColor: map['primaryColor'] != null
          ? Color(map['primaryColor'] as int)
          : null,
      surfaceContainerColor: map['surfaceContainerColor'] != null
          ? Color(map['surfaceContainerColor'] as int)
          : null,
      secondaryTextColor: map['secondaryTextColor'] != null
          ? Color(map['secondaryTextColor'] as int)
          : null,
      outlineColor: map['outlineColor'] != null
          ? Color(map['outlineColor'] as int)
          : null,
      isBackgroundAutoDerived: map['isBackgroundAutoDerived'] as bool? ?? false,
    );
  }

  factory CustomThemeConfig.fromJsonString(
    String jsonStr, {
    required bool isDarkFallback,
  }) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return CustomThemeConfig.fromMap(map);
    } catch (_) {
      return isDarkFallback
          ? CustomThemeConfig.defaultDark()
          : CustomThemeConfig.defaultLight();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomThemeConfig &&
          runtimeType == other.runtimeType &&
          backgroundColor.toARGB32() == other.backgroundColor.toARGB32() &&
          textColor?.toARGB32() == other.textColor?.toARGB32() &&
          primaryColor?.toARGB32() == other.primaryColor?.toARGB32() &&
          surfaceContainerColor?.toARGB32() ==
              other.surfaceContainerColor?.toARGB32() &&
          secondaryTextColor?.toARGB32() ==
              other.secondaryTextColor?.toARGB32() &&
          outlineColor?.toARGB32() == other.outlineColor?.toARGB32() &&
          isBackgroundAutoDerived == other.isBackgroundAutoDerived;

  @override
  int get hashCode => Object.hash(
        backgroundColor.toARGB32(),
        textColor?.toARGB32(),
        primaryColor?.toARGB32(),
        surfaceContainerColor?.toARGB32(),
        secondaryTextColor?.toARGB32(),
        outlineColor?.toARGB32(),
        isBackgroundAutoDerived,
      );
}
