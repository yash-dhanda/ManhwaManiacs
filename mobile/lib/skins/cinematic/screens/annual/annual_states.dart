import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A takeover page on black holding one state of The Annual.
class _StatePage extends StatelessWidget {
  const _StatePage({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(color: CineColors.paper0, child: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: SingleChildScrollView(child: child)))));
}

/// `recordedDays < 7`: a single page and `Close`.
class AnnualNotEnough extends StatelessWidget {
  const AnnualNotEnough({super.key, required this.recordedDays, required this.onClose});
  final int recordedDays;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => _StatePage(
        child: CineNotice(tone: CineNoticeTone.empty, kicker: 'THE ANNUAL', headline: notEnoughLine(recordedDays), primary: CineNoticeAction('Close', onClose)),
      );
}

/// "Setting the pages…" typed, with the indeterminate rule.
class AnnualLoading extends StatelessWidget {
  const AnnualLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.cine.typeHeadline;
    return _StatePage(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(
            liveRegion: true,
            child: TypedHeadline('Setting the pages…', style: CineText.style(context, role).copyWith(color: CineColors.ink100), cap: role.cap, level: 1),
          ),
          const SizedBox(height: 20),
          const CineIndeterminateRule(),
        ],),
      ),
    );
  }
}

/// Offline, and this year was never opened before.
class AnnualOffline extends StatelessWidget {
  const AnnualOffline({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => _StatePage(
        child: CineNotice(tone: CineNoticeTone.offline, kicker: 'OFFLINE EDITION', headline: 'The Annual needs a connection the first time.', primary: CineNoticeAction('Close', onClose)),
      );
}

/// `CORRECTION` "The Annual didn't print." with `Try again` and `Close`.
class AnnualError extends StatelessWidget {
  const AnnualError({super.key, required this.onRetry, required this.onClose});
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => _StatePage(
        child: CineNotice(
          tone: CineNoticeTone.error,
          kicker: 'CORRECTION',
          headline: "The Annual didn't print.",
          primary: CineNoticeAction('Try again', onRetry),
          quiet: CineNoticeAction('Close', onClose),
        ),
      );
}

