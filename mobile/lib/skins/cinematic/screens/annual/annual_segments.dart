import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/annual/annual_player.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// One 2 px segment per shown page, 4 px apart, track `rule.2`, filled `spot`
/// for past pages and filling linearly over the hold for the current one; they
/// freeze while paused (the player stops its clock).
class AnnualSegments extends StatelessWidget {
  const AnnualSegments({super.key, required this.player});
  final AnnualPlayer player;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: ListenableBuilder(
          listenable: player,
          builder: (context, _) => Row(
            children: [
              for (var i = 0; i < player.pages.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: SizedBox(
                    height: 2,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(color: CineColors.rule2),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: i < player.index
                              ? 1
                              : (i == player.index ? player.progress : 0),
                          child: const ColoredBox(
                              key: ValueKey('segment-fill'),
                              color: CineColors.spot,),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
