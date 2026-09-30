import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/machine_badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/hero_tilt.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlights.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:motor/motor.dart';

/// What a spotlight card can do; the screen implements them.
class SpotlightHandlers {
  const SpotlightHandlers({required this.onPrimary, required this.onSecondary, required this.onOpen, required this.onDrop, this.targets, this.onLiftPhase, this.onMagnetChanged});

  final void Function(SpotlightSpec spec, Rect from) onPrimary;
  final void Function(SpotlightSpec spec, Rect from) onSecondary;

  /// A tap on the cover, or a throw up with its velocity.
  final void Function(SpotlightSpec spec, Rect from, {Offset? velocity}) onOpen;

  /// A drop on a friend orb.
  final void Function(SpotlightSpec spec, Object? profileId) onDrop;
  final List<MagnetTarget> Function()? targets;
  final ValueChanged<GlassLiftPhase>? Function(String sourceId, String seriesKey, Rect Function() rectOf)? onLiftPhase;
  final ValueChanged<Object?>? onMagnetChanged;
}

/// The hero card tilts up to 6 degrees from the accelerometer (phones) or toward the pointer (hover frames).
class SpotlightTilt extends ConsumerStatefulWidget {
  const SpotlightTilt({super.key, required this.active, required this.child});

  /// Whether the sensor may be read now (Home visible, resumed, on screen, the preference on, motion not reduced).
  final bool active;
  final Widget child;

  @override
  ConsumerState<SpotlightTilt> createState() => _SpotlightTiltState();
}

class _SpotlightTiltState extends ConsumerState<SpotlightTilt> with TickerProviderStateMixin {
  late final SingleMotionController _x = SingleMotionController(motion: SpringMotion(springOf(gt.springTrack)), vsync: this);
  late final SingleMotionController _y = SingleMotionController(motion: SpringMotion(springOf(gt.springTrack)), vsync: this);
  StreamSubscription<Offset>? _sub;
  Offset? _pose;
  bool _hover = false;

  bool get _reduced => ref.read(glassMotionPrefsProvider).reduced;

  @override
  void initState() {
    super.initState();
    _x.value = 0;
    _y.value = 0;
    _sync();
  }

  @override
  void didUpdateWidget(SpotlightTilt old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final want = widget.active && !_reduced;
    if (want && _sub == null) {
      _pose = null;
      _sub = ref.read(gravityProvider).stream.listen((g) {
        _pose ??= g;
        if (_hover) return;
        final a = heroTiltFromGravity(g, pose: _pose!);
        _x.animateTo(a.x);
        _y.animateTo(a.y);
      }, onError: (Object _) {},);
    } else if (!want && _sub != null) {
      unawaited(_sub!.cancel());
      _sub = null;
      _x.animateTo(0);
      _y.animateTo(0);
    }
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    _x.dispose();
    _y.dispose();
    super.dispose();
  }

  void _hoverAt(PointerHoverEvent e, Size size) {
    if (_reduced) return;
    _hover = true;
    final a = heroTiltFromPointer(e.localPosition, Offset(size.width, size.height));
    _x.animateTo(a.x);
    _y.animateTo(a.y);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => MouseRegion(
          onHover: (e) => _hoverAt(e, c.biggest),
          onExit: (_) {
            _hover = false;
            _x.animateTo(0);
            _y.animateTo(0);
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_x, _y]),
            child: widget.child,
            builder: (context, child) => Transform(alignment: Alignment.center, transform: heroTiltMatrix((x: _x.value, y: _y.value)), child: child),
          ),
        ),
      );
}

/// The Wrapped card face: the year in `display` on the brand aurora (no cover).
class WrappedFace extends StatelessWidget {
  const WrappedFace({super.key, required this.year});
  final int year;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [gt.colorAurora1, gt.colorAurora2, gt.colorAurora3])),
        child: Center(child: GlassLabel('$year', role: gt.typeDisplay, color: const Color(0xFFFFFFFF), onGlass: true)),
      );
}

/// The card's cover: a [GlassPoster] at [width] with the card radius, lifted, thrown and dropped like every poster.
class SpotlightCover extends ConsumerStatefulWidget {
  const SpotlightCover({super.key, required this.spec, required this.width, required this.position, required this.count, required this.handlers, this.radius = 26});
  final SpotlightSpec spec;
  final double width;
  final int position, count;
  final SpotlightHandlers handlers;
  final double radius;

  @override
  ConsumerState<SpotlightCover> createState() => _SpotlightCoverState();
}

class _SpotlightCoverState extends ConsumerState<SpotlightCover> {
  final GlobalKey _box = GlobalKey();

  Rect _rect() {
    final ro = _box.currentContext?.findRenderObject();
    return ro is RenderBox && ro.attached ? ro.localToGlobal(Offset.zero) & ro.size : Rect.zero;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.spec;
    final h = widget.handlers;
    final cover = s.isWrapped ? WrappedFace(year: s.year ?? DateTime.now().year) : HomeCoverImage(url: s.coverUrl, width: widget.width);
    return SizedBox(
      key: _box,
      width: widget.width,
      height: widget.width * 1.5,
      child: GlassPoster(
        cover: cover,
        title: '${widget.position + 1} of ${widget.count}: ${s.title}',
        width: widget.width,
        radius: widget.radius,
        lMax: s.palette?.lMax ?? 0.5,
        targets: s.hasSeries && s.world != null ? h.targets : (s.hasSeries ? h.targets : null),
        onTap: () => h.onOpen(s, _rect()),
        onThrowOpen: (v) => h.onOpen(s, _rect(), velocity: v),
        onDropOnTarget: (id) => h.onDrop(s, id),
        onLiftPhase: s.hasSeries ? h.onLiftPhase?.call(s.sourceId!, s.seriesKey!, _rect) : null,
        onMagnetChanged: h.onMagnetChanged,
      ),
    );
  }
}

/// The two page controls over the card's lower edge (glass 2.4.1 rule 2): the lit tinted primary and the clear secondary with its
/// `dimClear` when the cover is bright. While the spotlight is outside the viewport they are their content twins.
class SpotlightActions extends ConsumerWidget {
  const SpotlightActions({super.key, required this.spec, required this.handlers, required this.onScreen});
  final SpotlightSpec spec;
  final SpotlightHandlers handlers;
  final bool onScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lMax = spec.palette?.lMax ?? 0.5;
    final dim = lMax > 0.45 && onScreen;
    Rect rectOf(BuildContext c) {
      final ro = c.findRenderObject();
      return ro is RenderBox && ro.attached ? ro.localToGlobal(Offset.zero) & ro.size : Rect.zero;
    }

    final primary = Builder(
      builder: (c) => GlassButton(
        label: spec.primaryLabel,
        variant: GlassButtonVariant.primary,
        role: GlassRole.pageControl,
        twin: onScreen ? null : GlassTwin.tinted,
        debugLabel: 'SpotlightPrimary',
        onPressed: () => handlers.onPrimary(spec, rectOf(c)),
      ),
    );
    final secondary = spec.secondaryLabel == null
        ? null
        : Builder(
            builder: (c) => DecoratedBox(
              decoration: BoxDecoration(color: dim ? const Color(0x59000000) : const Color(0x00000000), borderRadius: BorderRadius.circular(25)),
              child: GlassButton(
                label: spec.secondaryLabel!,
                overMedia: true,
                role: GlassRole.pageControl,
                lb: lMax,
                twin: onScreen ? null : GlassTwin.onGlass,
                debugLabel: 'SpotlightSecondary',
                onPressed: () => handlers.onSecondary(spec, rectOf(c)),
              ),
            ),
          );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: primary),
        if (secondary != null) ...[const SizedBox(width: 8), Flexible(child: secondary)],
      ],
    );
  }
}

/// The friend chip of a letter card: `bloom` wash and rim.
class BloomChip extends StatelessWidget {
  const BloomChip(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: gt.colorBloomWash, borderRadius: BorderRadius.circular(16), border: Border.all(color: gt.colorBloomRim, width: 0.5)),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), child: GlassLabel(label, role: gt.typeFootnote, wght: 600, color: gt.colorBloom, maxLines: 2)),
      );
}

/// The text under (or beside) the card: title through [LetterReveal] (it re-reveals whenever the page changes), the meta line, and
/// the `why` with the machine sparkle or the letter's bloom chip.
class SpotlightText extends StatelessWidget {
  const SpotlightText({super.key, required this.spec, this.wide = false});
  final SpotlightSpec spec;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final align = wide ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        LetterReveal(spec.title, role: wide ? gt.typeDisplay : gt.typeTitle1, screenId: kHomeScreenId, maxLines: 2, textAlign: wide ? TextAlign.start : TextAlign.center),
        const SizedBox(height: 4),
        GlassLabel(spec.meta, role: gt.typeFootnote, color: gt.colorLabel2, textAlign: wide ? TextAlign.start : TextAlign.center),
        if (spec.from != null) ...[const SizedBox(height: 6), BloomChip("${spec.from!.name} thinks you'd like this")],
        if (spec.why != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (spec.aiWhy) ...[const MachineBadge(), const SizedBox(width: 4)],
              Flexible(child: GlassLabel(spec.why!, role: gt.typeFootnote, italic: true, color: gt.colorLabel2, maxLines: 2, textAlign: wide ? TextAlign.start : TextAlign.center)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Used by the wide stage to size the cover.
double spotlightCoverWidth(BuildContext context, {required bool wide}) => wide ? 240 : MediaQuery.sizeOf(context).width * 0.62;

GlassFrameKind spotlightFrame(BuildContext context) => GlassFrame.of(context);
