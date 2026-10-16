import 'package:flutter/material.dart';

import '../data/exercises.dart';
import '../data/fitness_store.dart';
import '../models.dart';
import '../widgets/common.dart';
import '../widgets/start_workout_sheet.dart';

/// Pick any exercises, then start them as one session.
class CustomWorkoutScreen extends StatefulWidget {
  const CustomWorkoutScreen({super.key});

  @override
  State<CustomWorkoutScreen> createState() => _CustomWorkoutScreenState();
}

class _CustomWorkoutScreenState extends State<CustomWorkoutScreen> {
  late Place _place = StoreScope.read(context).place;
  final _selected = <Exercise>[];

  void _toggle(Exercise e, bool on) =>
      setState(() => on ? _selected.add(e) : _selected.remove(e));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom workout')),
      floatingActionButton: _selected.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showStartWorkoutSheet(
                context,
                Routine(
                  name: 'Custom workout',
                  place: _place,
                  items: [for (final e in _selected) RoutineItem(exercise: e)],
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: Text('Start (${_selected.length})'),
            ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: PageScaffold.maxContentWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              SegmentedButton<Place>(
                segments: [
                  for (final p in Place.values)
                    ButtonSegment(
                      value: p,
                      icon: Icon(p.icon),
                      label: Text(p.label),
                    ),
                ],
                selected: {_place},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() {
                  _place = s.first;
                  _selected.removeWhere((e) => e.place != _place);
                }),
              ),
              for (final group in MuscleGroup.values) ...[
                SectionHeader(group.label),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final e in exercisesFor(group, _place))
                        CheckboxListTile(
                          value: _selected.contains(e),
                          onChanged: (v) => _toggle(e, v ?? false),
                          title: Text(e.name),
                          subtitle: Text(
                            '${e.sets} × ${RoutineItem(exercise: e).target} · ${e.equipment}',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
