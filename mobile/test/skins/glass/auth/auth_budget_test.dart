import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'auth_rig.dart';
import 'auth_screens.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final name in ['setup', 'login', 'register', 'picker', 'onboarding-1', 'onboarding-3', 'onboarding-4', 'onboarding-6']) {
    testWidgets('$name: at most two live glass layers at rest', (t) async {
      final rig = await authCases.firstWhere((c) => c.name == name).pump(t);
      await settleFor(t, 3500);
      final reg = rig.container.read(glassRegistryProvider);
      expect(reg.layers, lessThanOrEqualTo(2), reason: '$name draws ${reg.layers} layers');
    });
  }

  testWidgets('the profile form sheet over the picker keeps the two-stacked-layer rule', (t) async {
    final rig = await authCases.firstWhere((c) => c.name == 'picker').pump(t);
    await settleFor(t, 2500);
    await t.tap(find.bySemanticsLabel('Add profile').first, warnIfMissed: false);
    await settleFor(t, 1500);
    expect(rig.container.read(glassRegistryProvider).layers, lessThanOrEqualTo(3));
  });
}
