import 'dart:ui' show Color;

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
