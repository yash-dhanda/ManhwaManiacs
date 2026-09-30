import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_field_ripple.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../primitives/support.dart' show pumpFor;
import 'home_rig.dart';

Finder get _caret => find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_CaretPainter');

void main() {
  setUpAll(loadAppFonts);

  homeTest('reduced motion: no caret, the greeting at once, no ripple, no tilt, the card fades in over 200 ms', (t) async {
    final rig = await pumpHome(t, homeRepoOf('ready'), settle: false);
    rig.container.read(glassInAppPrefsProvider.notifier).setReduceMotion(true);
    await t.pump();
    await pumpFor(t, 50);
    expect(_caret, findsNothing);
    // The whole greeting is there at 50 ms.
    final greeting = find.descendant(of: find.byType(TypedHeadline), matching: find.byType(RichText));
    expect(greeting, findsWidgets);
    final root = t.widget<RichText>(greeting.first).text as TextSpan;
    for (final c in root.children ?? const <InlineSpan>[]) {
      expect((c as TextSpan).style?.color, isNot(const Color(0x00000000)));
    }
    await pumpFor(t, 3000);
    // No ripple is ever drawn.
    expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is RipplePainter), findsNothing);
    // No sensor reads.
    expect(rig.container.read(gravityProvider).sensorSubscriptions, 0);
    expect(rig.container.read(glassLightAngleProvider).valueOrNull, kLightAngleRest);
    expect(find.byType(Spotlight), findsOneWidget);
  });
}
