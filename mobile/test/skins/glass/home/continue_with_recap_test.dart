import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/recap/recap_setting.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/continue_with_recap.dart';

final now = DateTime(2026, 9, 30, 12);

HomeContinueTarget target({int daysAgo = 10, bool available = true}) => HomeContinueTarget(
      sourceId: 's',
      seriesKey: 'k',
      chapterKey: 'c1',
      recap: RecapAvailability(available: available),
      lastReadAt: now.subtract(Duration(days: daysAgo)),
    );

ContinueDecision d(RecapSetting s, HomeContinueTarget t, {bool offer = true}) => decideContinue(setting: s, item: t, now: now, offerRegistered: offer);

void main() {
  test('off always dives', () {
    expect(d(const RecapSetting(mode: RecapMode.off), target()), ContinueDecision.dive);
  });
  test('always opens the recap after a day away, dives the same day or without availability', () {
    const s = RecapSetting(mode: RecapMode.always);
    expect(d(s, target()), ContinueDecision.recap);
    expect(d(s, target(daysAgo: 0)), ContinueDecision.dive);
    expect(d(s, target(available: false)), ContinueDecision.dive);
  });
  test('ask offers within the threshold no, beyond yes, skipped series never', () {
    const s = RecapSetting();
    expect(d(s, target(daysAgo: 6)), ContinueDecision.dive);
    expect(d(s, target(daysAgo: 7)), ContinueDecision.offer);
    expect(d(s, target(daysAgo: 30)), ContinueDecision.offer);
    expect(d(s.copyWith(skipSeries: ['s:k']), target()), ContinueDecision.dive);
  });
  test('the offer sheet absent falls back to the dive', () {
    expect(d(const RecapSetting(), target(), offer: false), ContinueDecision.dive);
  });
  test('locations', () {
    expect(target().readerLocation, contains('/reader/s/k/c1'));
    expect(const HomeContinueTarget(sourceId: 's', seriesKey: 'k', chapterKey: 'c', isNovel: true).readerLocation, contains('/novels/s/k/c'));
    expect(target().seriesId, 's:k');
  });
}
