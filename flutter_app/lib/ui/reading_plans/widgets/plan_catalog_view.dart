import 'package:bsb/infrastructure/reading_plan_models.dart';
import 'package:bsb/infrastructure/reading_plan_service.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:flutter/material.dart';

class PlanCatalogView extends StatefulWidget {
  final VoidCallback? onPlanSelected;

  const PlanCatalogView({
    super.key,
    this.onPlanSelected,
  });

  @override
  State<PlanCatalogView> createState() => _PlanCatalogViewState();
}

class _PlanCatalogViewState extends State<PlanCatalogView> {
  final ReadingPlanService _service = getIt<ReadingPlanService>();

  Map<String, UserPlanProgress> _progressByPlanId = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final all = await _service.getAllProgress();
    if (mounted) {
      setState(() {
        _progressByPlanId = {for (final p in all) p.planId: p};
        _isLoading = false;
      });
    }
  }

  bool _trackHasProgress(PlanTrack track) {
    for (final pace in track.availablePaces) {
      final planId = ReadingPlan.makePlanId(track, pace);
      final p = _progressByPlanId[planId];
      if (p != null && p.completedDays.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<void> _showPaceDialog(PlanTrack track) async {
    final activeProgress = _service.activeProgressNotifier.value;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(track.title),
          contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: track.availablePaces.map((pace) {
              final planId = ReadingPlan.makePlanId(track, pace);
              final progress = _progressByPlanId[planId];
              final isActive = activeProgress?.planId == planId;

              String? subtitle;
              if (isActive) {
                if (progress != null && progress.completedDays.isNotEmpty) {
                  subtitle =
                      'Currently active • ${progress.completedDays.length} of ${progress.totalDays} days completed';
                } else {
                  subtitle = 'Currently active';
                }
              } else if (progress != null && progress.completedDays.isNotEmpty) {
                subtitle =
                    '${progress.completedDays.length} of ${progress.totalDays} days completed';
              }

              return ListTile(
                title: Text(
                  pace.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: subtitle != null ? Text(subtitle) : null,
                trailing: isActive
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(dialogContext).colorScheme.primary,
                      )
                    : (progress != null && progress.completedDays.isNotEmpty
                        ? const Icon(Icons.chevron_right)
                        : null),
                onTap: () async {
                  Navigator.of(dialogContext).pop();
                  await _service.startOrResumePlan(track, pace);
                  widget.onPlanSelected?.call();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeProgress = _service.activeProgressNotifier.value;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Available Plans',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        _buildTrackCard(
          context: context,
          track: PlanTrack.throughTheBible,
          activeProgress: activeProgress,
        ),
        const SizedBox(height: 12),
        _buildTrackCard(
          context: context,
          track: PlanTrack.chronological,
          activeProgress: activeProgress,
        ),
        const SizedBox(height: 12),
        _buildTrackCard(
          context: context,
          track: PlanTrack.newTestament,
          activeProgress: activeProgress,
        ),
      ],
    );
  }

  Widget _buildTrackCard({
    required BuildContext context,
    required PlanTrack track,
    required UserPlanProgress? activeProgress,
  }) {
    final theme = Theme.of(context);
    final isActive = activeProgress?.track == track;
    final hasProgress = _trackHasProgress(track);

    final String buttonText;
    if (isActive) {
      buttonText = 'View';
    } else if (hasProgress) {
      buttonText = 'Resume';
    } else {
      buttonText = 'Start';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: isActive ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showPaceDialog(track),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  track.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: () {
                  if (isActive) {
                    widget.onPlanSelected?.call();
                  } else {
                    _showPaceDialog(track);
                  }
                },
                child: Text(buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
