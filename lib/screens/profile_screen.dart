import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/fitness_store.dart';
import '../models.dart';
import '../pwa/pwa.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/body_widgets.dart';
import '../widgets/common.dart';
import '../widgets/install_prompt.dart';

/// Me tab: body stats, BMI, goals and settings. No account needed.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final profile = store.profile;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const divider = Divider(height: 1, indent: 16, endIndent: 16);
    final valueStyle = theme.textTheme.titleMedium?.copyWith(
      color: scheme.primary,
    );

    return PageScaffold(
      title: 'Me',
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _editName(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: coralGradient,
                      shape: BoxShape.circle,
                    ),
                    child: profile.name.isEmpty
                        ? const Icon(Icons.person, color: obsidian)
                        : Text(
                            profile.name.characters.first.toUpperCase(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: obsidian,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name.isEmpty ? 'Add your name' : profile.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          'No account needed · data stays on this phone',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_outlined),
                ],
              ),
            ),
          ),
        ),
        const SectionHeader('Body'),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.height),
                title: const Text('Height'),
                trailing: Text(
                  profile.heightCm == null
                      ? 'Add'
                      : '${formatKg(profile.heightCm!)} cm',
                  style: valueStyle,
                ),
                onTap: () => showHeightDialog(context),
              ),
              divider,
              ListTile(
                leading: const Icon(Icons.monitor_weight_outlined),
                title: const Text('Weight'),
                trailing: Text(
                  '${formatKg(profile.weightKg)} kg',
                  style: valueStyle,
                ),
                onTap: () => showWeightDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const BmiCard(),
        const SectionHeader('Goals'),
        Card(
          child: Column(
            children: [
              _GoalStepper(
                icon: Icons.event_repeat,
                label: 'Workouts per week',
                value: profile.weeklyWorkoutsGoal,
                unit: 'workouts',
                min: 1,
                max: 14,
                onChanged: (v) => store.updateProfile(
                  profile.copyWith(weeklyWorkoutsGoal: v),
                ),
              ),
              divider,
              _GoalStepper(
                icon: Icons.timer_outlined,
                label: 'Active minutes per day',
                value: profile.dailyMinutesGoal,
                unit: 'min',
                step: 5,
                min: 5,
                max: 240,
                onChanged: (v) =>
                    store.updateProfile(profile.copyWith(dailyMinutesGoal: v)),
              ),
            ],
          ),
        ),
        const SectionHeader('Rest between sets'),
        SegmentedButton<int>(
          segments: [
            for (final s in FitnessStore.restChoices)
              ButtonSegment(value: s, label: Text(formatSeconds(s))),
          ],
          selected: {store.restSeconds},
          emptySelectionAllowed: true, // An old custom value matches none.
          showSelectedIcon: false,
          onSelectionChanged: (s) {
            if (s.isNotEmpty) store.setRestSeconds(s.first);
          },
        ),
        const SectionHeader('Appearance'),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto_outlined),
              label: Text('System'),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_outlined),
              label: Text('Light'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_outlined),
              label: Text('Dark'),
            ),
          ],
          selected: {store.themeMode},
          showSelectedIcon: false,
          onSelectionChanged: (s) => store.setThemeMode(s.first),
        ),
        const SectionHeader('App'),
        if (kIsWeb) ...[const _InstallCard(), const SizedBox(height: 12)],
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Export data'),
                subtitle: const Text('Copy a JSON backup to the clipboard'),
                onTap: () => _export(context),
              ),
              divider,
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Licenses'),
                subtitle: const Text('Fonts, icons and open-source code'),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'FitTrack',
                ),
              ),
              divider,
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: scheme.error,
                ),
                title: Text(
                  'Reset all data',
                  style: TextStyle(color: scheme.error),
                ),
                subtitle: const Text('Delete workouts, weigh-ins and goals'),
                onTap: () => _confirmReset(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'FitTrack 1.0 · Your data stays on this device.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _editName(BuildContext context) async {
    final store = StoreScope.read(context);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: store.profile.name),
    );
    if (name != null) store.updateProfile(store.profile.copyWith(name: name));
  }

  Future<void> _export(BuildContext context) async {
    final store = StoreScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Clipboard.setData(ClipboardData(text: store.exportJson()));
      messenger.showSnackBar(
        const SnackBar(content: Text('Backup copied to clipboard')),
      );
    } on PlatformException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not access the clipboard')),
      );
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final store = StoreScope.read(context);
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This permanently deletes your workouts, weigh-ins and goals '
          'from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await store.resetAll();
  }
}

class _GoalStepper extends StatelessWidget {
  const _GoalStepper({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final IconData icon;
  final String label;
  final int value;
  final String unit;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(
        '$value $unit',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease',
            onPressed: value - step >= min
                ? () => onChanged(value - step)
                : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          IconButton(
            tooltip: 'Increase',
            onPressed: value + step <= max
                ? () => onChanged(value + step)
                : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _InstallCard extends StatelessWidget {
  const _InstallCard();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Pwa.instance,
      builder: (context, _) {
        final pwa = Pwa.instance;
        final IconData icon;
        final String title, subtitle;
        Widget? action;
        if (pwa.isStandalone) {
          icon = Icons.check_circle_outline;
          title = 'App installed';
          subtitle = 'You are using FitTrack as an installed app.';
        } else {
          // Always a button: one-tap install, or the steps for this phone.
          icon = Icons.install_mobile;
          title = 'Install FitTrack';
          subtitle = 'Add it to your home screen. Works offline.';
          action = FilledButton(
            onPressed: () => showInstallSheet(context),
            child: const Text('Install'),
          );
        }
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: action,
          ),
        );
      },
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Name'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
