bool canInstall() => false;

bool isStandalone() => false;

bool isIos() => false;

bool isAndroid() => false;

bool isInAppBrowser() => false;

bool openInBrowser() => false;

bool updateReady() => false;

Future<bool> promptInstall() async => false;

void reload() {}

void setThemeColor(String color) {}

void beep({bool long = false}) {}

void unlockAudio() {}

void keepAwake(bool on) {}

void keepData() {}

void onChange(void Function() callback) {}
