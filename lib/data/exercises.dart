import '../models.dart';
import 'exercise_catalog.dart';

List<Exercise> exercisesFor(MuscleGroup group, Place place) => [
  for (final e in exerciseCatalog)
    if (e.group == group && e.place == place) e,
];

Exercise? exerciseById(String id) {
  for (final e in exerciseCatalog) {
    if (e.id == id) return e;
  }
  return null;
}

/// A ready-made workout: the group's exercises scaled to [level].
Routine routineFor(
  MuscleGroup group,
  Place place, [
  Level level = Level.intermediate,
]) {
  var exercises = exercisesFor(group, place);
  if (level == Level.beginner) {
    final easier = [
      for (final e in exercises)
        if (e.level != Level.advanced) e,
    ];
    if (easier.length >= 3) exercises = easier;
  }
  // Long lists: keep the moves closest to the chosen level, in catalog order.
  if (exercises.length > _maxExercises) {
    final byFit = [...exercises]
      ..sort(
        (a, b) => (a.level.index - level.index).abs().compareTo(
          (b.level.index - level.index).abs(),
        ),
      );
    final keep = byFit.take(_maxExercises).toSet();
    exercises = [
      for (final e in exercises)
        if (keep.contains(e)) e,
    ];
  }
  return Routine(
    name: '${group.label} ${level.label}',
    group: group,
    place: place,
    items: [for (final e in exercises) _scaled(e, level)],
    note: group == MuscleGroup.core ? _absNote : null,
  );
}

const _maxExercises = 6;

const _absNote =
    'Abs show when body fat is low. Pair this with the Fat burn circuit '
    'and a good diet.';

const _fatBurnIds = [
  'jumping-jacks',
  'burpee',
  'mountain-climber',
  'high-knees',
  'bicycle-crunch',
  'flutter-kicks',
];

/// Cardio + abs circuit with short rests (no equipment, so gym or home).
Routine fatBurnRoutine(Place place, [Level level = Level.intermediate]) =>
    Routine(
      name: 'Fat Burn ${level.label}',
      group: MuscleGroup.cardio,
      place: place,
      restSeconds: 30,
      note:
          'Move fast and keep rests short. Do it 3–4 times a week; '
          'diet does the rest.',
      items: [
        for (final id in _fatBurnIds)
          if (exerciseById(id) case final e?) _scaled(e, level),
      ],
    );

RoutineItem _scaled(Exercise e, Level level) {
  // Long single sets (cardio machines) scale by time only.
  final long = e.sets == 1;
  final factor = switch (level) {
    Level.beginner => 0.75,
    Level.intermediate => 1.0,
    Level.advanced => 1.25,
  };
  final sets = long
      ? 1
      : switch (level) {
          Level.beginner => 2,
          Level.intermediate => e.sets,
          Level.advanced => (e.sets + 1).clamp(1, 5),
        };
  final step = long ? 60 : 5;
  return RoutineItem(
    exercise: e,
    sets: sets,
    reps: e.isTimed ? 0 : (e.reps * factor).round().clamp(5, 50),
    seconds: e.isTimed
        ? ((e.seconds * factor / step).round() * step).clamp(step, 3600)
        : 0,
  );
}

/// Suggested muscle group for a weekday (Monday = chest).
MuscleGroup groupForDay(DateTime day) =>
    MuscleGroup.values[(day.weekday - 1) % MuscleGroup.values.length];
