import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// "Your Circle is quiet" (nobody else shares), with the `users-three` lens.
class CircleQuiet extends StatelessWidget {
  const CircleQuiet({super.key});

  @override
  Widget build(BuildContext context) => const GlassObjectLens(
        situation: LensSituation.circleQuiet,
        title: 'Your Circle is quiet',
        description: 'When people on this server share their reading, it shows up here.',
        placement: GlassLensPlacement.inline,
      );
}

/// Only you on the server.
class CircleOnlyYou extends StatelessWidget {
  const CircleOnlyYou({super.key});

  @override
  Widget build(BuildContext context) => const GlassObjectLens(
        situation: LensSituation.circleQuiet,
        title: "There's nobody else on this server yet.",
        placement: GlassLensPlacement.inline,
      );
}

/// The Circle needs a connection.
class CircleOffline extends StatelessWidget {
  const CircleOffline({super.key, this.onRetry, this.title = 'The Circle needs a connection'});
  final Future<bool> Function()? onRetry;
  final String title;

  @override
  Widget build(BuildContext context) => GlassObjectLens(situation: LensSituation.offline, title: title, tone: GlassLensTone.offline, placement: GlassLensPlacement.inline, onRetry: onRetry);
}

/// "Couldn't load your Circle" with "Try again".
class CircleError extends StatelessWidget {
  const CircleError({super.key, required this.onRetry, this.title = "Couldn't load your Circle"});
  final VoidCallback onRetry;
  final String title;

  @override
  Widget build(BuildContext context) => GlassObjectLens(situation: LensSituation.loadError, title: title, tone: GlassLensTone.error, placement: GlassLensPlacement.inline, primary: LensAction('Try again', onRetry));
}

/// A tab's empty line.
class CircleEmpty extends StatelessWidget {
  const CircleEmpty(this.text, {super.key});
  final String text;

  static const activity = 'No activity yet';
  static const letters = 'No letters yet. When someone recommends a series, it lands here.';
  static const shelves = 'No shared shelves yet';

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: GlassFrame.screenMargin(context), vertical: 24),
        child: GlassText(text, role: gt.typeBody, color: gt.colorLabel2, textAlign: TextAlign.center),
      );
}
