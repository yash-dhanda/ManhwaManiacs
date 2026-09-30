import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart'
    show GenreWeight;
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// "Top genres: Fantasy 41 %, Romance 22 %, Action 15 %."
String genreSummary(List<GenreWeight> genres) =>
    'Top genres: ${genres.take(3).map((g) => '${g.genre} ${(g.weight * 100).round()} %').join(', ')}.';

/// The top 6-8 genres, normalised to the largest weight.
List<GenreWeight> radarGenres(List<GenreWeight> all) {
  final sorted = [...all]..sort((a, b) => b.weight.compareTo(a.weight));
  return sorted.take(8).toList();
}

/// The genre radar (cinematic 9.2.1): 1 px `rule.1` rings at 25/50/75/100 %
/// and spokes, a 1 px `ink.100` polygon with no fill, 4 x 4 `spot` square
/// vertices, labels in `type.kicker` `ink.45`. Fewer than 3 genres: rows.
class GenreRadar extends StatelessWidget {
  const GenreRadar({super.key, required this.genres, this.size = 240});

  final List<GenreWeight> genres;
  final double size;

  @override
  Widget build(BuildContext context) {
    final list = radarGenres(genres);
    final t = context.cine;
    if (list.length < 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final g in list)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: CineRoleText(
                    '${g.genre.toUpperCase()} · ${(g.weight * 100).round()} %',
                    t.typeKicker,
                    color: CineColors.ink60,),),
        ],
      );
    }
    final kicker = CineText.style(context, t.typeKicker)
        .copyWith(color: CineColors.ink45)
        .copyWith(fontSize: 10);
    final summary = genreSummary(list);
    final full = size + 96;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: summary,
      child: SizedBox(
        width: full,
        height: size + 48,
        child: CustomPaint(painter: _RadarPainter(list, size / 2, kicker)),
      ),
    );
  }
}

Offset _spoke(int i, int n) {
  final a = i * 2 * math.pi / n;
  return Offset(math.sin(a), -math.cos(a));
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter(this.genres, this.radius, this.kicker);
  final List<GenreWeight> genres;
  final double radius;
  final TextStyle kicker;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final n = genres.length;
    final hair = Paint()
      ..color = CineColors.rule1
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final f in [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawCircle(c, radius * f, hair);
    }
    final max = genres.first.weight;
    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final s = _spoke(i, n);
      canvas.drawLine(c, c + s * radius, hair);
      pts.add(c + s * (radius * (genres[i].weight / max)));
    }
    final path = Path()..addPolygon(pts, true);
    canvas.drawPath(
      path,
      Paint()
        ..color = CineColors.ink100
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (final p in pts) {
      canvas.drawRect(Rect.fromCenter(center: p, width: 4, height: 4),
          Paint()..color = CineColors.spot,);
    }
    for (var i = 0; i < n; i++) {
      final tp = TextPainter(
          text: TextSpan(text: genres[i].genre.toUpperCase(), style: kicker),
          textDirection: TextDirection.ltr,)
        ..layout(maxWidth: 88);
      final p = c + _spoke(i, n) * (radius + 14);
      final s = _spoke(i, n);
      final dx = s.dx > 0.3 ? 0.0 : (s.dx < -0.3 ? -tp.width : -tp.width / 2);
      final dy = s.dy > 0.3 ? 0.0 : (s.dy < -0.3 ? -tp.height : -tp.height / 2);
      tp.paint(canvas, p + Offset(dx, dy));
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (s) {
        final c = s.center(Offset.zero);
        final max = genres.first.weight;
        return [
          for (var i = 0; i < genres.length; i++)
            CustomPainterSemantics(
              rect: Rect.fromCenter(
                  center: c +
                      _spoke(i, genres.length) *
                          (radius * genres[i].weight / max),
                  width: 24,
                  height: 24,),
              properties: SemanticsProperties(
                  textDirection: TextDirection.ltr,
                  label:
                      '${genres[i].genre}, ${(genres[i].weight * 100).round()} percent',),
            ),
        ];
      };

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.genres != genres || old.radius != radius;
}
