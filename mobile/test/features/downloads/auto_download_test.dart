import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/utils/auto_download.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/updates/models/update_notification.dart';

const gb = 1024 * 1024 * 1024;

FollowedSeries follow(int id, {bool notify = true}) => FollowedSeries(
      id: id,
      sourceId: 'src',
      seriesKey: 's$id',
      title: 'Series $id',
      coverUrl: '',
      isFavorite: false,
      readingStatus: 'reading',
      notify: notify,
      sortOrder: 0,
      contentRating: 'safe',
      rating: '',
      chapterCount: 0,
    );

UpdateNotification note(int i, int followId, {bool read = false, String? key}) => UpdateNotification(
      id: i,
      followedSeriesId: followId,
      sourceId: 'src',
      seriesKey: 's$followId',
      chapterKey: key ?? 'c$i',
      chapterTitle: 'Chapter $i',
      chapterNumber: i.toDouble(),
      isRead: read,
    );

List<Object> plan(
  List<UpdateNotification> unread, {
  List<FollowedSeries>? follows,
  Set<String> saved = const {},
  int? free = 100 * gb,
  int? cap,
  int used = 0,
  bool wifiOnly = false,
  bool onWifi = true,
}) =>
    planAutoDownload(
      unread: unread,
      follows: follows ?? [follow(1), follow(2)],
      savedKeys: saved,
      freeBytes: free,
      capBytes: cap,
      usedBytes: used,
      wifiOnly: wifiOnly,
      onWifi: onWifi,
    );

void main() {
  test('unread notifications of followed series only', () {
    final r = plan([note(1, 1), note(2, 1, read: true), note(3, 9)]);
    expect(r, hasLength(1));
  });

  test('a series with notify off is skipped', () {
    expect(plan([note(1, 1), note(2, 2)], follows: [follow(1), follow(2, notify: false)]), hasLength(1));
  });

  test('chapters already saved are skipped', () {
    expect(plan([note(1, 1), note(2, 1)], saved: {'src s1 c1'}), hasLength(1));
  });

  test('the 1.5 GB floor stops the plan before it is crossed', () {
    // 8 MB per chapter: free = floor + 20 MB fits two chapters, not three.
    final r = plan([for (var i = 1; i <= 5; i++) note(i, 1)], free: kFreeSpaceFloorBytes + 20 * 1024 * 1024);
    expect(r, hasLength(2));
  });

  test('the cap stops the plan before used would pass it', () {
    final r = plan([for (var i = 1; i <= 5; i++) note(i, 1)], cap: 100 * 1024 * 1024, used: 84 * 1024 * 1024);
    expect(r, hasLength(2));
  });

  test('Wi-Fi only off Wi-Fi queues nothing; on Wi-Fi queues', () {
    expect(plan([note(1, 1)], wifiOnly: true, onWifi: false), isEmpty);
    expect(plan([note(1, 1)], wifiOnly: true), hasLength(1));
  });

  test('at most 20 chapters', () {
    expect(plan([for (var i = 1; i <= 40; i++) note(i, 1)]), hasLength(20));
  });

  test('the toast line', () {
    expect(queuedNewChaptersLine(6), 'Queued 6 new chapters.');
    expect(queuedNewChaptersLine(1), 'Queued 1 new chapter.');
  });
}
