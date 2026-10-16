import 'package:fitness_tracker_app/data/exercises.dart';
import 'package:fitness_tracker_app/data/session_controller.dart';
import 'package:fitness_tracker_app/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  DateTime clock() => now;
  void advance(int seconds) => now = now.add(Duration(seconds: seconds));

  setUp(() => now = DateTime(2026, 10, 15, 7));

  Routine routine() => Routine(
    name: 'Test',
    place: Place.home,
    group: MuscleGroup.core,
    items: [
      RoutineItem(
        exercise: exerciseById('push-up')!,
        sets: 2,
        reps: 5,
        rest: 30,
      ),
      RoutineItem(
        exercise: exerciseById('plank')!,
        sets: 1,
        seconds: 20,
        rest: 0,
      ),
    ],
  );

  test('reps set, rest countdown, then next set', () {
    final c = SessionController(routine(), clock: clock);
    expect(c.phase, SessionPhase.ready);

    c.startSet();
    c.finishSet();
    expect(c.phase, SessionPhase.rest);
    expect(c.set, 2);
    expect(c.remaining, 30);

    advance(10);
    c.tick();
    expect(c.remaining, 20);

    advance(20);
    var alerted = false;
    c.onAlert = () => alerted = true;
    c.tick();
    expect(alerted, isTrue);
    expect(c.phase, SessionPhase.work); // rest leads straight into the set
    expect(c.completedSets, 1);
  });

  test('rest setting replaces rest; +15 s extends it; no-rest stays', () {
    final c = SessionController(routine(), restSeconds: 90, clock: clock);
    c.startSet();
    c.finishSet();
    expect(c.remaining, 90);

    advance(80);
    c.addRest(15);
    c.tick();
    expect(c.phase, SessionPhase.rest);
    expect(c.remaining, 25);

    final noRest = SessionController(
      Routine(
        name: 'Plank',
        place: Place.home,
        items: [
          RoutineItem(exercise: exerciseById('plank')!, sets: 2, rest: 0),
        ],
      ),
      restSeconds: 90,
      clock: clock,
    );
    noRest.startSet();
    noRest.finishSet();
    expect(noRest.phase, SessionPhase.ready); // straight to the next set
  });

  test('beeps at 3, 2, 1 before a countdown ends, not during reps', () {
    final c = SessionController(routine(), clock: clock);
    final cues = <int>[];
    c.onCountdown = cues.add;
    for (var i = 0; i < 40; i++) {
      advance(1);
      c.tick();
      c.tick(); // ticks run several times a second
    }
    expect(cues, [3, 2, 1]); // ready countdown; then a reps set (no timer)
    c.finishSet();
    for (var i = 0; i < 30; i++) {
      advance(1);
      c.tick();
    }
    expect(cues, [3, 2, 1, 3, 2, 1]); // 30 s rest
  });

  test('get-ready countdown starts the set after 10 s', () {
    final c = SessionController(routine(), clock: clock);
    var alerted = false;
    c.onAlert = () => alerted = true;
    expect(c.remaining, SessionController.readySeconds);

    advance(4);
    c.tick();
    expect(c.phase, SessionPhase.ready);
    expect(c.remaining, 6);

    c.togglePause(); // the countdown can be paused too
    advance(30);
    c.tick();
    expect(c.phase, SessionPhase.ready);

    c.togglePause();
    advance(6);
    c.tick();
    expect(alerted, isTrue);
    expect(c.phase, SessionPhase.work);
  });

  test('timed set finishes itself and the session ends', () {
    final c = SessionController(routine(), clock: clock);
    c.skipExercise();
    expect(c.item.exercise.id, 'plank');

    c.startSet();
    advance(5);
    c.togglePause();
    advance(60);
    c.tick();
    expect(c.phase, SessionPhase.work);
    expect(c.remaining, 15);

    c.togglePause();
    advance(15);
    c.tick();
    expect(c.phase, SessionPhase.done);
    expect(c.completedSets, 1);
    expect(c.minutes, 1);
    expect(c.summaryNotes, 'Test · 2 exercises · 1 sets');
  });

  test('paused time is not counted', () {
    final c = SessionController(routine(), clock: clock);
    c.startSet();
    advance(30);
    c.togglePause();
    advance(900);
    expect(c.totalElapsed, const Duration(seconds: 30));
    c.togglePause();
    advance(30);
    c.finishNow();
    advance(60);
    expect(c.totalElapsed, const Duration(seconds: 60));
    expect(c.minutes, 1);
  });

  test('custom cardio-only routine is logged as HIIT', () {
    Routine custom(List<String> ids) => Routine(
      name: 'Custom',
      place: Place.gym,
      items: [for (final id in ids) RoutineItem(exercise: exerciseById(id)!)],
    );
    expect(
      custom(['treadmill-run', 'stationary-bike']).workoutType,
      WorkoutType.hiit,
    );
    expect(
      custom(['treadmill-run', 'lat-pulldown']).workoutType,
      WorkoutType.strength,
    );
  });

  test('catalog has every group for gym and home', () {
    for (final group in MuscleGroup.values) {
      for (final place in Place.values) {
        final list = exercisesFor(group, place);
        expect(list, isNotEmpty, reason: '${group.name}/${place.name}');
        for (final e in list) {
          expect(e.steps.length, inInclusiveRange(4, 6), reason: e.id);
          expect(e.isTimed ? e.seconds : e.reps, greaterThan(0), reason: e.id);
        }
      }
    }
    expect(
      routineFor(MuscleGroup.legs, Place.gym).estimatedMinutes,
      greaterThan(10),
    );
  });
}
