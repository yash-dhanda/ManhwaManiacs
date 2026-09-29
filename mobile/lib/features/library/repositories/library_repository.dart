import 'package:manhwamaniacs/core/utils/pagination.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/collection_detail.dart';
import 'package:manhwamaniacs/features/library/models/continue_reading_item.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/library/models/series_detail.dart';
import 'package:manhwamaniacs/features/library/models/suggestion.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';

/// What a repoint answers: the moved follow and where reading resumes.
typedef RepointResult = ({
  FollowedSeries followed,
  String? mappedChapterKey,
  double? mappedChapterNumber,
});

/// The per-profile library — source-native (spec §4.2). A series is in the
/// library iff a `followed_series` row exists for it; identity is
/// `(sourceId, seriesKey)`, with the row's own `id` (`followedId`) a handle
/// for the mutation/detail routes only.
abstract interface class LibraryRepository {
  Future<Result<PagedResult<FollowedSeries>>> listSeries({
    int page = 1,
    int perPage = 40,
    String? sort,
    String? search,
    String? readingStatus,
    bool? isFavorite,
  });

  Future<Result<SeriesDetail>> getSeries(int followedId);

  Future<Result<FollowedSeries>> follow({
    required String sourceId,
    required String seriesKey,
  });

  Future<Result<void>> unfollow(int followedId);

  Future<Result<FollowedSeries>> patchSeries(
    int followedId, {
    bool? isFavorite,
    String? readingStatus,
    bool? notify,
    bool? matureOverride,
    bool clearMatureOverride = false,
    int? sortOrder,
  });

  /// `POST /library/series/{id}/repoint`: move a follow to another source.
  Future<Result<RepointResult>> repoint(
    int followedId, {
    required String sourceId,
    required String seriesKey,
    required bool keepOld,
  });

  Future<Result<List<ContinueReadingItem>>> continueReading({int limit = 10});

  Future<Result<List<FollowedSeries>>> recentlyUpdated({int limit = 10});

  /// `GET /library/recommendations?limit=` — the profile's gated genre affinity.
  Future<Result<List<GenreWeight>>> genreWeights({int limit = 40});

  /// "For you" plus one "Because you read …" row per seed, drawn from the
  /// worldwide catalog; each title says which of the reader's sources carry
  /// it. [seeds] 1–8, [perSeed] 3–15.
  Future<Result<WorldRecommendations>> worldRecommendations({
    int seeds = 5,
    int perSeed = 10,
  });

  /// Describe what you feel like reading; get titles from the worldwide
  /// catalog, each with why it fits. [limit] 1–15.
  ///
  /// One call here is one paid API request on the server, so this is only ever
  /// fired by an explicit submit — never on mount, never per keystroke.
  Future<Result<WorldSuggestResponse>> worldSuggest(
    String prompt, {
    int limit = 12,
  });

  /// Whether [worldSuggest] can run. Free and local on the server; call it on
  /// mount.
  Future<Result<SuggestionAvailability>> suggestAvailability();

  Future<Result<PagedResult<FollowedSeries>>> search(
    String query, {
    int page = 1,
    int perPage = 20,
  });

  Future<Result<LibraryStatistics>> statistics();

  /// Recently read, newest first.
  ///
  /// [bySeries] collapses to one row per BOOK — the furthest-read chapter in
  /// each — which is what a "what have I been reading" screen wants. Pass
  /// false for the raw position list.
  Future<Result<List<ReadingHistoryItem>>> readingHistory({
    int limit = 50,
    int offset = 0,
    bool bySeries = true,
  });

  Future<Result<List<Collection>>> listCollections();

  Future<Result<CollectionDetail>> getCollection(int collectionId);

  Future<Result<Collection>> createCollection({
    required String name,
    String? description,
  });

  Future<Result<Collection>> updateCollection(
    int collectionId, {
    String? name,
    String? description,
    int? sortOrder,
  });

  Future<Result<void>> deleteCollection(int collectionId);

  Future<Result<CollectionDetail>> addSeriesToCollection(
    int collectionId, {
    required String sourceId,
    required String seriesKey,
  });

  Future<Result<void>> removeSeriesFromCollection(
    int collectionId, {
    required String sourceId,
    required String seriesKey,
  });

  Future<Result<List<Tag>>> listTags({String? category});

  Future<Result<Tag>> createTag({
    required String name,
    String category = 'custom',
    String? color,
  });

  Future<Result<void>> deleteTag(int tagId);

  Future<Result<void>> addTagToSeries({
    required String sourceId,
    required String seriesKey,
    required int tagId,
  });

  Future<Result<void>> removeTagFromSeries({
    required String sourceId,
    required String seriesKey,
    required int tagId,
  });
}
