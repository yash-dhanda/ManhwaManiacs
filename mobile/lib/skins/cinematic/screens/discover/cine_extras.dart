import 'dart:async';

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ocr/services/ocr_snippet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';

// TODO(mobile/04, mobile/05): stand-ins for the focus ring, toast, Quick look,
// pull to reprint and highlight sweep primitives; same DESIGN values.

/// A 2 px `spot` ring around [child] while a descendant has keyboard focus.
class CineFocusRing extends StatefulWidget {
  const CineFocusRing({super.key, required this.child});

  final Widget child;

  @override
  State<CineFocusRing> createState() => _CineFocusRingState();
}

class _CineFocusRingState extends State<CineFocusRing> {
  bool _on = false;

  @override
  Widget build(BuildContext context) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (f) {
          final keyboard = FocusManager.instance.highlightMode ==
              FocusHighlightMode.traditional;
          if (mounted) setState(() => _on = f && keyboard);
        },
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: _on
                ? Border.all(color: context.cine.colorSpot, width: 2)
                : null,
          ),
          child: widget.child,
        ),
      );
}

/// The Cinematic toast: paper.2 plate, 2 px left edge (`spot`, or `proof` for
/// errors), held 3600 ms (6000 ms for errors).
void showCineToast(BuildContext context, String text, {bool error = false}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final t = context.cine;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (c) => Positioned(
      left: CineSpace.s4,
      right: CineSpace.s4,
      bottom: MediaQuery.paddingOf(c).bottom + CineSpace.s4,
      child: Semantics(
        liveRegion: true,
        container: true,
        label: text,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.colorPaper2,
            border: Border(
                left: BorderSide(
                    color: error ? t.colorProof : t.colorSpot, width: 2,),),
          ),
          child: Padding(
            padding: const EdgeInsets.all(CineSpace.s3),
            child: Text(text,
                style: cineText(c, t.typeUi)
                    .copyWith(decoration: TextDecoration.none),),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Timer(error ? CineDur.holdToastError : CineDur.holdToast, () {
    if (entry.mounted) entry.remove();
  });
}

/// Quick look: a content-fit sheet with the cover, the title and `Open`.
/// Fires haptic `longpress.open`; callers open it from a 450 ms long-press.
Future<void> showQuickLook(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String? coverUrl,
  String? kicker,
  String? caption,
  required VoidCallback onOpen,
  String openLabel = 'Open',
}) {
  unawaited(ref.read(skinHapticsProvider).fire(HapticEvent.longpressOpen));
  final t = context.cine;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: t.colorPaper2,
    barrierColor: CineScrim.modal,
    shape: const RoundedRectangleBorder(),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CineSpace.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 96,
                height: 144,
                child: CineCover(url: coverUrl, displayWidth: 96),),
            const SizedBox(width: CineSpace.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kicker != null) Kicker(kicker),
                  Semantics(
                    header: true,
                    child: Text(title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: cineText(sheet, t.typeSubhead),),
                  ),
                  if (caption != null)
                    Text(caption,
                        style:
                            cineText(sheet, t.typeFolio, color: t.colorInk60),),
                  const SizedBox(height: CineSpace.s3),
                  QuietButton(
                    openLabel,
                    onPressed: () {
                      Navigator.of(sheet).pop();
                      onOpen();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Pull to reprint: armed at 96 px (haptic `refresh.arm`), the caption and
/// leader dial ride above the content.
class PullToReprint extends ConsumerWidget {
  const PullToReprint(
      {super.key, required this.onRefresh, required this.child,});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.cine;
    final reduced = cineReduced(context);
    return CustomRefreshIndicator(
      offsetToArmed: 96,
      onRefresh: onRefresh,
      onStateChanged: (c) {
        if (c.didChange(to: IndicatorState.armed)) {
          unawaited(ref.read(skinHapticsProvider).fire(HapticEvent.refreshArm));
        }
      },
      builder: (context, child, controller) {
        final v = controller.value.clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned(
              top: CineSpace.s3,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: v,
                child: Center(
                  child: controller.isLoading
                      ? const LeaderDial()
                      : Text(
                          controller.isArmed
                              ? 'RELEASE TO REPRINT'
                              : 'PULL TO REPRINT',
                          style: cineText(context, t.typeKicker,
                              color: t.colorInk60,),
                        ),
                ),
              ),
            ),
            Transform.translate(
                offset: Offset(0, reduced ? 0 : 48 * v), child: child,),
          ],
        );
      },
      child: child,
    );
  }
}

/// A live "Retrying in N s" line for a `Retry-After`; calls [onZero] once.
class RetryCountdown extends StatefulWidget {
  const RetryCountdown(
      {super.key,
      required this.seconds,
      this.prefix = 'Retrying in',
      this.style,
      this.onZero,});

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
  Widget build(BuildContext context) => Text('${widget.prefix} $_left s',
      style: widget.style ?? cineText(context, context.cine.typeDeck),);
}

/// A snippet whose highlighted terms sweep a `spot.wash` band in, left to
/// right: 200 ms per band, 60 ms apart, `easeSet`. The end state at once
/// under reduced motion.
class SweepHighlightText extends StatefulWidget {
  const SweepHighlightText(this.snippet,
      {super.key, required this.style, this.maxLines, this.maxScale, this.textAlign = TextAlign.center,});

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
                      Interval(start, end.clamp(0, 1)).transform(_c.value),);
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
            maxScaleFactor: widget.maxScale!, child: rich,);
  }
}

/// Fires [onLongPress] after 450 ms (the Cinematic long-press; Flutter's
/// default is 500 ms). A null [onLongPress] adds nothing.
class CineLongPress extends StatelessWidget {
  const CineLongPress(
      {super.key, required this.onLongPress, required this.child,});

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
              duration: const Duration(milliseconds: 450),),
          (r) => r.onLongPress = cb,
        ),
      },
      child: child,
    );
  }
}

/// The letter reveal (`SetHeading`): letters fade in one after another over
/// `CineDur.letter`; the whole text at once under reduced motion. [play]
/// false holds it hidden (the `signal` trigger: flip it when the data lands).
/// TODO(mobile/04): swap for the real primitive; the blur half of the reveal
/// (`CineDur.letterBlur`) is not drawn by this stand-in.
class SetHeading extends StatefulWidget {
  const SetHeading(this.text, {super.key, required this.style, this.play = true, this.scaler});

  final String text;
  final TextStyle style;
  final bool play;
  final TextScaler? scaler;

  @override
  State<SetHeading> createState() => SetHeadingState();
}

class SetHeadingState extends State<SetHeading> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this, duration: CineDur.letter);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SetHeading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.play != widget.play) _sync();
  }

  void _sync() {
    if (cineReduced(context)) {
      controller.value = 1;
    } else if (widget.play && controller.value == 0 && !controller.isAnimating) {
      unawaited(controller.forward());
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.text.characters.toList();
    final base = widget.style.color ?? context.cine.colorInk100;
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Text.rich(
          TextSpan(
            style: widget.style,
            children: [
              for (var i = 0; i < letters.length; i++)
                TextSpan(
                  text: letters[i],
                  style: TextStyle(
                    color: base.withValues(
                      alpha: base.a *
                          CineCurves.settle.transform(
                            ((controller.value * (letters.length + 8) - i) / 8).clamp(0.0, 1.0),
                          ),
                    ),
                  ),
                ),
            ],
          ),
          textScaler: widget.scaler,
        ),
      ),
    );
  }
}
