import 'package:manhwamaniacs/core/utils/pagination.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/reader/models/reader_chapter.dart';
import 'package:manhwamaniacs/features/reader/models/reader_page.dart';
import 'package:manhwamaniacs/features/sources/models/series_enrichment.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';

abstract interface class SourcesRepository {
  Future<Result<List<SourceSummary>>> listSources();

  /// Federated search across the local library and every visible source,
  /// grouped per source. Backed by `GET /sources/search`; the shared Dio
  /// attaches the bearer token and `X-Profile-Id`, so results are already
  /// account-, profile- and mature-scoped server-side.
  Future<Result<GroupedSearchResult>> searchGrouped(
    String query, {
    int page = 1,
    int perPage = 40,
    int? tier,
  });

  /// The caller's pinned sources, in display order.
  Future<Result<List<SourcePin>>> listPins();

  /// Replace the whole pinned set — this is not an incremental add/remove, the
  /// array order *is* the display order. Returns the stored set.
  Future<Result<List<SourcePin>>> replacePins(List<String> sourceIds);

  /// `GET /sources/{id}/genres`.
  /// `GET /sources/{id}/chapters/{key}/pages`.
  Future<Result<List<ReaderPage>>> getChapterPages(
      String sourceId, String chapterKey,);

  Future<Result<List<SourceGenre>>> listGenres(String sourceId);

  /// `GET /sources/health`, worst first.
  Future<Result<List<SourceSummary>>> listHealth();

  /// `GET /system/source-health`.
  Future<Result<SourceHealthSummary>> healthSummary();

  Future<Result<List<SourceBrowseMode>>> listBrowseModes(String sourceId);

  Future<Result<PagedResult<SourceSeriesSummary>>> listSeries(
    String sourceId, {
    int page = 1,
    String? query,
    String? sort,
    String? genre,
    bool refresh = false,
  });

  Future<Result<SourceSeriesSummary>> getSeries(
      String sourceId, String seriesId,);

  Future<Result<List<SourceChapterSummary>>> getChapters(
    String sourceId,
    String seriesId,
  );

  /// Unified reader payload for an online chapter (pages + adjacent chapter
  /// ids). Hits ``GET /sources/{sourceId}/series/{seriesId}/chapters/{chapterId}/reader``.
  Future<Result<ReaderChapter>> getReaderChapter(
    String sourceId,
    String seriesId,
    String chapterId,
  );

  /// `GET /series/enrichment?source=&series=`: the AniList credits block, or
  /// `null` (as `Ok(null)`) when there is no confident match.
  Future<Result<SeriesEnrichment?>> seriesEnrichment(
    String sourceId,
    String seriesKey,
  );
}
