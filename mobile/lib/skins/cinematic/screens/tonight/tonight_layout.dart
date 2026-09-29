import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Geometry and pure helpers of the Tonight screen (cinematic 8.8, 8.0.9, 13 moment 17).

/// A wide layout: the tablet spread and 8-column grid (cinematic 8.0.9).
bool tonightWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 600;

/// The cover height on phones: `min(width x 1.25, 0.70 x screen height)`.
double phoneCoverHeight(Size screen) => math.min(screen.width * 1.25, 0.70 * screen.height);

/// The spread height on tablets: `clamp(560, 0.72 x screen height, 820)`.
double spreadHeight(Size screen) => (0.72 * screen.height).clamp(560.0, 820.0);

/// The trailer scrub progress (cinematic 8.8): 0 until the last 240 px of the header's compression,
/// 1 when it is the 64 px strip.
double scrubProgress(double shrinkOffset, double maxExtent, double minExtent) =>
    ((shrinkOffset - (maxExtent - minExtent - 240)) / 240).clamp(0.0, 1.0);

/// A linear 0..1 ramp of [p] between [from] and [to].
double ramp(double p, double from, double to) => ((p - from) / (to - from)).clamp(0.0, 1.0);

/// `scrim.foot` (cinematic 2.8.2): the 13 eased stops of `CineScrim` into [tint], reaching alpha 1
/// at [solidAtPx] and staying solid to [height].
LinearGradient scrimFoot(Color tint, double solidAtPx, double height) {
  final solid = solidAtPx.clamp(1.0, height);
  final start = math.max(0.0, solid - 0.6 * height);
  final span = solid - start;
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [
      0.0,
      for (final s in CineScrim.kScrimStops) (start + s * span) / height,
      1.0,
    ].fold<List<double>>([], (out, v) => out..add(out.isNotEmpty && v <= out.last ? out.last + 1e-6 : v.clamp(0.0, 1.0))),
    colors: [
      tint.withValues(alpha: 0),
      for (final a in CineScrim.kScrimAlpha) tint.withValues(alpha: a),
      tint,
    ],
  );
}

/// The type role a headline is set in, stepped down until it fits [maxLines] (cinematic 3.1).
CineTextRole fitCoverRole(BuildContext context, String text, double width, {required int maxLines, bool wide = false}) {
  final c = context.cine;
  final roles = wide ? [c.typeCover, c.typeMasthead, c.typeHeadline] : [c.typeCover, c.typeMasthead, c.typeHeadline];
  for (final r in roles) {
    if (_lines(context, text, r, width) <= maxLines) return r;
  }
  return roles.last;
}

int _lines(BuildContext context, String text, CineTextRole role, double width) {
  final p = TextPainter(
    text: TextSpan(text: text, style: CineText.style(context, role)),
    textDirection: TextDirection.ltr,
    textScaler: CineText.scaler(context, role),
  )..layout(maxWidth: width);
  final n = p.computeLineMetrics().length;
  p.dispose();
  return n;
}

/// The painted height of [text] set in [role] across [width].
double measureText(BuildContext context, String text, CineTextRole role, double width, {int? maxLines}) {
  final p = TextPainter(
    text: TextSpan(text: text, style: CineText.style(context, role)),
    textDirection: TextDirection.ltr,
    textScaler: CineText.scaler(context, role),
    maxLines: maxLines,
    ellipsis: maxLines == null ? null : '…',
  )..layout(maxWidth: width);
  final h = p.height;
  p.dispose();
  return h;
}

/// The Hero tags of a feed, one holder per `(sourceId, seriesKey)`: the first widget in reading
/// order (the cover story, then each section) owns it, so one page never carries two Heroes of the
/// same tag (a flight would throw).
class HeroTags {
  HeroTags._(this._owner);
  final Map<String, (String, String)> _owner;

  /// Which widget claims which tag, keyed by `'cover'`, `'also:<i>'` or `'<sectionIndex>:<itemIndex>'`.
  factory HeroTags.of(HomeFeed feed) {
    final seen = <(String, String)>{};
    final owner = <String, (String, String)>{};
    void claim(String id, String? source, String? series) {
      if (source == null || series == null) return;
      final tag = (source, series);
      if (seen.add(tag)) owner[id] = tag;
    }

    final c = feed.cover;
    if (c != null) claim('cover', c.sourceId, c.seriesKey);
    for (var i = 0; i < feed.also.length; i++) {
      claim('also:$i', feed.also[i].sourceId, feed.also[i].seriesKey);
    }
    for (var s = 0; s < feed.sections.length; s++) {
      final items = feed.sections[s].items;
      for (var i = 0; i < items.length; i++) {
        final it = items[i];
        if (it is HomeContinueItem) claim('$s:$i', it.row.sourceId, it.row.seriesKey);
        if (it is HomeSeriesItem) claim('$s:$i', it.series.sourceId, it.series.seriesKey);
        if (it is HomePickItem) {
          if (it.source != null) claim('$s:$i', it.source!.sourceId, it.source!.id);
          final w = it.world;
          if (w != null && w.available.length == 1) claim('$s:$i', w.available.first.sourceId, w.available.first.seriesKey);
        }
        if (it is HomeSavedItem) claim('$s:$i', it.sourceId, it.seriesKey);
      }
    }
    return HeroTags._(owner);
  }

  (String, String)? of(String id) => _owner[id];
}

/// Folio captions (cinematic 8.8 table).
String chapterFolio(double? n, {int? percent}) {
  final ch = n == null ? '' : ' ${n % 1 == 0 ? n.toInt() : n}';
  return percent == null ? 'CH$ch'.trim() : 'CH$ch · $percent%'.trim();
}

/// `3 WEEKS AGO`, `4 D AGO`, `2 MONTHS AGO` for Where were we?.
String agoCaption(DateTime? at, DateTime now) {
  if (at == null) return '';
  final d = now.difference(at).inDays;
  if (d < 7) return '${math.max(d, 1)} D AGO';
  if (d < 35) return '${d ~/ 7} ${d ~/ 7 == 1 ? 'WEEK' : 'WEEKS'} AGO';
  final m = math.max(1, d ~/ 30);
  return '$m ${m == 1 ? 'MONTH' : 'MONTHS'} AGO';
}

/// `3 H 20 M` from seconds (the numbers teaser's TIME READ).
String hoursMinutes(int seconds) {
  final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60;
  if (h == 0) return '$m M';
  return m == 0 ? '$h H' : '$h H $m M';
}

/// `3 H` for a section whose copy was saved, from a stale timestamp.
String ageShort(DateTime at, DateTime now) {
  final d = now.difference(at);
  if (d.inDays >= 1) return '${d.inDays} D';
  if (d.inHours >= 1) return '${d.inHours} H';
  return '${math.max(1, d.inMinutes)} M';
}

/// `PICKED 3 DAYS AGO` for an AI section older than 24 h, else null.
String? pickedAgo(DateTime? at, DateTime now) {
  if (at == null) return null;
  final d = now.difference(at);
  if (d.inHours < 24) return null;
  final days = d.inDays;
  return days == 1 ? '1 DAY AGO' : '$days DAYS AGO';
}
