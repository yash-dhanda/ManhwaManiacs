import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/recap/recap_setting.dart';
import 'package:manhwamaniacs/features/recap/utils/should_open_recap.dart';

void main() {
  final now = DateTime(2026, 9, 30, 12);
  DateTime ago(int d) => DateTime(2026, 9, 30 - d, 23, 59);
  RecapEntryDecision dec(RecapSetting s, {DateTime? last, bool available = true, String id = 's:k'}) => recapEntryDecision(setting: s, seriesId: id, lastReadAt: last, now: now, available: available);

  test('ask offers from seriesDays, always opens, off and skip and never-read and unavailable are none', () {
    const ask = RecapSetting();
    expect(dec(ask, last: ago(6)), RecapEntryDecision.none);
    expect(dec(ask, last: ago(7)), RecapEntryDecision.offer);
    expect(dec(ask, last: ago(21)), RecapEntryDecision.offer);
    expect(dec(const RecapSetting(mode: RecapMode.always), last: ago(7)), RecapEntryDecision.open);
    expect(dec(const RecapSetting(mode: RecapMode.always), last: ago(3)), RecapEntryDecision.none);
    expect(dec(const RecapSetting(mode: RecapMode.off), last: ago(30)), RecapEntryDecision.none);
    expect(dec(const RecapSetting(skipSeries: ['s:k']), last: ago(30)), RecapEntryDecision.none);
    expect(dec(ask), RecapEntryDecision.none);
    expect(dec(ask, last: ago(30), available: false), RecapEntryDecision.none);
  });

  test('chapter pill: gap of chapterDays, and below seriesDays or declined', () {
    bool pill(RecapSetting s, int d, {bool declined = false}) => chapterPillDecision(setting: s, lastReadAt: ago(d), now: now, seriesDeclined: declined);
    const s = RecapSetting();
    expect(pill(s, 2), isFalse);
    expect(pill(s, 3), isTrue);
    expect(pill(s, 4), isTrue);
    expect(pill(s, 7), isFalse);
    expect(pill(s, 7, declined: true), isTrue);
    expect(pill(const RecapSetting(mode: RecapMode.off), 4), isFalse);
    expect(chapterPillDecision(setting: s, now: now, seriesDeclined: false), isFalse);
  });
}
