import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Where "Print my first issue" is: [printing] dims the wall and shows the overlay; [fade] then
/// fades every poster not in [keep] (the ones about to fly) to black over 240 ms.
class PrintUi {
  const PrintUi({this.printing = false, this.fade = false, this.keep = const {}});
  final bool printing, fade;
  final Set<int> keep;
}

final printUiProvider = StateProvider.autoDispose<PrintUi>((ref) => const PrintUi(), name: 'printUi');

/// The 2 px indeterminate `spot` rule and "Printing issue No. 1..." typed over the dimmed wall.
class PrintOverlay extends StatelessWidget {
  const PrintOverlay({super.key, required this.fade});
  final bool fade;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final grid = CineGrid.of(context);
    final span = grid.span(grid.columns);
    final style = CineText.style(context, c.typeMasthead).copyWith(color: c.colorInk100);
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: fade ? 0 : 1,
        duration: const Duration(milliseconds: 240),
        curve: CineCurves.lift,
        child: Align(
          child: SizedBox(
            width: span,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const CineIndeterminateRule(),
              const SizedBox(height: 24),
              TypedHeadline('Printing issue No. 1…', style: style, cap: c.typeMasthead.cap),
            ],),
          ),
        ),
      ),
    );
  }
}
