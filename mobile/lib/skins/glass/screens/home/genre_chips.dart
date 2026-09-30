import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip_row.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rail_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rails.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// "Your genres": a chip row in weight order, each chip a link to For you filtered by that genre.
class HomeGenreChips extends ConsumerWidget {
  const HomeGenreChips({super.key, required this.rail});
  final HomeRailSpec rail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genres = rail.items.cast<HomeGenreItem>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeRailHeader(title: rail.title, railId: rail.id),
        GlassChipRow(
          children: [
            for (final g in genres)
              GlassChip(label: g.genre, onPressed: () => ref.read(skinRouterProvider).push<void>(Routes.picks({'genre': g.genre})), onLink: () {}, semanticsLabel: '${g.genre}, genre'),
          ],
        ),
      ],
    );
  }
}
