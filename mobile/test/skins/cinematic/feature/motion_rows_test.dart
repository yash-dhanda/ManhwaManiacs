// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/motion_names.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/reader_entry.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_motion.dart';

import 'feature_test_support.dart';

void main() {
  test('the motion-timings rows carry the planned figures', () {
    int ms(MotionName m, String where) =>
        featureMotionRows.firstWhere((r) => r.move == m && r.where.contains(where)).plannedMs;
    expect(ms(MotionName.matchCut, 'in'), 480);
    expect(ms(MotionName.matchCut, 'out'), 336);
    expect(ms(MotionName.dissolve, 'ambient'), 800);
    expect(ms(MotionName.columnWipe, 'phone'), 616);
    expect(ms(MotionName.columnWipe, 'tablet'), 744);
  });

  test('Column wipe timings: 248 + 40 + 328 on phones, 312 + 40 + 392 on tablets', () {
    const p = WipeTimings(4);
    expect((p.closeMs, WipeTimings.hold, p.openMs), (248, 40, 328));
    const t = WipeTimings(8);
    expect((t.closeMs, WipeTimings.hold, t.openMs), (312, 40, 392));
    expect(WipeTimings.forWidth(390).blades, 4);
    expect(WipeTimings.forWidth(834).blades, 8);
  });

  Future<void> wipe(WidgetTester tester, {required bool wide, bool reduced = false, required List<int> covered}) async {
    await pumpFeature(
      tester,
      wide: wide,
      reducedMotion: reduced,
      child: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => columnWipe(context, onCovered: () => covered.add(1)),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
  }

  testWidgets('phone wipe: covered at 288 ms, gone by 616 ms', (tester) async {
    final covered = <int>[];
    await wipe(tester, wide: false, covered: covered);
    await tester.pump(const Duration(milliseconds: 250));
    expect(covered, isEmpty);
    await tester.pump(const Duration(milliseconds: 60));
    expect(covered, [1]);
    await tester.pump(const Duration(milliseconds: 330));
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byType(Positioned), findsNothing);
  });

  testWidgets('tablet wipe: covered at 352 ms', (tester) async {
    final covered = <int>[];
    await wipe(tester, wide: true, covered: covered);
    await tester.pump(const Duration(milliseconds: 340));
    expect(covered, isEmpty);
    await tester.pump(const Duration(milliseconds: 30));
    expect(covered, [1]);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('reduced motion: a 200 ms cross-fade through black', (tester) async {
    final covered = <int>[];
    await wipe(tester, wide: false, reduced: true, covered: covered);
    await tester.pump(const Duration(milliseconds: 90));
    expect(covered, isEmpty);
    await tester.pump(const Duration(milliseconds: 30));
    expect(covered, [1]);
    await tester.pump(const Duration(milliseconds: 200));
  });
}
