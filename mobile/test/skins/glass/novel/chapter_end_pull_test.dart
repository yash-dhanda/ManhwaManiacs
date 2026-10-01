import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/chapter_end_pull.dart';

void main() {
  test('arms at 48 and locks at 72 displayed px', () {
    final p = ChapterEndPull();
    expect(p.update(47.9), isEmpty);
    expect(p.update(48), [ChapterPullEvent.arm]);
    expect(p.update(71.9), isEmpty);
    expect(p.update(72), [ChapterPullEvent.lock]);
    expect(p.update(90), isEmpty);
  });

  test('crossing back below 72 unlocks (threshold.back)', () {
    final p = ChapterEndPull()..update(80);
    expect(p.locked, isTrue);
    expect(p.update(60), [ChapterPullEvent.unlock]);
    expect(p.locked, isFalse);
    expect(p.update(75), [ChapterPullEvent.lock]);
  });

  test('a jump straight past 72 arms and locks at once', () {
    expect(ChapterEndPull().update(100), [ChapterPullEvent.arm, ChapterPullEvent.lock]);
  });

  test('the rubber band uses c = 0.35 and inverts', () {
    const d = 800.0;
    final shown = rubberband(200, d, 0.35);
    expect(shown, closeTo(d * (1 - 1 / (200 * 0.35 / d + 1)), 1e-9));
    expect(rubberbandInverse(shown, d, 0.35), closeTo(200, 1e-6));
    expect(GlassChapterEndPhysics.c, 0.35);
  });

  test('physics: a drag past the end is displayed through the band', () {
    const physics = GlassChapterEndPhysics();
    final m = FixedScrollMetrics(minScrollExtent: 0, maxScrollExtent: 1000, pixels: 1000, viewportDimension: 800, axisDirection: AxisDirection.down, devicePixelRatio: 1);
    final applied = physics.applyPhysicsToUserOffset(m, -200);
    expect(-applied, closeTo(rubberband(200, 800, 0.35), 1e-6));
    // Within the content it is 1:1.
    final inside = FixedScrollMetrics(minScrollExtent: 0, maxScrollExtent: 1000, pixels: 500, viewportDimension: 800, axisDirection: AxisDirection.down, devicePixelRatio: 1);
    expect(physics.applyPhysicsToUserOffset(inside, -50), -50);
  });

  test('reduced motion: the end is a hard stop', () {
    const physics = GlassChapterEndPhysics(reduced: true);
    final m = FixedScrollMetrics(minScrollExtent: 0, maxScrollExtent: 1000, pixels: 1000, viewportDimension: 800, axisDirection: AxisDirection.down, devicePixelRatio: 1);
    expect(physics.applyBoundaryConditions(m, 1030), 30);
  });
}
