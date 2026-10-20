import 'package:flutter/material.dart';

enum WorkoutType {
  running('Running', Icons.speed, 9.8, Color(0xFFFF6B3D)),
  walking('Walking', Icons.route, 3.5, Color(0xFF3DA5FF)),
  cycling('Cycling', Icons.pedal_bike, 7.5, Color(0xFF9B6BFF)),
  strength('Strength', Icons.fitness_center, 5.0, Color(0xFFFF4D6D)),
  hiit('HIIT', Icons.local_fire_department, 8.0, Color(0xFFFFA62B)),
  yoga('Yoga', Icons.spa, 2.5, Color(0xFF2EC4B6)),
  swimming('Swimming', Icons.water, 7.0, Color(0xFF4D7CFE)),
  sports('Sports', Icons.sports_soccer, 7.0, Color(0xFF00B37E)),
  other('Other', Icons.bolt, 4.0, Color(0xFF8D99AE));

  const WorkoutType(this.label, this.icon, this.met, this.color);

  final String label;
  final IconData icon;

  /// Metabolic equivalent of task, used for the calorie estimate.
  final double met;
  final Color color;

  static WorkoutType fromName(String? name) =>
      values.asNameMap()[name] ?? WorkoutType.other;
}

enum Intensity {
  light('Light', 0.8),
  moderate('Moderate', 1.0),
  intense('Intense', 1.2);

  const Intensity(this.label, this.factor);

  final String label;
  final double factor;

  static Intensity fromName(String? name) =>
      values.asNameMap()[name] ?? Intensity.moderate;
}

/// Estimated kcal burned: MET × intensity × body weight (kg) × hours.
int estimateCalories({
  required WorkoutType type,
  required Intensity intensity,
  required int minutes,
  required double weightKg,
}) => (type.met * intensity.factor * weightKg * minutes / 60).round();

class Workout {
  const Workout({
    required this.id,
    required this.type,
    required this.minutes,
    required this.intensity,
    required this.date,
    required this.calories,
    this.notes = '',
  });

  final String id;
  final WorkoutType type;
  final int minutes;
  final Intensity intensity;
  final DateTime date;
  final int calories;
  final String notes;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'minutes': minutes,
    'intensity': intensity.name,
    'date': date.toIso8601String(),
    'calories': calories,
    'notes': notes,
  };

  factory Workout.fromJson(Map<String, Object?> json) => Workout(
    id: json['id'] as String,
    type: WorkoutType.fromName(json['type'] as String?),
    minutes: (json['minutes'] as num).toInt(),
    intensity: Intensity.fromName(json['intensity'] as String?),
    // UTC strings -> local time.
    date: DateTime.parse(json['date'] as String).toLocal(),
    calories: (json['calories'] as num).toInt(),
    notes: json['notes'] as String? ?? '',
  );
}

class WeightEntry {
  const WeightEntry({required this.date, required this.kg});

  final DateTime date;
  final double kg;

  Map<String, Object?> toJson() => {'date': date.toIso8601String(), 'kg': kg};

  factory WeightEntry.fromJson(Map<String, Object?> json) => WeightEntry(
    date: DateTime.parse(json['date'] as String).toLocal(),
    kg: (json['kg'] as num).toDouble(),
  );
}

class Profile {
  const Profile({
    this.name = '',
    this.weightKg = 70,
    this.heightCm,
    this.dailyMinutesGoal = 30,
    this.weeklyWorkoutsGoal = 4,
    this.onboarded = false,
  });

  final String name;
  final double weightKg;

  /// Null until the user enters it (needed for BMI).
  final double? heightCm;
  final int dailyMinutesGoal;
  final int weeklyWorkoutsGoal;
  final bool onboarded;

  Profile copyWith({
    String? name,
    double? weightKg,
    double? heightCm,
    int? dailyMinutesGoal,
    int? weeklyWorkoutsGoal,
    bool? onboarded,
  }) => Profile(
    name: name ?? this.name,
    weightKg: weightKg ?? this.weightKg,
    heightCm: heightCm ?? this.heightCm,
    dailyMinutesGoal: dailyMinutesGoal ?? this.dailyMinutesGoal,
    weeklyWorkoutsGoal: weeklyWorkoutsGoal ?? this.weeklyWorkoutsGoal,
    onboarded: onboarded ?? this.onboarded,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'dailyMinutesGoal': dailyMinutesGoal,
    'weeklyWorkoutsGoal': weeklyWorkoutsGoal,
    'onboarded': onboarded,
  };

  factory Profile.fromJson(Map<String, Object?> json) => Profile(
    name: json['name'] as String? ?? '',
    weightKg: (json['weightKg'] as num?)?.toDouble() ?? 70,
    heightCm: (json['heightCm'] as num?)?.toDouble(),
    dailyMinutesGoal: (json['dailyMinutesGoal'] as num?)?.toInt() ?? 30,
    weeklyWorkoutsGoal: (json['weeklyWorkoutsGoal'] as num?)?.toInt() ?? 4,
    onboarded: json['onboarded'] as bool? ?? false,
  );

  /// Body mass index, or null without a height.
  double? get bmi => heightCm == null
      ? null
      : weightKg / ((heightCm! / 100) * (heightCm! / 100));
}

/// WHO adult BMI ranges.
enum BmiCategory {
  underweight('Underweight', Color(0xFF3DA5FF)),
  healthy('Healthy weight', Color(0xFF22C55E)),
  overweight('Overweight', Color(0xFFF59E0B)),
  obese('Obese', Color(0xFFEF4444));

  const BmiCategory(this.label, this.color);

  final String label;
  final Color color;

  static BmiCategory of(double bmi) => bmi < 18.5
      ? underweight
      : bmi < 25
      ? healthy
      : bmi < 30
      ? overweight
      : obese;
}

// ---- Exercise library ----

enum MuscleGroup {
  chest('Chest', Icons.fitness_center, Color(0xFFFF5F6D), Color(0xFFFFA45B)),
  back('Back', Icons.fitness_center, Color(0xFF2F80ED), Color(0xFF56CCF2)),
  shoulders(
    'Shoulders',
    Icons.fitness_center,
    Color(0xFFF7971E),
    Color(0xFFFFC837),
  ),
  arms('Arms', Icons.sports_mma, Color(0xFF8E2DE2), Color(0xFFB36BFF)),
  legs('Legs', Icons.fitness_center, Color(0xFF0BA360), Color(0xFF3CD48B)),
  core('Core', Icons.center_focus_strong, Color(0xFFFC466B), Color(0xFF7B5CFF)),
  cardio('Cardio', Icons.monitor_heart, Color(0xFFEB3349), Color(0xFFF45C43));

  const MuscleGroup(this.label, this.icon, this.color, this.color2);

  final String label;
  final IconData icon;
  final Color color;

  /// Second gradient color for cards.
  final Color color2;
}

enum Place {
  gym('Gym', Icons.fitness_center),
  home('Home', Icons.home_outlined);

  const Place(this.label, this.icon);

  final String label;
  final IconData icon;

  static Place fromName(String? name) => values.asNameMap()[name] ?? Place.gym;
}

enum ExerciseMode { reps, time }

enum Level {
  beginner('Beginner', 1),
  intermediate('Intermediate', 2),
  advanced('Advanced', 3);

  const Level(this.label, this.bolts);

  final String label;

  /// Difficulty shown as 1-3 bolt icons.
  final int bolts;

  static Level fromName(String? name) =>
      values.asNameMap()[name] ?? Level.beginner;
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.group,
    required this.place,
    required this.equipment,
    required this.mode,
    required this.level,
    required this.sets,
    required this.reps,
    required this.seconds,
    required this.rest,
    required this.muscles,
    required this.steps,
    required this.mistakes,
    required this.tip,
  });

  final String id;
  final String name;
  final MuscleGroup group;
  final Place place;
  final String equipment;
  final ExerciseMode mode;
  final Level level;
  final int sets;
  final int reps;
  final int seconds;
  final int rest;
  final String muscles;
  final List<String> steps;
  final List<String> mistakes;
  final String tip;

  bool get isTimed => mode == ExerciseMode.time;

  /// Our own video file (web/videos/), used when it exists.
  String get videoFile => 'videos/$id.mp4';

  /// Its thumbnail, made by `npm run compress-videos`.
  String get posterFile => 'videos/$id.jpg';
}

/// One exercise inside a routine, with the sets/reps the user chose.
class RoutineItem {
  RoutineItem({
    required this.exercise,
    int? sets,
    int? reps,
    int? seconds,
    int? rest,
  }) : sets = sets ?? exercise.sets,
       reps = reps ?? exercise.reps,
       seconds = seconds ?? exercise.seconds,
       rest = rest ?? exercise.rest;

  final Exercise exercise;
  final int sets;
  final int reps;
  final int seconds;
  final int rest;

  /// Target shown to the user, e.g. "12 reps" or "0:45".
  String get target => exercise.isTimed ? formatSeconds(seconds) : '$reps reps';

  /// Rough duration estimate: 3 s per rep, plus rest between sets.
  int get estimatedSeconds =>
      sets * (exercise.isTimed ? seconds : reps * 3) + rest * (sets - 1);

  RoutineItem copyWith({int? sets, int? reps, int? seconds, int? rest}) =>
      RoutineItem(
        exercise: exercise,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        seconds: seconds ?? this.seconds,
        rest: rest ?? this.rest,
      );
}

class Routine {
  const Routine({
    required this.name,
    required this.items,
    required this.place,
    this.group,
    this.note,
    this.restSeconds,
  });

  final String name;
  final List<RoutineItem> items;
  final Place place;
  final MuscleGroup? group;

  /// Short advice shown above the exercise list.
  final String? note;

  /// Rest for this routine, instead of the user's setting (e.g. circuits).
  final int? restSeconds;

  int get totalSets => items.fold(0, (sum, i) => sum + i.sets);

  int get estimatedMinutes {
    final seconds = items.fold(0, (sum, i) => sum + i.estimatedSeconds);
    return (seconds + 20 * (items.length - 1)) ~/ 60 + 1;
  }

  /// How a finished routine is logged in the history.
  WorkoutType get workoutType {
    final cardio = group == null
        ? items.isNotEmpty &&
              items.every((i) => i.exercise.group == MuscleGroup.cardio)
        : group == MuscleGroup.cardio;
    return cardio ? WorkoutType.hiit : WorkoutType.strength;
  }
}

String formatSeconds(int seconds) {
  final m = seconds ~/ 60, s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
