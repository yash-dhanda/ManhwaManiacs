import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/glass/caustic.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'home_rig.dart';

void main() {
  setUpAll(loadAppFonts);

  homeTest('solid glass: the spotlight controls are solid, the lit action is iris700 and nothing casts a caustic', (t) async {
    final rig = await pumpHome(t, homeRepoOf('ready'), settle: false);
    rig.container.read(glassInAppPrefsProvider.notifier).setSolidGlass(true);
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
    final primary = find.byWidgetPredicate((w) => w is GlassButton && w.debugLabel == 'SpotlightPrimary');
    final secondary = find.byWidgetPredicate((w) => w is GlassButton && w.debugLabel == 'SpotlightSecondary');
    expect(primary, findsOneWidget);
    expect(secondary, findsOneWidget);
    expect(find.descendant(of: primary, matching: find.byWidgetPredicate((w) => w is ColoredBox && w.color == gt.colorIris700)), findsWidgets);
    expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is GlassCausticPainter), findsNothing);
    expect(rig.container.read(glassRegistryProvider).layers, 0);
  });
}
