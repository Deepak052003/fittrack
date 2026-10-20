import 'package:flutter/material.dart';

import '../models.dart';
import '../pwa/pwa.dart';
import '../screens/session_screen.dart';

/// Adjust sets/reps, then start the session.
Future<void> showStartWorkoutSheet(BuildContext context, Routine routine) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => StartWorkoutSheet(routine: routine),
  );
}

class StartWorkoutSheet extends StatefulWidget {
  const StartWorkoutSheet({super.key, required this.routine});

  final Routine routine;

  @override
  State<StartWorkoutSheet> createState() => _StartWorkoutSheetState();
}

class _StartWorkoutSheetState extends State<StartWorkoutSheet> {
  late var _items = List.of(widget.routine.items);

  Routine get _routine => Routine(
    name: widget.routine.name,
    items: _items,
    place: widget.routine.place,
    group: widget.routine.group,
    note: widget.routine.note,
    restSeconds: widget.routine.restSeconds,
  );

  Future<void> _edit(int index) async {
    final result = await showDialog<Object>(
      context: context,
      builder: (_) =>
          _ItemEditor(item: _items[index], canRemove: _items.length > 1),
    );
    if (result is RoutineItem) {
      setState(() => _items[index] = result);
    } else if (result == _remove) {
      setState(() => _items = List.of(_items)..removeAt(index));
    }
  }

  void _start() {
    // Must run inside the tap so iOS allows the timer beep later.
    Pwa.instance.unlockAudio();
    final navigator = Navigator.of(context);
    final routine = _routine;
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => SessionScreen(routine: routine),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routine = _routine;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            routine.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_items.length} exercises · ${routine.totalSets} sets · '
            '~${routine.estimatedMinutes} min',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final item = _items[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: item.exercise.group.color.withValues(
                      alpha: 0.15,
                    ),
                    foregroundColor: item.exercise.group.color,
                    child: Text('${i + 1}'),
                  ),
                  title: Text(item.exercise.name),
                  subtitle: Text('${item.sets} sets × ${item.target}'),
                  trailing: const Icon(Icons.tune),
                  onTap: () => _edit(i),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _items.length > 1
                ? 'Tap an exercise to change sets or reps, or remove it.'
                : 'Tap the exercise to change sets or reps.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _start,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start workout'),
          ),
        ],
      ),
    );
  }
}

/// Returned by [_ItemEditor] when the user removes the exercise.
const _remove = #remove;

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({required this.item, required this.canRemove});

  final RoutineItem item;
  final bool canRemove;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late var _item = widget.item;

  @override
  Widget build(BuildContext context) {
    final timed = _item.exercise.isTimed;
    return AlertDialog(
      scrollable: true,
      title: Text(_item.exercise.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Stepper(
            label: 'Sets',
            value: _item.sets,
            min: 1,
            max: 10,
            onChanged: (v) => setState(() => _item = _item.copyWith(sets: v)),
          ),
          if (timed)
            _Stepper(
              label: 'Seconds',
              value: _item.seconds,
              min: 5,
              max: 1800,
              step: 5,
              format: formatSeconds,
              onChanged: (v) =>
                  setState(() => _item = _item.copyWith(seconds: v)),
            )
          else
            _Stepper(
              label: 'Reps',
              value: _item.reps,
              min: 1,
              max: 50,
              onChanged: (v) => setState(() => _item = _item.copyWith(reps: v)),
            ),
        ],
      ),
      actions: [
        if (widget.canRemove)
          TextButton(
            onPressed: () => Navigator.pop(context, _remove),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _item),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.format,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String Function(int)? format;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          tooltip: 'Decrease $label',
          onPressed: value - step >= min ? () => onChanged(value - step) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 56,
          child: Text(
            format?.call(value) ?? '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: 'Increase $label',
          onPressed: value + step <= max ? () => onChanged(value + step) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
