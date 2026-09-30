import 'package:manhwamaniacs/features/recap/recap_setting.dart';

/// Whole local calendar days between two instants (local timezone, by date not by 24 h).
int localDaysBetween(DateTime from, DateTime to) {
  final a = from.toLocal(), b = to.toLocal();
  return DateTime(b.year, b.month, b.day).difference(DateTime(a.year, a.month, a.day)).inDays;
}

bool _blocked(RecapSetting s, String seriesId) => s.mode == RecapMode.off || s.skipSeries.contains(seriesId);

/// Whether a `Continue` opens the recap first (glass 15.6, cinematic 9.1.5). [seriesId] is
/// `"{sourceId}:{seriesKey}"`.
bool shouldOpenRecapFirst({
  required RecapSetting setting,
  required String seriesId,
  required DateTime? lastReadAt,
  required DateTime now,
  required bool available,
}) =>
    available && mayAutoOpen(setting: setting, seriesId: seriesId, lastReadAt: lastReadAt, now: now);

/// The same checks without availability: whether a `Continue` whose item carries no `recap` must
/// ask the endpoint first.
bool mayAutoOpen({required RecapSetting setting, required String seriesId, required DateTime? lastReadAt, required DateTime now}) {
  if (_blocked(setting, seriesId) || lastReadAt == null) return false;
  final gap = localDaysBetween(lastReadAt, now);
  return switch (setting.mode) {
    RecapMode.always => gap >= 1,
    RecapMode.ask => gap >= setting.seriesDays,
    RecapMode.off => false,
  };
}

/// The reader's first-page chip: the gap is at least `seriesDays` (`ask`) or 14 days (`always` or
/// `off`), and a recap is available.
bool chipVisible({required RecapSetting setting, required DateTime? lastReadAt, required DateTime now, required bool available}) {
  if (!available || lastReadAt == null) return false;
  final need = setting.mode == RecapMode.ask ? setting.seriesDays : 14;
  return localDaysBetween(lastReadAt, now) >= need;
}
