import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The size of a genre by weight quartile: 20 / 17 / 14 / 12 px, heaviest first.
double genreSize(int rank, int count) {
  final q = count == 0 ? 3 : (rank * 4 ~/ count).clamp(0, 3);
  return const [20.0, 17.0, 14.0, 12.0][q];
}

/// `Your genres` (cinematic 9.1.3): a weighted slug line, Archivo wdth 75 wght 600 uppercase,
/// the top quartile `ink.100` and the rest `ink.60`. Each genre opens Discover on that genre.
class PicksGenreLine extends StatelessWidget {
  const PicksGenreLine({super.key, required this.genres});
  final List<GenreWeight> genres;

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) return const SizedBox.shrink();
    final c = context.cine;
    final sorted = [...genres]..sort((a, b) => b.weight.compareTo(a.weight));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(header: true, child: CineRoleText('YOUR GENRES', c.typeKicker, color: c.colorInk45)),
      SizedBox(height: c.space2),
      Wrap(spacing: c.space4, children: [
        for (var i = 0; i < sorted.length; i++)
          () {
            final size = genreSize(i, sorted.length);
            final top = i * 4 ~/ sorted.length == 0;
            final style = CineText.literal(context, CineFace.archivo, size, 24, upper: true, wght: 600, wdth: 75).copyWith(letterSpacing: size * 0.10, color: top ? c.colorInk100 : c.colorInk60);
            return Semantics(
              button: true,
              label: sorted[i].genre,
              excludeSemantics: true,
              child: InkWell(
                onTap: () => context.go(Uri.parse(Routes.discover()).replace(queryParameters: {'genre': sorted[i].genre}).toString()),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: cineHitMin(context)),
                  child: Align(
                    widthFactor: 1,
                    child: Text(sorted[i].genre.toUpperCase(), style: style, textScaler: CineText.literalScaler(context, CineFace.archivo, upper: true).clamp(maxScaleFactor: 1.5)),
                  ),
                ),
              ),
            );
          }(),
      ],),
    ],);
  }
}
