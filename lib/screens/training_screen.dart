import 'package:flutter/material.dart';

import '../data/exercises.dart';
import '../data/fitness_store.dart';
import '../models.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/exercise_video.dart';
import 'custom_workout_screen.dart';
import 'routine_screen.dart';

/// Home tab: progress rings, today's suggestion and workouts by body part.
class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final name = store.profile.name;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: PageScaffold.maxContentWidth,
        ),
        child: ListView(
          key: const PageStorageKey('training'),
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.paddingOf(context).top + 24,
            16,
            120,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TrackedLabel(
                    name.isEmpty ? greeting(now) : '${greeting(now)}, $name',
                  ),
                  const SizedBox(height: 4),
                  Text("Let's train", style: theme.textTheme.headlineMedium),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _Dashboard(),
            const SizedBox(height: 16),
            SegmentedButton<Place>(
              segments: [
                for (final p in Place.values)
                  ButtonSegment(
                    value: p,
                    icon: Icon(p.icon),
                    label: Text(p.label),
                  ),
              ],
              selected: {store.place},
              showSelectedIcon: false,
              onSelectionChanged: (s) => store.setPlace(s.first),
            ),
            const SizedBox(height: 16),
            _TodayCard(
              routine: routineFor(groupForDay(now), store.place, store.level),
              level: store.level,
            ),
            const SectionHeader('Body focus'),
            Wrap(
              spacing: 8,
              children: [
                for (final level in Level.values)
                  ChoiceChip(
                    label: Text(level.label),
                    selected: store.level == level,
                    onSelected: (_) => store.setLevel(level),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (final group in MuscleGroup.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BodyPartCard(
                  routine: routineFor(group, store.place, store.level),
                  level: store.level,
                ),
              ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: const TintedIcon(
                  icon: Icons.playlist_add_check,
                  color: coral,
                ),
                title: const Text('Custom workout'),
                subtitle: const Text('Pick any exercises you like'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const CustomWorkoutScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openRoutine(BuildContext context, Routine routine, Level level) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => RoutineScreen(routine: routine, level: level),
    ),
  );
}

/// Three rings (week goal, today's minutes, streak) and the week's days.
class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final profile = store.profile;
    final today = DateTime.now();
    final monday = startOfWeek(today);
    final minutes = store.minutesOn(today);
    final week = store.workoutsThisWeek;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Ring(
                  progress: week / profile.weeklyWorkoutsGoal,
                  value: '$week/${profile.weeklyWorkoutsGoal}',
                  label: 'This week',
                ),
                _Ring(
                  progress: minutes / profile.dailyMinutesGoal,
                  value: '$minutes',
                  unit: 'min',
                  label: 'Today',
                ),
                _Ring(
                  progress: store.streak / 7,
                  value: '${store.streak}',
                  unit: store.streak == 1 ? 'day' : 'days',
                  label: 'Streak',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 7; i++)
                  _DayDot(
                    day: addDays(monday, i),
                    done: store.workoutsOn(addDays(monday, i)).isNotEmpty,
                    today: isSameDay(addDays(monday, i), today),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.progress,
    required this.value,
    required this.label,
    this.unit,
  });

  final double progress;
  final String value;
  final String label;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ProgressRing(
          progress: progress,
          size: 88,
          strokeWidth: 7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (unit != null)
                Text(
                  unit!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TrackedLabel(label, size: 10),
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.day, required this.done, required this.today});

  final DateTime day;
  final bool done;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        TrackedLabel(weekdayShort(day).substring(0, 1), size: 10),
        const SizedBox(height: 6),
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: done ? coralGradient : null,
            color: done ? null : glassFill(context),
            border: done
                ? null
                : Border.all(
                    color: today ? coral : glassEdge(context),
                    width: today ? 1.5 : 1,
                  ),
            boxShadow: done
                ? [
                    BoxShadow(
                      color: coral.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: done
              ? const Icon(Icons.check, size: 16, color: obsidian)
              : Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: today ? coral : scheme.onSurfaceVariant,
                  ),
                ),
        ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.routine, required this.level});

  final Routine routine;
  final Level level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openRoutine(context, routine, level),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TrackedLabel("Today's workout", color: coral),
                    const SizedBox(height: 6),
                    Text(routine.name, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    _Meta(routine: routine, level: level),
                    const SizedBox(height: 16),
                    GradientButton(
                      onPressed: () => _openRoutine(context, routine, level),
                      icon: Icons.play_arrow,
                      label: 'Start',
                      height: 46,
                      expand: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _GroupThumb(routine: routine, size: 104),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyPartCard extends StatelessWidget {
  const _BodyPartCard({required this.routine, required this.level});

  final Routine routine;
  final Level level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openRoutine(context, routine, level),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _GroupThumb(routine: routine, size: 68),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.group!.label,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    _Meta(routine: routine, level: level),
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

/// A frame from the group's own video, or its icon on a soft tint.
class _GroupThumb extends StatelessWidget {
  const _GroupThumb({required this.routine, required this.size});

  final Routine routine;
  final double size;

  @override
  Widget build(BuildContext context) {
    final group = routine.group!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: SizedBox.square(
        dimension: size,
        child: FutureBuilder<OwnVideo?>(
          future: routine.items.isEmpty
              ? null
              : findOwnVideo(routine.items.first.exercise),
          builder: (context, snapshot) {
            final poster = snapshot.data?.poster;
            if (poster != null) return Image(image: poster, fit: BoxFit.cover);
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    group.color.withValues(alpha: 0.28),
                    group.color2.withValues(alpha: 0.10),
                  ],
                ),
              ),
              child: Icon(group.icon, color: group.color, size: size * 0.42),
            );
          },
        ),
      ),
    );
  }
}

/// "4 exercises · 12 min" plus difficulty bolts.
class _Meta extends StatelessWidget {
  const _Meta({required this.routine, required this.level});

  final Routine routine;
  final Level level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Flexible(
          child: Text(
            '${routine.items.length} exercises · '
            '${routine.estimatedMinutes} min',
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        LevelBolts(level: level),
      ],
    );
  }
}
