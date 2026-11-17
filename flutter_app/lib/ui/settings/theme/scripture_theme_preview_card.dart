import 'package:bsb/app_state.dart';
import 'package:bsb/core/theme.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scripture/scripture.dart';

/// A realistic scripture reading preview card that renders real typography,
/// verse number, footnote marker, chapter tabs, and text selection handles for any [ColorScheme].
class ScriptureThemePreviewCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool? wordsOfJesusInRed;
  final Color? wordsOfJesusColor;
  final Color? verseNumberColor;
  final double textSize;
  final String title;

  const ScriptureThemePreviewCard({
    super.key,
    required this.colorScheme,
    this.wordsOfJesusInRed,
    this.wordsOfJesusColor,
    this.verseNumberColor,
    this.textSize = 15.0,
    this.title = 'MAT 8',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final appState = getIt.isRegistered<AppState>() ? getIt<AppState>() : null;
    final showWordsInColor =
        wordsOfJesusInRed ?? appState?.wordsOfJesusInRed ?? true;
    final redWordsColor =
        wordsOfJesusColor ??
        ScriptureTheme.defaultWordsOfJesusColor(colorScheme.brightness);
    final resolvedVerseNumberColor =
        verseNumberColor ?? colorScheme.onSurfaceVariant;

    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Real App Bar Preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.menu, size: 22, color: colorScheme.onSurface),
                  const SizedBox(width: 12),
                  // Real Chapter Tab Chip
                  Container(
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(18.0),
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 12.0, right: 6.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Charis',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.close,
                          size: 16,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Inactive Chapter Tab Chip
                  Container(
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.6,
                      ),
                      borderRadius: BorderRadius.circular(18.0),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    alignment: Alignment.center,
                    child: Text(
                      'JHN 3',
                      style: TextStyle(
                        fontFamily: 'Charis',
                        fontSize: 12.5,
                        fontWeight: FontWeight.normal,
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.add, size: 22, color: colorScheme.onSurface),
                  const SizedBox(width: 12),
                  Icon(Icons.more_vert, size: 22, color: colorScheme.onSurface),
                ],
              ),
            ),

            // Scripture Content (Matthew 8:3)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Charis',
                    fontSize: textSize,
                    height: 1.55,
                    color: colorScheme.onSurface,
                  ),
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: VerseNumberWidget(
                        number: '3',
                        style: TextStyle(
                          fontFamily: 'Charis',
                          fontSize: textSize,
                          color: resolvedVerseNumberColor,
                        ),
                        padding: const EdgeInsets.only(right: 4.0),
                      ),
                    ),
                    const TextSpan(
                      text: 'Jesus reached out His hand and touched the man. ',
                    ),
                    TextSpan(
                      text: '“I am willing,”',
                      style: TextStyle(
                        color: showWordsInColor
                            ? redWordsColor
                            : colorScheme.onSurface,
                      ),
                    ),
                    const TextSpan(text: ' He said. '),
                    TextSpan(
                      text: '“Be clean!”',
                      style: TextStyle(
                        color: showWordsInColor
                            ? redWordsColor
                            : colorScheme.onSurface,
                      ),
                    ),
                    const TextSpan(text: ' And '),
                    // Selected word "immediately" with selection handles
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: _SelectedWordWithHandles(
                        word: 'immediately',
                        style: TextStyle(
                          fontFamily: 'Charis',
                          fontSize: textSize,
                          height: 1.25,
                          color: colorScheme.onSurface,
                        ),
                        highlightColor: colorScheme.primary.withValues(
                          alpha: 0.28,
                        ),
                        handleColor: colorScheme.primary,
                      ),
                    ),
                    const TextSpan(text: ' his leprosy was cleansed.'),
                    // Footnote marker in accent color
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: FootnoteWidget(
                        marker: '*',
                        text: '',
                        style: TextStyle(
                          fontFamily: 'Charis',
                          fontSize: textSize,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedWordWithHandles extends StatelessWidget {
  final String word;
  final TextStyle style;
  final Color highlightColor;
  final Color handleColor;

  const _SelectedWordWithHandles({
    required this.word,
    required this.style,
    required this.highlightColor,
    required this.handleColor,
  });

  @override
  Widget build(BuildContext context) {
    const handleSize = 16.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Highlight background for the word
        Container(
          decoration: BoxDecoration(
            color: highlightColor,
            borderRadius: BorderRadius.circular(2.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0),
          child: Text(word, style: style),
        ),
        // Start handle (bottom-left)
        Positioned(
          left: -handleSize,
          bottom: -handleSize,
          child: CustomPaint(
            size: const Size(handleSize, handleSize),
            painter: _SelectionHandlePainter(color: handleColor, isStart: true),
          ),
        ),
        // End handle (bottom-right)
        Positioned(
          right: -handleSize,
          bottom: -handleSize,
          child: CustomPaint(
            size: const Size(handleSize, handleSize),
            painter: _SelectionHandlePainter(
              color: handleColor,
              isStart: false,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionHandlePainter extends CustomPainter {
  final Color color;
  final bool isStart;

  const _SelectionHandlePainter({required this.color, required this.isStart});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final radius = size.width / 2.0;
    final circle = Rect.fromCircle(
      center: Offset(radius, radius),
      radius: radius,
    );

    // For start handle (left handle pointing up-right into bottom-left of selection):
    // The top-right quadrant is filled.
    // For end handle (right handle pointing up-left into bottom-right of selection):
    // The top-left quadrant is filled.
    final point = isStart
        ? Rect.fromLTWH(radius, 0, radius, radius)
        : Rect.fromLTWH(0, 0, radius, radius);

    final path = Path()
      ..addOval(circle)
      ..addRect(point);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SelectionHandlePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isStart != isStart;
  }
}
