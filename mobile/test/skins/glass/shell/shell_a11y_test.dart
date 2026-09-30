import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'shell_rig.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final (size, name) in [(const Size(390, 844), 'phone 390 x 844'), (const Size(1366, 1024), 'desktop 1366 x 1024')]) {
    for (final (platform, tap) in [(TargetPlatform.iOS, '44 pt'), (TargetPlatform.android, '48 dp')]) {
      testWidgets('every shell control at $name meets the $tap and labelled tap-target guidelines', (t) async {
        debugDefaultTargetPlatformOverride = platform;
        final handle = t.ensureSemantics();
        await pumpGlassShell(t, size: size, start: '/dev/glass/shell');
        await expectLater(t, meetsGuideline(platform == TargetPlatform.iOS ? iOSTapTargetGuideline : androidTapTargetGuideline));
        await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }
}
