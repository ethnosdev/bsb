import 'package:bsb/infrastructure/reading_plan_models.dart';
import 'package:bsb/infrastructure/reading_plan_service.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/tabs/tab_manager.dart';
import 'package:flutter/material.dart';

class PlanDayTile extends StatelessWidget {
  final PlanDay day;
  final UserPlanProgress progress;
  final ReadingPlan plan;
  final bool isHighlighted;

  const PlanDayTile({
    super.key,
    required this.day,
    required this.progress,
    required this.plan,
    this.isHighlighted = false,
  });

  void _onReadTapped(BuildContext context, PlanReading reading) {
    final previousChapters = <({int bookId, int chapter})>[];

    // Find where this reading is in the current day
    final readingIndex = day.readings.indexOf(reading);

    if (readingIndex > 0) {
      // Previous reading in the same day
      final prev = day.readings[readingIndex - 1];
      previousChapters.add(
        (bookId: prev.bookId, chapter: prev.endChapter),
      );
    }

    if (readingIndex <= 0) {
      // First reading in this day — look at the previous day's last reading
      final dayIndex = day.dayNumber - 1; // 0-based index
      if (dayIndex > 0) {
        final prevDay = plan.days[dayIndex - 1];
        if (prevDay.readings.isNotEmpty) {
          final prevReading = prevDay.readings.last;
          previousChapters.add(
            (bookId: prevReading.bookId, chapter: prevReading.endChapter),
          );
        }
      }
    }

    getIt<TabManager>().openTabOrReuse(
      reading.bookId,
      reading.startChapter,
      previousChapters: previousChapters,
      targetVerse: 1,
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDayDone = progress.isDayCompleted(day);
    final service = getIt<ReadingPlanService>();

    return Card(
      elevation: isHighlighted ? 2 : 0,
      color: isHighlighted
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
          : (isDayDone
              ? theme.colorScheme.surfaceContainerLowest
              : theme.colorScheme.surfaceContainerLow),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isHighlighted
            ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
            : BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Day ${day.dayNumber}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDayDone
                              ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)
                              : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${day.totalChapters} ${day.totalChapters == 1 ? 'ch' : 'chs'})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isDayDone ? 'Mark day as incomplete' : 'Mark day as complete',
                  icon: Icon(
                    isDayDone ? Icons.check_circle : Icons.check_circle_outline,
                    color: isDayDone
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  onPressed: () => service.toggleDayComplete(day.dayNumber),
                ),
              ],
            ),
            const Divider(height: 8),
            ...day.readings.map((reading) {
              final isReadingDone = progress.isReadingCompleted(day.dayNumber, reading);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Checkbox(
                      value: isReadingDone,
                      onChanged: (_) => service.toggleReadingComplete(day.dayNumber, reading),
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: Text(
                        reading.referenceDisplay,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration: isReadingDone ? TextDecoration.lineThrough : null,
                          color: isReadingDone
                              ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)
                              : null,
                          fontWeight: isReadingDone ? FontWeight.normal : FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.auto_stories_outlined, size: 16),
                      label: const Text('Read'),
                      onPressed: () => _onReadTapped(context, reading),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
