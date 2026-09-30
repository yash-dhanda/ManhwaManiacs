import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The Glass card while `Flags.glassAvailable` is false: the disabled plate (`NEXT ISSUE`, the
/// name in Bodoni Italic, "In preparation."), no frames, no loop, no button.
class NextIssuePlate extends StatelessWidget {
  const NextIssuePlate({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      enabled: false,
      container: true,
      excludeSemantics: true,
      label: 'Glass. Next issue. In preparation. It arrives in a later update.',
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          key: const Key('next-issue-plate'),
          decoration: BoxDecoration(color: c.colorPaper1, border: Border.all(color: c.colorRule1)),
          padding: EdgeInsets.all(c.space4),
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CineRoleText('NEXT ISSUE', c.typeKicker, color: c.colorInk60),
            SizedBox(height: c.space2),
            CineLit('Glass', CineFace.bodoni, 20, 24, italic: true, wght: 600, color: c.colorInk60),
            SizedBox(height: c.space2),
            CineRoleText('In preparation. It arrives in a later update.', c.typeCaption, color: c.colorInk60, textAlign: TextAlign.center),
          ],),
        ),
      ),
    );
  }
}
