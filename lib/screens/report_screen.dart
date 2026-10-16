import 'package:flutter/material.dart';

import '../data/fitness_store.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/body_widgets.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/workout_widgets.dart';
import 'workouts_screen.dart';

/// Totals, this week, recent history, weight and BMI.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = dateOnly(DateTime.now());
    final week = store.minutesPerDay(7);
    final recent = store.workouts.take(3).toList();

    return PageScaffold(
      title: 'Report',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: _Total(
                    icon: Icons.emoji_events_outlined,
                    color: scheme.primary,
                    value: formatNumber(store.workouts.length),
                    label: 'Workouts',
                  ),
                ),
                Expanded(
                  child: _Total(
                    icon: Icons.local_fire_department,
                    color: caloriesOrange,
                    value: formatNumber(store.totalCalories),
                    label: 'kcal',
                  ),
                ),
                Expanded(
                  child: _Total(
                    icon: Icons.timer_outlined,
                    color: iceBlue,
                    value: formatNumber(store.totalMinutes),
                    label: 'Minutes',
                  ),
                ),
              ],
            ),
          ),
        ),
        SectionHeader(
          'This week',
          trailing: Text(
            '${store.streak} day streak',
            style: theme.textTheme.labelLarge?.copyWith(color: coral),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: SizedBox(
              height: 190,
              child: NeonLineChart(
                values: [for (final m in week) m.toDouble()],
                labels: [
                  for (var i = 6; i >= 0; i--) weekdayShort(addDays(today, -i)),
                ],
                goal: store.profile.dailyMinutesGoal.toDouble(),
                showValues: true,
                semanticsLabel:
                    'Active minutes over the last 7 days: '
                    '${week.fold(0, (a, b) => a + b)} in total.',
              ),
            ),
          ),
        ),
        SectionHeader(
          'History',
          trailing: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
            ),
            child: const Text('See all'),
          ),
        ),
        if (recent.isEmpty)
          const EmptyState(
            icon: Icons.history,
            title: 'No workouts yet',
            message: 'Finish a workout and it shows up here.',
          )
        else
          for (final w in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: WorkoutTile(
                workout: w,
                onTap: () => showLogWorkoutSheet(context, initial: w),
              ),
            ),
        const SectionHeader('Body'),
        const WeightCard(),
        const SizedBox(height: 12),
        const BmiCard(),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TintedIcon(icon: icon, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
