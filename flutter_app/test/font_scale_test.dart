import 'package:bsb/core/font_scale.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FontScale', () {
    test('clampBase restricts base size to [minBaseSize, maxBaseSize]', () {
      expect(FontScale.clampBase(20.0), equals(20.0));
      expect(FontScale.clampBase(5.0), equals(8.0));
      expect(FontScale.clampBase(35.0), equals(30.0));
      expect(FontScale.clampBase(-1.0), equals(8.0));
      expect(FontScale.clampBase(8.0), equals(8.0));
      expect(FontScale.clampBase(30.0), equals(30.0));
    });

    test('scripture matches base text size', () {
      expect(FontScale.scripture(20.0), equals(20.0));
      expect(FontScale.scripture(14.0), equals(14.0));
      expect(FontScale.scripture(28.0), equals(28.0));
    });

    test('englishPassage scales and rounds appropriately', () {
      expect(FontScale.englishPassage(20.0), equals(18.0));
      expect(FontScale.englishPassage(15.0), equals(14.0)); // 13.5 -> 14.0
    });

    test('englishFallback scales and rounds appropriately', () {
      expect(FontScale.englishFallback(20.0), equals(17.0));
      expect(FontScale.englishFallback(16.0), equals(14.0)); // 13.6 -> 14.0
    });

    test('originalPassage scales for Greek and Hebrew/Aramaic', () {
      expect(FontScale.originalPassage(20.0, Language.greek), equals(22.0));
      expect(FontScale.originalPassage(20.0, Language.hebrew), equals(24.0));
      expect(FontScale.originalPassage(20.0, Language.aramaic), equals(24.0));
    });

    test('heroWord scales and clamps within [24.0, 64.0]', () {
      expect(FontScale.heroWord(20.0), equals(42.0));
      expect(FontScale.heroWord(8.0), equals(24.0)); // 8 * 2.1 = 16.8 clamped to 24.0
      expect(FontScale.heroWord(35.0), equals(64.0)); // 35 * 2.1 = 73.5 clamped to 64.0
    });

    test('lexiconBody scales and clamps within [12.0, 26.0]', () {
      expect(FontScale.lexiconBody(20.0), equals(15.0));
      expect(FontScale.lexiconBody(8.0), equals(12.0)); // 8 * 0.75 = 6.0 clamped to 12.0
      expect(FontScale.lexiconBody(40.0), equals(26.0)); // 40 * 0.75 = 30.0 clamped to 26.0
    });

    test('sheetHeadword scales and clamps within [20.0, 48.0]', () {
      expect(FontScale.sheetHeadword(20.0), equals(32.0));
      expect(FontScale.sheetHeadword(8.0), equals(20.0)); // 8 * 1.6 = 12.8 clamped to 20.0
      expect(FontScale.sheetHeadword(35.0), equals(48.0)); // 35 * 1.6 = 56.0 clamped to 48.0
    });

    test('sheetRootLemma scales and rounds appropriately', () {
      expect(FontScale.sheetRootLemma(20.0), equals(22.0));
    });

    test('similarEnglish scales and clamps within [12.0, 26.0]', () {
      expect(FontScale.similarEnglish(20.0), equals(15.0));
      expect(FontScale.similarEnglish(10.0), equals(12.0));
    });

    test('similarOriginal scales and clamps within [12.0, 30.0]', () {
      expect(FontScale.similarOriginal(20.0, Language.greek), equals(16.0));
      expect(FontScale.similarOriginal(20.0, Language.hebrew), equals(18.0));
      expect(FontScale.similarOriginal(8.0, Language.greek), equals(12.0));
      expect(FontScale.similarOriginal(35.0, Language.hebrew), equals(30.0));
    });

    test('infoTitle and infoSpacing scale linearly', () {
      expect(FontScale.infoTitle(20.0), equals(24.0));
      expect(FontScale.infoSpacing(20.0), equals(12.0));
    });
  });
}
