import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/core/time/locked_until.dart';
import 'package:manhwamaniacs/shared/widgets/lock_countdown.dart';

void main() {
  late DateTime now;
  final until = DateTime.utc(2026, 11, 23, 14);

  Widget host({required DateTime target, required void Function() onUnlocked, bool withUnlocked = false}) => ProviderScope(
        overrides: [clockProvider.overrideWithValue(() => now)],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: LockCountdown(
            lockedUntil: target,
            onUnlocked: onUnlocked,
            unlocked: withUnlocked ? (_) => const Text('open') : null,
            builder: (_, left) => Text(formatCountdown(left)),
          ),
        ),
      );

  Future<void> advance(WidgetTester t, Duration d) async {
    now = now.add(d);
    await t.pump(d);
  }

  setUp(() => now = until.subtract(const Duration(hours: 3, minutes: 27, seconds: 14)));

  testWidgets('ticks once a second and fires onUnlocked exactly once at zero', (t) async {
    var fired = 0;
    await t.pumpWidget(host(target: until, onUnlocked: () => fired++));
    expect(find.text('3:27:14'), findsOneWidget);
    await advance(t, const Duration(seconds: 1));
    expect(find.text('3:27:13'), findsOneWidget);
    await advance(t, const Duration(hours: 3, minutes: 27, seconds: 13));
    expect(find.text('00:00'), findsOneWidget);
    expect(fired, 1);
    await advance(t, const Duration(seconds: 5));
    expect(fired, 1);
    expect(find.text('00:00'), findsOneWidget, reason: 'never negative');
  });

  testWidgets('semantics label is in words', (t) async {
    await t.pumpWidget(host(target: until, onUnlocked: () {}));
    expect(find.bySemanticsLabel('Opens in 3 hours 28 minutes'), findsOneWidget);
  });

  testWidgets('swaps to the unlocked child at zero', (t) async {
    now = until.subtract(const Duration(seconds: 2));
    await t.pumpWidget(host(target: until, onUnlocked: () {}, withUnlocked: true));
    expect(find.text('00:02'), findsOneWidget);
    await advance(t, const Duration(seconds: 2));
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('already past: no negative time, fires once post-frame', (t) async {
    now = until.add(const Duration(minutes: 5));
    var fired = 0;
    await t.pumpWidget(host(target: until, onUnlocked: () => fired++, withUnlocked: true));
    await t.pump();
    expect(find.text('open'), findsOneWidget);
    expect(fired, 1);
    await t.pump(const Duration(seconds: 3));
    expect(fired, 1);
  });

  testWidgets('cancels its timer on dispose', (t) async {
    await t.pumpWidget(host(target: until, onUnlocked: () {}));
    await t.pumpWidget(const SizedBox());
    expect(t.binding.transientCallbackCount, 0);
    await t.pump(const Duration(seconds: 3));
  });
}
