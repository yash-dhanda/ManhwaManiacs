import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ocr/services/ocr_snippet.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look_actions.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';

export 'package:manhwamaniacs/skins/cinematic/primitives/cine_pull_to_reprint.dart'
    show CinePullToReprint;
export 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart'
    show SetHeading, SetTrigger;

/// Quick look on the real sheet: cover, credits and one action (`Open`).
Future<void> showQuickLook(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String? coverUrl,
  String? kicker,
  String? caption,
  required VoidCallback onOpen,
  String openLabel = 'Open',
  bool haptic = true,
}) {
  if (haptic) {
    unawaited(ref.read(skinHapticsProvider).fire(HapticEvent.longpressOpen));
  }
  return openQuickLook(
    context,
    title: title,
    kicker: kicker,
    credits: caption,
    cover: CineCover(url: coverUrl, displayWidth: 96),
    actions: [
      QuickLookAction('open', openLabel, CineIconRole.external,
          onSelected: onOpen,),
    ],
  );
}

/// A live "Retrying in N s" line for a `Retry-After`; calls [onZero] once.
class RetryCountdown extends StatefulWidget {
  const RetryCountdown({
    super.key,
    required this.seconds,
    this.prefix = 'Retrying in',
    this.style,
    this.onZero,
  });

  final int seconds;
  final String prefix;
  final TextStyle? style;
  final VoidCallback? onZero;

  @override
  State<RetryCountdown> createState() => _RetryCountdownState();
}

class _RetryCountdownState extends State<RetryCountdown> {
  late int _left = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_left <= 1) {
        t.cancel();
        setState(() => _left = 0);
        widget.onZero?.call();
        return;
      }
      setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
        '${widget.prefix} $_left s',
        style: widget.style ?? cineText(context, context.cine.typeDeck),
      );
}

/// A snippet whose highlighted terms sweep a `spot.wash` band in, left to
/// right: 200 ms per band, 60 ms apart, `easeSet`. The end state at once
/// under reduced motion.
class SweepHighlightText extends StatefulWidget {
  const SweepHighlightText(
    this.snippet, {
    super.key,
    required this.style,
    this.maxLines,
    this.maxScale,
    this.textAlign = TextAlign.center,
  });

  final String snippet;
  final TextStyle style;
  final int? maxLines;
  final double? maxScale;
  final TextAlign textAlign;

  @override
  State<SweepHighlightText> createState() => _SweepHighlightTextState();
}

class _SweepHighlightTextState extends State<SweepHighlightText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  late final List<OcrSnippetSpan> _spans = ocrSnippetSpans(widget.snippet);
  bool _started = false;

  int get _bands => _spans.where((s) => s.highlighted).length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final n = _bands;
    if (n == 0 || cineReduced(context)) {
      _c.value = 1;
      return;
    }
    _c.duration = CineDur.clip + const Duration(milliseconds: 60) * (n - 1);
    unawaited(_c.forward());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final total = _c.duration?.inMilliseconds ?? 1;
    var band = 0;
    final children = <InlineSpan>[];
    for (final s in _spans) {
      if (!s.highlighted) {
        children.add(TextSpan(text: s.text, style: widget.style));
        continue;
      }
      final start = 60 * band++ / total;
      final end = (60 * (band - 1) + CineDur.clip.inMilliseconds) / total;
      children.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final v = total <= 1
                  ? 1.0
                  : CineCurves.easeSet.transform(
                      Interval(start, end.clamp(0, 1)).transform(_c.value),
                    );
              return Stack(
                children: [
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: v,
                      child: ColoredBox(color: t.colorSpotWash),
                    ),
                  ),
                  Text(s.text, style: widget.style),
                ],
              );
            },
          ),
        ),
      );
    }
    final rich = RichText(
      maxLines: widget.maxLines,
      overflow:
          widget.maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
      textAlign: widget.textAlign,
      textScaler: MediaQuery.textScalerOf(context),
      text: TextSpan(style: widget.style, children: children),
    );
    return widget.maxScale == null
        ? rich
        : MediaQuery.withClampedTextScaling(
            maxScaleFactor: widget.maxScale!,
            child: rich,
          );
  }
}

/// Fires [onLongPress] after 450 ms (the Cinematic long-press; Flutter's
/// default is 500 ms). A null [onLongPress] adds nothing.
class CineLongPress extends StatelessWidget {
  const CineLongPress({
    super.key,
    required this.onLongPress,
    required this.child,
  });

  final VoidCallback? onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cb = onLongPress;
    if (cb == null) return child;
    return RawGestureDetector(
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(
            duration: const Duration(milliseconds: 450),
          ),
          (r) => r.onLongPress = cb,
        ),
      },
      child: child,
    );
  }
}

/// The real focus-ring painter around [child] while a descendant (an `InkWell`,
/// a field) holds hardware-keyboard focus; adds no focus stop of its own.
class ChildFocusRing extends StatefulWidget {
  const ChildFocusRing({super.key, required this.child});

  final Widget child;

  @override
  State<ChildFocusRing> createState() => _ChildFocusRingState();
}

class _ChildFocusRingState extends State<ChildFocusRing> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (f) {
        final keyboard = FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
        if (mounted) setState(() => _on = f && keyboard);
      },
      child: CustomPaint(
        foregroundPainter: CineFocusRingPainter(
          visible: _on,
          round: false,
          ink: c.colorInk100,
          width: c.focusWidth,
          offset: c.focusOffset,
          halo: c.focusHalo,
        ),
        child: widget.child,
      ),
    );
  }
}
