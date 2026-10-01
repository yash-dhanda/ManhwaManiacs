import 'dart:math' as math;
import 'dart:ui' show Color, Offset;

import 'package:manhwamaniacs/features/circle/models/circle_models.dart';

/// The reading-now ring colour: the series' `ambient.duo`, else the fallback `#B8B2A4`.
const Color ringFallback = Color(0xFFB8B2A4);

Color ringColour(CircleNow now) => now.ambient?.duo ?? ringFallback;

/// `Reading Omniscient Reader · CH 212` when the viewer has stored progress on `now.chapterKey`
/// (`source:series:chapter` keys in [viewerProgressKeys]), else without the chapter (the spoiler
/// guard for the folio).
String nowLabel(CircleNow now, Set<String> viewerProgressKeys) {
  final n = now.chapterNumber;
  final has = n != null && viewerProgressKeys.contains('${now.sourceId}:${now.seriesKey}:${now.chapterKey}');
  final ch = has ? ' · CH ${n == n.roundToDouble() ? n.toInt() : n}' : '';
  return 'Reading ${now.title}$ch';
}

// ── Glass presence arc (glass 9.3.1) ─────────────────────────────────────────

/// Where a member is: reading now (within 15 minutes of `now.since`; the server sends `now` only when `show_presence` is on),
/// active today (the viewer's local day), or away.
enum PresenceState { reading, today, away }

const Duration kReadingWindow = Duration(minutes: 15);

PresenceState presenceState(CircleMember m, DateTime now) {
  final n = m.now;
  if (n != null && (n.since == null || now.difference(n.since!) <= kReadingWindow)) {
    return PresenceState.reading;
  }
  final a = m.lastActiveAt?.toLocal(), l = now.toLocal();
  if (a != null && a.year == l.year && a.month == l.month && a.day == l.day) return PresenceState.today;
  return PresenceState.away;
}

DateTime _recency(CircleMember m) => m.now?.since ?? m.lastActiveAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

/// The arc read front to back: reading, then today, then away, each newest first.
List<CircleMember> arcOrder(List<CircleMember> ms, DateTime now) => [...ms]..sort((a, b) {
    final s = presenceState(a, now).index.compareTo(presenceState(b, now).index);
    return s != 0 ? s : _recency(b).compareTo(_recency(a));
  });

/// The orb size and brightness of a state: 64 / 1, 60 / 0.85, 56 / 0.7.
({double size, double brightness}) slotLook(PresenceState s) => switch (s) {
      PresenceState.reading => (size: 64.0, brightness: 1.0),
      PresenceState.today => (size: 60.0, brightness: 0.85),
      PresenceState.away => (size: 56.0, brightness: 0.7),
    };

/// One place on the arc (centre in the band's coordinates).
class ArcSlot {
  const ArcSlot({required this.centre, required this.size, required this.brightness});
  final Offset centre;
  final double size, brightness;
}

const double kArcSagitta = 24;

/// The front (lowest) point of the arc in the band: 24 px of sagitta above it plus room for the largest orb.
const double kArcFrontY = kArcSagitta + 32;

/// Slots along a shallow arc whose chord spans `width - 40` with a 24 px sagitta: slot 0 at the centre (the lowest point), then
/// alternating right and left, outward and higher. [states] gives each slot's look (away when absent).
List<ArcSlot> arcLayout(int count, double width, {List<PresenceState> states = const []}) {
  if (count <= 0) return const [];
  final a = math.max(1.0, (width - 40) / 2);
  const h = kArcSagitta;
  final r = (a * a + h * h) / (2 * h);
  final ring = ((count - 1) / 2).ceil();
  final step = ring == 0 ? 0.0 : math.min(76.0, a / ring);
  final cx = width / 2;
  return [
    for (var i = 0; i < count; i++)
      () {
        final k = (i + 1) ~/ 2;
        final dx = i == 0 ? 0.0 : (i.isOdd ? 1 : -1) * k * step;
        final y = kArcFrontY - (r - math.sqrt(math.max(0, r * r - dx * dx)));
        final look = slotLook(i < states.length ? states[i] : PresenceState.away);
        return ArcSlot(centre: Offset(cx + dx, y), size: look.size, brightness: look.brightness);
      }(),
  ];
}
