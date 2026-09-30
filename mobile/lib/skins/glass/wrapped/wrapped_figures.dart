import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/shareable.dart';
import 'package:manhwamaniacs/features/library/utils/wrapped_cards.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart' show GenreWeight;
import 'package:manhwamaniacs/skins/glass/primitives/cards/source_monogram.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/clock_painter.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/radar_painter.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/streak_flame.dart';
import 'package:manhwamaniacs/skins/glass/screens/stats/stats_format.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/page_pile.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/podium.dart';
import 'package:manhwamaniacs/skins/glass/wrapped/wrapped_copy.dart';

/// Draws one cover: a live `GlassCoverImage` on screen, a precached image in a share PNG.
typedef CoverBuilder = Widget Function(String? url, double width, double height, double radius);

/// What a figure needs. [data] is null on screen (the profile's own data) and the `shareEligible` result in a share (nothing else may be
/// drawn); [flame] and [orb] are live-only extras (a share draws the flame at rest and no orbs).
class FigureInput {
  const FigureInput({
    required this.card,
    required this.annual,
    required this.cover,
    this.data,
    this.progress = 1,
    this.podiumMs = 10000,
    this.pile,
    this.flame,
    this.orb,
    this.togetherName,
    this.togetherTitle,
    this.onText,
    this.share = false,
  });

  final WrappedCard card;
  final Annual annual;
  final CoverBuilder cover;
  final ShareData? data;
  final double progress;
  final double podiumMs;
  final PagePile? pile;
  final Widget? flame;
  final Widget Function(String name, double size)? orb;
  final String? togetherName;
  final String? togetherTitle;

  /// Debug recorder of every string drawn (the mature-rule tests).
  final void Function(String text)? onText;
  final bool share;
}

/// Series a figure may draw: [data] in a share, else the annual's own lists.
List<ShareSeries> _series(FigureInput i, {int n = 5}) => (i.data?.series ?? i.annual.topSeries).take(n).toList();

List<GenreWeight> _genres(FigureInput i) => (i.data?.genres ?? i.annual.genres);

Widget _text(FigureInput i, String text, GlassTypeRole role, {Color? color, TextAlign align = TextAlign.center, int maxLines = 1, bool italic = false, double? size, int? wght}) {
  i.onText?.call(text);
  return GlassLabel(text, role: role, color: color ?? gt.colorLabel1, maxLines: maxLines, italic: italic, size: size, wght: wght, maxScale: 1, textAlign: align);
}

/// The 312 x 304 figure of [i].card. Laid out in frame units; scale it with a `FittedBox` or `figureFit`.
Widget wrappedFigure(FigureInput i) => SizedBox(width: 312, height: 304, child: _body(i));

Widget _body(FigureInput i) {
  switch (i.card) {
    case WrappedCard.cover:
      return _cover(i);
    case WrappedCard.time:
      return _time(i);
    case WrappedCard.volume:
      return _volume(i);
    case WrappedCard.topFive:
      return _podium(i);
    case WrappedCard.genres:
      return _radar(i);
    case WrappedCard.when:
      return _clock(i);
    case WrappedCard.streak:
      return _streak(i);
    case WrappedCard.busiestDay:
      return _busiest(i);
    case WrappedCard.firstsLasts:
      return _firsts(i);
    case WrappedCard.topSource:
      return _source(i);
    case WrappedCard.together:
      return _together(i);
    case WrappedCard.summary:
      return _summary(i);
  }
}

Widget _fan(FigureInput i, List<ShareSeries> s, {required double w, required double h, required double overlap, required double maxAngle, double top = 0}) {
  final n = s.length;
  if (n == 0) return const SizedBox.shrink();
  final step = w * (1 - overlap);
  final total = w + step * (n - 1);
  final left0 = (312 - total) / 2;
  return Stack(clipBehavior: Clip.none, children: [
    for (var k = 0; k < n; k++)
      Positioned(
        left: left0 + step * k,
        top: top,
        child: Transform.rotate(angle: (n == 1 ? 0 : (k / (n - 1) * 2 - 1)) * maxAngle * math.pi / 180, child: i.cover(s[k].coverUrl, w, h, w <= 64 ? 8 : 14)),
      ),
  ],);
}

Widget _cover(FigureInput i) {
  final s = _series(i, n: 3);
  return Stack(clipBehavior: Clip.none, children: [
    _fan(i, s, w: 112, h: 168, overlap: 0.3, maxAngle: 6, top: 56),
    if (i.orb != null) Positioned(left: 128, top: 248, child: i.orb!('', 56)),
  ],);
}

Widget _time(FigureInput i) {
  final hours = wrappedHours(i.annual);
  final days = wrappedDays(i.annual);
  final shown = (hours * i.progress).round();
  return Stack(children: [
    Positioned(left: 0, right: 0, top: 20, height: 88, child: Center(child: _text(i, '$shown', gt.typeWrappedNumeral))),
    Positioned(left: 0, right: 0, top: 116, child: _text(i, 'hours', gt.typeTitle2, color: gt.colorLabel2)),
    if (days >= 1) Positioned(left: 0, right: 0, top: 184, child: _text(i, "That's ${plural(days, 'full day')}.", gt.typeTitle3)),
  ],);
}

Widget _volume(FigureInput i) {
  final months = i.annual.chaptersByMonth;
  final mx = months.fold<int>(0, math.max);
  return Stack(children: [
    Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: 80,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var m = 0; m < 12; m++)
          Padding(
            padding: EdgeInsets.only(left: m == 0 ? 0 : 6),
            child: Container(
                width: 20,
                height: mx == 0 ? 2 : math.max(2.0, 80 * months[m] / mx * i.progress),
                decoration: BoxDecoration(color: gt.colorIris500, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),),
          ),
      ],),
    ),
    Positioned(left: 0, top: 104, width: 312, height: 200, child: CustomPaint(painter: _PilePainter(i.pile, i.annual.pagesRead))),
  ],);
}

class _PilePainter extends CustomPainter {
  const _PilePainter(this.pile, this.pages);
  final PagePile? pile;
  final int pages;

  @override
  void paint(Canvas canvas, Size size) {
    final p = pile ?? (PagePile(pages: pages, size: size)..settle());
    final paint = Paint()..color = gt.colorLabel2;
    for (final b in p.bodies) {
      if (b.age < b.delay) continue;
      canvas.save();
      canvas.translate(b.x, b.y + kPageH / 2);
      canvas.rotate(b.tilt * (b.asleep ? 0.3 : 1));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: kPageW, height: kPageH), const Radius.circular(1)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PilePainter old) => true;
}

Widget _podium(FigureInput i) {
  final s = _series(i);
  final shown = s.length;
  return Stack(clipBehavior: Clip.none, children: [
    for (var r = 1; r <= math.min(3, shown); r++)
      if (podiumStep(r) != null) Positioned.fromRect(rect: podiumStep(r)!, child: DecoratedBox(decoration: BoxDecoration(color: gt.colorSurface2, borderRadius: BorderRadius.circular(3)))),
    for (var r = shown; r >= 1; r--)
      Positioned(
        left: podiumRest(r).left,
        top: podiumRest(r).top + (r <= 3 ? dropOffset(r, i.podiumMs) : 0) * (r <= 3 ? 1 : 0),
        child: r <= 3
            ? i.cover(s[r - 1].coverUrl, podiumRest(r).width, podiumRest(r).height, 12)
            : Row(children: [
                i.cover(s[r - 1].coverUrl, 32, 48, 6),
                const SizedBox(width: 8),
                SizedBox(width: 240, child: _text(i, s[r - 1].title, gt.typeFootnote, align: TextAlign.start)),
              ],),
      ),
  ],);
}

Widget _radar(FigureInput i) {
  final g = _genres(i).take(8).toList();
  if (g.length < 3) return Center(child: _text(i, g.map((x) => x.genre).join(' · '), gt.typeTitle3));
  final data = [for (final x in g) ChartDatum(label: x.genre, value: x.weight * 100)];
  const size = Size(280, 280);
  return Stack(children: [
    Positioned(left: 16, top: 12, width: 280, height: 280, child: CustomPaint(painter: RadarPainter(data: data, scale: math.max(0.001, i.progress), reduced: i.progress >= 1))),
    for (var k = 0; k < g.length; k++)
      Positioned(
        left: 16 + RadarPainter.labelAt(k, g.length, size).dx - 40,
        top: 12 + RadarPainter.labelAt(k, g.length, size).dy - 8,
        width: 80,
        child: _text(i, g[k].genre, gt.typeCaption2, color: gt.colorLabel3),
      ),
  ],);
}

Widget _clock(FigureInput i) {
  final data = [for (var h = 0; h < 24; h++) ChartDatum(label: hourLabel(h), value: (h < i.annual.byHour.length ? i.annual.byHour[h] : 0).toDouble())];
  return Stack(children: [
    Positioned(
        left: 36,
        top: 32,
        width: 240,
        height: 240,
        child: Center(child: SizedBox(width: 200, height: 200, child: CustomPaint(painter: ClockPainter(data: data, grow: math.max(0.001, i.progress), reduced: i.progress >= 1)))),),
  ],);
}

Widget _streak(FigureInput i) => Stack(children: [
      Positioned(left: 46, top: 42, child: i.flame ?? const StreakFlamePicture(size: 220)),
    ],);

Widget _busiest(FigureInput i) {
  final chapters = busiestChapters(i.annual);
  final s = _series(i);
  return Stack(clipBehavior: Clip.none, children: [
    Positioned(left: 0, right: 0, top: 8, height: 88, child: Center(child: _text(i, '${(chapters * i.progress).round()}', gt.typeWrappedNumeral))),
    Positioned(left: 0, right: 0, top: 104, child: _text(i, 'chapters in one day', gt.typeTitle3, color: gt.colorLabel2)),
    _fan(i, s, w: 64, h: 96, overlap: 0.25, maxAngle: 12, top: 176),
  ],);
}

Widget _firsts(FigureInput i) {
  final t = firstsLastsTitles(i.annual);
  return Stack(children: [
    Positioned(left: 16, top: 20, child: i.cover(i.data?.first?.coverUrl ?? _shareFirst(i)?.coverUrl, 128, 192, 18)),
    Positioned(left: 168, top: 20, child: i.cover(i.data?.last?.coverUrl ?? _shareLast(i)?.coverUrl, 128, 192, 18)),
    Positioned(left: 16, width: 128, top: 224, child: _text(i, t.firstMonth, gt.typeCaption1, color: gt.colorLabel2)),
    Positioned(left: 168, width: 128, top: 224, child: _text(i, 'Now', gt.typeCaption1, color: gt.colorLabel2)),
  ],);
}

ShareSeries? _shareFirst(FigureInput i) => i.data != null ? null : _fromMap((i.annual.firstsLasts?['first'] as Map?)?['series']);
ShareSeries? _shareLast(FigureInput i) => i.data != null ? null : _fromMap((i.annual.firstsLasts?['last'] as Map?)?['series']);
ShareSeries? _fromMap(Object? m) => m is Map<String, dynamic> ? ShareSeries.fromJson(m) : null;

Widget _source(FigureInput i) {
  final top = i.annual.topSources;
  final src = i.data?.source ?? (top.isEmpty ? null : top.first);
  final rows = i.share ? [if (src != null) src] : top.take(3).toList();
  return Stack(children: [
    Positioned(
      left: 108,
      top: 0,
      width: 96,
      height: 96,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1A1A20), border: Border.all(color: const Color(0x38FFFFFF))),
        child: Center(child: src == null ? const SizedBox.shrink() : GlassSourceMonogram(name: src.name, sourceId: src.sourceId, size: 64)),
      ),
    ),
    for (var k = 0; k < rows.length; k++)
      Positioned(
        left: 24,
        right: 24,
        top: 144 + k * 52.0,
        height: 44,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [Expanded(child: _text(i, rows[k].name, gt.typeFootnote, align: TextAlign.start)), _text(i, '${(rows[k].share * 100).round()} %', gt.typeMono, color: gt.colorLabel2)]),
          const SizedBox(height: 6),
          SizedBox(
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(color: gt.colorFill1, borderRadius: BorderRadius.circular(2)),
              child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (rows[k].share * i.progress).clamp(0.0, 1.0),
                  child: DecoratedBox(decoration: BoxDecoration(color: gt.colorIris500, borderRadius: BorderRadius.circular(2))),),
            ),
          ),
        ],),
      ),
  ],);
}

Widget _together(FigureInput i) => Stack(clipBehavior: Clip.none, children: [
      if (i.orb != null) ...[
        Positioned(left: 64, top: 32, child: i.orb!('', 72)),
        Positioned(left: 176, top: 32, child: i.orb!(i.togetherName ?? '', 72)),
      ],
      Positioned(left: 108, top: 136, child: i.cover(_series(i, n: 1).firstOrNull?.coverUrl, 96, 144, 14)),
    ],);

Widget _summary(FigureInput i) {
  final s = _series(i, n: 3);
  final a = i.annual;
  final grid = [
    ('${wrappedHours(a)}', 'hours'),
    (groupThousands(a.chaptersRead), 'chapters'),
    (groupThousands(a.pagesRead), 'pages'),
    ('${a.longestStreak.days}', 'day streak'),
  ];
  final words = _genres(i).take(3).map((g) => g.genre).join(' · ');
  return Stack(clipBehavior: Clip.none, children: [
    Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var k = 0; k < s.length; k++) Padding(padding: EdgeInsets.only(left: k == 0 ? 0 : 12), child: i.cover(s[k].coverUrl, 88, 132, 12)),
      ],),
    ),
    for (var k = 0; k < 4; k++)
      Positioned(
        left: 16 + (k % 2) * 148.0,
        top: 148 + (k ~/ 2) * 60.0,
        width: 140,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _text(i, grid[k].$1, gt.typeTitle1, align: TextAlign.start),
          _text(i, grid[k].$2, gt.typeCaption1, color: gt.colorLabel2, align: TextAlign.start),
        ],),
      ),
    if (words.isNotEmpty) Positioned(left: 0, right: 0, top: 280, child: _text(i, words, gt.typeFootnote, color: gt.colorLabel2)),
  ],);
}
