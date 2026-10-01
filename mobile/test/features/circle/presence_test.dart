import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/utils/presence.dart';

CircleMember m(int id, {DateTime? since, bool now = false, DateTime? active}) => CircleMember(
      profileId: id,
      name: 'M$id',
      now: now ? CircleNow(sourceId: 's', seriesKey: 'k', chapterKey: 'c', title: 'Omniscient Reader', since: since) : null,
      lastActiveAt: active,
    );

void main() {
  final t = DateTime(2026, 9, 30, 12);

  group('presenceState', () {
    test('reading within 15 minutes of now.since', () {
      expect(presenceState(m(1, now: true, since: t.subtract(const Duration(minutes: 15))), t), PresenceState.reading);
      expect(presenceState(m(1, now: true, since: t.subtract(const Duration(minutes: 15, seconds: 1)), active: t), t), PresenceState.today);
    });
    test('now null is never reading, even when active 5 minutes ago', () {
      expect(presenceState(m(1, active: t.subtract(const Duration(minutes: 5))), t), PresenceState.today);
    });
    test('the local midnight edge', () {
      expect(presenceState(m(1, active: DateTime(2026, 9, 30, 0, 0, 1)), t), PresenceState.today);
      expect(presenceState(m(1, active: DateTime(2026, 9, 29, 23, 59, 59)), t), PresenceState.away);
      expect(presenceState(m(1), t), PresenceState.away);
    });
  });

  test('arcOrder: reading, today, away, each newest first', () {
    final list = [
      m(1, active: t.subtract(const Duration(days: 3))),
      m(2, active: t.subtract(const Duration(hours: 2))),
      m(3, now: true, since: t.subtract(const Duration(minutes: 9))),
      m(4, active: t.subtract(const Duration(hours: 1))),
      m(5, now: true, since: t.subtract(const Duration(minutes: 2))),
      m(6, active: t.subtract(const Duration(days: 1))),
    ];
    expect(arcOrder(list, t).map((e) => e.profileId), [5, 3, 4, 2, 6, 1]);
  });

  group('arcLayout', () {
    test('a single member sits at the centre, lowest', () {
      final s = arcLayout(1, 390, states: const [PresenceState.reading]);
      expect(s, hasLength(1));
      expect(s.single.centre.dx, closeTo(195, 1e-9));
      expect(s.single.size, 64);
      expect(s.single.brightness, 1);
    });
    test('four are placed symmetrically: front centre, then right, left, right', () {
      final s = arcLayout(4, 390);
      expect(s[0].centre.dx, closeTo(195, 1e-9));
      expect(s[1].centre.dx, greaterThan(195));
      expect(s[2].centre.dx, lessThan(195));
      expect(s[1].centre.dx - 195, closeTo(195 - s[2].centre.dx, 1e-9));
      expect(s[1].centre.dy, closeTo(s[2].centre.dy, 1e-9));
      expect(s[1].centre.dy, lessThan(s[0].centre.dy));
      expect(s[3].centre.dy, lessThan(s[1].centre.dy));
      // The chord spans width - 40 with a 24 px sagitta: the ends sit 24 px above the front.
      for (final x in s) {
        expect(x.centre.dx, inInclusiveRange(20, 370));
        expect(s[0].centre.dy - x.centre.dy, inInclusiveRange(0, 24));
      }
    });
    test('slot sizes and brightness follow the states', () {
      expect(slotLook(PresenceState.reading), (size: 64.0, brightness: 1.0));
      expect(slotLook(PresenceState.today), (size: 60.0, brightness: 0.85));
      expect(slotLook(PresenceState.away), (size: 56.0, brightness: 0.7));
    });
  });
}
