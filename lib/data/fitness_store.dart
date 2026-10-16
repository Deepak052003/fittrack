import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import '../utils/format.dart';

/// All app data, saved on the device (localStorage on web).
class FitnessStore extends ChangeNotifier {
  FitnessStore._(this._prefs) {
    _workouts = _readList(_kWorkouts, Workout.fromJson)..sort(_newestFirst);
    _weights = _readList(_kWeights, WeightEntry.fromJson)..sort(_oldestFirst);
    _profile = _readProfile();
    _place = Place.fromName(_prefs.getString(_kPlace));
    _level = Level.fromName(_prefs.getString(_kLevel));
    _restSeconds = _prefs.getInt(_kRest) ?? 60;
    _themeMode =
        ThemeMode.values.asNameMap()[_prefs.getString(_kTheme)] ??
        ThemeMode.dark; // Dark is the default look.
  }

  static Future<FitnessStore> load() async =>
      FitnessStore._(await SharedPreferences.getInstance());

  static const _kWorkouts = 'workouts';
  static const _kWeights = 'weights';
  static const _kProfile = 'profile';
  static const _kTheme = 'themeMode';
  static const _kPlace = 'place';
  static const _kLevel = 'level';
  static const _kRest = 'restSeconds';
  static const _kInstallSnooze = 'installSnoozedUntil';

  /// Rest options on the Me tab.
  static const restChoices = [30, 45, 60, 90, 120];

  final SharedPreferences _prefs;
  final _random = Random();

  late List<Workout> _workouts;
  late List<WeightEntry> _weights;
  late Profile _profile;
  late ThemeMode _themeMode;
  late Place _place;
  late Level _level;
  late int _restSeconds;

  /// Newest first.
  List<Workout> get workouts => List.unmodifiable(_workouts);

  /// Oldest first.
  List<WeightEntry> get weights => List.unmodifiable(_weights);
  Profile get profile => _profile;
  ThemeMode get themeMode => _themeMode;

  /// Gym or home: which exercise list the Train tab shows.
  Place get place => _place;

  /// Difficulty shown on the Training tab.
  Level get level => _level;

  /// Rest between sets, in seconds (60 by default).
  int get restSeconds => _restSeconds;

  // ---- Queries ----

  Iterable<Workout> workoutsOn(DateTime day) =>
      _workouts.where((w) => isSameDay(w.date, day));

  int minutesOn(DateTime day) =>
      workoutsOn(day).fold(0, (sum, w) => sum + w.minutes);

  List<Workout> workoutsSince(DateTime start) =>
      _workouts.where((w) => !w.date.isBefore(start)).toList();

  int get workoutsThisWeek => workoutsSince(startOfWeek(DateTime.now())).length;

  int get totalMinutes => _workouts.fold(0, (sum, w) => sum + w.minutes);

  int get totalCalories => _workouts.fold(0, (sum, w) => sum + w.calories);

  /// Active minutes for each of the last [days] days, oldest first.
  List<int> minutesPerDay(int days) {
    final totals = <String, int>{};
    for (final w in _workouts) {
      final key = dayKey(w.date);
      totals[key] = (totals[key] ?? 0) + w.minutes;
    }
    final today = dateOnly(DateTime.now());
    return [
      for (var i = days - 1; i >= 0; i--)
        totals[dayKey(addDays(today, -i))] ?? 0,
    ];
  }

  /// Days in a row with a workout, ending today or yesterday.
  int get streak {
    final activeDays = {for (final w in _workouts) dayKey(w.date)};
    var day = dateOnly(DateTime.now());
    if (!activeDays.contains(dayKey(day))) day = addDays(day, -1);
    var count = 0;
    while (activeDays.contains(dayKey(day))) {
      count++;
      day = addDays(day, -1);
    }
    return count;
  }

  // ---- Workouts ----

  /// Saves a workout and returns its id.
  String addWorkout({
    required WorkoutType type,
    required int minutes,
    required Intensity intensity,
    required DateTime date,
    String notes = '',
  }) {
    final id =
        '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
        '${_random.nextInt(1 << 20).toRadixString(36)}';
    _workouts.add(_buildWorkout(id, type, minutes, intensity, date, notes));
    _saveWorkouts();
    return id;
  }

  void updateWorkout(
    String id, {
    required WorkoutType type,
    required int minutes,
    required Intensity intensity,
    required DateTime date,
    String notes = '',
  }) {
    final index = _workouts.indexWhere((w) => w.id == id);
    if (index == -1) return;
    _workouts[index] = _buildWorkout(id, type, minutes, intensity, date, notes);
    _saveWorkouts();
  }

  void deleteWorkout(String id) {
    _workouts.removeWhere((w) => w.id == id);
    _saveWorkouts();
  }

  /// Re-adds a deleted workout (used by "Undo").
  void restoreWorkout(Workout workout) {
    if (_workouts.any((w) => w.id == workout.id)) return;
    _workouts.add(workout);
    _saveWorkouts();
  }

  Workout _buildWorkout(
    String id,
    WorkoutType type,
    int minutes,
    Intensity intensity,
    DateTime date,
    String notes,
  ) => Workout(
    id: id,
    type: type,
    minutes: minutes,
    intensity: intensity,
    date: date,
    notes: notes,
    calories: estimateCalories(
      type: type,
      intensity: intensity,
      minutes: minutes,
      weightKg: _profile.weightKg,
    ),
  );

  void _saveWorkouts() {
    _workouts.sort(_newestFirst);
    _write(_kWorkouts, [for (final w in _workouts) w.toJson()]);
    notifyListeners();
  }

  // ---- Weight ----

  /// Logs today's weight (replacing an earlier entry from today).
  void logWeight(double kg) {
    final now = DateTime.now();
    _weights
      ..removeWhere((e) => isSameDay(e.date, now))
      ..add(WeightEntry(date: now, kg: kg))
      ..sort(_oldestFirst);
    _saveWeights();
  }

  void deleteWeight(WeightEntry entry) {
    _weights.remove(entry);
    _saveWeights();
  }

  void _saveWeights() {
    if (_weights.isNotEmpty) {
      _profile = _profile.copyWith(weightKg: _weights.last.kg);
      _write(_kProfile, _profile.toJson());
    }
    _write(_kWeights, [for (final e in _weights) e.toJson()]);
    notifyListeners();
  }

  // ---- Profile & settings ----

  void completeOnboarding({
    required String name,
    required double weightKg,
    double? heightCm,
    int weeklyWorkoutsGoal = 4,
  }) {
    _profile = _profile.copyWith(
      name: name.trim(),
      heightCm: heightCm,
      weeklyWorkoutsGoal: weeklyWorkoutsGoal,
      onboarded: true,
    );
    logWeight(weightKg);
  }

  void updateProfile(Profile profile) {
    _profile = profile;
    _write(_kProfile, _profile.toJson());
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    unawaited(_prefs.setString(_kTheme, mode.name));
    notifyListeners();
  }

  void setLevel(Level level) {
    _level = level;
    unawaited(_prefs.setString(_kLevel, level.name));
    notifyListeners();
  }

  void setPlace(Place place) {
    _place = place;
    unawaited(_prefs.setString(_kPlace, place.name));
    notifyListeners();
  }

  /// The automatic "Install app" prompt may be shown now.
  bool get installPromptDue =>
      DateTime.now().millisecondsSinceEpoch >=
      (_prefs.getInt(_kInstallSnooze) ?? 0);

  /// Waits [wait] before showing the install prompt again.
  void snoozeInstallPrompt(Duration wait) => unawaited(
    _prefs.setInt(
      _kInstallSnooze,
      DateTime.now().add(wait).millisecondsSinceEpoch,
    ),
  );

  void setRestSeconds(int seconds) {
    _restSeconds = seconds;
    unawaited(_prefs.setInt(_kRest, seconds));
    notifyListeners();
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
    'app': 'FitTrack',
    'exportedAt': DateTime.now().toIso8601String(),
    'profile': _profile.toJson(),
    'workouts': [for (final w in _workouts) w.toJson()],
    'weights': [for (final e in _weights) e.toJson()],
  });

  /// Deletes everything except the theme preference.
  Future<void> resetAll() async {
    for (final key in [_kWorkouts, _kWeights, _kProfile]) {
      await _prefs.remove(key);
    }
    _workouts = [];
    _weights = [];
    _profile = const Profile();
    notifyListeners();
  }

  // ---- Persistence helpers ----

  void _write(String key, Object value) =>
      unawaited(_prefs.setString(key, jsonEncode(value)));

  Object? _decode(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException catch (e) {
      debugPrint('Ignoring corrupt "$key" data: $e');
      return null;
    }
  }

  /// Reads a saved list, skipping only the entries that cannot be read.
  List<T> _readList<T>(String key, T Function(Map<String, Object?>) fromJson) {
    final data = _decode(key);
    if (data is! List) return [];
    final out = <T>[];
    for (final item in data) {
      try {
        out.add(fromJson((item as Map).cast()));
      } catch (e) {
        debugPrint('Skipping a corrupt "$key" entry: $e');
      }
    }
    return out;
  }

  Profile _readProfile() {
    try {
      final data = _decode(_kProfile) as Map?;
      return data == null ? const Profile() : Profile.fromJson(data.cast());
    } catch (e) {
      debugPrint('Ignoring corrupt "$_kProfile" data: $e');
      return const Profile();
    }
  }

  static int _newestFirst(Workout a, Workout b) => b.date.compareTo(a.date);
  static int _oldestFirst(WeightEntry a, WeightEntry b) =>
      a.date.compareTo(b.date);
}

/// Gives screens the store and rebuilds them when it changes.
class StoreScope extends InheritedNotifier<FitnessStore> {
  const StoreScope({
    super.key,
    required FitnessStore store,
    required super.child,
  }) : super(notifier: store);

  /// Store + rebuild on change (use in build).
  static FitnessStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  /// Store, no rebuild (use in callbacks).
  static FitnessStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
