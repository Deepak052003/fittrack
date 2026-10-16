import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets/common.dart';
import '../widgets/exercise_video.dart';
import '../widgets/start_workout_sheet.dart';

/// Form video, step-by-step cues and a Start button for one exercise.
class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = exercise;

    return Scaffold(
      appBar: AppBar(title: Text('${e.group.label} · ${e.place.label}')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: PageScaffold.maxContentWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  e.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ExerciseClip(exercise: e),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: Icon(
                      e.isTimed ? Icons.timer_outlined : Icons.repeat,
                      size: 18,
                    ),
                    label: Text(
                      '${e.sets} × ${RoutineItem(exercise: e).target}',
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.fitness_center, size: 18),
                    label: Text(e.equipment),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Closed by default so the page stays short.
              Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  leading: const Icon(Icons.tips_and_updates_outlined),
                  title: const Text('Form tips'),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    for (final (i, step) in e.steps.indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${i + 1}. $step'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: PageScaffold.maxContentWidth,
            ),
            child: GradientButton(
              onPressed: () => showStartWorkoutSheet(
                context,
                Routine(
                  name: e.name,
                  items: [RoutineItem(exercise: e)],
                  place: e.place,
                  group: e.group,
                ),
              ),
              icon: Icons.play_arrow,
              label: 'Start exercise',
            ),
          ),
        ),
      ),
    );
  }
}
