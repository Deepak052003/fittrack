import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/fitness_store.dart';
import '../pwa/pwa.dart';
import '../screens/session_screen.dart';
import 'app_logo.dart';
import 'common.dart';

/// Shows the install sheet: one-tap install when the browser offers it,
/// otherwise the steps for this phone. Returns true if the app was installed.
Future<bool> showInstallSheet(BuildContext context) async {
  final installed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _InstallSheet(),
  );
  return installed ?? false;
}

/// Offers "Install app" by itself when the app is opened in a phone browser.
/// After "Not now" it waits 3 days. Never inside the installed app.
class InstallPrompt extends StatefulWidget {
  const InstallPrompt({super.key, required this.child});

  final Widget child;

  @override
  State<InstallPrompt> createState() => _InstallPromptState();
}

class _InstallPromptState extends State<InstallPrompt> {
  final _timers = <Timer>[];
  var _ready = false;
  var _shown = false;

  @override
  void initState() {
    super.initState();
    Pwa.instance.addListener(_check);
    // Let the first screen appear; then ask if one-tap install is offered.
    _timers.add(
      Timer(const Duration(milliseconds: 1500), () {
        _ready = true;
        _check();
      }),
    );
    // The browser may never offer it (already dismissed, or no support):
    // then show the steps for this phone anyway.
    _timers.add(Timer(const Duration(seconds: 4), () => _check(steps: true)));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    Pwa.instance.removeListener(_check);
    super.dispose();
  }

  Future<void> _check({bool steps = false}) async {
    final pwa = Pwa.instance;
    if (_shown || !_ready || !mounted || !kIsWeb) return;
    if (pwa.isStandalone || SessionScreen.active.value) return;
    final phone = pwa.isIos || pwa.isAndroid;
    final show =
        pwa.canInstall || pwa.isInAppBrowser || (phone && (steps || pwa.isIos));
    if (!show) return;
    final store = StoreScope.read(context);
    if (!store.installPromptDue) return;
    _shown = true;
    final installed = await showInstallSheet(context);
    if (!installed) store.snoozeInstallPrompt(const Duration(days: 3));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _InstallSheet extends StatelessWidget {
  const _InstallSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final pwa = Pwa.instance;
    Widget step(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );

    final inApp = pwa.isInAppBrowser;
    final List<Widget> body;
    if (inApp) {
      // LinkedIn, Instagram... browsers cannot install: move to the real browser.
      body = [
        if (pwa.isAndroid) ...[
          GradientButton(
            label: 'Open in Chrome',
            icon: Icons.open_in_browser,
            onPressed: pwa.openInBrowser,
          ),
          const SizedBox(height: 10),
          step(Icons.more_vert, 'Or tap ⋮ (top right) → “Open in browser”'),
        ] else ...[
          step(Icons.more_horiz, '1. Tap ••• or the compass icon'),
          step(Icons.open_in_browser, '2. Choose “Open in Safari”'),
          step(Icons.ios_share, '3. In Safari: Share → Add to Home Screen'),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: Uri.base.origin));
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Link copied')));
          },
          icon: const Icon(Icons.link),
          label: const Text('Copy link'),
        ),
      ];
    } else if (pwa.canInstall) {
      body = [
        GradientButton(
          label: 'Install app',
          icon: Icons.install_mobile,
          onPressed: () async {
            final navigator = Navigator.of(context);
            final accepted = await pwa.promptInstall();
            navigator.pop(accepted);
          },
        ),
      ];
    } else if (pwa.isIos) {
      body = [
        step(Icons.ios_share, '1. Tap Share in the browser bar'),
        step(Icons.add_box_outlined, '2. Choose “Add to Home Screen”'),
        step(Icons.check_circle_outline, '3. Tap Add'),
      ];
    } else {
      body = [
        step(Icons.more_vert, '1. Tap the ⋮ menu in the browser'),
        step(
          Icons.install_mobile,
          '2. Choose “Install app” or “Add to Home screen”',
        ),
        step(Icons.check_circle_outline, '3. Tap Install'),
        const SizedBox(height: 4),
        Text(
          'Already installed? Open FitTrack from your home screen.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ];
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 64),
            const SizedBox(height: 14),
            Text(
              inApp ? 'Open in your browser' : 'Install FitTrack',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              inApp
                  ? 'This in-app browser can\'t install apps or keep your '
                        'data. Open FitTrack in Chrome or Safari to install it.'
                  : 'Add it to your home screen: opens full screen, '
                        'works offline, no app store needed.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 20),
            ...body,
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(pwa.canInstall ? 'Not now' : 'Got it'),
            ),
          ],
        ),
      ),
    );
  }
}
