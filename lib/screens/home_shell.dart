import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../pwa/pwa.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/common.dart';
import '../widgets/workout_widgets.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'session_screen.dart';
import 'training_screen.dart';

/// Bottom navigation on phones, a navigation rail on wide screens.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _destinations = [
    (
      label: 'Training',
      icon: Icons.fitness_center_outlined,
      selected: Icons.fitness_center,
    ),
    (label: 'Report', icon: Icons.insights_outlined, selected: Icons.insights),
    (label: 'Me', icon: Icons.person_outline, selected: Icons.person),
  ];

  var _index = 0;
  var _updateShown = false;

  @override
  void initState() {
    super.initState();
    Pwa.instance.addListener(_onPwaChanged);
    SessionScreen.active.addListener(_onSessionChanged);
    // An update may have arrived before this screen was shown.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onPwaChanged());
    // Home-screen shortcut: ?action=log.
    if (Uri.base.queryParameters['action'] == 'log') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showLogWorkoutSheet(context);
      });
    }
  }

  @override
  void dispose() {
    Pwa.instance.removeListener(_onPwaChanged);
    SessionScreen.active.removeListener(_onSessionChanged);
    super.dispose();
  }

  // Runs after the workout screen has closed (not while it is disposing).
  void _onSessionChanged() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _onPwaChanged());

  // Offers the new version, but never in the middle of a workout.
  void _onPwaChanged() {
    if (_updateShown || !mounted || !Pwa.instance.updateReady) return;
    if (SessionScreen.active.value) return;
    _updateShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('A new version of FitTrack is ready.'),
        action: SnackBarAction(label: 'Reload', onPressed: Pwa.instance.reload),
      ),
    );
  }

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final page = switch (_index) {
      0 => const TrainingScreen(),
      1 => const ReportScreen(),
      _ => const ProfileScreen(),
    };
    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: KeyedSubtree(key: ValueKey(_index), child: page),
    );

    if (wide) {
      return Scaffold(
        body: AmbientBackground(
          child: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: AppLogo(size: 40),
                  ),
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selected),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      );
    }

    // Frosted nav bar floating over the page (extendBody).
    return Scaffold(
      extendBody: true,
      body: AmbientBackground(child: body),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: glassEdge(context))),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selected),
                    label: d.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
