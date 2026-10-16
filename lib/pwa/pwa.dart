import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import 'pwa_platform_stub.dart'
    if (dart.library.js_interop) 'pwa_platform_web.dart'
    as platform;

/// Browser helpers from web/index.html; no-ops elsewhere.
class Pwa extends ChangeNotifier {
  Pwa._() {
    platform.onChange(notifyListeners);
  }

  static final instance = Pwa._();

  /// The browser offered an install prompt (Chrome, Edge, Android).
  bool get canInstall => platform.canInstall();

  /// Running as an installed app rather than in a browser tab.
  bool get isStandalone => platform.isStandalone();

  /// iOS: install is manual (Share → Add to Home Screen).
  bool get isIos => platform.isIos();

  /// Android phone or tablet (install via the browser menu if needed).
  bool get isAndroid => platform.isAndroid();

  /// Opened inside another app (e.g. LinkedIn), where installing is blocked.
  bool get isInAppBrowser => platform.isInAppBrowser();

  /// Android: reopens the app in Chrome; false if not possible here.
  bool openInBrowser() => platform.openInBrowser();

  /// A new deploy is ready.
  bool get updateReady => platform.updateReady();

  /// Shows the install dialog; true if accepted.
  Future<bool> promptInstall() => platform.promptInstall();

  void reload() => platform.reload();

  void setThemeColor(Color color) => platform.setThemeColor(
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
  );

  /// Short beep for timers; [long] is the higher "go" tone.
  void beep({bool long = false}) => platform.beep(long: long);

  /// Call from a tap so iOS allows later beeps.
  void unlockAudio() => platform.unlockAudio();

  /// Keeps the screen on during a workout.
  void keepAwake(bool on) => platform.keepAwake(on);

  /// Asks the browser to keep saved data even when storage runs low.
  void keepData() => platform.keepData();
}
