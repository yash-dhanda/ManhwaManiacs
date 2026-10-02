import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/utils/series_identity.dart';

FollowedSeries _f(int id, String key, {String source = 'asurascans'}) => FollowedSeries(
      id: id,
      sourceId: source,
      seriesKey: key,
      title: 'Killer Pietro',
      coverUrl: '',
      isFavorite: false,
      readingStatus: 'reading',
      notify: false,
      sortOrder: 0,
      contentRating: 'safe',
      rating: 'safe',
      chapterCount: 10,
    );

void main() {
  test('followFor finds an Asura follow under a rotated key', () {
    final old = _f(1, 'killer-pietro-0a1b2c3d');
    expect(followFor([old], 'asurascans', 'killer-pietro-ffeeddcc'), same(old));
    expect(followFor([old], 'mangadex', 'killer-pietro-ffeeddcc'), isNull);
  });

  test('followFor prefers the exact key', () {
    final a = _f(1, 'killer-pietro-0a1b2c3d'), b = _f(2, 'killer-pietro-ffeeddcc');
    expect(followFor([a, b], 'asurascans', 'killer-pietro-ffeeddcc'), same(b));
  });

  test('pinnedFollow: unfollow clears it, undo under a new id finds it again', () {
    final pinned = _f(7, 'x-0a1b2c3d');
    expect(pinnedFollow(pinned, null), same(pinned));
    expect(pinnedFollow(pinned, const []), isNull);
    final restored = _f(99, 'x-0a1b2c3d');
    expect(pinnedFollow(pinned, [restored]), same(restored));
  });
}
