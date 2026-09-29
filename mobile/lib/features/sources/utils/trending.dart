import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';

class TrendingTitle {
  const TrendingTitle(
      {required this.title, required this.sourceId, required this.seriesKey,});

  final String title;
  final String sourceId;
  final String seriesKey;
}

/// At most 10 titles: the first two per pinned source in pin order, de-duplicated
/// by case-folded title. A source with no `popular` page contributes nothing.
List<TrendingTitle> buildTrending(
  List<SourcePin> pinned,
  Map<String, List<SourceSeriesSummary>> popularFirstPage,
) {
  final seen = <String>{};
  final out = <TrendingTitle>[];
  for (final pin in pinned) {
    var taken = 0;
    for (final s
        in popularFirstPage[pin.sourceId] ?? const <SourceSeriesSummary>[]) {
      if (taken == 2 || out.length == 10) break;
      if (!seen.add(s.title.toLowerCase())) continue;
      out.add(TrendingTitle(
          title: s.title, sourceId: pin.sourceId, seriesKey: s.id,),);
      taken++;
    }
  }
  return out;
}
