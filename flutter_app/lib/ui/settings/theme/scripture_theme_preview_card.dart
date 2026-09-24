import 'package:flutter/material.dart';

/// A realistic scripture reading preview card that renders real typography,
/// verse numbers, and headings for any [ColorScheme].
class ScriptureThemePreviewCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool wordsOfJesusInRed;
  final double textSize;
  final String title;

  const ScriptureThemePreviewCard({
    super.key,
    required this.colorScheme,
    this.wordsOfJesusInRed = true,
    this.textSize = 15.0,
    this.title = 'John 1:1–3',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final redWordsColor = isDark
        ? const Color(0xFFFF8A80)
        : const Color(0xFFB71C1C);

    return Container(
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
          // Simulated App Bar / Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Charis',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                // Mini Tab Chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Active Tab',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scripture Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Heading
                Text(
                  'The Word Became Flesh',
                  style: TextStyle(
                    fontFamily: 'Charis',
                    fontWeight: FontWeight.bold,
                    fontSize: textSize + 1.5,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),

                // Passage Text
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Charis',
                      fontSize: textSize,
                      height: 1.55,
                      color: colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: '1 ',
                        style: TextStyle(
                          fontSize: textSize * 0.75,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const TextSpan(
                        text:
                            'In the beginning was the Word, and the Word was with God, and the Word was God. ',
                      ),
                      TextSpan(
                        text: '2 ',
                        style: TextStyle(
                          fontSize: textSize * 0.75,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const TextSpan(
                        text: 'He was with God in the beginning. ',
                      ),
                      TextSpan(
                        text: '3 ',
                        style: TextStyle(
                          fontSize: textSize * 0.75,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const TextSpan(
                        text:
                            'Through Him all things were made, and without Him nothing was made that has been made. ',
                      ),
                      if (wordsOfJesusInRed) ...[
                        const TextSpan(text: '\n\nJesus said: '),
                        TextSpan(
                          text:
                              '“I am the light of the world. Whoever follows Me will never walk in the darkness.”',
                          style: TextStyle(
                            color: redWordsColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
