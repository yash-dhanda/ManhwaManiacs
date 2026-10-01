import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

enum GlassLensTone { empty, error, offline }

/// `full` is chrome: a live T2 surface over the ambient field. `inline` is its content twin, for scrolling regions (a rail's
/// error card, a seam card, a list's empty row).
enum GlassLensPlacement { full, inline }

class LensAction {
  const LensAction(this.label, this.onPressed);
  final String label;
  final VoidCallback onPressed;
}

/// The object lens (glass 7.24): a 96 px `glassThin` circle (a fixed-size lens keeps T2, 2.4.3) holding a 44 px Light glyph in
/// its tone colour with no backing disc (the 2.1.2 exception), bobbing 2 px on a 6 s sine. Below: title, description (about 300 px
/// wide) and up to two buttons. Tones set the field: `empty` the profile's mood, `error` and `offline` the mood at half opacity.
/// An offline lens retries by itself when the connection returns (3 s cooldown) and hops once when the retry succeeds.
class GlassObjectLens extends ConsumerStatefulWidget {
  const GlassObjectLens({
    super.key,
    required this.situation,
    required this.title,
    this.description,
    this.tone = GlassLensTone.empty,
    this.placement = GlassLensPlacement.full,
    this.primary,
    this.secondary,
    this.onRetry,
    this.mood = Mood.neutral,
    this.clock,
    this.forceOnline,
  });

  final LensSituation situation;
  final String title;
  final String? description;
  final GlassLensTone tone;
  final GlassLensPlacement placement;
  final LensAction? primary;
  final LensAction? secondary;

  /// Offline auto-retry: returns true when the retry worked (the lens hops).
  final Future<bool> Function()? onRetry;
  final Mood mood;
  final DateTime Function()? clock;

  /// Tests: a stream standing in for the connectivity provider.
  final Stream<bool>? forceOnline;

  @override
  ConsumerState<GlassObjectLens> createState() => _GlassObjectLensState();
}

class _GlassObjectLensState extends ConsumerState<GlassObjectLens> with TickerProviderStateMixin {
  late final AnimationController _bob;
  late final AnimationController _hop;
  VoidCallback? _stop;
  DateTime? _lastRetry;

  DateTime _now() => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(vsync: this, duration: const Duration(seconds: 6));
    _hop = AnimationController(vsync: this);
    if (!ref.read(glassMotionPrefsProvider).reduced) _bob.repeat();
    _listen();
  }

  void _listen() {
    _stop?.call();
    _stop = null;
    if (widget.tone != GlassLensTone.offline || widget.onRetry == null) return;
    final forced = widget.forceOnline;
    if (forced != null) {
      final sub = forced.listen((online) {
        if (online) unawaited(retry());
      });
      _stop = () => unawaited(sub.cancel());
      return;
    }
    final sub = ref.listenManual(networkOnlineChangesProvider, (_, next) {
      if (next.valueOrNull ?? false) unawaited(retry());
    });
    _stop = sub.close;
  }

  /// Runs [GlassObjectLens.onRetry] unless one ran in the last 3 s.
  Future<void> retry() async {
    final f = widget.onRetry;
    if (f == null) return;
    final now = _now();
    if (_lastRetry != null && now.difference(_lastRetry!) < const Duration(seconds: 3)) return;
    _lastRetry = now;
    final ok = await f();
    if (ok && mounted) {
      _hop.value = 0;
      unawaited(GlassMotion.play(MotionName.lensHop, controller: _hop, target: 1));
    }
  }

  @override
  void didUpdateWidget(GlassObjectLens old) {
    super.didUpdateWidget(old);
    if (old.tone != widget.tone || (old.onRetry == null) != (widget.onRetry == null)) _listen();
  }

  @override
  void dispose() {
    _stop?.call();
    _bob.dispose();
    _hop.dispose();
    super.dispose();
  }

  Color get _glyphColor => lensGlyphIsNeutral(widget.situation)
      ? gt.colorLabel2
      : switch (widget.tone) {
          GlassLensTone.empty => gt.colorIris400,
          GlassLensTone.error => gt.colorDanger,
          GlassLensTone.offline => gt.colorWarning,
        };

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    if (reduced && _bob.isAnimating) _bob.stop();
    if (!reduced && !_bob.isAnimating) _bob.repeat();
    final host = GlassHost.of(context);
    final glyph = Icon(lensGlyph(widget.situation), size: 44, color: _glyphColor);
    final Widget disc = widget.placement == GlassLensPlacement.full
        ? SkinGlass(size: const Size.square(96), tier: GlassTierId.t2, shape: const GlassShape.circle(), debugLabel: 'GlassObjectLens', child: Center(child: glyph))
        : DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x9E131317), border: Border.all(color: const Color(0x38FFFFFF), width: 0.5)),
            child: SizedBox.square(dimension: 96, child: Center(child: glyph)),
          );
    final lens = SizedBox.square(
      dimension: 96,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bob, _hop]),
        builder: (context, child) {
          final bob = reduced ? 0.0 : 2 * math.sin(2 * math.pi * _bob.value);
          final hop = -12 * math.sin(math.pi * _hop.value.clamp(0.0, 1.0));
          return Transform.translate(offset: Offset(0, bob + hop), child: child);
        },
        child: disc,
      ),
    );
    final mood = widget.mood;
    final opacity = (kMoodOpacity[mood] ?? 0.2) * (widget.tone == GlassLensTone.empty ? 1 : 0.5);
    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: lens),
              const SizedBox(height: 16),
              Semantics(header: true, headingLevel: 2, child: GlassText(widget.title, role: gt.typeTitle3, textAlign: TextAlign.center, onGlass: host)),
              if (widget.description != null) ...[
                const SizedBox(height: 8),
                GlassText(widget.description!, role: gt.typeCallout, color: host ? gt.colorOnGlass : gt.colorLabel2, textAlign: TextAlign.center, onGlass: host),
              ],
              if (widget.primary != null || widget.secondary != null) ...[
                const SizedBox(height: 24),
                if (widget.primary != null) GlassButton(label: widget.primary!.label, variant: GlassButtonVariant.primary, onPressed: widget.primary!.onPressed),
                if (widget.secondary != null) ...[
                  const SizedBox(height: 8),
                  GlassButton(label: widget.secondary!.label, onPressed: widget.secondary!.onPressed),
                ],
              ],
            ],
          ),
        ),
      ),
    );
    if (widget.placement == GlassLensPlacement.inline) return body;
    // A full lens is the screen; if the screen is too short for it (a landscape phone, a huge text size) it scrolls.
    return GlassAmbientScope(spec: GlassAmbientSpec.mood(mood, opacity: opacity), child: Center(child: SingleChildScrollView(child: body)));
  }
}
