import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_common.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The "catalog unreachable" notice of step 3 (CORRECTION, cinematic 8.7 States).
class GenresUnreachable extends StatelessWidget {
  const GenresUnreachable({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => CineNotice(
        tone: CineNoticeTone.error,
        kicker: 'CORRECTION',
        headline: "The genre list didn't come through.",
        deck: 'You can set genres later from Discover.',
        primary: CineNoticeAction('Try again', onRetry),
      );
}

/// The wall's notice when the catalog is unreachable at step 5; the footer becomes `Finish`.
class SeedsUnreachable extends StatelessWidget {
  const SeedsUnreachable({super.key});

  @override
  Widget build(BuildContext context) => const CineNotice(
        tone: CineNoticeTone.empty,
        kicker: 'NOTE',
        headline: 'Follow series later from Discover.',
      );
}

/// Steps 2 to 5 with no network: `OFFLINE EDITION`, and the footer's `Skip for now`.
class OnboardingOffline extends StatelessWidget {
  const OnboardingOffline({super.key});

  @override
  Widget build(BuildContext context) => const CineNotice(
        tone: CineNoticeTone.offline,
        kicker: 'OFFLINE EDITION',
        headline: "Finish when you're back online.",
      );
}

/// A greeked paragraph: six justified lines of `paper.1` bars, the last 60 % wide, flickering.
class GenresGalley extends StatelessWidget {
  const GenresGalley({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final line = onboardingWide(context) ? 48.0 : 44.0;
    final reduced = CineMotion.reduced(context);
    Widget bars = Column(children: [
      for (var i = 0; i < 6; i++)
        SizedBox(
          height: line,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(widthFactor: i == 5 ? 0.6 : 1, child: SizedBox(height: line * 0.45, child: ColoredBox(color: c.colorPaper1))),
          ),
        ),
    ],);
    bars = reduced ? Opacity(opacity: 0.8, child: bars) : CineFlicker(child: bars);
    return ExcludeSemantics(child: bars);
  }
}

/// Bars for the catalog's genre or wall while it loads: shown only after 120 ms of waiting.
class AfterWait extends StatefulWidget {
  const AfterWait({super.key, required this.child});
  final Widget child;

  @override
  State<AfterWait> createState() => _AfterWaitState();
}

class _AfterWaitState extends State<AfterWait> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  Widget build(BuildContext context) => _show ? widget.child : const SizedBox.shrink();
}

/// A kicker line in the step header.
class StepKicker extends StatelessWidget {
  const StepKicker(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => CineRoleText(text, context.cine.typeKicker, color: context.cine.colorInk45);
}
