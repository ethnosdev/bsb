import 'package:bsb/core/font_family.dart';
import 'package:bsb/infrastructure/verse_element.dart';
import 'package:database_builder/database_builder.dart';
import 'package:flutter/material.dart';

/// Interactive word chip used for both English and Original Language words.
class PassageWordChip extends StatelessWidget {
  const PassageWordChip({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.fontFamily,
    this.fontSize = 18,
    this.textDirection,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
  });

  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final String? fontFamily;
  final double fontSize;
  final TextDirection? textDirection;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withAlpha(50),
          ),
        ),
        child: Text(
          text,
          textDirection: textDirection,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.normal,
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}

/// Reusable card displaying interactive English (BSB) words.
class EnglishPassageCard extends StatelessWidget {
  const EnglishPassageCard({
    super.key,
    required this.words,
    required this.selectedWord,
    required this.onWordSelected,
    this.fallbackText,
  });

  final List<OriginalWord> words;
  final OriginalWord? selectedWord;
  final ValueChanged<OriginalWord> onWordSelected;
  final String? fallbackText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'English (BSB)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (words.isNotEmpty)
              Wrap(
                spacing: 3,
                runSpacing: 4,
                children: words.map((word) {
                  final isSelected = word.id == selectedWord?.id ||
                      (selectedWord != null &&
                          word.clusterWordIds.contains(selectedWord!.id));
                  return PassageWordChip(
                    text: '${word.englishGloss}${word.punctuation ?? ''}',
                    isSelected: isSelected,
                    onTap: () => onWordSelected(word),
                    fontSize: 18,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                  );
                }).toList(),
              )
            else if (fallbackText != null)
              Text(
                fallbackText!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reusable card displaying interactive Hebrew/Greek/Aramaic words.
class OriginalPassageCard extends StatelessWidget {
  const OriginalPassageCard({
    super.key,
    required this.language,
    required this.words,
    required this.selectedWord,
    required this.onWordSelected,
    this.fontSize = 24,
  });

  final Language language;
  final List<OriginalWord> words;
  final OriginalWord? selectedWord;
  final ValueChanged<OriginalWord> onWordSelected;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = language == Language.hebrew || language == Language.aramaic;
    final direction = isRtl ? TextDirection.rtl : TextDirection.ltr;
    final fontFamily = fontFamilyForLanguage(language);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment:
              isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              language.displayName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              textDirection: direction,
              spacing: 4,
              runSpacing: 6,
              children: words.map((word) {
                final isSelected = word.id == selectedWord?.id ||
                    (selectedWord != null &&
                        selectedWord!.clusterWordIds.contains(word.id));
                return PassageWordChip(
                  text: word.word,
                  isSelected: isSelected,
                  onTap: () => onWordSelected(word),
                  fontFamily: fontFamily,
                  fontSize: fontSize,
                  textDirection: direction,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
