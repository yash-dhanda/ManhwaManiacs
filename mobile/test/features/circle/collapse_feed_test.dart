import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/utils/collapse_feed.dart';

const aarav = ProfileRef(profileId: 2, name: 'Aarav');
const mira = ProfileRef(profileId: 3, name: 'Mira');

FeedItem f(String id, {FeedKind k = FeedKind.finishedChapter, ProfileRef who = aarav, String series = 'solo', double? n, required DateTime at}) =>
    FeedItem(id: id, kind: k, actor: who, sourceId: 's', seriesKey: series, title: 'Solo Leveling', chapterNumber: n, createdAt: at);

void main() {
  final day = DateTime.utc(2026, 9, 30, 10);
  test('consecutive finishes by one actor in one series on one day collapse to a range', () {
    final out = collapseReads([
      f('3', n: 152, at: day),
      f('2', n: 141, at: day.subtract(const Duration(hours: 1))),
      f('1', n: 140, at: day.subtract(const Duration(hours: 2))),
    ], utcOffset: Duration.zero,);
    expect(out, hasLength(1));
    expect(out.single.range, (140.0, 152.0));
    expect(out.single.item.id, '3');
    expect(out.single.items, hasLength(3));
  });
  test('another actor, series, kind or day breaks the run', () {
    final out = collapseReads([
      f('a', n: 3, at: day),
      f('b', n: 2, at: day, who: mira),
      f('c', n: 1, at: day, series: 'other'),
      f('d', k: FeedKind.started, at: day),
      f('e', k: FeedKind.started, at: day),
      f('g', n: 9, at: day.subtract(const Duration(days: 1))),
      f('h', n: 8, at: day),
    ], utcOffset: Duration.zero,);
    expect(out.map((e) => e.item.id), ['a', 'b', 'c', 'd', 'e', 'g', 'h']);
    expect(out.every((e) => e.range == null), isTrue);
  });
  test('the local day follows the offset', () {
    // 23:30 and 00:30 UTC are one day at +05:30 (05:00 and 06:00 on the 1st).
    final items = [f('2', n: 2, at: DateTime.utc(2026, 10, 1, 0, 30)), f('1', n: 1, at: DateTime.utc(2026, 9, 30, 23, 30))];
    expect(collapseReads(items, utcOffset: Duration.zero), hasLength(2));
    expect(collapseReads(items, utcOffset: const Duration(hours: 5, minutes: 30)), hasLength(1));
  });
}
