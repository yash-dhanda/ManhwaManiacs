import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/cine_monogram.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/cine_wordmark.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/splash_timeline.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';

/// Screens with a typed headline (Login, the picker, Tonight) start typing when this turns true:
/// the hand-off has begun.
final splashDoneProvider = StateProvider<bool>((ref) => false, name: 'splashDone');

/// SharedPreferences key: epoch ms of the last hand-off (a warm start is under 4 h after it).
const String kSplashLastKey = 'mm.splash.last';

/// "Press start" (cinematic 8.2, 12.4): the top layer of the app frame, full screen, `#000`. The
/// choreography always runs 0 - 1180 ms and is never stretched; the hand-off starts at
/// `max(probeDone, 1180)`, where `probeDone` is `authControllerProvider` leaving `AuthUnknown`. A
/// tap, `Enter`, `Space` or `Esc` skips to the hand-off (or to the hold while the probe pends).
/// A warm start (a hand-off under 4 h ago, no skin restart) plays only the 200 ms fades.
///
/// [freezeAtMs] paints the frame at that time with no clock (the gallery and the harness).
class CineSplash extends ConsumerStatefulWidget {
  const CineSplash({super.key, this.freezeAtMs, this.warm, this.tablet});

  final double? freezeAtMs;

  /// Forces the warm path (tests); null reads the preferences.
  final bool? warm;
  final bool? tablet;

  @override
  ConsumerState<CineSplash> createState() => _CineSplashState();
}

class _CineSplashState extends ConsumerState<CineSplash> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  double _ms = 0;
  double _offset = 0;
  int? _probeDoneMs;
  int? _handoffAt;
  bool _impressed = false;
  bool _gone = false;
  late final bool _warm;
  bool _revealSoundPlayed = false;

  @override
  void initState() {
    super.initState();
    _ms = widget.freezeAtMs ?? 0;
    if (widget.freezeAtMs != null) return;
    final prefs = ref.read(sharedPrefsProvider);
    _warm = widget.warm ??
        splashIsWarm(
          lastHandoffEpochMs: prefs.getInt(kSplashLastKey),
          skinRestart: prefs.containsKey(kSkinT0Key),
          nowEpochMs: DateTime.now().millisecondsSinceEpoch,
        );
    // SKIN RESTART: reads and clears mm.skin.t0 on the first frame.
    logSkinRestart(prefs);
    if (ref.read(authControllerProvider) is! AuthUnknown) _probeDoneMs = 0;
    ref.listenManual<AuthState>(authControllerProvider, (prev, next) {
      if (_probeDoneMs == null && next is! AuthUnknown) _probeDoneMs = _ms.round();
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  bool get _reduced => CineMotion.reduced(context);

  double get _reduceFadeIn => 300;

  void _tick(Duration d) {
    final ms = d.inMicroseconds / 1000 + _offset;
    if (!_warm && !_revealSoundPlayed) {
      _revealSoundPlayed = true;
      _play();
    }
    if (!_warm && !_impressed && ms >= kSplashImpressionMs) {
      _impressed = true;
      if (!_reduced) cineFeedback(context, HapticEvent.splashImpress);
    }
    // A pending probe is settled against the clock that has run so far.
    if (_handoffAt == null) {
      final at = _warm || _reduced ? _warmHandoff() : splashHandoffAt(_probeDoneMs);
      if (at != null && ms >= at) _startHandoff(ms);
    }
    if (_handoffAt != null && ms >= _handoffAt! + kSplashHandoffMs) {
      _ticker.stop();
      setState(() => _gone = true);
      return;
    }
    setState(() => _ms = ms);
  }

  int? _warmHandoff() => _probeDoneMs == null ? null : (_probeDoneMs! > 2 * kSplashWarmFadeMs ? _probeDoneMs! : 2 * kSplashWarmFadeMs);

  void _play() {
    try {
      SkinAudio.instance.play(SoundEvent.splashReveal).catchError((Object _) {});
    } catch (_) {}
  }

  void _startHandoff(double ms) {
    _handoffAt = ms.round();
    ref.read(splashDoneProvider.notifier).state = true;
    ref.read(sharedPrefsProvider).setInt(kSplashLastKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Skips to the hand-off, or to the hold while the probe is pending.
  void _skip() {
    if (_handoffAt != null || widget.freezeAtMs != null) return;
    if (_probeDoneMs == null) {
      // Jump the choreography to its end; the hand-off waits for the probe.
      if (_ms < kSplashImpressionMs) setState(() => _offset += kSplashImpressionMs - _ms);
      return;
    }
    _startHandoff(_ms);
  }

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.escape) {
      _skip();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();
    final c = context.cine;
    final tablet = widget.tablet ?? MediaQuery.sizeOf(context).width >= 600;
    final ms = _ms;
    final handoff = _handoffAt == null ? 0.0 : ((ms - _handoffAt!) / kSplashHandoffMs).clamp(0.0, 1.0);
    final opacity = 1 - handoff;

    Widget lockup;
    if (_warm && widget.freezeAtMs == null) {
      // Warm: the stacked lockup fades in over 200 ms and out over 200 ms, no letters.
      final inT = (ms / kSplashWarmFadeMs).clamp(0.0, 1.0);
      final outT = _handoffAt == null ? 0.0 : ((ms - _handoffAt!) / kSplashWarmFadeMs).clamp(0.0, 1.0);
      lockup = Opacity(opacity: (inT * (1 - outT)).clamp(0.0, 1.0), child: const CineWordmark(frozenMs: 2000));
    } else if (_reduced && widget.freezeAtMs == null) {
      // Reduced: the lockup fades in over 300 ms, holds until ready, fades out over 200 ms.
      final inT = (ms / _reduceFadeIn).clamp(0.0, 1.0);
      final outT = _handoffAt == null ? 0.0 : ((ms - _handoffAt!) / 200).clamp(0.0, 1.0);
      lockup = Opacity(opacity: (inT * (1 - outT)).clamp(0.0, 1.0), child: const CineWordmark(frozenMs: 2000));
    } else {
      final mono = splashSpan('monogram-in').at(ms);
      final inter = splashSpan('intersection').at(ms);
      final out = splashSpan('monogram-out').at(ms);
      final monoOpacity = mono * (1 - out);
      final monoScale = 1 - 0.04 * out;
      final rule = splashSpan('oxford-rule').at(ms);
      final press = splashImpressionOffset(ms);
      lockup = Stack(alignment: Alignment.center, children: [
        Opacity(
          opacity: monoOpacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: monoScale,
            child: CineMonogram(width: tablet ? 160 : 112, intersection: inter, glow: 0.35 * inter),
          ),
        ),
        if (ms >= kSplashLetterStartMs || widget.freezeAtMs != null)
          Transform.translate(
            offset: Offset(0, press),
            child: CineWordmark(frozenMs: widget.freezeAtMs, ruleProgress: rule),
          ),
      ],);
    }

    final dial = splashShowsDial(ms.round(), _probeDoneMs) && widget.freezeAtMs == null;
    return ExcludeSemantics(
      excluding: false,
      child: Focus(
        onKeyEvent: _key,
        canRequestFocus: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _skip,
          child: Semantics(
            liveRegion: true,
            label: 'Loading ManhwaManiacs',
            excludeSemantics: true,
            child: Opacity(
              opacity: opacity,
              child: ColoredBox(
                color: const Color(0xFF000000),
                child: SizedBox.expand(
                  child: Stack(alignment: Alignment.center, children: [
                    Center(child: lockup),
                    if (dial)
                      Align(
                        alignment: const Alignment(0, 0.35),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const CineLeaderDial(size: 24, showAfter: Duration.zero, semanticLabel: 'Connecting'),
                          SizedBox(height: c.space2),
                          CineRoleText('CONNECTING', c.typeKicker, color: c.colorInk60),
                        ],),
                      ),
                  ],),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
