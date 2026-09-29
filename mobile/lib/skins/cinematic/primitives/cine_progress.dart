import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A 2 px determinate rule (cinematic 7.18): track `rule.1`, fill `spot`, width 240 ms.
class CineRuleProgress extends StatelessWidget {
  const CineRuleProgress({super.key, required this.value, this.track = true, this.semanticLabel});
  final double value;
  final bool track;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final v = value.clamp(0.0, 1.0);
    final d = CineMotion.reduced(context) ? Duration.zero : c.durLine;
    return Semantics(
      label: semanticLabel,
      value: '${(v * 100).round()} percent',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 2,
          child: Stack(children: [
            if (track) Positioned.fill(child: ColoredBox(color: c.colorRule1)),
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: v),
                duration: d,
                curve: c.easeSet,
                builder: (_, w, __) => Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: w, child: ColoredBox(color: c.colorSpot))),
              ),
            ),
          ],),
        ),
      ),
    );
  }
}

/// 2 px `spot` flush on a cover's bottom edge (a Cutting's progress).
class CinePosterProgress extends StatelessWidget {
  const CinePosterProgress({super.key, required this.value});
  final double value;

  @override
  Widget build(BuildContext context) => CineRuleProgress(value: value, track: false);
}

/// 2 px `spot` at the very bottom of a reader.
class CineMicroProgress extends StatelessWidget {
  const CineMicroProgress({super.key, required this.value});
  final double value;

  @override
  Widget build(BuildContext context) => Align(alignment: Alignment.bottomCenter, child: CineRuleProgress(value: value, track: false));
}

/// A 25 %-wide `spot` segment running left -> right on a 1200 ms linear loop; keeps running
/// under reduced motion.
class CineIndeterminateRule extends StatefulWidget {
  const CineIndeterminateRule({super.key, this.height = 2, this.track = true});
  final double height;
  final bool track;

  @override
  State<CineIndeterminateRule> createState() => _CineIndeterminateRuleState();
}

class _CineIndeterminateRuleState extends State<CineIndeterminateRule> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: CineDur.loopRule)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      value: 'Loading',
      child: ExcludeSemantics(
        child: SizedBox(
          height: widget.height,
          child: LayoutBuilder(builder: (context, box) {
            return ClipRect(
              child: Stack(children: [
                if (widget.track) Positioned.fill(child: ColoredBox(color: c.colorRule1)),
                AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) => Positioned(
                    left: (box.maxWidth * 1.25) * _c.value - box.maxWidth * 0.25,
                    width: box.maxWidth * 0.25,
                    top: 0,
                    bottom: 0,
                    child: ColoredBox(color: c.colorSpot),
                  ),
                ),
              ],),
            );
          },),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.lead, required this.span, required this.ring, required this.from, required this.to});
  final double lead, span;
  final Color ring, from, to;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 - 0.5, ctr = size.center(Offset.zero);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ring;
    canvas.drawCircle(ctr, r, line);
    canvas.drawLine(Offset(ctr.dx - r, ctr.dy), Offset(ctr.dx + r, ctr.dy), line);
    canvas.drawLine(Offset(ctr.dx, ctr.dy - r), Offset(ctr.dx, ctr.dy + r), line);
    if (span <= 0) return;
    final rect = Rect.fromCircle(center: ctr, radius: r);
    final paint = Paint()
      ..shader = SweepGradient(
        endAngle: span,
        colors: [from, to],
        transform: GradientRotation(lead - span),
      ).createShader(rect);
    canvas.drawArc(rect, lead - span, span, true, paint);
  }

  @override
  bool shouldRepaint(_DialPainter o) => o.lead != lead || o.span != span || o.ring != ring || o.from != from || o.to != to;
}

/// The leader dial that replaces every spinner (cinematic 7.18): 32 px, 24 inline, 16 in controls,
/// 12 inside a switch knob. Mounts only after 400 ms of waiting; keeps running under reduced motion.
class CineLeaderDial extends StatefulWidget {
  const CineLeaderDial({super.key, this.size = 32, this.showAfter = const Duration(milliseconds: 400), this.semanticLabel = 'Loading'});
  final double size;
  final Duration showAfter;
  final String semanticLabel;

  @override
  State<CineLeaderDial> createState() => _CineLeaderDialState();
}

class _CineLeaderDialState extends State<CineLeaderDial> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Timer? _t;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: CineDur.leader);
    if (widget.showAfter == Duration.zero) {
      _shown = true;
      _c.repeat();
    } else {
      _t = Timer(widget.showAfter, () {
        if (!mounted) return;
        setState(() => _shown = true);
        _c.repeat();
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      value: widget.semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: _shown
              ? AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) => CustomPaint(painter: _DialPainter(lead: -math.pi / 2 + _c.value * 2 * math.pi, span: 2 * math.pi, ring: c.colorInk30, from: c.colorLeaderSweep.withValues(alpha: 0), to: c.colorLeaderSweep)),
                )
              : null,
        ),
      ),
    );
  }
}

/// The 40 px dial with a `spot` sweep over 5 s, one pass; reduced motion shows `5 S` ... `1 S`
/// updated once per second instead.
class CineCountdownDial extends StatefulWidget {
  const CineCountdownDial({super.key, this.onDone, this.duration});
  final VoidCallback? onDone;
  final Duration? duration;

  @override
  State<CineCountdownDial> createState() => _CineCountdownDialState();
}

class _CineCountdownDialState extends State<CineCountdownDial> with SingleTickerProviderStateMixin {
  late final Duration _d = widget.duration ?? CineDur.countdownNext;
  late final AnimationController _c = AnimationController(vsync: this, duration: _d);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _c.linear();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    return Semantics(
      value: 'Next chapter countdown',
      child: ExcludeSemantics(
        child: SizedBox(
          width: 40,
          height: 40,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              if (reduced) {
                final left = math.max(1, (_d.inSeconds - (_c.value * _d.inSeconds).floor()));
                return Center(child: CineLit('$left S', CineFace.plexMono, 12, 16, color: c.colorInk60));
              }
              return CustomPaint(painter: _DialPainter(lead: -math.pi / 2 + _c.value * 2 * math.pi, span: _c.value * 2 * math.pi, ring: c.colorInk30, from: c.colorSpot, to: c.colorSpot));
            },
          ),
        ),
      ),
    );
  }
}

extension on AnimationController {
  void linear() => forward();
}

/// `07 / 40` in `typeFolioLg`, tabular figures.
class CineFolioCounter extends StatelessWidget {
  const CineFolioCounter({super.key, required this.index, required this.total});
  final int index, total;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    String two(int n) => n.toString().padLeft(2, '0');
    return Semantics(
      label: 'Item $index of $total',
      child: ExcludeSemantics(
        child: Text(
          '${two(index)} / ${two(total)}',
          style: CineText.style(context, c.typeFolioLg).copyWith(color: c.colorInk100, fontFeatures: const [FontFeature.tabularFigures()]),
          textScaler: CineText.scaler(context, c.typeFolioLg),
        ),
      ),
    );
  }
}

enum CineDownloadState { notDownloaded, queued, downloading, saved, failed, paused, stale }

class _DashedSquare extends CustomPainter {
  _DashedSquare(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    final r = (Offset.zero & size).deflate(0.5);
    void dash(Offset a, Offset b) {
      final len = (b - a).distance, dir = (b - a) / len;
      for (var d = 0.0; d < len; d += 4) {
        canvas.drawLine(a + dir * d, a + dir * math.min(d + 2, len), p);
      }
    }

    dash(r.topLeft, r.topRight);
    dash(r.topRight, r.bottomRight);
    dash(r.bottomRight, r.bottomLeft);
    dash(r.bottomLeft, r.topLeft);
  }

  @override
  bool shouldRepaint(_DashedSquare o) => o.color != color;
}

/// The 16 px download mark (cinematic 7.18); the hit grows to 44/48.
class CineDownloadMark extends StatelessWidget {
  const CineDownloadMark({super.key, required this.state, this.progress = 0, this.onTap});
  final CineDownloadState state;
  final double progress;
  final VoidCallback? onTap;

  String get label => switch (state) {
        CineDownloadState.saved => 'Saved',
        CineDownloadState.queued => 'Queued',
        CineDownloadState.downloading => 'Downloading, ${(progress * 100).round()} percent',
        CineDownloadState.failed => 'Failed, tap to retry',
        CineDownloadState.paused => 'Paused',
        CineDownloadState.stale => 'Saved copy is out of date, download again',
        CineDownloadState.notDownloaded => 'Not downloaded',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    Widget mark() {
      switch (state) {
        case CineDownloadState.notDownloaded:
          return CineGlyphIcon(CineGlyph.cloudArrowDown, size: 16, color: c.colorInk45);
        case CineDownloadState.stale:
          return CineGlyphIcon(CineGlyph.cloudArrowDown, size: 16, color: c.colorSpot);
        case CineDownloadState.saved:
          return CineGlyphIcon(CineGlyph.checkSquare, size: 16, weight: CineIconWeight.fill, color: c.colorSet);
        case CineDownloadState.queued:
          return SizedBox(width: 16, height: 16, child: CustomPaint(painter: _DashedSquare(c.colorInk45)));
        case CineDownloadState.downloading:
          return Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(border: Border.all(color: c.colorInk45)),
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(heightFactor: progress.clamp(0.0, 1.0), widthFactor: 1, child: ColoredBox(color: c.colorSpot)),
          );
        case CineDownloadState.failed:
          return Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(border: Border.all(color: c.colorProof)),
            alignment: Alignment.center,
            child: CineLit('!', CineFace.archivo, 10, 12, wght: 800, color: c.colorProof),
          );
        case CineDownloadState.paused:
          return SizedBox(
            width: 16,
            height: 16,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 2, height: 12, color: c.colorSpot),
              const SizedBox(width: 4),
              Container(width: 2, height: 12, color: c.colorSpot),
            ],),
          );
      }
    }

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: CinePressable(
        onTap: onTap,
        builder: (_, __) => CineHit(child: mark()),
      ),
    );
  }
}

/// Storage meter: other apps `ink.60`, ManhwaManiacs `spot`, free `rule.1`; the cap a 2 px tick.
class CineStorageMeter extends StatelessWidget {
  const CineStorageMeter({super.key, required this.otherGb, required this.appGb, required this.totalGb, this.capGb, this.note});
  final double otherGb, appGb, totalGb;
  final double? capGb;
  final String? note;

  static String _g(double v) => v.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final t = math.max(0.001, totalGb);
    int flex(double v) => (v / t * 1000).round().clamp(0, 1000);
    final other = flex(otherGb), app = flex(appGb), free = math.max(0, 1000 - other - app);
    return Semantics(
      value: '${_g(otherGb + appGb)} of ${_g(totalGb)} gigabytes used',
      child: ExcludeSemantics(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          if (capGb != null)
            LayoutBuilder(builder: (_, box) => SizedBox(
                  height: 6,
                  child: Stack(children: [
                    Positioned(left: (box.maxWidth * (capGb! / t).clamp(0.0, 1.0)) - 1, top: 0, width: 2, height: 6, child: ColoredBox(color: c.colorInk100)),
                  ],),
                ),),
          SizedBox(
            height: 8,
            child: Row(children: [
              if (other > 0) Expanded(flex: other, child: ColoredBox(color: c.colorInk60)),
              if (app > 0) Expanded(flex: app, child: ColoredBox(color: c.colorSpot)),
              if (free > 0) Expanded(flex: free, child: ColoredBox(color: c.colorRule1)),
            ],),
          ),
          if (note != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              CineRoleText('NOTE', c.typeKicker, color: c.colorSpot),
              const SizedBox(width: 8),
              Expanded(child: CineRoleText(note!, c.typeCaption, color: c.colorInk60)),
            ],),
          ],
        ],),
      ),
    );
  }
}
