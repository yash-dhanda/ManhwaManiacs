import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/updates/models/update_notification.dart';
import 'package:manhwamaniacs/features/updates/utils/notification_grouping.dart';

import '../library/shelf_fixtures.dart';

UpdateNotification _n(int id, String series, double ch, DateTime at, {bool read = false, String source = 'demo'}) => UpdateNotification(
      id: id,
      followedSeriesId: 1,
      sourceId: source,
      seriesKey: series,
      chapterKey: 'c$ch',
      chapterTitle: 'Chapter $ch',
      chapterNumber: ch,
      isRead: read,
      createdAt: at,
    );

void main() {
  final now = DateTime(2026, 9, 30, 12);

  test('day labels: TODAY, YESTERDAY, then the English date in capitals', () {
    expect(dayLabel(DateTime(2026, 9, 30, 1), now), 'TODAY');
    expect(dayLabel(DateTime(2026, 9, 29, 23), now), 'YESTERDAY');
    expect(dayLabel(DateTime(2026, 9, 28, 9), now), 'MONDAY 28 SEPTEMBER');
    expect(dayLabel(DateTime(2026), DateTime(2026, 1, 2)), 'YESTERDAY');
  });

  test('groups by day, then by series; chapters ascend, groups run newest first', () {
    final days = groupNotifications([
      _n(1, 'a', 142, DateTime(2026, 9, 30, 9)),
      _n(2, 'a', 141, DateTime(2026, 9, 30, 8)),
      _n(3, 'b', 5, DateTime(2026, 9, 30, 10)),
      _n(4, 'a', 140, DateTime(2026, 9, 29, 20), read: true),
    ], now, followed: [shelfSeries(1, title: 'Alpha')],);
    expect(days.map((d) => d.label), ['TODAY', 'YESTERDAY']);
    expect(days[0].groups.map((g) => g.seriesKey), ['b', 'a']);
    final a = days[0].groups[1];
    expect(a.chapters.map((c) => c.chapterNumber), [141, 142]);
    expect(a.unread, 2);
    expect(firstUnread(a)!.chapterNumber, 141);
    expect(days[1].groups.single.allRead, isTrue);
    expect(firstUnread(days[1].groups.single), isNull);
  });

  test('the source filter keeps one source only', () {
    final days = groupNotifications([
      _n(1, 'a', 1, DateTime(2026, 9, 30, 9)),
      _n(2, 'b', 1, DateTime(2026, 9, 30, 9), source: 'other'),
    ], now, sourceId: 'other',);
    expect(days.single.groups.single.seriesKey, 'b');
  });
}
