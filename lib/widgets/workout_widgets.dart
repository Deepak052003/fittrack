import 'package:flutter/material.dart';

import '../data/fitness_store.dart';
import '../models.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'common.dart';

class WorkoutTile extends StatelessWidget {
  const WorkoutTile({super.key, required this.workout, this.onTap});

  final Workout workout;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = workout;
    final details = [
      formatMinutes(w.minutes),
      w.intensity.label,
      formatTime(context, w.date),
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: TintedIcon(icon: w.type.icon, color: w.type.color),
        title: Text(
          w.type.label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          w.notes.isEmpty ? details : '$details\n${w.notes}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: w.notes.isNotEmpty,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatNumber(w.calories),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text('kcal', style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

/// Deletes [workout] and offers an "Undo" snackbar.
void deleteWorkoutWithUndo(
  FitnessStore store,
  ScaffoldMessengerState messenger,
  Workout workout,
) {
  store.deleteWorkout(workout.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${workout.type.label} deleted'),
        persist: false,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => store.restoreWorkout(workout),
        ),
      ),
    );
}

/// Log a new workout, or edit [initial].
Future<void> showLogWorkoutSheet(
  BuildContext context, {
  WorkoutType? type,
  Workout? initial,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (context) => LogWorkoutSheet(initialType: type, initial: initial),
  );
}

class LogWorkoutSheet extends StatefulWidget {
  const LogWorkoutSheet({super.key, this.initialType, this.initial});

  final WorkoutType? initialType;
  final Workout? initial;

  @override
  State<LogWorkoutSheet> createState() => _LogWorkoutSheetState();
}

class _LogWorkoutSheetState extends State<LogWorkoutSheet> {
  static const _minMinutes = 1.0;
  static const _maxMinutes = 240.0;

  late var _type =
      widget.initial?.type ?? widget.initialType ?? WorkoutType.running;
  late var _minutes = (widget.initial?.minutes ?? 30)
      .clamp(_minMinutes, _maxMinutes)
      .toDouble();
  late var _intensity = widget.initial?.intensity ?? Intensity.moderate;
  late var _date = widget.initial?.date ?? DateTime.now();
  late final _notes = TextEditingController(text: widget.initial?.notes);

  bool get _editing => widget.initial != null;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final yearAgo = DateTime(now.year - 1, now.month, now.day);
    final day = await showDatePicker(
      context: context,
      initialDate: dateOnly(_date),
      firstDate: _date.isBefore(yearAgo) ? dateOnly(_date) : yearAgo,
      lastDate: dateOnly(now),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted) return;
    final t = time ?? TimeOfDay.fromDateTime(_date);
    setState(
      () => _date = DateTime(day.year, day.month, day.day, t.hour, t.minute),
    );
  }

  void _save(int calories) {
    final store = StoreScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final minutes = _minutes.round();
    final notes = _notes.text.trim();
    if (_editing) {
      store.updateWorkout(
        widget.initial!.id,
        type: _type,
        minutes: minutes,
        intensity: _intensity,
        date: _date,
        notes: notes,
      );
    } else {
      store.addWorkout(
        type: _type,
        minutes: minutes,
        intensity: _intensity,
        date: _date,
        notes: notes,
      );
    }
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _editing
                ? 'Workout updated'
                : '${_type.label} logged · ${formatNumber(calories)} kcal',
          ),
        ),
      );
  }

  void _delete() {
    final store = StoreScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    deleteWorkoutWithUndo(store, messenger, widget.initial!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final weightKg = StoreScope.of(context).profile.weightKg;
    final calories = estimateCalories(
      type: _type,
      intensity: _intensity,
      minutes: _minutes.round(),
      weightKg: weightKg,
    );

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: theme.textTheme.labelLarge),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _editing ? 'Edit workout' : 'Log workout',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            label('Activity'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in WorkoutType.values)
                  ChoiceChip(
                    showCheckmark: false,
                    avatar: Icon(
                      t.icon,
                      size: 18,
                      color: t == _type ? scheme.onSecondaryContainer : t.color,
                    ),
                    label: Text(t.label),
                    selected: t == _type,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Duration', style: theme.textTheme.labelLarge),
                const Spacer(),
                Text(
                  formatMinutes(_minutes.round()),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Slider(
              value: _minutes,
              min: _minMinutes,
              max: _maxMinutes,
              divisions: (_maxMinutes - _minMinutes).toInt(),
              label: formatMinutes(_minutes.round()),
              onChanged: (v) => setState(() => _minutes = v),
            ),
            const SizedBox(height: 8),
            label('Intensity'),
            SegmentedButton<Intensity>(
              segments: [
                for (final i in Intensity.values)
                  ButtonSegment(value: i, label: Text(i.label)),
              ],
              selected: {_intensity},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _intensity = s.first),
            ),
            const SizedBox(height: 20),
            label('When'),
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                '${formatDayLabel(_date)}, ${formatTime(context, _date)}',
              ),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. 5 km easy run, leg day…',
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: caloriesOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: caloriesOrange,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Estimated burn')),
                  Text(
                    '${formatNumber(calories)} kcal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (_editing) ...[
                  IconButton.outlined(
                    tooltip: 'Delete workout',
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () => _save(calories),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(_editing ? 'Save changes' : 'Save workout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
