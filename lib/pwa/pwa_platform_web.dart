import 'dart:js_interop';

/// `window.fitPwa` from web/index.html.
@JS('fitPwa')
external _FitPwa? get _fitPwa;

extension type _FitPwa._(JSObject _) implements JSObject {
  external bool canInstall();
  external bool isStandalone();
  external bool isIos();
  external bool isAndroid();
  external bool isInAppBrowser();
  external bool openInBrowser();
  external bool updateReady();
  external JSPromise<JSBoolean> promptInstall();
  external void reload();
  external void setThemeColor(String color);
  external void beep(bool long);
  external void unlockAudio();
  external void keepAwake(bool on);
  external void keepData();
  external void onChange(JSFunction callback);
}

bool canInstall() => _fitPwa?.canInstall() ?? false;

bool isStandalone() => _fitPwa?.isStandalone() ?? false;

bool isIos() => _fitPwa?.isIos() ?? false;

bool isAndroid() => _fitPwa?.isAndroid() ?? false;

bool isInAppBrowser() => _fitPwa?.isInAppBrowser() ?? false;

bool openInBrowser() => _fitPwa?.openInBrowser() ?? false;

bool updateReady() => _fitPwa?.updateReady() ?? false;

Future<bool> promptInstall() async {
  final pwa = _fitPwa;
  if (pwa == null) return false;
  return (await pwa.promptInstall().toDart).toDart;
}

void reload() => _fitPwa?.reload();

void setThemeColor(String color) => _fitPwa?.setThemeColor(color);

void beep({bool long = false}) => _fitPwa?.beep(long);

void unlockAudio() => _fitPwa?.unlockAudio();

void keepAwake(bool on) => _fitPwa?.keepAwake(on);

void keepData() => _fitPwa?.keepData();

void onChange(void Function() callback) => _fitPwa?.onChange(callback.toJS);
