import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';

import '../primitives/support.dart';

void main() {
  setUp(GlassHaptics.debugLog.clear);

  testWidgets('a poster reports growing at 150 ms, lifted at 450 ms and ended on release', (tester) async {
    final phases = <GlassLiftPhase>[];
    await tester.pumpWidget(primHost(GlassPoster(cover: const ColoredBox(color: Color(0xFF334455)), title: 'Solo', width: 120, onTap: () {}, onContextPreview: () {}, onLiftPhase: phases.add)));
    await pumpFor(tester, 400);
    final g = await tester.startGesture(tester.getCenter(find.byType(GlassPoster)));
    await pumpFor(tester, 300);
    expect(phases, [GlassLiftPhase.growing]);
    await pumpFor(tester, 200);
    expect(phases, [GlassLiftPhase.growing, GlassLiftPhase.lifted]);
    await g.up();
    await pumpFor(tester, 800);
    expect(phases.last, GlassLiftPhase.ended);
    expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.longpressOpen));
  });

  testWidgets('a tap fires no lift phase and the radius parameter renders', (tester) async {
    final phases = <GlassLiftPhase>[];
    await tester.pumpWidget(primHost(GlassPoster(cover: const ColoredBox(color: Color(0xFF334455)), title: 'Solo', width: 120, radius: 26, onTap: () {}, onLiftPhase: phases.add)));
    await pumpFor(tester, 400);
    await tester.tap(find.byType(GlassPoster));
    await pumpFor(tester, 100);
    expect(phases, isEmpty);
    expect(tester.widget<GlassPoster>(find.byType(GlassPoster)).radius, 26);
  });
}
