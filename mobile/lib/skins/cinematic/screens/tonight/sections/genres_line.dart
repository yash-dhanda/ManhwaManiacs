import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_section_header.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// `Your genres`: a wrapping slug line of genre links sized by weight tercile (12/16, 15/20, 20/24),
/// each at least 44 x 44 and going to Discover with `?genre=` (cinematic 8.8).
class GenresLineSection extends StatelessWidget {
  const GenresLineSection({super.key, required this.plan});
  final PlannedSection plan;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final genres = plan.section.items.whereType<HomeGenreItem>().toList();
    if (genres.isEmpty) return const SizedBox.shrink();
    final sorted = [...genres.map((g) => g.weight)]..sort();
    double at(double q) => sorted[((sorted.length - 1) * q).round()];
    final low = at(1 / 3), high = at(2 / 3);
    (double, double) sizeOf(double w) => w > high ? (20, 24) : (w > low ? (15, 20) : (12, 16));
    return Padding(
      padding: EdgeInsets.only(bottom: tonightWide(context) ? 64 : 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        CineSectionHeader(headingId: 'tonight.genres', heading: plan.section.title, folio: plan.folio),
        SizedBox(height: c.space3),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, children: [
          for (var i = 0; i < genres.length; i++) ...[
            if (i > 0) CineLit('·', CineFace.archivo, 12, 16, color: c.colorInk30),
            _Genre(genre: genres[i].genre, size: sizeOf(genres[i].weight)),
          ],
        ],),
      ],),
    );
  }
}

class _Genre extends StatelessWidget {
  const _Genre({required this.genre, required this.size});
  final String genre;
  final (double, double) size;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      link: true,
      label: genre,
      excludeSemantics: true,
      onTap: () => _open(context),
      child: CinePressable(
        onTap: () => _open(context),
        builder: (context, st) => ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Center(
            widthFactor: 1,
            child: CineLit(
              genre,
              CineFace.archivo,
              size.$1,
              size.$2,
              upper: true,
              wght: 600,
              wdth: 75,
              tracking: 0.10,
              color: st.hovered || st.focused ? c.colorInk100 : c.colorInk80,
              decoration: st.hovered ? TextDecoration.underline : null,
            ),
          ),
        ),
      ),
    );
  }

  /// Discover opens that genre's sheet; `mobile/16` owns the `genre` parameter, which the typed
  /// builder does not list yet, so the query is appended by hand.
  void _open(BuildContext context) => context.go('${Routes.discover()}?genre=${Uri.encodeQueryComponent(genre)}');
}
