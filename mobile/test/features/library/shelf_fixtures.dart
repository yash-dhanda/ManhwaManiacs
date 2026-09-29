import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/read_state.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';

/// An invented followed series for the shelf tests.
FollowedSeries shelfSeries(
  int id, {
  String? title,
  String source = 'shelf',
  bool fav = false,
  String status = 'reading',
  int? newCount,
  bool started = true,
  int sortOrder = 0,
  String rating = 'safe',
  int chapters = 40,
  double? chapter,
  List<Tag> tags = const [],
  String cover = '',
  DateTime? lastReadAt,
}) =>
    FollowedSeries(
      id: id,
      sourceId: source,
      seriesKey: 'series-$id',
      title: title ?? 'Series $id',
      coverUrl: cover,
      isFavorite: fav,
      readingStatus: status,
      notify: false,
      sortOrder: sortOrder,
      contentRating: 'safe',
      rating: rating,
      chapterCount: chapters,
      readState: ReadState(
        started: started,
        chapterKey: started ? 'c${chapter?.toInt() ?? 12}' : null,
        chapterNumber: started ? (chapter ?? 12) : null,
        position: started ? (chapter?.toInt() ?? 12) : null,
        total: chapters,
        latestNumber: chapters.toDouble(),
        newCount: newCount,
        lastReadAt: lastReadAt,
      ),
      tags: tags,
    );

/// The JSON `GET /library/series` sends for [s].
Map<String, dynamic> shelfJson(FollowedSeries s) => s.toJson();
