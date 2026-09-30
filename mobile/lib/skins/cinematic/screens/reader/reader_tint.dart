import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/reader/engine/page_tint.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The two animated roles of the page-tinted chrome (cinematic 9.4.4): `page.tint` for the scrims'
/// 25 % mix and `page.light` for the ruler's played part, the micro progress and the setup sheet's
/// top rule. Both null means the chrome is untinted.
class ReaderTint {
  const ReaderTint({this.tint, this.light});
  final Color? tint, light;
  static const none = ReaderTint();
}

/// `page.tint` and `page.light` for a tint source; the cover source derives both from the series
/// cover's `ambient.duo`, falling back to `#B8B2A4`.
ReaderTint readerTintFor(PageTintSource source, Color coverDuo) {
  final seed = switch (source) {
    PageTintPage(:final seed) => parseAmbientHex(seed, fallback: coverDuo),
    PageTintCover() => coverDuo,
  };
  final hsl = HSLColor.fromColor(seed);
  return ReaderTint(tint: pageTint(hsl.hue, hsl.saturation), light: pageLight(hsl.hue, hsl.saturation));
}

class ReaderTintScope extends InheritedWidget {
  const ReaderTintScope({super.key, required this.value, required super.child});
  final ReaderTint value;

  static ReaderTint of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ReaderTintScope>()?.value ?? ReaderTint.none;

  @override
  bool updateShouldNotify(ReaderTintScope old) => old.value.tint != value.tint || old.value.light != value.light;
}

/// The reader chrome root's colour animation: one `TweenAnimationBuilder<Color?>` per role. Every
/// change dissolves over `durDissolve` along `CineCurves.turn`, retargeting from the current
/// colour. Reduced motion swaps at most once every 2 s without a fade. [enabled] false leaves the
/// chrome untinted.
class ReaderTintHost extends StatefulWidget {
  const ReaderTintHost({super.key, required this.source, required this.enabled, required this.coverDuo, required this.child});

  final ValueListenable<PageTintSource?> source;
  final bool enabled;
  final Color coverDuo;
  final Widget child;

  @override
  State<ReaderTintHost> createState() => _ReaderTintHostState();
}

class _ReaderTintHostState extends State<ReaderTintHost> {
  ReaderTint? _applied;
  Timer? _cool;

  @override
  void dispose() {
    _cool?.cancel();
    super.dispose();
  }

  ReaderTint _resolve(PageTintSource? src, bool reduced) {
    if (!widget.enabled || src == null) return ReaderTint.none;
    final target = readerTintFor(src, widget.coverDuo);
    if (!reduced) return _applied = target;
    // Reduced motion: at most one swap every 2 s. While cooling, the colour on screen stays and the
    // newest target is applied when the timer runs out.
    if (_cool != null && _applied != null) return _applied!;
    _cool = Timer(const Duration(seconds: 2), () {
      _cool = null;
      if (mounted) setState(() {});
    });
    return _applied = target;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = CineMotion.reduced(context);
    final cine = context.cine;
    return ValueListenableBuilder<PageTintSource?>(
      valueListenable: widget.source,
      child: widget.child,
      builder: (context, src, child) {
        final t = _resolve(src, reduced);
        if (t.tint == null) return ReaderTintScope(value: ReaderTint.none, child: child!);
        final duration = reduced ? Duration.zero : cine.durDissolve;
        // The first tint dissolves in from the untinted colours: black scrims and `ink.100`.
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(begin: const Color(0xFF000000), end: t.tint),
          duration: duration,
          curve: CineCurves.turn,
          builder: (context, tint, _) => TweenAnimationBuilder<Color?>(
            tween: ColorTween(begin: cine.colorInk100, end: t.light),
            duration: duration,
            curve: CineCurves.turn,
            builder: (context, light, _) => ReaderTintScope(value: ReaderTint(tint: tint, light: light), child: child!),
          ),
        );
      },
    );
  }
}
