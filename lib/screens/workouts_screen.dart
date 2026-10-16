import 'package:flutter/material.dart';

import '../data/fitness_store.dart';
import '../models.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/workout_widgets.dart';

/// Full workout history grouped by day. Swipe left to delete, tap to edit.
class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final workouts = store.workouts;

    if (workouts.isEmpty) {
      return const PageScaffold(
        title: 'History',
        children: [
          EmptyState(
            icon: Icons.fitness_center,
            title: 'No workouts yet',
            message: 'Log your first workout to start building a streak.',
          ),
        ],
      );
    }

    // Workouts are newest first, so the groups are too.
    final groups = <DateTime, List<Workout>>{};
    for (final w in workouts) {
      groups.putIfAbsent(dateOnly(w.date), () => []).add(w);
    }
    final totalMinutes = workouts.fold(0, (sum, w) => sum + w.minutes);
    final totalCalories = workouts.fold(0, (sum, w) => sum + w.calories);
    final theme = Theme.of(context);

    return PageScaffold(
      title: 'History',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: SummaryStat(
                    label: 'Workouts',
                    value: formatNumber(workouts.length),
                  ),
                ),
                Expanded(
                  child: SummaryStat(
                    label: 'Total time',
                    value: formatMinutes(totalMinutes),
                  ),
                ),
                Expanded(
                  child: SummaryStat(
                    label: 'Burned',
                    value: '${formatNumber(totalCalories)} kcal',
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final MapEntry(key: day, value: items) in groups.entries) ...[
          SectionHeader(
            formatDayLabel(day),
            trailing: Text(
              formatMinutes(items.fold(0, (sum, w) => sum + w.minutes)),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final w in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DismissibleWorkout(workout: w),
            ),
        ],
      ],
    );
  }
}

class _DismissibleWorkout extends StatelessWidget {
  const _DismissibleWorkout({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(workout.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) => deleteWorkoutWithUndo(
        StoreScope.read(context),
        ScaffoldMessenger.of(context),
        workout,
      ),
      child: WorkoutTile(
        workout: workout,
        onTap: () => showLogWorkoutSheet(context, initial: workout),
      ),
    );
  }
}

/// History as its own page, with manual logging (runs, rides, sports).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const WorkoutsScreen(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLogWorkoutSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Log workout'),
      ),
    );
  }
}
