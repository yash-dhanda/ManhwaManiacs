import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/recap/recap_setting.dart';
import 'package:manhwamaniacs/features/recap/utils/should_open_recap.dart';

void main() {
  final now = DateTime(2026, 9, 30, 10);
  DateTime ago(int days, {int hour = 10}) => DateTime(2026, 9, 30 - days, hour);
  const ask = RecapSetting();
  const always = RecapSetting(mode: RecapMode.always);
  const off = RecapSetting(mode: RecapMode.off);
  bool open(RecapSetting s, DateTime? last, {bool avail = true, String id = 's:k'}) =>
      shouldOpenRecapFirst(setting: s, seriesId: id, lastReadAt: last, now: now, available: avail);

  test('ask: the gap in local days against seriesDays', () {
    expect(open(ask, ago(7)), isTrue);
    expect(open(ask, ago(6)), isFalse);
    expect(open(ask, ago(7, hour: 23)), isTrue, reason: 'days count by calendar date');
    expect(open(ask, ago(6, hour: 0)), isFalse);
  });
  test('always: a different local day', () {
    expect(open(always, ago(1, hour: 23)), isTrue);
    expect(open(always, DateTime(2026, 9, 30, 0, 5)), isFalse);
  });
  test('off, skipSeries, unavailable and never read', () {
    expect(open(off, ago(30)), isFalse);
    expect(open(always.copyWith(skipSeries: ['s:k']), ago(30)), isFalse);
    expect(open(ask, ago(30), avail: false), isFalse);
    expect(open(ask, null), isFalse);
  });
  test('mayAutoOpen ignores availability', () {
    expect(mayAutoOpen(setting: ask, seriesId: 's:k', lastReadAt: ago(9), now: now), isTrue);
    expect(mayAutoOpen(setting: off, seriesId: 's:k', lastReadAt: ago(9), now: now), isFalse);
  });
  test('chipVisible: seriesDays for ask, 14 days otherwise', () {
    bool chip(RecapSetting s, int d, {bool avail = true}) => chipVisible(setting: s, lastReadAt: ago(d), now: now, available: avail);
    expect(chip(ask, 7), isTrue);
    expect(chip(ask, 6), isFalse);
    expect(chip(always, 13), isFalse);
    expect(chip(always, 14), isTrue);
    expect(chip(off, 14), isTrue);
    expect(chip(ask, 30, avail: false), isFalse);
  });
}
