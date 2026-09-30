import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/auto_scroll_chip.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/running_head.dart';

import '../feature/feature_test_support.dart' show featureTheme;

Future<void> _pump(WidgetTester tester, TargetPlatform p, Widget child) => tester.pumpWidget(
      MaterialApp(theme: featureTheme(p), home: Scaffold(body: Center(child: child))),
    );

void main() {
  for (final (platform, min) in [(TargetPlatform.iOS, 44.0), (TargetPlatform.android, 48.0)]) {
    testWidgets('the chip and the waveform are at least $min on $platform, eight apart from neighbours', (tester) async {
      await _pump(
        tester,
        platform,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CineAutoScrollChip(speedX: 1, running: true, onToggle: () {}, onOpenRuler: () {}),
            const SizedBox(width: 8),
            HouseSoundWaveform(label: 'Rain on glass', onTap: () {}),
          ],
        ),
      );
      final targets = find.byType(CinePressable);
      expect(targets, findsNWidgets(2));
      for (final e in targets.evaluate()) {
        final s = tester.getSize(find.byElementPredicate((x) => x == e));
        expect(s.height, greaterThanOrEqualTo(min), reason: '${e.widget} height');
        expect(s.width, greaterThanOrEqualTo(min), reason: '${e.widget} width');
      }
      final a = tester.getRect(targets.first), b = tester.getRect(targets.last);
      expect(b.left - a.right, greaterThanOrEqualTo(8));
    });
  }

  testWidgets('the chip toggles on tap, opens the ruler on long-press and reads its state', (tester) async {
    final handle = tester.ensureSemantics();
    var toggles = 0, rulers = 0;
    await _pump(
      tester,
      TargetPlatform.android,
      CineAutoScrollChip(speedX: 1.25, running: false, paced: true, onToggle: () => toggles++, onOpenRuler: () => rulers++),
    );
    expect(find.text('1.25× · PACED', findRichText: true), findsOneWidget);
    expect(find.bySemanticsLabel('Auto-scroll, 1.25 times, paused'), findsOneWidget);
    await tester.tap(find.byType(CineAutoScrollChip));
    await tester.pump(const Duration(milliseconds: 100));
    expect(toggles, 1);
    await tester.longPress(find.byType(CineAutoScrollChip));
    await tester.pump();
    expect(rulers, 1);
    handle.dispose();
  });
}
