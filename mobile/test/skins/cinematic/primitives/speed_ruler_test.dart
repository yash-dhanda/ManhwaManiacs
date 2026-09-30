import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/speed_ruler.dart';

import 'cine_harness.dart';

void main() {
  test('snap: 0.05 steps inside 0.50-3.00', () {
    expect(snapSpeedX(1.02), 1.0);
    expect(snapSpeedX(1.03), 1.05);
    expect(snapSpeedX(0.1), 0.5);
    expect(snapSpeedX(9), 3.0);
    expect(speedAt(0, 250), 0.5);
    expect(speedAt(250, 250), 3.0);
    expect(speedAt(50, 250), 1.0);
    expect(speedX(1.0, 250), 50);
    expect(crossesQuarter(0.99, 1.0), isTrue);
    expect(crossesQuarter(1.0, 1.1), isFalse);
    expect(speedLabel(1.25), '1.25×');
  });

  Future<void> pump(WidgetTester tester, {required List<double> live, required List<double> committed, double value = 1.0}) => pumpCine(
        tester,
        Padding(
          padding: const EdgeInsets.all(20),
          child: SpeedRuler(value: value, onChanged: live.add, onCommit: committed.add, pxCaption: (x) => '≈ ${(x * 47).round()} PX/S'),
        ),
      );

  testWidgets('drag moves live, commits once on release', (tester) async {
    final live = <double>[], committed = <double>[];
    await pump(tester, live: live, committed: committed);
    final track = find.byKey(const ValueKey('speed-ruler-track'));
    final rect = tester.getRect(track);
    final g = await tester.startGesture(Offset(rect.left + rect.width * 0.2, rect.center.dy));
    await g.moveTo(Offset(rect.left + rect.width * 0.6, rect.center.dy));
    await tester.pump();
    expect(live, isNotEmpty);
    expect(committed, isEmpty);
    await g.up();
    await tester.pump();
    expect(committed, hasLength(1));
    expect(committed.single, closeTo(2.0, 0.06));
  });

  testWidgets('presets commit; touch-and-hold resets to 1.00', (tester) async {
    final live = <double>[], committed = <double>[];
    await pump(tester, live: live, committed: committed, value: 2.0);
    await tester.tap(find.text('1.25'));
    await tester.pump();
    expect(committed.last, 1.25);
    await tester.longPress(find.byKey(const ValueKey('speed-ruler-track')));
    await tester.pump();
    expect(committed.last, 1.0);
    expect(live.last, 1.0);
    expect(find.text('≈ 94 PX/S'), findsOneWidget);
  });

  testWidgets('labels at 0.5, 1, 1.5, 2, 2.5, 3', (tester) async {
    await pump(tester, live: [], committed: []);
    for (final l in ['0.5', '1', '1.5', '2', '2.5', '3']) {
      expect(find.text(l), findsWidgets);
    }
  });
}
