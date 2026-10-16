import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/fitness_store.dart';
import 'pwa/pwa.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inter font license (shown on the licenses page).
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Inter',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  final store = await FitnessStore.load();
  if (store.profile.onboarded) Pwa.instance.keepData();
  runApp(FitTrackApp(store: store));
}
