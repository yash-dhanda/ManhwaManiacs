import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/library_series_actions.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

FollowedSeries _s(int id, {bool fav = false, String status = 'reading', bool notify = false, bool? mature}) => FollowedSeries(
      id: id,
      sourceId: 'src',
      seriesKey: 'solo',
      title: 'Solo',
      coverUrl: '',
      isFavorite: fav,
      readingStatus: status,
      notify: notify,
      sortOrder: 0,
      contentRating: 'safe',
      rating: 'safe',
      matureOverride: mature,
      chapterCount: 3,
    );

class _Repo implements LibraryRepository {
  final log = <String>[];
  @override
  Future<Result<void>> unfollow(int followedId) async {
    log.add('DELETE /library/follow/$followedId');
    return const Ok(null);
  }

  @override
  Future<Result<FollowedSeries>> follow({required String sourceId, required String seriesKey}) async {
    log.add('POST /library/follow');
    return Ok(_s(77));
  }

  @override
  Future<Result<FollowedSeries>> patchSeries(int followedId,
      {bool? isFavorite, String? readingStatus, bool? notify, bool? matureOverride, bool clearMatureOverride = false, int? sortOrder,}) async {
    log.add('PATCH /library/series/$followedId fav=$isFavorite status=$readingStatus notify=$notify mature=$matureOverride');
    return Ok(_s(followedId, fav: isFavorite ?? false, status: readingStatus ?? 'reading', notify: notify ?? false, mature: matureOverride));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('Remove from library then Undo: DELETE, POST follow, then one PATCH restoring favourite, status, notify and mature override', () async {
    final repo = _Repo();
    final c = ProviderContainer(overrides: [libraryRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    final actions = c.read(librarySeriesActionsProvider);
    final series = _s(5, fav: true, status: 'on_hold', notify: true, mature: true);
    final removed = await actions.remove(series);
    expect(removed.error, isNull);
    expect(await actions.restore(series, slots: removed.slots), isNull);
    expect(repo.log, [
      'DELETE /library/follow/5',
      'POST /library/follow',
      'PATCH /library/series/77 fav=true status=on_hold notify=true mature=true',
    ]);
  });
}
