// ignore_for_file: use_full_hex_values_for_flutter_colors

import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4287123996),
      surfaceTint: Color(4287123996),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4294958273),
      onPrimaryContainer: Color(4281210112),
      secondary: Color(4285815107),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4294958273),
      onSecondaryContainer: Color(4280948487),
      tertiary: Color(4284178999),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4292929457),
      onTertiaryContainer: Color(4279836160),
      error: Color(4290386458),
      onError: Color(4294967295),
      errorContainer: Color(4294957782),
      onErrorContainer: Color(4282449922),
      surface: Color(4294965493),
      onSurface: Color(4280424980),
      onSurfaceVariant: Color(4283515963),
      outline: Color(4286805097),
      outlineVariant: Color(4292264886),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281806632),
      inversePrimary: Color(4294948730),
      primaryFixed: Color(4294958273),
      onPrimaryFixed: Color(4281210112),
      primaryFixedDim: Color(4294948730),
      onPrimaryFixedVariant: Color(4285217541),
      secondaryFixed: Color(4294958273),
      onSecondaryFixed: Color(4280948487),
      secondaryFixedDim: Color(4293116069),
      onSecondaryFixedVariant: Color(4284105262),
      tertiaryFixed: Color(4292929457),
      onTertiaryFixed: Color(4279836160),
      tertiaryFixedDim: Color(4291021719),
      onTertiaryFixedVariant: Color(4282599970),
      surfaceDim: Color(4293318605),
      surfaceBright: Color(4294965493),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294963688),
      surfaceContainer: Color(4294700001),
      surfaceContainerHigh: Color(4294305243),
      surfaceContainerHighest: Color(4293910742),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4284888833),
      surfaceTint: Color(4287123996),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4288833328),
      onPrimaryContainer: Color(4294967295),
      secondary: Color(4283842090),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4287328088),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4282336798),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4285626700),
      onTertiaryContainer: Color(4294967295),
      error: Color(4287365129),
      onError: Color(4294967295),
      errorContainer: Color(4292490286),
      onErrorContainer: Color(4294967295),
      surface: Color(4294965493),
      onSurface: Color(4280424980),
      onSurfaceVariant: Color(4283252791),
      outline: Color(4285226066),
      outlineVariant: Color(4287068269),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281806632),
      inversePrimary: Color(4294948730),
      primaryFixed: Color(4288833328),
      onPrimaryFixed: Color(4294967295),
      primaryFixedDim: Color(4286926618),
      onPrimaryFixedVariant: Color(4294967295),
      secondaryFixed: Color(4287328088),
      onSecondaryFixed: Color(4294967295),
      secondaryFixedDim: Color(4285617985),
      onSecondaryFixedVariant: Color(4294967295),
      tertiaryFixed: Color(4285626700),
      onTertiaryFixed: Color(4294967295),
      tertiaryFixedDim: Color(4284047413),
      onTertiaryFixedVariant: Color(4294967295),
      surfaceDim: Color(4293318605),
      surfaceBright: Color(4294965493),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294963688),
      surfaceContainer: Color(4294700001),
      surfaceContainerHigh: Color(4294305243),
      surfaceContainerHighest: Color(4293910742),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4281867008),
      surfaceTint: Color(4287123996),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4284888833),
      onPrimaryContainer: Color(4294967295),
      secondary: Color(4281409036),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4283842090),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4280231170),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4282336798),
      onTertiaryContainer: Color(4294967295),
      error: Color(4283301890),
      onError: Color(4294967295),
      errorContainer: Color(4287365129),
      onErrorContainer: Color(4294967295),
      surface: Color(4294965493),
      onSurface: Color(4278190080),
      onSurfaceVariant: Color(4281082393),
      outline: Color(4283252791),
      outlineVariant: Color(4283252791),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281806632),
      inversePrimary: Color(4294961368),
      primaryFixed: Color(4284888833),
      onPrimaryFixed: Color(4294967295),
      primaryFixedDim: Color(4282852352),
      onPrimaryFixedVariant: Color(4294967295),
      secondaryFixed: Color(4283842090),
      onSecondaryFixed: Color(4294967295),
      secondaryFixedDim: Color(4282198038),
      onSecondaryFixedVariant: Color(4294967295),
      tertiaryFixed: Color(4282336798),
      onTertiaryFixed: Color(4294967295),
      tertiaryFixedDim: Color(4280889354),
      onTertiaryFixedVariant: Color(4294967295),
      surfaceDim: Color(4293318605),
      surfaceBright: Color(4294965493),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294963688),
      surfaceContainer: Color(4294700001),
      surfaceContainerHigh: Color(4294305243),
      surfaceContainerHighest: Color(4293910742),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4294948730),
      surfaceTint: Color(4294948730),
      onPrimary: Color(4283180800),
      primaryContainer: Color(4285217541),
      onPrimaryContainer: Color(4294958273),
      secondary: Color(4293116069),
      onSecondary: Color(4282461209),
      secondaryContainer: Color(4284105262),
      onSecondaryContainer: Color(4294958273),
      tertiary: Color(4291021719),
      onTertiary: Color(4281152270),
      tertiaryContainer: Color(4282599970),
      onTertiaryContainer: Color(4292929457),
      error: Color(4294948011),
      onError: Color(4285071365),
      errorContainer: Color(4287823882),
      onErrorContainer: Color(4294957782),
      surface: Color(4279833100),
      onSurface: Color(4293910742),
      onSurfaceVariant: Color(4292264886),
      outline: Color(4288581250),
      outlineVariant: Color(4283515963),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4293910742),
      inversePrimary: Color(4287123996),
      primaryFixed: Color(4294958273),
      onPrimaryFixed: Color(4281210112),
      primaryFixedDim: Color(4294948730),
      onPrimaryFixedVariant: Color(4285217541),
      secondaryFixed: Color(4294958273),
      onSecondaryFixed: Color(4280948487),
      secondaryFixedDim: Color(4293116069),
      onSecondaryFixedVariant: Color(4284105262),
      tertiaryFixed: Color(4292929457),
      onTertiaryFixed: Color(4279836160),
      tertiaryFixedDim: Color(4291021719),
      onTertiaryFixedVariant: Color(4282599970),
      surfaceDim: Color(4279833100),
      surfaceBright: Color(4282464049),
      surfaceContainerLowest: Color(4279504136),
      surfaceContainerLow: Color(4280424980),
      surfaceContainer: Color(4280688152),
      surfaceContainerHigh: Color(4281411618),
      surfaceContainerHighest: Color(4282135340),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4294950277),
      surfaceTint: Color(4294948730),
      onPrimary: Color(4280684800),
      primaryContainer: Color(4290937673),
      onPrimaryContainer: Color(4278190080),
      secondary: Color(4293379241),
      onSecondary: Color(4280553987),
      secondaryContainer: Color(4289366898),
      onSecondaryContainer: Color(4278190080),
      tertiary: Color(4291350427),
      onTertiary: Color(4279506944),
      tertiaryContainer: Color(4287468901),
      onTertiaryContainer: Color(4278190080),
      error: Color(4294949553),
      onError: Color(4281794561),
      errorContainer: Color(4294923337),
      onErrorContainer: Color(4278190080),
      surface: Color(4279833100),
      onSurface: Color(4294966008),
      onSurfaceVariant: Color(4292528058),
      outline: Color(4289831059),
      outlineVariant: Color(4287660149),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4293910742),
      inversePrimary: Color(4285348870),
      primaryFixed: Color(4294958273),
      onPrimaryFixed: Color(4280224768),
      primaryFixedDim: Color(4294948730),
      onPrimaryFixedVariant: Color(4283706368),
      secondaryFixed: Color(4294958273),
      onSecondaryFixed: Color(4280159489),
      secondaryFixedDim: Color(4293116069),
      onSecondaryFixedVariant: Color(4282921246),
      tertiaryFixed: Color(4292929457),
      onTertiaryFixed: Color(4279177984),
      tertiaryFixedDim: Color(4291021719),
      onTertiaryFixedVariant: Color(4281547027),
      surfaceDim: Color(4279833100),
      surfaceBright: Color(4282464049),
      surfaceContainerLowest: Color(4279504136),
      surfaceContainerLow: Color(4280424980),
      surfaceContainer: Color(4280688152),
      surfaceContainerHigh: Color(4281411618),
      surfaceContainerHighest: Color(4282135340),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4294966008),
      surfaceTint: Color(4294948730),
      onPrimary: Color(4278190080),
      primaryContainer: Color(4294950277),
      onPrimaryContainer: Color(4278190080),
      secondary: Color(4294966008),
      onSecondary: Color(4278190080),
      secondaryContainer: Color(4293379241),
      onSecondaryContainer: Color(4278190080),
      tertiary: Color(4294574031),
      onTertiary: Color(4278190080),
      tertiaryContainer: Color(4291350427),
      onTertiaryContainer: Color(4278190080),
      error: Color(4294965753),
      onError: Color(4278190080),
      errorContainer: Color(4294949553),
      onErrorContainer: Color(4278190080),
      surface: Color(4279833100),
      onSurface: Color(4294967295),
      onSurfaceVariant: Color(4294966008),
      outline: Color(4292528058),
      outlineVariant: Color(4292528058),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4293910742),
      inversePrimary: Color(4282589696),
      primaryFixed: Color(4294959564),
      onPrimaryFixed: Color(4278190080),
      primaryFixedDim: Color(4294950277),
      onPrimaryFixedVariant: Color(4280684800),
      secondaryFixed: Color(4294959564),
      onSecondaryFixed: Color(4278190080),
      secondaryFixedDim: Color(4293379241),
      onSecondaryFixedVariant: Color(4280553987),
      tertiaryFixed: Color(4293192885),
      onTertiaryFixed: Color(4278190080),
      tertiaryFixedDim: Color(4291350427),
      onTertiaryFixedVariant: Color(4279506944),
      surfaceDim: Color(4279833100),
      surfaceBright: Color(4282464049),
      surfaceContainerLowest: Color(4279504136),
      surfaceContainerLow: Color(4280424980),
      surfaceContainer: Color(4280688152),
      surfaceContainerHigh: Color(4281411618),
      surfaceContainerHighest: Color(4282135340),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        textTheme: textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        scaffoldBackgroundColor: colorScheme.surface,
        canvasColor: colorScheme.surface,
      );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
