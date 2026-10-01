import 'package:manhwamaniacs/features/circle/models/circle_models.dart';

/// "Hide from my Circle" / "Unhide" (glass 8.25.15): adds [s] or removes it; the whole list goes out through `sharingPatch`.
List<ExcludedSeries> toggleExcluded(List<ExcludedSeries> list, ExcludedSeries s) => list.contains(s) ? [for (final e in list) if (e != s) e] : [...list, s];

bool isExcluded(List<ExcludedSeries> list, String sourceId, String seriesKey) => list.any((e) => e.sourceId == sourceId && e.seriesKey == seriesKey);
