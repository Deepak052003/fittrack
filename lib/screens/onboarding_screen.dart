import 'package:flutter/material.dart';

import '../data/fitness_store.dart';
import '../models.dart';
import '../pwa/pwa.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/app_logo.dart';
import '../widgets/common.dart';

/// First launch: name, height and weight (for BMI and calories), weekly goal.
/// No account or email needed.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController(text: '70');
  var _days = 4;
  String? _heightError, _weightError;

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  double? get _bmi {
    final cm = parseHeight(_height.text), kg = parseWeight(_weight.text);
    if (cm == null || kg == null) return null;
    return Profile(weightKg: kg, heightCm: cm).bmi;
  }

  void _start() {
    final kg = parseWeight(_weight.text);
    final cm = _height.text.trim().isEmpty ? null : parseHeight(_height.text);
    setState(() {
      _weightError = kg == null ? 'Enter 20–400 kg' : null;
      _heightError = _height.text.trim().isNotEmpty && cm == null
          ? 'Enter 100–250 cm'
          : null;
    });
    if (kg == null || _heightError != null) return;
    StoreScope.read(context).completeOnboarding(
      name: _name.text,
      weightKg: kg,
      heightCm: cm,
      weeklyWorkoutsGoal: _days,
    );
    Pwa.instance.keepData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bmi = _bmi;

    return Scaffold(
      body: AmbientBackground(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.paddingOf(context).top + 48,
                24,
                8,
              ),
              child: Column(
                children: [
                  const AppLogo(size: 76),
                  const SizedBox(height: 24),
                  const TrackedLabel('Home & gym training', color: coral),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome to FitTrack',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Video-guided workouts. No sign-up.\n'
                    'Your data stays on this phone.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Your name (optional)',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _height,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Height',
                                suffixText: 'cm',
                                errorText: _heightError,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _weight,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Weight',
                                suffixText: 'kg',
                                errorText: _weightError,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (bmi != null)
                        Text(
                          'Your BMI: ${bmi.toStringAsFixed(1)} · '
                          '${BmiCategory.of(bmi).label}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: BmiCategory.of(bmi).color,
                          ),
                        )
                      else
                        Text(
                          'Height and weight are used for BMI and calories.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 24),
                      const TrackedLabel('Workouts per week', size: 12),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final days in const [2, 3, 4, 5, 6])
                            ChoiceChip(
                              label: Text('$days days'),
                              selected: _days == days,
                              showCheckmark: false,
                              onSelected: (_) => setState(() => _days = days),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      GradientButton(onPressed: _start, label: 'Get started'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
