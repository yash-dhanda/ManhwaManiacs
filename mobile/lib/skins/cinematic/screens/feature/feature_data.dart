import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/utils/resume_order.dart';

/// Everything the series page renders, resolved once by [FeatureView].
class FeatureData {
  const FeatureData({
    required this.sourceId,
    required this.seriesKey,
    required this.series,
    required this.chapters,
    this.followed,
  });

  final String sourceId;
  final String seriesKey;
  final SourceSeriesSummary series;
  final List<SourceChapterSummary> chapters;
  final FollowedSeries? followed;

  /// The same page data with another chapter list (offline and empty states).
  FeatureData withChapters(List<SourceChapterSummary> next) => FeatureData(
        sourceId: sourceId,
        seriesKey: seriesKey,
        series: series,
        chapters: next,
        followed: followed,
      );

  SeriesIdentity get identity => (sourceId: sourceId, seriesKey: seriesKey);
  bool get isFollowed => followed != null;
  String get title => series.title;

  /// Chapters oldest to newest, unnumbered ones last (the reading order).
  List<SourceChapterSummary> get readingOrder => readingOrderOf(chapters);
}
