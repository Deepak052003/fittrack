import 'dart:convert';

import 'package:fitness_tracker_app/app.dart';
import 'package:fitness_tracker_app/data/exercises.dart';
import 'package:fitness_tracker_app/data/fitness_store.dart';
import 'package:fitness_tracker_app/models.dart';
import 'package:fitness_tracker_app/utils/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('onboarding saves height and opens Training', (tester) async {
    final store = await FitnessStore.load();
    await tester.pumpWidget(FitTrackApp(store: store));
    expect(find.text('Welcome to FitTrack'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Alex');
    await tester.enterText(find.byType(TextField).at(1), '175');
    await tester.pump();
    expect(find.textContaining('Your BMI: 22.9'), findsOneWidget);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.ensureVisible(find.text('Get started'));
    await tester.pump();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text("Let's train"), findsOneWidget);
    expect(store.profile.heightCm, 175);
    expect(store.profile.name, 'Alex');
  });

  testWidgets('a finished workout is saved to history', (tester) async {
    // Phone-sized screen, like the real app.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = await FitnessStore.load();
    store.completeOnboarding(name: 'Alex', weightKg: 70, heightCm: 175);
    await tester.pumpWidget(FitTrackApp(store: store));
    await tester.pumpAndSettle();

    // Training -> Chest card -> workout page.
    await tester.scrollUntilVisible(
      find.text('Chest'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Bring it to the top, clear of the floating nav bar.
    await tester.ensureVisible(find.text('Chest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chest'));
    await tester.pumpAndSettle();
    expect(find.text('Barbell Bench Press'), findsOneWidget);

    // The session has a running timer, so pump instead of pumpAndSettle.
    await tester.tap(find.text('Start'));
    await step(tester);
    expect(find.text('GET READY'), findsOneWidget); // 10 s countdown
    await tester.tap(find.text('Start now'));
    await step(tester);
    expect(find.text('× 6'), findsOneWidget); // beginner: 8 reps × 0.75

    await tester.tap(find.text('Done'));
    await step(tester);
    expect(find.text('REST'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await step(tester);
    await tester.tap(find.text('Finish workout'));
    await step(tester);

    expect(find.text('WORKOUT COMPLETE'), findsOneWidget);
    expect(store.workouts, hasLength(1));
    expect(store.workouts.single.type, WorkoutType.strength);
  });

  test('store computes calories, totals and streak', () async {
    final store = await FitnessStore.load();
    store.completeOnboarding(name: 'Alex', weightKg: 70, heightCm: 175);
    final now = DateTime.now();
    store.addWorkout(
      type: WorkoutType.running,
      minutes: 30,
      intensity: Intensity.moderate,
      date: now,
    );
    store.addWorkout(
      type: WorkoutType.yoga,
      minutes: 20,
      intensity: Intensity.light,
      date: addDays(now, -1),
    );

    expect(store.minutesOn(now), 30);
    expect(
      store.workoutsOn(now).first.calories,
      343,
    ); // 9.8 MET × 70 kg × 0.5 h
    expect(store.streak, 2);
    expect(store.totalMinutes, 50);
    expect(store.minutesPerDay(7).last, 30);

    final reloaded = await FitnessStore.load();
    expect(reloaded.workouts, hasLength(2));
    expect(reloaded.profile.heightCm, 175);
  });

  test('one corrupt history entry does not drop the others', () async {
    final good = {
      'id': 'a',
      'type': 'running',
      'minutes': 20,
      'intensity': 'moderate',
      'date': DateTime(2026, 10, 1, 7).toIso8601String(),
      'calories': 200,
    };
    SharedPreferences.setMockInitialValues({
      'workouts': jsonEncode([
        good,
        {'id': 'b', 'type': 'running', 'date': 'not a date'},
      ]),
    });
    final store = await FitnessStore.load();
    expect(store.workouts.map((w) => w.id), ['a']);
  });

  test('BMI and its category', () {
    const profile = Profile(weightKg: 70, heightCm: 175);
    expect(profile.bmi, closeTo(22.86, 0.01));
    expect(BmiCategory.of(profile.bmi!), BmiCategory.healthy);
    expect(const Profile(weightKg: 70).bmi, isNull);
    expect(BmiCategory.of(17), BmiCategory.underweight);
    expect(BmiCategory.of(27), BmiCategory.overweight);
    expect(BmiCategory.of(31), BmiCategory.obese);
  });

  test('levels scale sets and reps', () {
    final beginner = routineFor(MuscleGroup.chest, Place.gym, Level.beginner);
    final advanced = routineFor(MuscleGroup.chest, Place.gym, Level.advanced);
    expect(beginner.items.first.sets, 2);
    expect(advanced.items.first.sets, 4);
    expect(advanced.items.first.reps, greaterThan(beginner.items.first.reps));
    // The one advanced move (wall walk) is left out for beginners.
    final shoulders = routineFor(
      MuscleGroup.shoulders,
      Place.home,
      Level.beginner,
    );
    expect(shoulders.items.any((i) => i.exercise.id == 'wall-walk'), isFalse);
  });

  test('UTC timestamps are read back as local time', () {
    final local = DateTime(2026, 3, 1, 7, 10);
    final workout = Workout.fromJson({
      'id': 'a',
      'type': 'running',
      'minutes': 30,
      'date': local.toUtc().toIso8601String(),
      'calories': 300,
    });
    expect(workout.date.isUtc, isFalse);
    expect(workout.date, local);
  });
}

/// A new page is shown one frame after it is pushed, so pump twice.
Future<void> step(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}
