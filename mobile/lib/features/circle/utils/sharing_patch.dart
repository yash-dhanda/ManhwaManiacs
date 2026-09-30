import 'package:manhwamaniacs/features/circle/models/circle_models.dart';

/// Only the keys that changed, partial bodies (glass 9.3). Cinematic has no switch for `show_presence` and `share_streak`, so it
/// never changes them and they are not sent from there; Glass Settings does (glass 8.25.15). `excluded_series` goes as the whole
/// list when it changed.
Map<String, Object?> sharingPatch(Sharing before, Sharing after) {
  final out = <String, Object?>{};
  if (before.activity != after.activity) out['activity'] = after.activity;
  if (before.reactions != after.reactions) out['reactions'] = after.reactions;
  if (before.shelves != after.shelves) out['shelves'] = after.shelves;
  if (before.recommendations != after.recommendations) out['recommendations'] = after.recommendations;
  if (before.includeMature != after.includeMature) out['include_mature'] = after.includeMature;
  if (before.showPresence != after.showPresence) out['show_presence'] = after.showPresence;
  if (before.shareStreak != after.shareStreak) out['share_streak'] = after.shareStreak;
  final a = before.excludedSeries, b = after.excludedSeries;
  if (a.length != b.length || [for (var i = 0; i < a.length; i++) a[i] == b[i]].contains(false)) {
    out['excluded_series'] = [for (final e in b) {'source_id': e.sourceId, 'series_key': e.seriesKey}];
  }
  return out;
}
