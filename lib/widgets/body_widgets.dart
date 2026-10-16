import 'package:flutter/material.dart';

import '../data/fitness_store.dart';
import '../models.dart';
import '../utils/format.dart';
import 'charts.dart';

Future<void> showWeightDialog(BuildContext context) async {
  final store = StoreScope.read(context);
  final kg = await showDialog<double>(
    context: context,
    builder: (_) => _NumberDialog(
      title: "Today's weight",
      suffix: 'kg',
      initial: store.profile.weightKg,
      parse: parseWeight,
      error: 'Enter a weight between 20 and 400 kg',
    ),
  );
  if (kg != null) store.logWeight(kg);
}

Future<void> showHeightDialog(BuildContext context) async {
  final store = StoreScope.read(context);
  final cm = await showDialog<double>(
    context: context,
    builder: (_) => _NumberDialog(
      title: 'Your height',
      suffix: 'cm',
      initial: store.profile.heightCm,
      parse: parseHeight,
      error: 'Enter a height between 100 and 250 cm',
    ),
  );
  if (cm != null) store.updateProfile(store.profile.copyWith(heightCm: cm));
}

/// BMI from height and the latest weight, on a colored scale.
class BmiCard extends StatelessWidget {
  const BmiCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = StoreScope.of(context).profile;
    final bmi = profile.bmi;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('BMI', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => showHeightDialog(context),
                  child: Text(bmi == null ? 'Add height' : 'Edit height'),
                ),
              ],
            ),
            if (bmi == null)
              Text('Add your height to see your body mass index.', style: muted)
            else ...[
              Row(
                children: [
                  Text(
                    bmi.toStringAsFixed(1),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _Pill(BmiCategory.of(bmi)),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _BmiScale(bmi),
              ),
              const SizedBox(height: 8),
              Text(
                '${formatKg(profile.heightCm!)} cm · '
                '${formatKg(profile.weightKg)} kg',
                style: muted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.category);

  final BmiCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.label,
        style: TextStyle(color: category.color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Colored BMI bar from 15 to 40 with a marker.
class _BmiScale extends StatelessWidget {
  const _BmiScale(this.bmi);

  final double bmi;

  static const _min = 15.0, _max = 40.0;
  static const _bands = [
    (BmiCategory.underweight, 18.5),
    (BmiCategory.healthy, 25.0),
    (BmiCategory.overweight, 30.0),
    (BmiCategory.obese, _max),
  ];

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double x(double value) => (value - _min) / (_max - _min) * width;
        final segments = <Widget>[];
        var from = _min;
        for (final (category, to) in _bands) {
          segments.add(
            Container(width: x(to) - x(from), height: 8, color: category.color),
          );
          from = to;
        }
        return SizedBox(
          height: 38,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 6,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(children: segments),
                ),
              ),
              Positioned(
                left: x(bmi.clamp(_min, _max)) - 9,
                top: 1,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: BmiCategory.of(bmi).color,
                      width: 4,
                    ),
                  ),
                ),
              ),
              for (final value in const [18.5, 25.0, 30.0])
                Positioned(
                  left: x(value) - 12,
                  top: 22,
                  width: 24,
                  child: Text(
                    formatKg(value),
                    textAlign: TextAlign.center,
                    style: labelStyle,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Latest weight, trend chart and recent weigh-ins.
class WeightCard extends StatelessWidget {
  const WeightCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final weights = store.weights;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Weight', style: theme.textTheme.titleMedium),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () => showWeightDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Log'),
                ),
              ],
            ),
            if (weights.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Log your weight to see your trend.', style: muted),
              )
            else ...[
              Text(
                '${formatKg(weights.last.kg)} kg',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                weights.length == 1
                    ? 'Logged ${formatDayLabel(weights.last.date)}'
                    : '${_signed(weights.last.kg - weights.first.kg)} kg since '
                          '${formatShortDate(weights.first.date)}',
                style: muted,
              ),
              if (weights.length >= 2) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    height: 150,
                    child: WeightChart(entries: weights),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              for (final entry in weights.reversed.take(3))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${formatKg(entry.kg)} kg'),
                  subtitle: Text(formatDayLabel(entry.date)),
                  trailing: IconButton(
                    tooltip: 'Delete entry',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => store.deleteWeight(entry),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String _signed(double kg) => '${kg > 0 ? '+' : ''}${formatKg(kg)}';
}

class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.title,
    required this.suffix,
    required this.initial,
    required this.parse,
    required this.error,
  });

  final String title;
  final String suffix;
  final double? initial;
  final double? Function(String) parse;
  final String error;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final _controller = TextEditingController(
    text: widget.initial == null ? '' : formatKg(widget.initial!),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = widget.parse(_controller.text);
    if (value == null) {
      setState(() => _error = widget.error);
    } else {
      Navigator.pop(context, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          suffixText: widget.suffix,
          errorText: _error,
        ),
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
