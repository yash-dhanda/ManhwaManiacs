import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The post-play card at a chapter's end (cinematic 8.16.7): the kicker `NEXT`, `Chapter 13` typed
/// at 50 ms per character, a 40 px countdown dial (a `spot` sweep over 5000 ms, one pass; under
/// reduced motion no sweep and a `5 S` ... `1 S` folio updated once per second), `Play now`
/// (primary) and `Cancel` (quiet).
///
/// The countdown pauses while focus is inside the card and does not start while a screen reader
/// runs (the card waits for `Play now`). With [countdown] false (auto-play off) the card shows
/// without the dial and waits.
class PostPlayCard extends StatefulWidget {
  const PostPlayCard({
    super.key,
    required this.nextLabel,
    required this.onPlayNow,
    required this.onCancel,
    this.countdown = true,
    this.duration = const Duration(milliseconds: 5000),
  });

  /// `Chapter 13`.
  final String nextLabel;
  final VoidCallback onPlayNow, onCancel;
  final bool countdown;
  final Duration duration;

  @override
  State<PostPlayCard> createState() => _PostPlayCardState();
}

class _PostPlayCardState extends State<PostPlayCard> with SingleTickerProviderStateMixin {
  late final AnimationController _dial = AnimationController(vsync: this, duration: widget.duration);
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'post-play');
  bool _started = false, _done = false;
  Timer? _ticker;
  int _left = 5;

  @override
  void initState() {
    super.initState();
    _scope.addListener(_onFocus);
    _dial.addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });
    _left = (widget.duration.inMilliseconds / 1000).ceil();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _start();
    }
  }

  bool get _reader => MediaQuery.accessibleNavigationOf(context);

  void _start() {
    if (!widget.countdown || _reader || _scope.hasFocus) return;
    if (CineMotion.reduced(context)) {
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_scope.hasFocus) return;
        if (!mounted) return;
        setState(() => _left--);
        if (_left <= 0) {
          t.cancel();
          _finish();
        }
      });
    } else if (!_dial.isAnimating) {
      unawaited(_dial.forward());
    }
  }

  void _onFocus() {
    if (!widget.countdown || _done) return;
    if (_scope.hasFocus) {
      _dial.stop();
    } else if (!CineMotion.reduced(context)) {
      _start();
    }
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onPlayNow();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _scope.dispose();
    _dial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final title = CineText.literal(context, CineFace.bodoni, 28, 34).copyWith(color: c.colorInk100);
    return FocusScope(
      node: _scope,
      child: Semantics(
        container: true,
        label: 'Next: ${widget.nextLabel}',
        child: Container(
          key: const Key('post-play-card'),
          padding: EdgeInsets.all(c.space4),
          decoration: BoxDecoration(border: Border.all(color: c.colorRule2)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CineRoleText('NEXT', c.typeKicker, color: c.colorInk60),
                    SizedBox(height: c.space1),
                    reduced
                        ? Text(widget.nextLabel, style: title)
                        : TypedHeadline(widget.nextLabel, style: title, cap: 1.3),
                    SizedBox(height: c.space3),
                    Row(
                      children: [
                        CineButton(label: 'Play now', size: CineButtonSize.sm, onPressed: _finish),
                        SizedBox(width: c.space2),
                        CineButton(label: 'Cancel', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: () {
                          _done = true;
                          _dial.stop();
                          _ticker?.cancel();
                          widget.onCancel();
                        },),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.countdown && !_reader) ...[
                SizedBox(width: c.space3),
                reduced
                    ? Semantics(
                        liveRegion: false,
                        child: CineRoleText('$_left S', c.typeFolio, color: c.colorSpot, key: const Key('post-play-folio')),
                      )
                    : SizedBox(
                        width: 40,
                        height: 40,
                        child: AnimatedBuilder(
                          animation: _dial,
                          builder: (context, _) => CustomPaint(key: const Key('post-play-dial'), painter: _DialPainter(_dial.value, c.colorSpot, c.colorRule2)),
                        ),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.t, this.spot, this.ring);
  final double t;
  final Color spot, ring;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3);
    canvas
      ..drawArc(r, 0, 6.2831853, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = ring)
      ..drawArc(r, -1.5707963, 6.2831853 * t, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = spot);
  }

  @override
  bool shouldRepaint(_DialPainter o) => o.t != t;
}
