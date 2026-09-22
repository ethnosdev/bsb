import 'package:bsb/infrastructure/reading_plan_models.dart';
import 'package:bsb/infrastructure/reading_plan_service.dart';
import 'package:bsb/infrastructure/service_locator.dart';
import 'package:bsb/ui/reading_plans/widgets/active_plan_dashboard.dart';
import 'package:bsb/ui/reading_plans/widgets/plan_catalog_view.dart';
import 'package:flutter/material.dart';

class ReadingPlansPage extends StatefulWidget {
  const ReadingPlansPage({super.key});

  @override
  State<ReadingPlansPage> createState() => _ReadingPlansPageState();
}

class _ReadingPlansPageState extends State<ReadingPlansPage> {
  final ReadingPlanService _service = getIt<ReadingPlanService>();
  bool _showCatalog = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserPlanProgress?>(
      valueListenable: _service.activeProgressNotifier,
      builder: (context, activeProgress, child) {
        final hasActivePlan = activeProgress != null;
        final isCatalogView = _showCatalog || !hasActivePlan;
        final activePlan = hasActivePlan ? _service.getActivePlan() : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(isCatalogView && hasActivePlan ? 'Browse Plans' : 'Reading Plans'),
            leading: isCatalogView && hasActivePlan
                ? IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Back to active plan',
                    onPressed: () {
                      setState(() {
                        _showCatalog = false;
                      });
                    },
                  )
                : null,
            actions: [
              if (!isCatalogView && hasActivePlan) ...[
                IconButton(
                  icon: const Icon(Icons.grid_view_rounded),
                  tooltip: 'Browse all plans',
                  onPressed: () {
                    setState(() {
                      _showCatalog = true;
                    });
                  },
                ),
                PopupMenuButton<String>(
                  tooltip: 'Plan Options',
                  onSelected: (value) async {
                    if (value == 'reset') {
                      _confirmReset(context, activeProgress.planId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'reset',
                      child: Row(
                        children: [
                          Icon(Icons.restart_alt),
                          SizedBox(width: 8),
                          Text('Reset Progress'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          body: isCatalogView || activePlan == null
              ? PlanCatalogView(
                  onPlanSelected: () {
                    setState(() {
                      _showCatalog = false;
                    });
                  },
                )
              : ActivePlanDashboard(
                  plan: activePlan,
                  progress: activeProgress,
                  onBrowsePlans: () {
                    setState(() {
                      _showCatalog = true;
                    });
                  },
                ),
        );
      },
    );
  }

  Future<void> _confirmReset(BuildContext context, String planId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Reading Plan?'),
        content: const Text(
          'Are you sure you want to reset your progress for this plan? All completed days will be cleared. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.resetPlan(planId);
    }
  }
}
