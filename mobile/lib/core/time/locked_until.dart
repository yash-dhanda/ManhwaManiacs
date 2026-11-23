import 'package:manhwamaniacs/core/time/server_instant.dart';

/// Early-access chapters (a source's paying members get a chapter hours before
/// everyone else, yet it is listed for all).
///
/// The server sends the instant a chapter opens to everyone (`locked_until`);
/// whether it is still locked is decided here, by the device clock, and
/// nowhere else. A cached copy, a stale list or a notification read an hour
/// ago therefore stops saying "locked" on its own — nothing has to refetch to
/// find out a chapter opened.

/// The `locked_until` of a JSON object, or null when it is absent, null or
/// unparseable. A malformed value means "open": a chapter wrongly shown as
/// locked is worse than one that answers 423 when opened.
DateTime? lockedUntilOf(Object? raw) => serverInstant(raw);

/// True while [lockedUntil] is in the future at [now] (default: the device clock).
bool isLockedAt(DateTime? lockedUntil, [DateTime? now]) =>
    lockedUntil != null && lockedUntil.isAfter(now ?? DateTime.now());

/// The time left until [lockedUntil], never negative.
Duration lockRemaining(DateTime lockedUntil, [DateTime? now]) {
  final left = lockedUntil.difference(now ?? DateTime.now());
  return left.isNegative ? Duration.zero : left;
}

/// `3:27:14` over an hour, `27:14` under. Rounded UP to the second so the
/// display reads `0:01` until the instant has really passed rather than `0:00`
/// while the chapter is still shut.
String formatCountdown(Duration left) {
  final total = left.isNegative ? 0 : (left.inMicroseconds + 999999) ~/ 1000000;
  final h = total ~/ 3600, m = (total % 3600) ~/ 60, s = total % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// The countdown as words, for a screen reader: "3 hours 27 minutes", "27
/// minutes", "under a minute".
String spokenRemaining(Duration left) {
  final minutes = left.isNegative ? 0 : (left.inSeconds + 59) ~/ 60;
  final h = minutes ~/ 60, m = minutes % 60;
  String unit(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
  if (h == 0 && m == 0) return 'under a minute';
  return [if (h > 0) unit(h, 'hour'), if (m > 0) unit(m, 'minute')].join(' ');
}

/// A compact minute-granularity hint for lists: "3 h 27 min", "27 min", "<1 min".
String compactRemaining(Duration left) {
  final minutes = left.isNegative ? 0 : (left.inSeconds + 59) ~/ 60;
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0 && m == 0) return '<1 min';
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h $m min';
}

/// The clock time [lockedUntil] falls on in the device's local zone, as
/// "7:45 PM" (12-hour, as the app words times elsewhere).
String localOpenTime(DateTime lockedUntil) {
  final l = lockedUntil.toLocal();
  final h12 = l.hour % 12 == 0 ? 12 : l.hour % 12;
  return '$h12:${l.minute.toString().padLeft(2, '0')} ${l.hour < 12 ? 'AM' : 'PM'}';
}

/// How long after the instant a locked chapter is asked for again: the device
/// clock and the server's rarely agree to the second.
const Duration kLockRetryGrace = Duration(seconds: 4);
