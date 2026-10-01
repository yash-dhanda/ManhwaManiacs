import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroine/heroine.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/utils/presence.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/avatar_map.dart';
import 'package:manhwamaniacs/skins/glass/transitions/poster_zoom.dart' show glassZoomMotion;
import 'package:manhwamaniacs/skins/skins.dart';

/// The one orb that is flying into the friend sheet's header right now (glass 9.3.1 signature): only the tapped orb instance
/// carries the `circle-orb-{id}` Heroine tag, so two orbs of one person on screen never share it.
final flyingOrbProvider = StateProvider<Object?>((ref) => null, name: 'glassFlyingOrb');

String circleOrbTag(int profileId) => 'circle-orb-$profileId';

/// Opens [member]'s friend sheet: marks [token] as the flying orb just before the push, and puts focus back on [returnFocus]
/// when the sheet closes. Reduced motion: the Heroine flight is replaced by the route's 200 ms cross-fade (no tag).
Future<void> openFriend(WidgetRef ref, ProfileRef member, {Object? token, Rect? from, FocusNode? returnFocus}) async {
  final reduced = ref.read(glassReducedProvider);
  ref.read(flyingOrbProvider.notifier).state = reduced ? null : token;
  final e = GlassMotion.recorder.begin(MotionName.zoom.label, 558);
  try {
    await ref.read(skinRouterProvider).push<void>(Routes.circleMember(member.profileId), extra: GlassNavExtra(originRect: from));
  } finally {
    GlassMotion.recorder.end(e);
  }
  try {
    ref.read(flyingOrbProvider.notifier).state = null;
  } catch (_) {}
  if (returnFocus != null && returnFocus.context != null) returnFocus.requestFocus();
}

/// A ring around an orb (glass 9.3.1): reading now breathes `bloom` 0.5 <-> 1 over 2.4 s on a sine (2 px at a 3 px offset),
/// active today is static at 40 %, away has none. Reduced motion: static at 1 (reading) or 0.4 (today). Decoration only.
class PresenceRing extends ConsumerStatefulWidget {
  const PresenceRing({super.key, required this.state, required this.size, required this.child, this.phase});
  final PresenceState state;
  final double size;
  final Widget child;

  /// Captures: a fixed point of the breath (0..1).
  final double? phase;

  @override
  ConsumerState<PresenceRing> createState() => _PresenceRingState();
}

class _PresenceRingState extends ConsumerState<PresenceRing> with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  GlassMotionEntry? _rec;

  @override
  void dispose() {
    if (_rec != null) GlassMotion.recorder.end(_rec!);
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassReducedProvider);
    final reading = widget.state == PresenceState.reading;
    final breathe = reading && !reduced && widget.phase == null;
    if (breathe && !_breath.isAnimating) {
      _breath.repeat();
      _rec ??= GlassMotion.recorder.begin(MotionName.liveRingBreathe.label, 2400);
    } else if (!breathe && _breath.isAnimating) {
      _breath.stop();
    }
    if (widget.state == PresenceState.away) return widget.child;
    final d = widget.size + 10;
    return SizedBox.square(
      dimension: d,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _breath,
              builder: (_, __) {
                final t = widget.phase ?? _breath.value;
                final a = !reading ? 0.4 : (reduced ? 1.0 : 0.75 - 0.25 * math.cos(2 * math.pi * t));
                return Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: gt.colorBloom.withValues(alpha: a), width: 2)),
                );
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// A Circle member's orb as a button with at least the hit minimum around it, a `bloom` friend ring, the Heroine tag while it is
/// the flying orb, and an accessible name.
class CircleOrbButton extends ConsumerStatefulWidget {
  const CircleOrbButton({super.key, required this.member, required this.size, required this.semanticsLabel, this.onPressed, this.focusNode, this.brightness = 1, this.mood});
  final ProfileRef member;
  final double size;
  final String semanticsLabel;

  /// Defaults to opening the friend sheet.
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final double brightness;
  final Color? mood;

  @override
  ConsumerState<CircleOrbButton> createState() => _CircleOrbButtonState();
}

class _CircleOrbButtonState extends ConsumerState<CircleOrbButton> {
  final GlobalKey _key = GlobalKey();

  Rect? _rect() {
    final ro = _key.currentContext?.findRenderObject();
    return ro is RenderBox && ro.attached && ro.hasSize ? ro.localToGlobal(Offset.zero) & ro.size : null;
  }

  void _open() {
    if (widget.onPressed != null) return widget.onPressed!();
    unawaited(openFriend(ref, widget.member, token: this, from: _rect(), returnFocus: widget.focusNode));
  }

  @override
  Widget build(BuildContext context) {
    final flying = ref.watch(flyingOrbProvider) == this;
    Widget orb = GlassProfileOrb(preset: glassPresetFor(widget.member.avatarKey), size: widget.size, friend: true, mood: widget.mood, name: widget.member.name);
    if (flying) orb = Heroine(tag: circleOrbTag(widget.member.profileId), motion: glassZoomMotion(), child: orb);
    if (widget.brightness < 1) orb = Opacity(opacity: widget.brightness, child: orb);
    return GlassPressable(
      key: _key,
      shape: const GlassShape.circle(),
      material: GlassMaterial.content,
      sink: 0.94,
      focusNode: widget.focusNode,
      onTap: _open,
      semanticsLabel: widget.semanticsLabel,
      hoverGlow: false,
      builder: (context, info) => ExcludeSemantics(child: orb),
    );
  }
}
