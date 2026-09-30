import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart' show DelayedShow, FlickerPlate;
import 'package:manhwamaniacs/skins/cinematic/screens/picks/world_card_tile.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The columns of the For you grid: one on phones, 2 from 600 dp, 3 from 900 dp.
int forYouColumns(double width) => width >= 900 ? 3 : (width >= 600 ? 2 : 1);

/// `01 For you`: World cards in a grid; loading shows six flicker plates after the 120 ms skeleton delay.
class ForYouGrid extends StatelessWidget {
  const ForYouGrid({super.key, required this.items, this.loading = false});
  final List<WorldItem> items;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return LayoutBuilder(builder: (context, box) {
      final cols = forYouColumns(MediaQuery.sizeOf(context).width);
      final gap = c.space3;
      final w = (box.maxWidth - gap * (cols - 1)) / cols;
      final children = loading
          ? [for (var i = 0; i < 6; i++) FlickerPlate(width: w, height: 156)]
          : [for (var i = 0; i < items.length; i++) WorldCardTile(key: ValueKey('fy-${items[i].title}-${items[i].anilistId}'), item: items[i])];
      final grid = Wrap(spacing: gap, runSpacing: gap, children: [for (final ch in children) SizedBox(width: w, child: ch)]);
      return loading ? DelayedShow(delay: const Duration(milliseconds: 120), child: grid) : grid;
    },);
  }
}
