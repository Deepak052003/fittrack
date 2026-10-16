import 'package:flutter/foundation.dart';

import '../models.dart';

enum SessionPhase { ready, work, rest, done }

/// Workout session logic: sets, reps and timers. Call [tick] often.
class SessionController extends ChangeNotifier {
  SessionController(
    this.routine, {
    this.restSeconds,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _startedAt = _phaseStart = _clock();
  }

  final Routine routine;

  /// The user's rest setting; replaces each exercise's rest
  /// (exercises with no rest, like cardio machines, keep none).
  final int? restSeconds;
  final DateTime Function() _clock;

  /// Get-ready countdown before an exercise starts by itself.
  static const readySeconds = 10;

  /// Called when a countdown finishes (used for the beep).
  VoidCallback? onAlert;

  /// Called at 3, 2 and 1 seconds left in a countdown.
  void Function(int secondsLeft)? onCountdown;
  int? _lastCue;

  late final DateTime _startedAt;
  DateTime? _endedAt;
  late DateTime _phaseStart;
  DateTime? _pausedAt;
  Duration _pausedTotal = Duration.zero;
  Duration _sessionPaused = Duration.zero;

  SessionPhase phase = SessionPhase.ready;
  int exerciseIndex = 0;
  int set = 1;
  int completedSets = 0;
  int restTarget = 0;

  RoutineItem get item => routine.items[exerciseIndex];
  RoutineItem? get nextItem =>
      isLastExercise ? null : routine.items[exerciseIndex + 1];
  bool get isLastExercise => exerciseIndex == routine.items.length - 1;
  bool get paused => _pausedAt != null;
  DateTime get startedAt => _startedAt;

  /// Active time; pauses are not counted.
  Duration get totalElapsed =>
      (_pausedAt ?? _endedAt ?? _clock()).difference(_startedAt) -
      _sessionPaused;
  double get progress =>
      routine.totalSets == 0 ? 0 : completedSets / routine.totalSets;

  Duration get phaseElapsed =>
      (_pausedAt ?? _clock()).difference(_phaseStart) - _pausedTotal;

  /// Seconds left in the get-ready countdown, a timed set or a rest.
  int get remaining {
    final target = switch (phase) {
      SessionPhase.ready => readySeconds,
      SessionPhase.work when item.exercise.isTimed => item.seconds,
      SessionPhase.rest => restTarget,
      _ => 0,
    };
    return (target - phaseElapsed.inSeconds).clamp(0, 1 << 20);
  }

  /// Starts now instead of waiting for the countdown.
  void startSet() {
    if (phase == SessionPhase.ready) _startWork();
  }

  void finishSet() {
    if (phase != SessionPhase.work) return;
    completedSets++;
    if (set < item.sets) {
      set++;
      _rest(_restFor(item));
    } else if (!isLastExercise) {
      final rest = _restFor(item);
      exerciseIndex++;
      set = 1;
      _rest(rest);
    } else {
      _finish();
    }
  }

  void skipRest() {
    if (phase == SessionPhase.rest) _startWork();
  }

  /// Adds time to the current rest (the "+15 s" button).
  void addRest(int seconds) {
    if (phase != SessionPhase.rest) return;
    restTarget += seconds;
    notifyListeners();
  }

  void skipExercise() {
    if (isLastExercise) {
      _finish();
    } else {
      exerciseIndex++;
      set = 1;
      _enter(SessionPhase.ready);
    }
  }

  void togglePause() {
    if (phase == SessionPhase.done) return;
    if (_pausedAt == null) {
      _pausedAt = _clock();
    } else {
      _resume();
    }
    notifyListeners();
  }

  void finishNow() => _finish();

  /// Advances countdowns; safe to call often.
  void tick() {
    if (paused || phase == SessionPhase.done) return;
    if (phase == SessionPhase.ready && remaining == 0) {
      onAlert?.call();
      _startWork();
    } else if (phase == SessionPhase.work &&
        item.exercise.isTimed &&
        remaining == 0) {
      onAlert?.call();
      finishSet();
    } else if (phase == SessionPhase.rest && remaining == 0) {
      onAlert?.call();
      _startWork();
    } else {
      final left = remaining;
      final counting = phase != SessionPhase.work || item.exercise.isTimed;
      if (counting && left >= 1 && left <= 3 && left != _lastCue) {
        _lastCue = left;
        onCountdown?.call(left);
      }
      notifyListeners();
    }
  }

  /// Saved with the workout in the history.
  String get summaryNotes =>
      '${routine.name} · ${routine.items.length} exercises · '
      '$completedSets sets';

  int get minutes {
    final m = (totalElapsed.inSeconds / 60).round();
    return m < 1 ? 1 : m;
  }

  int _restFor(RoutineItem i) => i.rest == 0 ? 0 : restSeconds ?? i.rest;

  void _rest(int seconds) {
    if (seconds <= 0) {
      _enter(SessionPhase.ready);
      return;
    }
    restTarget = seconds;
    _enter(SessionPhase.rest);
  }

  void _startWork() => _enter(SessionPhase.work);

  void _resume() {
    final paused = _clock().difference(_pausedAt!);
    _pausedTotal += paused;
    _sessionPaused += paused;
    _pausedAt = null;
  }

  void _finish() {
    if (_pausedAt != null) _resume();
    _endedAt ??= _clock();
    _enter(SessionPhase.done);
  }

  void _enter(SessionPhase next) {
    if (_pausedAt != null) _resume();
    phase = next;
    _lastCue = null;
    _phaseStart = _clock();
    _pausedTotal = Duration.zero;
    notifyListeners();
  }
}
