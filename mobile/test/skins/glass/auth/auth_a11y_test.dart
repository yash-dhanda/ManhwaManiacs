import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'auth_rig.dart';
import 'auth_screens.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final (platform, name) in [(TargetPlatform.iOS, '44 pt'), (TargetPlatform.android, '48 dp')]) {
    for (final c in authCases) {
      testWidgets('${c.name}: every control at 390 x 844 is at least $name and labelled', (t) async {
        debugDefaultTargetPlatformOverride = platform;
        final h = t.ensureSemantics();
        await c.pump(t, android: platform == TargetPlatform.android);
        await settleFor(t, 3500);
        await expectLater(t, meetsGuideline(platform == TargetPlatform.iOS ? iOSTapTargetGuideline : androidTapTargetGuideline));
        await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
        h.dispose();
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }

  for (final name in ['login', 'register', 'picker', 'onboarding-4']) {
    testWidgets('$name: no overflow at text scale 2.0', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(t.platformDispatcher.clearAllTestValues);
      await authCases.firstWhere((c) => c.name == name).pump(t);
      await settleFor(t, 3500);
      expect(t.takeException(), isNull);
    });
  }
}
