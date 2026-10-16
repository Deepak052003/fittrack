import 'package:flutter/material.dart';

import 'data/fitness_store.dart';
import 'pwa/pwa.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme.dart';
import 'widgets/install_prompt.dart';

class FitTrackApp extends StatelessWidget {
  const FitTrackApp({super.key, required this.store});

  final FitnessStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: Builder(
        builder: (context) => MaterialApp(
          title: 'FitTrack',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: StoreScope.of(context).themeMode,
          builder: (context, child) {
            // Match the browser / installed-app title bar to the app theme.
            Pwa.instance.setThemeColor(Theme.of(context).colorScheme.surface);
            return child!;
          },
          home: const _RootGate(),
        ),
      ),
    );
  }
}

/// Shows onboarding until the profile is set up (and again after a reset).
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    return InstallPrompt(
      child: StoreScope.of(context).profile.onboarded
          ? const HomeShell()
          : const OnboardingScreen(),
    );
  }
}
