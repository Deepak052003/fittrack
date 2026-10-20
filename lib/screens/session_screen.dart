import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/fitness_store.dart';
import '../data/session_controller.dart';
import '../models.dart';
import '../pwa/pwa.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/exercise_video.dart';

/// Workout player: get-ready countdown, form video, reps or timer, rest.
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.routine});

  final Routine routine;

  /// True while a workout is open (app updates wait until it ends).
  static final active = ValueNotifier(false);

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late final _controller =
      SessionController(
          widget.routine,
          restSeconds:
              widget.routine.restSeconds ??
              StoreScope.read(context).restSeconds,
        )
        ..onAlert = _alert
        ..onCountdown = _tick
        ..addListener(_saveWhenDone);
  Timer? _timer;
  late final AppLifecycleListener _lifecycle;
  var _sound = true;
  var _saved = false;

  /// History entry for this session once progress has been saved.
  String? _savedId;

  @override
  void initState() {
    super.initState();
    SessionScreen.active.value = true;
    _timer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _controller.tick(),
    );
    // Leaving the app may end it (reload, phone closes it): keep the progress.
    _lifecycle = AppLifecycleListener(onHide: _saveProgress);
    Pwa.instance.keepAwake(true);
  }

  @override
  void dispose() {
    SessionScreen.active.value = false;
    _timer?.cancel();
    _lifecycle.dispose();
    Pwa.instance.keepAwake(false);
    _controller.dispose();
    super.dispose();
  }

  /// Saves (or updates) the session in the history so far.
  void _saveProgress() {
    final c = _controller;
    if (c.completedSets == 0) return;
    final store = StoreScope.read(context);
    final id = _savedId;
    if (id == null) {
      _savedId = store.addWorkout(
        type: widget.routine.workoutType,
        minutes: c.minutes,
        intensity: Intensity.moderate,
        date: c.startedAt,
        notes: c.summaryNotes,
      );
    } else {
      store.updateWorkout(
        id,
        type: widget.routine.workoutType,
        minutes: c.minutes,
        intensity: Intensity.moderate,
        date: c.startedAt,
        notes: c.summaryNotes,
      );
    }
  }

  void _alert() {
    if (_sound) Pwa.instance.beep(long: true);
    HapticFeedback.heavyImpact();
  }

  // 3-2-1 before a countdown ends.
  void _tick(int secondsLeft) {
    if (_sound) Pwa.instance.beep();
  }

  // Finished workouts go straight to the history.
  void _saveWhenDone() {
    final c = _controller;
    if (_saved || c.phase != SessionPhase.done || c.completedSets == 0) return;
    _saved = true;
    _saveProgress();
  }

  Future<void> _confirmQuit() async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit workout?'),
        content: const Text('This session will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
    if ((quit ?? false) && mounted) {
      // Quitting discards progress saved while the app was in the background.
      final id = _savedId;
      if (id != null) StoreScope.read(context).deleteWorkout(id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AmbientBackground(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          final done = c.phase == SessionPhase.done;
          return PopScope(
            canPop: done,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _confirmQuit();
            },
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                title: Text(
                  widget.routine.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                leading: const CloseButton(),
                actions: [
                  IconButton(
                    tooltip: _sound ? 'Mute' : 'Unmute',
                    icon: Icon(
                      _sound
                          ? Icons.volume_up_outlined
                          : Icons.volume_off_outlined,
                    ),
                    onPressed: () {
                      if (!_sound) {
                        Pwa.instance.unlockAudio();
                        Pwa.instance.beep(); // Lets the user hear it works.
                      }
                      setState(() => _sound = !_sound);
                    },
                  ),
                  if (!done)
                    PopupMenuButton<String>(
                      onSelected: (v) =>
                          v == 'skip' ? c.skipExercise() : c.finishNow(),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'skip',
                          child: Text('Skip exercise'),
                        ),
                        PopupMenuItem(
                          value: 'finish',
                          child: Text('Finish workout'),
                        ),
                      ],
                    ),
                ],
              ),
              body: Column(
                children: [
                  if (!done) _SegmentBar(c),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: switch (c.phase) {
                            SessionPhase.ready => _ReadyView(c),
                            SessionPhase.work => _WorkView(c),
                            SessionPhase.rest => _RestView(c),
                            SessionPhase.done => _DoneView(c, saved: _saved),
                          },
                        ),
                      ),
                    ),
                  ),
                  if (!done) _Footer(c),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One segment per exercise: done, current, upcoming.
class _SegmentBar extends StatelessWidget {
  const _SegmentBar(this.c);

  final SessionController c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        children: [
          for (var i = 0; i < c.routine.items.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: i <= c.exerciseIndex ? coralGradient : null,
                  color: i <= c.exerciseIndex ? null : glassEdge(context),
                ),
                foregroundDecoration: i == c.exerciseIndex
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Theme.of(context).colorScheme.surface
                            .withValues(alpha: 0.45),
                      )
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Video, then the exercise name and "Set 1 of 3".
class _Header extends StatelessWidget {
  const _Header(this.c, {required this.label});

  final SessionController c;
  final String label;

  @override
  Widget build(BuildContext context) {
    final e = c.item.exercise;
    return Column(
      children: [
        ExerciseClip(key: ValueKey(e.id), exercise: e),
        const SizedBox(height: 20),
        TrackedLabel(label, color: coral),
        const SizedBox(height: 6),
        Text(
          e.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        // One short form cue; the full steps stay on the exercise page.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lightbulb_outline, size: 16, color: coral),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  e.tip,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 10-second countdown; the set starts by itself.
class _ReadyView extends StatelessWidget {
  const _ReadyView(this.c);

  final SessionController c;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = c.item;
    return Column(
      children: [
        _Header(c, label: 'Get ready'),
        const SizedBox(height: 4),
        TrackedLabel(
          'Set ${c.set} of ${item.sets} · '
          '${item.exercise.isTimed ? item.target : '× ${item.reps}'}',
        ),
        const SizedBox(height: 20),
        ProgressRing(
          progress: 1 - c.remaining / SessionController.readySeconds,
          size: 132,
          strokeWidth: 8,
          child: Text(
            '${c.remaining}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          onPressed: () {
            Pwa.instance.unlockAudio();
            c.startSet();
          },
          icon: Icons.play_arrow,
          label: 'Start now',
        ),
        const SizedBox(height: 4),
        _PauseButton(c),
      ],
    );
  }
}

class _WorkView extends StatelessWidget {
  const _WorkView(this.c);

  final SessionController c;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = c.item;
    final timed = item.exercise.isTimed;

    return Column(
      children: [
        _Header(c, label: 'Set ${c.set} of ${item.sets}'),
        const SizedBox(height: 16),
        if (timed)
          ProgressRing(
            progress: 1 - c.remaining / item.seconds,
            size: 168,
            strokeWidth: 10,
            child: Text(
              formatSeconds(c.remaining),
              style: theme.textTheme.displaySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          )
        else ...[
          ShaderMask(
            shaderCallback: coralGradient.createShader,
            child: Text(
              '× ${item.reps}',
              style: theme.textTheme.displayLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          Text(
            formatSeconds(c.phaseElapsed.inSeconds),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
        const SizedBox(height: 24),
        GradientButton(
          onPressed: c.finishSet,
          icon: Icons.check,
          label: timed ? 'Done early' : 'Done',
        ),
        const SizedBox(height: 4),
        _PauseButton(c),
      ],
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton(this.c);

  final SessionController c;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: c.togglePause,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      icon: Icon(c.paused ? Icons.play_arrow : Icons.pause),
      label: Text(c.paused ? 'Resume' : 'Pause'),
    );
  }
}

/// Big coral countdown with the next exercise below.
class _RestView extends StatelessWidget {
  const _RestView(this.c);

  final SessionController c;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = c.item;

    return Column(
      children: [
        const TrackedLabel('Rest', color: coral, size: 12),
        const SizedBox(height: 16),
        ProgressRing(
          progress: c.restTarget == 0 ? 1 : 1 - c.remaining / c.restTarget,
          size: 210,
          strokeWidth: 10,
          child: Text(
            formatSeconds(c.remaining),
            style: theme.textTheme.displayMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => c.addRest(15),
          icon: const Icon(Icons.add),
          label: const Text('15 s'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: c.togglePause,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: Icon(c.paused ? Icons.play_arrow : Icons.pause),
                label: Text(c.paused ? 'Resume' : 'Pause'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GradientButton(
                onPressed: c.skipRest,
                icon: Icons.skip_next,
                label: 'Skip',
                height: 52,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrackedLabel(
                  'Next · ${c.exerciseIndex + 1}/${c.routine.items.length}',
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        next.exercise.name,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      next.exercise.isTimed ? next.target : '× ${next.reps}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: coral,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Set ${c.set} of ${next.sets}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ExerciseClip(
                  key: ValueKey(next.exercise.id),
                  exercise: next.exercise,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView(this.c, {required this.saved});

  final SessionController c;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final calories = estimateCalories(
      type: c.routine.workoutType,
      intensity: Intensity.moderate,
      minutes: c.minutes,
      weightKg: StoreScope.of(context).profile.weightKg,
    );

    return Column(
      children: [
        const ProgressRing(
          progress: 1,
          size: 120,
          strokeWidth: 8,
          child: Icon(Icons.emoji_events_outlined, size: 48, color: coral),
        ),
        const SizedBox(height: 20),
        const TrackedLabel('Workout complete', color: coral),
        const SizedBox(height: 6),
        Text(c.routine.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: SummaryStat(
                    label: 'Duration',
                    value: formatSeconds(c.totalElapsed.inSeconds),
                  ),
                ),
                Expanded(
                  child: SummaryStat(
                    label: 'Sets',
                    value: '${c.completedSets}',
                  ),
                ),
                Expanded(
                  child: SummaryStat(label: 'kcal', value: '$calories'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          saved ? 'Saved to your history' : 'No sets done, nothing saved',
          style: muted,
        ),
        const SizedBox(height: 24),
        GradientButton(onPressed: () => Navigator.pop(context), label: 'Done'),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer(this.c);

  final SessionController c;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = c.nextItem;
    final muted = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              formatSeconds(c.totalElapsed.inSeconds),
              style: theme.textTheme.labelLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            // The rest view already shows what is next.
            if (c.phase != SessionPhase.rest)
              Flexible(
                child: Text(
                  next == null
                      ? 'Last exercise'
                      : 'Up next: ${next.exercise.name}',
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
