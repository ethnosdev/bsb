import 'package:bsb/infrastructure/reading_plan_models.dart';
import 'package:bsb/ui/reading_plans/widgets/plan_day_tile.dart';
import 'package:flutter/material.dart';

class ActivePlanDashboard extends StatefulWidget {
  final ReadingPlan plan;
  final UserPlanProgress progress;
  final VoidCallback onBrowsePlans;

  const ActivePlanDashboard({
    super.key,
    required this.plan,
    required this.progress,
    required this.onBrowsePlans,
  });

  @override
  State<ActivePlanDashboard> createState() => _ActivePlanDashboardState();
}

class _ActivePlanDashboardState extends State<ActivePlanDashboard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFinished = widget.progress.isPlanFinished;
    final nextDayNum = widget.progress.nextUncompletedDayNumber;
    final nextDay = (nextDayNum > 0 && nextDayNum <= widget.plan.days.length)
        ? widget.plan.days[nextDayNum - 1]
        : null;

    final completedCount = widget.progress.completedDays.length;
    final remainingCount = (widget.progress.totalDays - completedCount).clamp(
      0,
      widget.progress.totalDays,
    );

    return Scaffold(
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 12, bottom: 32),
        itemCount:
            widget.plan.days.length +
            2, // header card + next up card + all days
        itemBuilder: (context, index) {
          if (index == 0) {
            // Header summary card
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.plan.track.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            label: const Text('Switch'),
                            onPressed: widget.onBrowsePlans,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: widget.progress.progressPercentage,
                          minHeight: 10,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerLowest,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$completedCount of ${widget.progress.totalDays} days completed',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(widget.progress.progressPercentage * 100).toStringAsFixed(1)}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isFinished
                            ? 'Plan Completed!'
                            : '$remainingCount days remaining',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (index == 1) {
            // Next up / completion card
            if (isFinished) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Card(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.celebration_outlined,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Congratulations!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You have completed the entire reading plan.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (nextDay == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Up',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PlanDayTile(
                    day: nextDay,
                    progress: widget.progress,
                    plan: widget.plan,
                    isHighlighted: true,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'All Days',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Days list (index >= 2)
          final dayIndex = index - 2;
          final day = widget.plan.days[dayIndex];
          final isNextUp = day.dayNumber == nextDayNum && !isFinished;

          return PlanDayTile(
            key: ValueKey('day_${day.dayNumber}'),
            day: day,
            progress: widget.progress,
            plan: widget.plan,
            isHighlighted: isNextUp,
          );
        },
      ),
    );
  }
}
