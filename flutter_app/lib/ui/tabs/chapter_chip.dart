import 'package:flutter/material.dart';
import 'bible_tab.dart';

class ChapterChip extends StatelessWidget {
  const ChapterChip({
    super.key,
    required this.tab,
    required this.isActive,
    required this.onTap,
    this.onClose,
  });

  final BibleTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = isActive
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    final foregroundColor = isActive
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return SizedBox(
      height: 36.0,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
          side: isActive
              ? BorderSide(color: colorScheme.primary, width: 1.2)
              : BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.only(
              left: 10.0,
              right: isActive && onClose != null ? 4.0 : 10.0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  tab.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    letterSpacing: 0.5,
                  ),
                ),
                if (isActive && onClose != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClose,
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: foregroundColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
