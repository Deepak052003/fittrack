# FitTrack code guide (for a .NET developer new to Dart/Flutter)

## 1. .NET → Flutter, in one table

| In .NET you know… | In this app it is… | File |
| --- | --- | --- |
| `Program.cs` / `Main` | `main()` | `lib/main.dart` |
| `Startup` / DI container | `FitTrackApp` creates the store and `StoreScope` hands it to every screen | `lib/app.dart` |
| Controller / ViewModel | `FitnessStore` (all data + save/load) and `SessionController` (workout timer logic) | `lib/data/` |
| Models / POCOs | `Workout`, `Profile`, `Exercise`, `Routine` | `lib/models.dart` |
| Razor views / XAML | Widgets. Each screen is a class with a `build()` method that returns the UI tree | `lib/screens/` |
| User controls / partials | Small reusable widgets | `lib/widgets/` |
| Repository + database | `shared_preferences` (key/value store; `localStorage` in the browser) | `lib/data/fitness_store.dart` |
| Seed data | The exercise catalog (a `const` list) | `lib/data/exercise_catalog.dart` |
| `INotifyPropertyChanged` | `ChangeNotifier` + `notifyListeners()` | store and session controller |
| Unit tests (xUnit) | `flutter test` with `test/*.dart` | `test/` |
| `wwwroot` | `web/` (index.html, manifest, icons) | `web/` |

Two Dart habits that differ from C#:
- There are no `public`/`private` keywords. A name starting with `_` is private to its file.
- Almost everything is immutable (`final`, `const`). To "change" an object you make a copy (`copyWith`).

## 2. Reading order (about 1 hour)

Read in this order; each file builds on the previous one.

1. `lib/main.dart` (10 lines). Loads saved data, then runs the app.
2. `lib/models.dart`. Plain data classes and enums. Note `toJson`/`fromJson`: that is how data is saved.
3. `lib/data/fitness_store.dart`. The "controller". Start with `addWorkout()` and follow it to `_saveWorkouts()` and `notifyListeners()`. Then look at `StoreScope` at the bottom: `StoreScope.of(context)` is how a screen gets the store.
4. `lib/app.dart`. The root widget: theme, and the gate that shows onboarding or the home screen.
5. `lib/screens/home_shell.dart`. The tab bar. The `switch (_index)` picks which screen to show.
6. `lib/screens/training_screen.dart`. A typical screen: reads from the store, builds cards.
7. `lib/widgets/workout_widgets.dart`. The "Log workout" bottom sheet: a form with local state (`setState`).
8. `lib/data/session_controller.dart` then `lib/screens/session_screen.dart`. Logic first, UI second. The screen only draws what the controller says.
9. `lib/screens/routine_screen.dart` → `exercise_detail_screen.dart`, and `report_screen.dart` / `profile_screen.dart` (the Me tab). Navigation with `Navigator.push`.
10. `lib/pwa/` and `web/index.html`. The browser bridge (install button, beep, keep screen on).

## 3. Follow one click end to end

"Start" on a workout page (e.g. Chest Beginner):

1. `training_screen.dart`: tapping a body-part card pushes `RoutineScreen` with `routineFor(group, place, level)` from `data/exercises.dart`.
2. `routine_screen.dart`: the Start button pushes `SessionScreen` (the tune icon opens `start_workout_sheet.dart` to adjust sets/reps).
3. `screens/session_screen.dart`: creates a `SessionController` and a `Timer` that calls `controller.tick()` 4× per second.
4. `data/session_controller.dart`: `startSet()`, `finishSet()`, `tick()` move between `ready → work → rest → done` and call `notifyListeners()`.
5. `session_screen.dart`: `ListenableBuilder` rebuilds the UI on every notify. The `switch (c.phase)` chooses which view to draw.
6. When the workout ends, `_saveWhenDone()` calls `StoreScope.read(context).addWorkout(...)`; the Training and Report tabs update automatically because they use `StoreScope.of(context)`.

`StoreScope.of` = "give me the store and rebuild me when it changes". `StoreScope.read` = "give me the store, no rebuild" (use inside button handlers).

## 4. Debugging (VS Code)

1. Install the **Flutter** extension (VS Code will suggest it; the SDK path is already set in `.vscode/settings.json`).
2. Press **F5** → "FitTrack (Chrome)". The app opens in Chrome.
3. Set a breakpoint by clicking left of a line number, e.g. in `SessionController.finishSet()`. Start a workout, press "Done set", and execution stops there. Hover variables, use the Debug Console, step with F10/F11, like in Visual Studio.
4. **Hot reload**: edit any `build()` method, save, and the running app updates in about a second without restarting (Ctrl+S with the debugger attached). If something looks stale, use hot restart (Ctrl+Shift+F5).
5. `debugPrint('value: $x')` is `Console.WriteLine`. Output appears in the Debug Console.
6. **Widget Inspector** (Flutter DevTools icon in the debug toolbar) shows the widget tree and lets you click an element on screen to jump to its code.
7. Red error screen = unhandled exception. The message names the widget and line. Most common: a `RenderFlex overflowed` (a row/column is too big for the screen) or a null value.

Tests: open the Testing side-bar or run `flutter test`. Start with `test/session_controller_test.dart`: it drives the controller with a fake clock, so you can see the state machine without any UI.

## 5. Common tasks

**Add an exercise**: add an `Exercise(...)` entry in `lib/data/exercise_catalog.dart`. Copy a neighbour. It appears in the right muscle group and gym/home list automatically. Its clip is `web/videos/<id>.mp4`.

**Add a field to a workout** (e.g. "distance"): add it to `Workout` in `models.dart`, including `toJson`/`fromJson`; add an input in `workout_widgets.dart`; show it in `WorkoutTile`.

**Add a tab**: add a destination in `home_shell.dart` (`_destinations` list and the `switch`).

**Change colours**: `lib/theme.dart`. The PWA colours live in `web/manifest.json` and `web/index.html`.

**Run checks before deploying**: `flutter analyze` (like the C# compiler warnings), `flutter test`, then `npm run deploy`.

## 6. Dart syntax you will meet

```dart
final name = 'Alex';            // var that cannot be reassigned
String? maybe;                  // nullable type (like string? in C#)
maybe ?? 'default';             // null-coalescing, same as C#
list.map((w) => w.minutes)      // LINQ Select
list.where((w) => w.minutes > 10)  // LINQ Where
list.fold(0, (sum, w) => sum + w.minutes)  // LINQ Aggregate
for (final w in workouts) ...   // foreach
'Hello $name, ${w.minutes} min' // string interpolation
switch (phase) { SessionPhase.ready => ..., _ => ... }  // switch expression
Future<void> save() async { await prefs.setString(...); }  // async/await, same idea
```

`Widget build(BuildContext context)` is the one method every screen has. `context` is "where am I in the tree"; `Theme.of(context)` and `StoreScope.of(context)` look upward from there.
