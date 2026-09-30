import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/utils/narration_timing.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The chapter ruler in time (cinematic 7.20 styling): a 2 px track, the played part in `ink.100`
/// and a thumb. Dragging seeks live, releasing settles the thumb with the `scrub` spring. Its
/// semantics value is "12 minutes 5 seconds of 30 minutes", with increase and decrease actions of
/// 15 seconds.
class ListenRuler extends StatefulWidget {
  const ListenRuler({super.key, required this.totalMs, required this.positionMs, required this.onSeek});

  final int totalMs;
  final ValueListenable<int> positionMs;

  /// Live, while dragging, on a tap and from the semantics actions.
  final ValueChanged<int> onSeek;

  @override
  State<ListenRuler> createState() => _ListenRulerState();
}

class _ListenRulerState extends State<ListenRuler> with SingleTickerProviderStateMixin {
  late final AnimationController _settle = AnimationController.unbounded(vsync: this);
  double? _dragX;
  double _width = 1;
  int _lastQuarter = -1;

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  int _msAt(double x) => (widget.totalMs * (x / (_width <= 0 ? 1 : _width)).clamp(0.0, 1.0)).round();

  void _seek(double x) {
    final ms = _msAt(x);
    // A soft tick every 15 s crossed while scrubbing.
    final q = ms ~/ 15000;
    if (_lastQuarter >= 0 && q != _lastQuarter) cineFeedback(context, HapticEvent.scrubTick);
    _lastQuarter = q;
    setState(() => _dragX = x.clamp(0.0, _width));
    widget.onSeek(ms);
  }

  void _release() {
    final from = _dragX;
    _lastQuarter = -1;
    if (from == null) return;
    final to = widget.totalMs <= 0 ? 0.0 : widget.positionMs.value / widget.totalMs * _width;
    setState(() => _dragX = null);
    if (CineMotion.reduced(context)) return;
    _settle
      ..value = from
      ..animateWith(SpringSimulation(CineSprings.scrub.description, from, to, 0));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final hit = cineHitMin(context);
    return ValueListenableBuilder<int>(
      valueListenable: widget.positionMs,
      builder: (context, ms, _) => Semantics(
        slider: true,
        label: 'Position in the chapter',
        value: positionSpoken(widget.totalMs, ms),
        increasedValue: positionSpoken(widget.totalMs, (ms + 15000).clamp(0, widget.totalMs)),
        decreasedValue: positionSpoken(widget.totalMs, (ms - 15000).clamp(0, widget.totalMs)),
        onIncrease: () => widget.onSeek((ms + 15000).clamp(0, widget.totalMs)),
        onDecrease: () => widget.onSeek((ms - 15000).clamp(0, widget.totalMs)),
        excludeSemantics: true,
        child: LayoutBuilder(
          builder: (context, box) {
            _width = box.maxWidth;
            final played = widget.totalMs <= 0 ? 0.0 : (ms / widget.totalMs).clamp(0.0, 1.0);
            return GestureDetector(
              key: const Key('listen-ruler'),
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _seek(d.localPosition.dx),
              onTapUp: (_) => _release(),
              onHorizontalDragStart: (d) => _seek(d.localPosition.dx),
              onHorizontalDragUpdate: (d) => _seek(d.localPosition.dx),
              onHorizontalDragEnd: (_) => _release(),
              onHorizontalDragCancel: _release,
              child: SizedBox(
                height: hit,
                child: AnimatedBuilder(
                  animation: _settle,
                  builder: (context, _) {
                    final x = _dragX ?? (_settle.isAnimating ? _settle.value : played * _width);
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Positioned(left: 0, right: 0, child: ColoredBox(color: c.colorRule2, child: const SizedBox(height: 2))),
                        Positioned(left: 0, width: x.clamp(0.0, _width), child: ColoredBox(key: const Key('listen-ruler-played'), color: c.colorInk100, child: const SizedBox(height: 2))),
                        Positioned(left: (x - 6).clamp(0.0, _width - 12), child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: c.colorInk100), child: const SizedBox(width: 12, height: 12))),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The transport under the transcript: the ruler, the `0:00` and `-18:40` folios, and previous
/// chapter, back 15 s, the round play (56 px on phones, 64 px on tablets), forward 15 s, next
/// chapter.
class ListenTransport extends ConsumerWidget {
  const ListenTransport({super.key, required this.onPrevious, required this.onNext, this.playFocus});

  final VoidCallback? onPrevious, onNext;
  final FocusNode? playFocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final s = ref.watch(narrationControllerProvider);
    final n = ref.read(narrationControllerProvider.notifier);
    final total = s.target?.audio.totalMs ?? 0;
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final size = tablet ? 64.0 : 56.0;
    final loading = s.status == NarrationStatus.loading || s.status == NarrationStatus.preparing;
    final failed = s.status == NarrationStatus.failed;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListenRuler(totalMs: total, positionMs: n.position, onSeek: (ms) => unawaited(n.seek(Duration(milliseconds: ms)))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: c.space1),
          child: ValueListenableBuilder<int>(
            valueListenable: n.position,
            builder: (context, ms, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CineRoleText(clockText(ms), c.typeFolio, color: c.colorInk60),
                Semantics(label: remainingSpoken(total, ms), excludeSemantics: true, child: CineRoleText(remainingFolio(total, ms), c.typeFolio, color: c.colorInk60)),
              ],
            ),
          ),
        ),
        SizedBox(height: c.space2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CineIconButton(label: 'Previous chapter', role: CineIconRole.chapterPrevious, onPressed: onPrevious),
            _Skip(label: 'Back 15 seconds', icon: PhosphorRegular.clockCounterClockwise, onTap: () => unawaited(n.seekBy(const Duration(seconds: -15)))),
            Semantics(
              button: true,
              label: failed ? 'Audio could not be loaded. Try again' : (s.isPlaying ? 'Pause' : 'Play'),
              excludeSemantics: true,
              onTap: () => _play(context, n, failed),
              child: CinePressable(
                round: true,
                focusNode: playFocus,
                onTap: loading ? null : () => _play(context, n, failed),
                builder: (context, st) => Container(
                  key: const Key('room-play'),
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: failed ? null : c.colorInk100, border: failed ? Border.all(color: c.colorProof) : null),
                  child: failed
                      ? CineRoleText('!', c.typeTitle, color: c.colorProof)
                      : loading
                          ? const CineLeaderDial(size: 24, showAfter: Duration.zero)
                          : CineIcon(s.isPlaying ? CineIconRole.pause : CineIconRole.play, weight: CineIconWeight.fill, color: c.colorPaper0),
                ),
              ),
            ),
            _Skip(label: 'Forward 15 seconds', icon: PhosphorRegular.arrowClockwise, onTap: () => unawaited(n.seekBy(const Duration(seconds: 15)))),
            CineIconButton(label: 'Next chapter', role: CineIconRole.chapterNext, onPressed: onNext),
          ],
        ),
      ],
    );
  }

  void _play(BuildContext context, NarrationController n, bool failed) {
    cineFeedback(context, HapticEvent.listenToggle);
    unawaited(failed ? n.retry() : n.toggle());
  }
}

/// `-15 s` / `+15 s`: a clock arrow with the 15 set small inside it; a 44 / 48 touch target.
class _Skip extends StatelessWidget {
  const _Skip({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: CinePressable(
        onTap: onTap,
        builder: (context, st) => SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 28, color: st.hovered || st.focused ? c.colorInk100 : c.colorInk80),
              CineRoleText('15', c.typeMicro, color: c.colorInk80),
            ],
          ),
        ),
      ),
    );
  }
}
