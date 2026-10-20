import 'package:flutter/material.dart';

import '../models.dart';
import '../pwa/pwa.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/exercise_video.dart';
import '../widgets/start_workout_sheet.dart';
import 'exercise_detail_screen.dart';
import 'session_screen.dart';

/// One workout (e.g. "Chest Beginner"): its exercises and a Start button.
class RoutineScreen extends StatelessWidget {
  const RoutineScreen({super.key, required this.routine, required this.level});

  final Routine routine;
  final Level level;

  void _start(BuildContext context) {
    // Must run inside the tap so iOS allows the timer beep later.
    Pwa.instance.unlockAudio();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => SessionScreen(routine: routine),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;

    return Scaffold(
      body: AmbientBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 300,
              backgroundColor: surface,
              foregroundColor: theme.colorScheme.onSurface,
              actions: [
                IconButton(
                  tooltip: 'Adjust sets and reps',
                  icon: const Icon(Icons.tune),
                  onPressed: () => showStartWorkoutSheet(context, routine),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 56,
                  bottom: 16,
                ),
                title: Text(
                  routine.name,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                background: _Hero(routine: routine, level: level),
              ),
            ),
            if (routine.note case final note?)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline, color: coral),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              note,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.separated(
                itemCount: routine.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) =>
                    _ExerciseRow(index: i, item: routine.items[i]),
              ),
            ),
          ],
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
              onPressed: () => _start(context),
              icon: Icons.play_arrow,
              label: 'Start',
            ),
          ),
        ),
      ),
    );
  }
}

/// Header art: a frame from our own video (or a glow and the group icon),
/// fading into the page.
class _Hero extends StatelessWidget {
  const _Hero({required this.routine, required this.level});

  final Routine routine;
  final Level level;

  @override
  Widget build(BuildContext context) {
    final group = routine.group!;
    final surface = Theme.of(context).colorScheme.surface;
    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<OwnVideo?>(
          future: routine.items.isEmpty
              ? null
              : findOwnVideo(routine.items.first.exercise),
          builder: (context, snapshot) {
            final poster = snapshot.data?.poster;
            if (poster != null) return Image(image: poster, fit: BoxFit.cover);
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.6, -0.4),
                  radius: 1.1,
                  colors: [group.color.withValues(alpha: 0.35), surface],
                ),
              ),
              child: Align(
                alignment: const Alignment(0.75, -0.1),
                child: Icon(
                  group.icon,
                  size: 150,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            );
          },
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.45, 1],
              colors: [
                Colors.black.withValues(alpha: 0.35),
                surface.withValues(alpha: 0.2),
                surface,
              ],
            ),
          ),
        ),
        Positioned(
          left: 56,
          bottom: 60,
          child: Row(
            children: [
              TrackedLabel(routine.place.label, color: coral),
              const SizedBox(width: 12),
              TrackedLabel(
                '${routine.items.length} exercises · '
                '${routine.estimatedMinutes} min',
              ),
              const SizedBox(width: 8),
              LevelBolts(level: level),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.index, required this.item});

  final int index;
  final RoutineItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = item.exercise;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ExerciseDetailScreen(exercise: e),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _Thumb(exercise: e),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TrackedLabel('Exercise ${index + 1}', size: 10),
                    const SizedBox(height: 2),
                    Text(e.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      e.isTimed
                          ? '${item.sets} × ${item.target}'
                          : '${item.sets} × ${item.reps} reps',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: coral,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A frame from our own video, or the body-part icon.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final group = exercise.group;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox.square(
        dimension: 68,
        child: FutureBuilder<OwnVideo?>(
          future: findOwnVideo(exercise),
          builder: (context, snapshot) {
            final poster = snapshot.data?.poster;
            if (poster != null) return Image(image: poster, fit: BoxFit.cover);
            return DecoratedBox(
              decoration: BoxDecoration(
                color: group.color.withValues(alpha: 0.16),
              ),
              child: Icon(
                exercise.isTimed ? Icons.timer_outlined : group.icon,
                color: group.color,
                size: 28,
              ),
            );
          },
        ),
      ),
    );
  }
}
