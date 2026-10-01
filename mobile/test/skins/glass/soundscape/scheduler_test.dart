import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/mixer.dart';

List<ScheduledEvent> run(EventScheduler s, Duration total) {
  final out = <ScheduledEvent>[];
  for (var t = EventScheduler.tick; t <= total; t += EventScheduler.tick) {
    out.addAll(s.advance(t));
  }
  return out;
}

void main() {
  test('at 6 per second over 10 s of virtual time there are 45 to 75 events', () {
    final ev = run(EventScheduler(rate: 6, bank: 12), const Duration(seconds: 10));
    expect(ev.length, inInclusiveRange(45, 75));
    expect(ev.every((e) => e.bankIndex >= 0 && e.bankIndex < 12 && e.r >= 0 && e.r < 1), isTrue);
  });

  test('never plays an event before the window start', () {
    const start = Duration(seconds: 3);
    final ev = run(EventScheduler(rate: 6, bank: 12, startAt: start), const Duration(seconds: 10));
    expect(ev, isNotEmpty);
    expect(ev.every((e) => e.at >= start), isTrue);
  });

  test('the same seed gives the same events', () {
    final a = run(EventScheduler(rate: 6, bank: 12, seed: 9), const Duration(seconds: 5));
    final b = run(EventScheduler(rate: 6, bank: 12, seed: 9), const Duration(seconds: 5));
    expect([for (final e in a) (e.at, e.bankIndex, e.r)], [for (final e in b) (e.at, e.bankIndex, e.r)]);
  });

  test('rain droplets pan between -0.8 and 0.8 and the rate walks inside 8-20', () {
    final s = EventScheduler(rate: 14, bank: 12, panRange: 0.8, walk: true);
    final ev = run(s, const Duration(seconds: 60));
    expect(ev.every((e) => e.pan.abs() <= 0.8), isTrue);
    expect(s.currentRate, inInclusiveRange(8, 20));
    expect(ev.length, greaterThan(60 * 6));
  });

  test('level bars: 8 values in 0-1, bars 1-3 follow the bed and 7-8 the tone', () {
    final m = LevelMeter();
    final f = m.frame((l) => l.name == 'bed' ? 1.0 : 0.0);
    expect(f.length, 8);
    expect(f.sublist(0, 3).every((v) => v > 0 && v <= 1), isTrue);
    expect(f.sublist(3).every((v) => v == 0), isTrue);
  });
}
