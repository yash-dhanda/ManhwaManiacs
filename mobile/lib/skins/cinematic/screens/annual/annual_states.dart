import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/buttons.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/notice.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/rules.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/typed_text.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

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
        child: CineNotice(kicker: 'THE ANNUAL', headline: notEnoughLine(recordedDays), actionLabel: 'Close', onAction: onClose, actionKind: CineButtonKind.secondary),
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
          Semantics(liveRegion: true, child: TypedText('Setting the pages…', style: cineStyleOf(context, role), scaler: CineType.scaler(context, role), header: true)),
          const SizedBox(height: 20),
          const IndeterminateRule(),
        ],),
      ),
    );
  }
}

TextStyle cineStyleOf(BuildContext context, CineTextRole role) => CineType.style(context, role).copyWith(color: CineColors.ink100);

/// Offline, and this year was never opened before.
class AnnualOffline extends StatelessWidget {
  const AnnualOffline({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => _StatePage(
        child: CineNotice(kicker: 'OFFLINE EDITION', headline: 'The Annual needs a connection the first time.', actionLabel: 'Close', onAction: onClose, actionKind: CineButtonKind.secondary),
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
          kicker: 'CORRECTION',
          kickerColor: CineColors.proof,
          headline: "The Annual didn't print.",
          actionLabel: 'Try again',
          onAction: onRetry,
          secondaryLabel: 'Close',
          onSecondary: onClose,
        ),
      );
}

/// A year that is not a number: the not-found screen inside the takeover.
/// TODO(mobile/06): mobile/06's 8.32 not-found screen owns this.
class AnnualNotFound extends StatelessWidget {
  const AnnualNotFound({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => _StatePage(
        child: CineNotice(kicker: 'NOT FOUND', headline: "That issue isn't on the shelf.", actionLabel: 'Close', onAction: onClose, actionKind: CineButtonKind.secondary),
      );
}
