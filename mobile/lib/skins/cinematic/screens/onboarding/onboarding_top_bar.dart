import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The takeover's top bar on `#000`: Back, the folio with its four rules, Skip.
class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({super.key, required this.index, required this.total, required this.onBack, required this.onSkip, this.enabled = true});

  /// The current step, 1-based, of [total].
  final int index, total;
  final VoidCallback onBack, onSkip;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final hit = cineHitMin(context);
    final top = MediaQuery.viewPaddingOf(context).top;
    return ColoredBox(
      color: const Color(0xFF000000),
      child: Padding(
        padding: EdgeInsets.only(top: top),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: hit),
          child: Row(children: [
            CineIconButton(label: 'Back', role: CineIconRole.back, onPressed: enabled ? onBack : null),
            Expanded(
              child: Semantics(
                label: 'Step $index of $total',
                excludeSemantics: true,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CineRoleText('$index / $total', c.typeFolio, color: c.colorInk60),
                  const SizedBox(height: 4),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 1; i <= total; i++) ...[
                      if (i > 1) const SizedBox(width: 4),
                      _Rule(state: i < index ? _RuleState.done : (i == index ? _RuleState.current : _RuleState.later)),
                    ],
                  ],),
                ],),
              ),
            ),
            CineButton(label: 'Skip', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: enabled ? onSkip : null),
          ],),
        ),
      ),
    );
  }
}

enum _RuleState { done, current, later }

/// One 24 x 2 rule; a completed step's fills `spot` from the left over 240 ms.
class _Rule extends StatelessWidget {
  const _Rule({required this.state});
  final _RuleState state;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    final base = state == _RuleState.current ? c.colorInk100 : c.colorRule2;
    return SizedBox(
      width: 24,
      height: 2,
      child: Stack(children: [
        Positioned.fill(child: ColoredBox(color: base)),
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: state == _RuleState.done ? 1 : 0),
            duration: reduced ? Duration.zero : c.durLine,
            curve: CineCurves.settle,
            builder: (_, w, __) => Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: w, child: ColoredBox(color: c.colorSpot))),
          ),
        ),
      ],),
    );
  }
}
