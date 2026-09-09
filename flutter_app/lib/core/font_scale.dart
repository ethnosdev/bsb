import 'package:database_builder/database_builder.dart';

/// Centralized typographic scalers relative to the user's base text size.
abstract final class FontScale {
  static const double minBaseSize = 8.0;
  static const double maxBaseSize = 30.0;
  static const double defaultBaseSize = 20.0;

  /// Clamps a base text size to valid user-setting bounds.
  static double clampBase(double size) => size.clamp(minBaseSize, maxBaseSize);

  /// Scripture body text (1.0x).
  static double scripture(double base) => base;

  /// English passage chip words (0.9x, default: 18.0 at base 20.0).
  static double englishPassage(double base) => (base * 0.9).roundToDouble();

  /// English passage fallback text (0.85x, default: 17.0 at base 20.0).
  static double englishFallback(double base) => (base * 0.85).roundToDouble();

  /// Original language passage words (1.2x for Hebrew/Aramaic = 24.0; 1.1x for Greek = 22.0).
  static double originalPassage(double base, Language language) {
    final factor = (language == Language.greek) ? 1.1 : 1.2;
    return (base * factor).roundToDouble();
  }

  /// Hebrew/Greek screen hero word (2.1x, clamped between 24 and 64).
  static double heroWord(double base) => (base * 2.1).clamp(24.0, 64.0);

  /// Lexicon Markdown body text (0.75x, clamped between 12 and 26).
  static double lexiconBody(double base) => (base * 0.75).clamp(12.0, 26.0);

  /// Reference modal sheet headword (1.6x, clamped between 20 and 48).
  static double sheetHeadword(double base) => (base * 1.6).clamp(20.0, 48.0);

  /// Reference modal root lemma (1.1x, default: 22.0).
  static double sheetRootLemma(double base) => (base * 1.1).roundToDouble();

  /// Similar verses English text snippets.
  static double similarEnglish(double base) => (base * 0.75).clamp(12.0, 26.0);

  /// Similar verses original language text snippets (0.9x for Hebrew, 0.8x for Greek).
  static double similarOriginal(double base, Language language) {
    final factor = (language == Language.greek) ? 0.8 : 0.9;
    return (base * factor).clamp(12.0, 30.0);
  }

  /// Informational page header (1.2x).
  static double infoTitle(double base) => base * 1.2;

  /// Informational page paragraph spacing (0.6x).
  static double infoSpacing(double base) => base * 0.6;
}
