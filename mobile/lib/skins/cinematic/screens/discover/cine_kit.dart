import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:manhwamaniacs/features/sources/utils/source_health.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart'
    as real;
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

bool cineReduced(BuildContext context) =>
    CineMotion.reduced(context);

TextStyle cineText(BuildContext c, CineTextRole role, {Color? color}) =>
    CineType.style(c, role).copyWith(color: color ?? c.cine.colorInk100);

bool isTablet(BuildContext c) => MediaQuery.sizeOf(c).width >= 600;

Color healthColor(BuildContext c, HealthState s) => switch (s) {
      HealthState.ok => c.cine.colorSet,
      HealthState.failing => c.cine.colorSpot,
      HealthState.dead => c.cine.colorProof,
      HealthState.unknown => c.cine.colorInk45,
      HealthState.demoted => c.cine.colorInk60,
    };

/// The 6 x 6 health square; its text lives in the parent's semantics.
class HealthMark extends StatelessWidget {
  const HealthMark(this.state, {super.key});

  final HealthState state;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          width: 6,
          height: 6,
          child: ColoredBox(color: healthColor(context, state)),
        ),
      );
}

class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: cineText(
          context,
          context.cine.typeKicker,
          color: color ?? context.cine.colorInk60,
        ),
        textScaler: CineType.scaler(context, context.cine.typeKicker),
      );
}

/// The 25 %-wide `spot` segment looping on a 1 px rule (tier 2 running).
class IndeterminateRule extends StatefulWidget {
  const IndeterminateRule({super.key});

  @override
  State<IndeterminateRule> createState() => _IndeterminateRuleState();
}

class _IndeterminateRuleState extends State<IndeterminateRule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: CineDur.loopRule)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          height: 2,
          child: LayoutBuilder(
            builder: (context, box) => AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(color: context.cine.colorRule1),
                  ),
                  Positioned(
                    left:
                        (box.maxWidth * 1.25) * _c.value - box.maxWidth * 0.25,
                    width: box.maxWidth * 0.25,
                    top: 0,
                    bottom: 0,
                    child: ColoredBox(color: context.cine.colorSpot),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// A 16 px indeterminate leader dial.
class LeaderDial extends StatelessWidget {
  const LeaderDial({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: context.cine.colorSpot,
          ),
        ),
      );
}

/// Section header: `01 Browse by genre` on a 1 px rule.
class SectionHead extends StatelessWidget {
  const SectionHead(this.folio, this.title, {super.key, this.trailing});

  final String? folio;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CineSpace.s4,
        CineSpace.s3,
        CineSpace.s4,
        CineSpace.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, thickness: 1, color: t.colorRule1),
          const SizedBox(height: CineSpace.s3),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    folio == null ? title : '$folio  $title',
                    style: cineText(context, t.typeSubhead),
                    textScaler: CineType.scaler(context, t.typeSubhead),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}

/// Route focus lands on the screen's level-1 heading: owns a [FocusNode] (or
/// uses [focusNode]) and requests it once, after the first frame.
class HeadingFocus extends StatefulWidget {
  const HeadingFocus({super.key, required this.child, this.focusNode});

  final Widget child;
  final FocusNode? focusNode;

  @override
  State<HeadingFocus> createState() => _HeadingFocusState();
}

class _HeadingFocusState extends State<HeadingFocus> {
  FocusNode? _own;
  FocusNode get _node =>
      widget.focusNode ?? (_own ??= FocusNode(debugLabel: 'heading'));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _node.requestFocus();
    });
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Focus(focusNode: _node, skipTraversal: true, child: widget.child);
}

/// Screen-reader header of level 1 for screens with no visible title.
class ZeroSizeHeading extends StatelessWidget {
  const ZeroSizeHeading(this.label, {super.key, this.focusNode});

  final String label;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => HeadingFocus(
        focusNode: focusNode,
        child: Semantics(
          header: true,
          headingLevel: 1,
          label: label,
          child: const SizedBox.shrink(),
        ),
      );
}

/// Shows [child] only after [delay] (the ASK dial appears after 1 s).
class DelayedShow extends StatefulWidget {
  const DelayedShow({
    super.key,
    required this.child,
    this.delay = const Duration(seconds: 1),
  });

  final Widget child;
  final Duration delay;

  @override
  State<DelayedShow> createState() => _DelayedShowState();
}

class _DelayedShowState extends State<DelayedShow> {
  bool _on = false;
  late final Timer _t = Timer(widget.delay, () {
    if (mounted) setState(() => _on = true);
  });

  @override
  void initState() {
    super.initState();
    _t; // starts the timer
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _on ? widget.child : const SizedBox(width: 24, height: 24);
}

void announce(BuildContext context, String message) => unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );

/// A header sheet (the shared `CineSheetRoute`); [body] fills the sheet below the header.
Future<T?> showCineSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder body,
}) =>
    real.showCineSheet<T>(
      context,
      kicker: 'DISCOVER',
      title: title,
      builder: (c) => Material(type: MaterialType.transparency, child: body(c)),
    );

/// The heavy rule under a masthead: drawn left to right over [CineDur.beat]
/// once the letters have landed ([CineDur.letter]); whole under reduced motion.
class DrawnRule extends StatefulWidget {
  const DrawnRule({super.key, this.thickness = 3});

  final double thickness;

  @override
  State<DrawnRule> createState() => _DrawnRuleState();
}

class _DrawnRuleState extends State<DrawnRule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: CineDur.beat);
  Timer? _delay;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (cineReduced(context)) {
      _c.value = 1;
    } else {
      _delay = Timer(CineDur.letter, () {
        if (mounted) unawaited(_c.forward());
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          height: widget.thickness,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: CineCurves.easeSet.transform(_c.value),
                child: ColoredBox(
                  color: context.cine.colorInk100,
                  child: SizedBox(height: widget.thickness),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Phosphor `dots-six-vertical` (Regular; the codepoint is in
/// brand/phosphor/codepoints.json, the generated set does not carry it).
const IconData kDotsSixVertical =
    IconData(0xEAE2, fontFamily: 'PhosphorRegular');

const IconData kCloseIcon = PhosphorRegular.x;
