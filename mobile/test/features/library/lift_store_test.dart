import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/providers/lift_store.dart';

void main() {
  test('the lift store holds one lift through its phases', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(liftProvider), isNull);
    const grow = LiftState(sourceId: 's', seriesKey: 'k', mature: true, phase: LiftPhase.growing, posterRect: Rect.fromLTWH(0, 0, 100, 150));
    c.read(liftProvider.notifier).state = grow;
    c.read(liftProvider.notifier).state = grow.copyWith(phase: LiftPhase.lifted, pointer: const Offset(40, 60));
    final s = c.read(liftProvider)!;
    expect((s.phase, s.mature, s.key, s.pointer), (LiftPhase.lifted, true, 's:k', const Offset(40, 60)));
    expect(s == grow, isFalse);
  });
}
