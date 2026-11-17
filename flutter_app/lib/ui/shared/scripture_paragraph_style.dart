import 'package:bsb/app_state.dart';
import 'package:bsb/core/theme.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scripture/scripture.dart';
import 'package:scripture/scripture_core.dart';

/// Builds a [UsfmParagraphStyle] applying full-opacity verse numbers and
/// optional Words of Jesus coloring from [ScriptureTheme].
UsfmParagraphStyle buildScriptureParagraphStyle(
  BuildContext context, {
  required ParagraphFormat format,
  required TextStyle baseStyle,
  required bool wordsOfJesusInRed,
}) {
  final theme = Theme.of(context);
  final scriptureTheme = theme.extension<ScriptureTheme>();
  final verseNumberColor =
      scriptureTheme?.verseNumberColor ?? theme.colorScheme.onSurfaceVariant;

  final base = UsfmParagraphStyle.usfmDefaults(
    format: format == ParagraphFormat.p ? ParagraphFormat.m : format,
    baseStyle: baseStyle,
  );
  final styled = base.copyWith(
    verseNumberStyle: base.verseNumberStyle.copyWith(color: verseNumberColor),
  );

  if (!wordsOfJesusInRed) {
    return styled;
  }

  final wordsColor =
      scriptureTheme?.wordsOfJesusColor ??
      (getIt.isRegistered<AppState>()
          ? getIt<AppState>().getWordsOfJesusColor(theme.brightness)
          : ScriptureTheme.defaultWordsOfJesusColor(theme.brightness));

  return styled.copyWith(
    wordsOfJesusStyle: styled.textStyle.copyWith(color: wordsColor),
  );
}
