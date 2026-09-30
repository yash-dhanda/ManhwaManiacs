import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'auth_rig.dart';
import 'auth_screens.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final name in ['login', 'picker', 'onboarding-3']) {
    testWidgets('$name: solid glass and increase contrast render without errors', (t) async {
      final rig = await authCases.firstWhere((c) => c.name == name).pump(t);
      rig.container.read(glassInAppPrefsProvider.notifier)
        ..setSolidGlass(true)
        ..setIncreaseContrast(true);
      await settleFor(t, 3000);
      expect(t.takeException(), isNull);
      expect(rig.container.read(glassA11yProvider).solid, isTrue);
    });
  }
}
