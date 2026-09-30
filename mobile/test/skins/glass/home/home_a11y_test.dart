import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/continue_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/poster_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../primitives/support.dart' show pumpFor;
import 'home_rig.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final (platform, tap) in [(TargetPlatform.iOS, '44 pt'), (TargetPlatform.android, '48 dp')]) {
    homeTest('every Home control at 390 x 844 meets the $tap and labelled tap-target guidelines', (t) async {
      debugDefaultTargetPlatformOverride = platform;
      final h = t.ensureSemantics();
      await pumpHome(t, homeRepoOf('ready'), platformAndroid: platform == TargetPlatform.android);
      await expectLater(t, meetsGuideline(platform == TargetPlatform.iOS ? iOSTapTargetGuideline : androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
      debugDefaultTargetPlatformOverride = null;
    });
  }

  homeTest('hardware-keyboard traversal reaches the spotlight and every rail', (t) async {
    await pumpHome(t, homeRepoOf('ready'));
    final seen = <Type>{};
    for (var i = 0; i < 40; i++) {
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await pumpFor(t, 60);
      final ctx = FocusManager.instance.primaryFocus?.context;
      if (ctx == null) continue;
      ctx.visitAncestorElements((e) {
        final w = e.widget;
        if (w is Spotlight || w is HomeContinueRail || w is HomePosterRail) seen.add(w.runtimeType);
        return true;
      });
    }
    expect(seen, containsAll(<Type>[Spotlight, HomeContinueRail, HomePosterRail]));
  });

  homeTest('no overflow at text scale 2.0', (t) async {
    t.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpHome(t, homeRepoOf('ready'));
    expect(t.takeException(), isNull);
    await t.fling(find.byType(Scrollable).first, const Offset(0, -1500), 3000);
    await pumpFor(t, 1500);
    expect(t.takeException(), isNull);
  });
}
