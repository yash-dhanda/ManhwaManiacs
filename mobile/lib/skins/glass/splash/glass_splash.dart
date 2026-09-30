import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/app/switch_skin.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/auth/providers/session_offline_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/brand_mark.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/status_capsule.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/shell/dock_geometry.dart';
import 'package:manhwamaniacs/skins/glass/shell/melt.dart';
import 'package:manhwamaniacs/skins/glass/shell/sidebar_geometry.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/splash/glass_mark.dart';
import 'package:manhwamaniacs/skins/glass/splash/splash_targets.dart';
import 'package:manhwamaniacs/skins/glass/splash/splash_timeline.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kGlassLastSeenKey = 'mm.glass.lastSeen';

/// The wordmark lines the lens reveals.
const List<String> kSplashWords = ['Manhwa', 'Maniacs'];

/// Writes `mm.glass.lastSeen` on `paused`, `hidden` and every 60 s while resumed (glass 12.4), which decides warm against cold.
class GlassLastSeenWriter extends ConsumerStatefulWidget {
  const GlassLastSeenWriter({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GlassLastSeenWriter> createState() => _GlassLastSeenWriterState();
}

class _GlassLastSeenWriterState extends ConsumerState<GlassLastSeenWriter> with WidgetsBindingObserver {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _t = Timer.periodic(const Duration(seconds: 60), (_) => _write());
  }

  void _write() {
    try {
      unawaited(ref.read(sharedPrefsProvider).setInt(kGlassLastSeenKey, DateTime.now().millisecondsSinceEpoch));
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) _write();
  }

  @override
  void dispose() {
    _t?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The Droplet (glass 8.2, 12.3, 12.4), drawn above the routes for one boot: it fades in from the black native frame, a droplet falls,
/// squashes and grows into a glass lens that refracts the mark into view, the wordmark rises and the lens hands off into its target.
/// Cold 1,200 ms, warm 400 ms, reduced a 200 ms cross-fade; a tap skips to the hand-off; the session probe holds the settle.
class GlassSplash extends ConsumerStatefulWidget {
  const GlassSplash({super.key, this.kind, this.now});

  /// Tests force a kind; null decides from the reduced flag, the last-seen time and the switch arrival.
  final SplashKind? kind;
  final DateTime Function()? now;

  @override
  ConsumerState<GlassSplash> createState() => _GlassSplashState();
}

class _GlassSplashState extends ConsumerState<GlassSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1));
  late SplashKind _kind;
  bool _done = false;
  bool _switchArrival = false;
  bool _landed = false;
  bool _settled = false;
  bool _skipped = false;

  int get _ms => (_c.value * splashDuration(_kind)).round();

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPrefsProvider);
    _switchArrival = prefs.containsKey(kSkinT0Key);
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    final lastSeenMs = prefs.getInt(kGlassLastSeenKey);
    final now = (widget.now ?? DateTime.now)();
    _kind = widget.kind ??
        (reduced
            ? SplashKind.reduced
            : splashIsWarm(now: now, lastSeen: lastSeenMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastSeenMs), skinSwitchArrival: _switchArrival)
                ? SplashKind.warm
                : SplashKind.cold);
    _c.duration = Duration(milliseconds: splashDuration(_kind));
    _c.addListener(_tick);
    unawaited(_run());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        unawaited(SemanticsService.sendAnnouncement(View.of(context), 'Loading ManhwaManiacs', Directionality.of(context)));
      } catch (_) {}
    });
  }

  Future<void> _run() async {
    final total = splashDuration(_kind);
    final hold = splashHandoffStart(_kind) / total;
    if (_kind == SplashKind.reduced) {
      unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.logoReduced));
      await _c.forward();
    } else {
      await _c.animateTo(hold);
      // The session probe: hold at the settle while the session is unresolved (3 s at most).
      var waited = 0;
      while (mounted && ref.read(authControllerProvider) is AuthUnknown && waited < 3000 && !_skipped) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        waited += 50;
      }
      if (!mounted) return;
      await _c.forward();
    }
    if (mounted) _finish();
  }

  void _tick() {
    if (_kind != SplashKind.cold) return;
    final ms = _ms;
    if (!_landed && ms >= 200) {
      _landed = true;
      unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.logoLand));
      glassSound(ref, SoundEvent.logoLand);
    }
    if (!_settled && ms >= 700) {
      _settled = true;
      unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.logoSettle));
      glassSound(ref, SoundEvent.logoSettle);
    }
  }

  void _skip() {
    if (_done || _skipped) return;
    _skipped = true;
    final hold = splashHandoffStart(_kind) / splashDuration(_kind);
    if (_c.value < hold) _c.value = hold;
  }

  void _finish() {
    if (_done) return;
    setState(() => _done = true);
    final prefs = ref.read(sharedPrefsProvider);
    unawaited(prefs.setInt(kGlassLastSeenKey, DateTime.now().millisecondsSinceEpoch));
    if (_switchArrival) _arrivalToast(prefs);
  }

  /// "Switched to Glass" with a 10 s draining rim and Undo (which switches back with no alert).
  void _arrivalToast(SharedPreferences prefs) {
    final from = takeSkinArrival(prefs);
    if (from == null) return;
    final back = skinIdFromName(from);
    if (back == null) return;
    showGlassToast(
      ref,
      GlassToastSpec(
        'Switched to Glass',
        undo: () => unawaited(switchSkinFrom(context, ref, to: back, undoable: false, outgoing: () => playMelt(ref))),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Rect _target(Size size) {
    final reg = registeredSplashTargetRect();
    if (reg != null) return reg;
    final fallback = ref.read(glassSplashFallbackProvider);
    if (fallback != null) return fallback;
    final frame = GlassFrame.ofSize(size);
    if (frame == GlassFrameKind.phone) return GlassDockGeometry.of(size, MediaQuery.paddingOf(context)).dock;
    final expanded = sidebarStartsExpanded(size.width);
    return GlassSidebarGeometry.of(size, expanded: expanded).profileCapsule;
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    final size = MediaQuery.sizeOf(context);
    final offline = ref.watch(sessionOfflineProvider);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _skip,
      child: Semantics(
        label: 'Loading ManhwaManiacs',
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final ms = _ms;
            if (_kind == SplashKind.reduced) return _reduced(size);
            final f = _kind == SplashKind.cold ? splashCold(ms) : splashWarm(ms);
            return _frame(size, f, offline);
          },
        ),
      ),
    );
  }

  Widget _reduced(Size size) {
    final t = splashReducedFade(_ms);
    return Opacity(opacity: 1 - t, child: const ColoredBox(color: Color(0xFF000000), child: Center(child: GlassMark())));
  }

  Widget _frame(Size size, SplashFrame f, bool offline) {
    final center = Offset(size.width / 2, size.height / 2);
    final target = _target(size);
    final lensRect = Rect.fromCenter(center: center, width: f.lensSide, height: f.lensSide);
    final rect = Rect.lerp(lensRect, target, Curves.easeInOutCubic.transform(f.handoff))!;
    final wordOpacity = (1 - f.handoff) * f.wordmark.clamp(0.0, 1.0);
    final showLens = f.lensOpacity > 0 && (_kind == SplashKind.warm || _ms >= 200);
    final holdSpinner = _kind == SplashKind.cold && _ms >= 990 && ref.read(authControllerProvider) is AuthUnknown;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: const Color(0xFF000000).withValues(alpha: 1 - f.handoff)),
        if (f.markOpacity > 0) Center(child: Opacity(opacity: f.markOpacity, child: const GlassMark())),
        if (_kind == SplashKind.cold && _ms < 200)
          Positioned.fromRect(
            rect: Rect.fromCenter(center: center.translate(0, f.dropletDy), width: 24, height: 24),
            child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x66FFFFFF), border: Border.all(width: 0.5, color: const Color(0x99FFFFFF)))),
          ),
        if (f.rippleOpacity > 0)
          Positioned.fill(child: CustomPaint(painter: _RipplePainter(center: center, radius: f.rippleRadius, opacity: f.rippleOpacity))),
        if (showLens)
          Positioned.fromRect(
            rect: rect,
            child: Opacity(
              opacity: f.lensOpacity,
              child: Transform.scale(
                scaleX: f.squashX,
                scaleY: f.squashY,
                child: SkinGlass(
                  size: rect.size,
                  tier: GlassTierId.t5,
                  shape: GlassShape.superellipse(rect.shortestSide * 0.28),
                  debugLabel: 'GlassSplashLens',
                  materialize: false,
                  child: Center(child: _Refract(height: rect.shortestSide * 0.62, blur: f.refractBlur, chroma: f.chromaOffset)),
                ),
              ),
            ),
          ),
        if (holdSpinner) Positioned(left: center.dx - 12, top: center.dy + f.lensSide / 2 + 12, child: const SizedBox(width: 24, height: 24, child: GlassSpinner(size: 24))),
        if (offline && _ms >= 700) Positioned(left: 0, right: 0, top: center.dy + f.lensSide / 2 + 16, child: const Center(child: GlassStatusCapsule(kind: GlassStatusKind.offline))),
        if (wordOpacity > 0)
          Positioned(
            left: 0,
            right: 0,
            top: center.dy + f.lensSide / 2 + 28,
            child: Opacity(opacity: wordOpacity.clamp(0.0, 1.0), child: _Wordmark(progress: f.wordmark)),
          ),
      ],
    );
  }
}

class _RipplePainter extends CustomPainter {
  const _RipplePainter({required this.center, required this.radius, required this.opacity});
  final Offset center;
  final double radius;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(center, radius, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = Color.fromRGBO(255, 255, 255, opacity));
  }

  @override
  bool shouldRepaint(_RipplePainter o) => o.radius != radius || o.opacity != opacity;
}

/// The MM column refracting into view: a blurred base and red and blue channel copies offset by +-[chroma] px.
class _Refract extends StatelessWidget {
  const _Refract({required this.height, required this.blur, required this.chroma});
  final double height;
  final double blur;
  final double chroma;

  @override
  Widget build(BuildContext context) {
    Widget mark(Color c) => GlassMark(height: height, color: c);
    Widget blurred(Widget w) => blur <= 0.01 ? w : ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: TileMode.decal), child: w);
    if (chroma <= 0.05) return blurred(mark(GlassMarkGeometry.frost));
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(offset: Offset(-chroma, 0), child: blurred(mark(const Color(0xFFFF4040)))),
        Transform.translate(offset: Offset(chroma, 0), child: blurred(mark(const Color(0xFF4060FF)))),
        Opacity(opacity: 0.85, child: blurred(mark(GlassMarkGeometry.frost))),
      ],
    );
  }
}

/// "Manhwa" / "Maniacs" rising from behind the lens: 13 glyphs, 24 ms apart on the `letter` spring, blur 12 to 0.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final ms = progress * 500;
    var i = 0;
    Widget line(String w) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final ch in w.characters)
              Builder(builder: (context) {
                final t = ((ms - (i++) * 24) / 345).clamp(0.0, 1.0);
                final base = roleStyle(context, gt.typeTitle1, wght: 700).copyWith(color: const Color(0xFFF5F7FA));
                final text = Text(ch, textScaler: TextScaler.noScaling, style: base);
                return Opacity(
                  opacity: t,
                  child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: t >= 1 ? text : ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 12 * (1 - t), sigmaY: 12 * (1 - t)), child: text)),
                );
              },),
          ],
        );
    return Column(mainAxisSize: MainAxisSize.min, children: [for (final w in kSplashWords) line(w)]);
  }
}

