import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:manhwamaniacs/features/sources/utils/source_health.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_extras.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

// TODO(mobile/04, mobile/05): stand-ins for the Cinematic primitives (slug
// lines, notices, plates, typed text, quiet buttons) until those steps land;
// each keeps the DESIGN.md values so swapping is a rename.

bool cineReduced(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

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
        style: cineText(context, context.cine.typeKicker,
            color: color ?? context.cine.colorInk60,),
        textScaler: CineType.scaler(context, context.cine.typeKicker),
      );
}

/// `NOTE` / `CORRECTION` / `OFFLINE EDITION` block with actions.
class CineNotice extends StatelessWidget {
  const CineNotice({
    super.key,
    required this.kicker,
    required this.headline,
    this.deck,
    this.actions = const [],
    this.kickerColor,
    this.folio,
  });

  final String kicker;
  final String headline;
  final String? deck;
  final List<Widget> actions;
  final Color? kickerColor;

  /// A live line under the headline (the `Retry-After` countdown).
  final Widget? folio;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: CineSpace.s4, vertical: CineSpace.s6,),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Kicker(kicker, color: kickerColor),
            const SizedBox(height: CineSpace.s3),
            TypedText(headline, style: cineText(context, t.typePull)),
            if (folio != null) ...[const SizedBox(height: CineSpace.s2), folio!],
            if (deck != null) ...[
              const SizedBox(height: CineSpace.s2),
              Text(deck!,
                  style: cineText(context, t.typeDeck, color: t.colorInk60),),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: CineSpace.s4),
              Wrap(
                  spacing: CineSpace.s4,
                  runSpacing: CineSpace.s2,
                  children: actions,),
            ],
          ],
        ),
      ),
    );
  }
}

/// A `quiet` text button with a 44 dp hit area.
class QuietButton extends StatelessWidget {
  const QuietButton(this.label,
      {super.key, this.onPressed, this.icon, this.semanticsLabel,});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final color = onPressed == null ? t.colorInk30 : t.colorInk100;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticsLabel ?? label,
      excludeSemantics: true,
      child: CineFocusRing(
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Center(
              widthFactor: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: cineText(context, t.typeUi, color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal contents tabs / slug line with a 2 px `spot` underline.
class SlugTabs extends StatelessWidget {
  const SlugTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.folios = true,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final bool folios;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: CineSpace.s5),
              _tab(context, i),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int i) {
    final t = context.cine;
    final on = i == selected;
    final label = folios
        ? '${(i + 1).toString().padLeft(2, '0')} ${labels[i]}'
        : labels[i];
    return Semantics(
      button: true,
      selected: on,
      label: labels[i],
      excludeSemantics: true,
      child: CineFocusRing(
        child: InkWell(
          onTap: () => onSelected(i),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: CineSpace.s3),
                child: Text(
                  label.toUpperCase(),
                  style: cineText(context, t.typeNav,
                      color: on ? t.colorInk100 : t.colorInk60,),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration:
                      cineReduced(context) ? CineDur.reduced : CineDur.column,
                  curve: CineCurves.settle,
                  height: on ? 2 : 1,
                  color: on ? t.colorSpot : t.colorRule1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Types [text] at 50 ms per grapheme; full text at once under reduced motion.
class TypedText extends StatefulWidget {
  const TypedText(this.text, {super.key, required this.style, this.maxLines});

  final String text;
  final TextStyle style;
  final int? maxLines;

  @override
  State<TypedText> createState() => _TypedTextState();
}

class _TypedTextState extends State<TypedText> {
  Timer? _timer;
  int _n = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    if (cineReduced(context)) {
      _n = widget.text.characters.length;
      return;
    }
    _timer = Timer.periodic(CineDur.type, (t) {
      if (!mounted) return;
      if (_n >= widget.text.characters.length) {
        t.cancel();
        return;
      }
      setState(() => _n++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: widget.text,
        excludeSemantics: true,
        child: Text(
          widget.text.characters.take(_n).toString(),
          style: widget.style,
          maxLines: widget.maxLines,
        ),
      );
}

/// A greeked plate that breathes (static 0.8 opacity under reduced motion).
class FlickerPlate extends StatefulWidget {
  const FlickerPlate({super.key, this.width, this.height, this.aspect});

  final double? width;
  final double? height;
  final double? aspect;

  @override
  State<FlickerPlate> createState() => _FlickerPlateState();
}

class _FlickerPlateState extends State<FlickerPlate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: CineDur.flicker);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (cineReduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      unawaited(_c.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plate = AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Opacity(
        opacity: cineReduced(context) ? 0.8 : 0.5 + 0.5 * _c.value,
        child: ColoredBox(color: context.cine.colorPaper1),
      ),
    );
    final sized =
        SizedBox(width: widget.width, height: widget.height, child: plate);
    return ExcludeSemantics(
      child: widget.aspect == null
          ? sized
          : AspectRatio(aspectRatio: widget.aspect!, child: plate),
    );
  }
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
                      child: ColoredBox(color: context.cine.colorRule1),),
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
          CineSpace.s4, CineSpace.s3, CineSpace.s4, CineSpace.s3,),
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

/// Screen-reader header of level 1 for screens with no visible title.
class ZeroSizeHeading extends StatelessWidget {
  const ZeroSizeHeading(this.label, {super.key, this.focusNode});

  final String label;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => Focus(
        focusNode: focusNode,
        child: Semantics(
          header: true,
          headingLevel: 1,
          label: label,
          child: const SizedBox.shrink(),
        ),
      );
}

void announce(BuildContext context, String message) => unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );

const IconData kCloseIcon = PhosphorRegular.x;
