import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// What a Slate shows for one poster.
class CineSlateData {
  const CineSlateData({
    required this.title,
    required this.kicker,
    this.deck,
    this.why,
    this.coverUrl,
    this.duo,
    this.onRead,
    this.onAdd,
    this.onDetails,
  });

  final String title, kicker;
  final String? deck, why, coverUrl;
  final Color? duo;
  final VoidCallback? onRead, onAdd, onDetails;
}

/// A handle on an open Slate.
class CineSlateHandle {
  CineSlateHandle._(this._key);
  final GlobalKey<_CineSlateState> _key;

  /// Collapses it (after the 120 ms grace when [grace] is set) and removes it.
  void close({bool grace = false}) => _key.currentState?._close(grace: grace);

  bool get isOpen => _key.currentState != null;
}

/// Opens the Slate: an `OverlayEntry` 2.1 x the poster's width, anchored over the poster and
/// clamped inside [bounds]; it grows from the poster's rect with the Slate move (cinematic 7.8).
CineSlateHandle showCineSlate(
  BuildContext context, {
  required Rect anchor,
  required Rect bounds,
  required CineSlateData data,
  bool keyboard = false,
  VoidCallback? onClosed,
  ValueChanged<bool>? onPointerInside,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  final key = GlobalKey<_CineSlateState>();
  entry = OverlayEntry(
    builder: (_) => _CineSlate(
      key: key,
      anchor: anchor,
      bounds: bounds,
      data: data,
      keyboard: keyboard,
      onPointerInside: onPointerInside,
      onDone: () {
        entry.remove();
        onClosed?.call();
      },
    ),
  );
  overlay.insert(entry);
  return CineSlateHandle._(key);
}

class _CineSlate extends StatefulWidget {
  const _CineSlate({super.key, required this.anchor, required this.bounds, required this.data, required this.keyboard, required this.onDone, this.onPointerInside});
  final Rect anchor, bounds;
  final CineSlateData data;
  final bool keyboard;
  final VoidCallback onDone;
  final ValueChanged<bool>? onPointerInside;

  @override
  State<_CineSlate> createState() => _CineSlateState();
}

class _CineSlateState extends State<_CineSlate> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _read = FocusNode(debugLabel: 'slate-read');
  Timer? _grace;
  bool _closing = false, _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduced = CineMotion.reduced(context);
    if (reduced) {
      CineMotion.play(MotionName.slate, _c, duration: CineDur.reduced, curve: Curves.linear);
    } else {
      CineMotion.play(MotionName.slate, _c);
    }
    if (widget.keyboard) WidgetsBinding.instance.addPostFrameCallback((_) => _read.requestFocus());
  }

  void _close({bool grace = false}) {
    if (_closing) return;
    void run() {
      if (!mounted || _closing) return;
      _closing = true;
      if (CineMotion.reduced(context)) {
        CineMotion.play(MotionName.slate, _c, target: 0, duration: CineDur.reduced, curve: Curves.linear).whenComplete(_done);
      } else {
        CineMotion.play(MotionName.slate, _c, target: 0, duration: CineDur.clip, curve: CineCurves.lift).whenComplete(_done);
      }
    }

    if (grace) {
      _grace?.cancel();
      _grace = Timer(CineDur.snap, run);
    } else {
      run();
    }
  }

  void _done() {
    if (mounted) widget.onDone();
  }

  void _cancelClose() => _grace?.cancel();

  @override
  void dispose() {
    _grace?.cancel();
    _c.dispose();
    _read.dispose();
    super.dispose();
  }

  Rect get _target {
    final w = widget.anchor.width * 2.1, h = w * 1.15;
    var left = widget.anchor.left;
    if (left + w > widget.bounds.right) left = widget.bounds.right - w;
    if (left < widget.bounds.left) left = widget.bounds.left;
    var top = widget.anchor.top;
    if (top + h > widget.bounds.bottom) top = math.max(widget.bounds.top, widget.bounds.bottom - h);
    return Rect.fromLTWH(left, top, w, h);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final target = _target;
    final d = widget.data;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final rect = reduced ? target : (Rect.lerp(widget.anchor, target, t) ?? target);
        return Positioned.fromRect(
          rect: rect,
          child: Opacity(
            opacity: reduced ? t : 1,
            child: MouseRegion(
              onEnter: (_) {
                _cancelClose();
                widget.onPointerInside?.call(true);
              },
              onExit: (_) {
                widget.onPointerInside?.call(false);
                if (!widget.keyboard) _close(grace: true);
              },
              child: Focus(
                canRequestFocus: false,
                onKeyEvent: (_, e) {
                  if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.escape || e.logicalKey == LogicalKeyboardKey.space)) {
                    _close();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: FocusScope(
                  child: Semantics(
                    container: true,
                    label: '${d.title}, preview',
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: target.width,
                        maxWidth: target.width,
                        minHeight: target.height,
                        maxHeight: target.height,
                        child: _content(context, c, target),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, CineTokens c, Rect target) {
    final d = widget.data;
    final half = target.height / 2;
    final duo = d.duo ?? c.colorAmbientFallbackDuo;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.colorPaper2, border: Border.all(color: c.colorRule2)),
      child: Column(children: [
        SizedBox(
          height: half,
          child: Stack(fit: StackFit.expand, children: [
            ClipRect(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: c.blurCard, sigmaY: c.blurCard),
                child: CineDuotone(duo: duo, child: CineImage(url: d.coverUrl, title: d.title)),
              ),
            ),
            DecoratedBox(decoration: BoxDecoration(gradient: cineScrimFoot(solidAtPx: half - 24 - 24 * 1.2, height: half))),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Builder(
                builder: (context) => SetHeading(
                  d.title,
                  id: 'slate-${d.title}',
                  style: CineText.style(context, c.typeSubhead).copyWith(color: c.colorInk100),
                  cap: c.typeSubhead.cap,
                  level: 3,
                  trigger: SetTrigger.signal,
                ),
              ),
            ),
          ],),
        ),
        Expanded(
          child: CineStock.raised(
            Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CineRoleText(d.kicker, c.typeKicker, color: context.cine.colorInk45, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (d.deck != null) ...[const SizedBox(height: 4), CineRoleText(d.deck!, c.typeBodyItalic, color: context.cine.colorInk60, maxLines: 2, overflow: TextOverflow.ellipsis)],
                  if (d.why != null) ...[const SizedBox(height: 4), CineRoleText(d.why!, c.typeCaption, color: context.cine.colorInk80, maxLines: 2, overflow: TextOverflow.ellipsis)],
                  const Spacer(),
                  FocusTraversalGroup(
                    child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      CineButton(label: 'Read', size: CineButtonSize.sm, focusNode: _read, onPressed: d.onRead ?? () {}),
                      CineButton(label: '+ Library', variant: CineButtonVariant.secondary, size: CineButtonSize.sm, onPressed: d.onAdd ?? () {}),
                      CineButton(label: 'Details', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: d.onDetails ?? () {}),
                    ],),
                  ),
                ],),
              ),
            ),
          ),
        ),
      ],),
    );
  }
}
