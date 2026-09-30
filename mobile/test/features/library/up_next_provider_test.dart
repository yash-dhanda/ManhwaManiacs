import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/pagination.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart';
import 'package:manhwamaniacs/features/ai/repositories/ai_repository.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/library/providers/up_next_provider.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

class _Ai extends AiRepository {
  _Ai({this.similarItems = const [], this.genreItems = const [], this.available = true}) : super(Dio());
  final List<WorldItem> similarItems, genreItems;
  final bool available;
  @override
  Future<SimilarResult> similar(SimilarQuery q) async {
    final list = q.fallbackGenres ? genreItems : similarItems;
    return SimilarResult(items: list, available: available, reason: available ? 'ok' : 'not_configured', basis: q.fallbackGenres ? 'genres' : 'ai');
  }
}

class _Lib implements LibraryRepository {
  _Lib(this.rows);
  final List<FollowedSeries> rows;
  @override
  Future<Result<PagedResult<FollowedSeries>>> listSeries({int page = 1, int perPage = 40, String? sort, String? search, String? readingStatus, bool? isFavorite, List<int>? tagIds, bool? newOnly}) async =>
      Ok(PagedResult(items: rows, page: 1, perPage: perPage, total: rows.length, hasNext: false));
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

FollowedSeries _f(String key, {bool fav = false, String status = 'reading', int day = 1}) => FollowedSeries(
      id: key.hashCode,
      sourceId: 's',
      seriesKey: key,
      title: key,
      coverUrl: '',
      isFavorite: fav,
      readingStatus: status,
      notify: true,
      sortOrder: 0,
      contentRating: 'safe',
      rating: 'safe',
      chapterCount: 10,
      updatedAt: DateTime(2026, 1, day),
    );

ProviderContainer _c({required AiRepository ai, WorldRecommendations rec = const WorldRecommendations(), List<FollowedSeries> rows = const []}) {
  final c = ProviderContainer(overrides: [
    aiRepositoryProvider.overrideWithValue(ai),
    recommendationsProvider.overrideWith((ref) async => rec),
    libraryRepositoryProvider.overrideWithValue(_Lib(rows)),
  ],);
  addTearDown(c.dispose);
  return c;
}

const _key = (sourceId: 's', seriesKey: 'this', mode: UpNextMode.theEnd);
const _caught = (sourceId: 's', seriesKey: 'this', mode: UpNextMode.caughtUp);

void main() {
  test('Similar first, with the why line', () async {
    final c = _c(ai: _Ai(similarItems: [const WorldItem(title: 'A', why: 'same premise')]));
    final r = await c.read(upNextProvider(_key).future);
    expect(r.source, UpNextSource.similar);
    expect(r.items.single.why, 'same premise');
  });

  test('AI closed: same genres, and caughtUp stops there', () async {
    final ai = _Ai(available: false, genreItems: [const WorldItem(title: 'G')]);
    final r = await _c(ai: ai).read(upNextProvider(_caught).future);
    expect(r.source, UpNextSource.sameGenres);
    expect(r.reason, 'not_configured');
    final none = await _c(ai: _Ai(available: false), rec: const WorldRecommendations(sections: [WorldSection(becauseTitle: 'x', items: [WorldItem(title: 'R')])]))
        .read(upNextProvider(_caught).future);
    expect(none.source, UpNextSource.none);
  });

  test('theEnd continues to recommendations, then to the shelf', () async {
    const rec = WorldRecommendations(sections: [
      WorldSection(becauseTitle: 'empty'),
      WorldSection(becauseTitle: 'x', items: [WorldItem(title: 'R')]),
    ],);
    final a = await _c(ai: _Ai(available: false), rec: rec).read(upNextProvider(_key).future);
    expect(a.source, UpNextSource.recommendations);
    expect(a.items.single.title, 'R');

    final rows = [
      _f('planned-old', status: 'plan_to_read', day: 2),
      _f('fav-old', fav: true, day: 3),
      _f('fav-new', fav: true, day: 9),
      _f('done', fav: true, status: 'completed'),
      _f('this', fav: true, day: 20),
      _f('plain'),
      _f('planned-new', status: 'plan_to_read', day: 8),
    ];
    final b = await _c(ai: _Ai(available: false), rows: rows).read(upNextProvider(_key).future);
    expect(b.source, UpNextSource.shelf);
    expect([for (final i in b.items) i.title], ['fav-new', 'fav-old', 'planned-new', 'planned-old']);
  });
}
