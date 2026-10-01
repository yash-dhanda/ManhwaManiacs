import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';

/// "Fantasy x": the dismissible `input` chip of `?genre=`.
class GenreFilterChip extends StatelessWidget {
  const GenreFilterChip(
      {super.key, required this.genre, required this.onClear,});
  final String genre;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => GlassChip(
      label: genre,
      kind: GlassChipKind.input,
      onRemove: onClear,
      semanticsLabel: 'Filtered to $genre. Remove filter',);
}
