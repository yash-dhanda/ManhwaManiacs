import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/sources/models/source_genre.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';

/// The genre chip ("All genres" or the chosen genre), drawn only when the source returned genres; it opens a menu.
class GenreChip extends StatelessWidget {
  const GenreChip({super.key, required this.genres, required this.selected, required this.onSelect});
  final List<SourceGenre> genres;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) return const SizedBox.shrink();
    return Builder(
      builder: (context) => GlassChip(
        label: selected == null || selected!.isEmpty ? 'All genres' : (genres.where((g) => g.id == selected).map((g) => g.label).firstOrNull ?? selected!),
        kind: GlassChipKind.choice,
        selected: selected != null && selected!.isNotEmpty,
        onPressed: () {
          final box = context.findRenderObject();
          if (box is! RenderBox) return;
          showGlassMenu(
            context,
            anchor: box.localToGlobal(Offset.zero) & box.size,
            title: 'Genre',
            entries: [
              GlassMenuEntry(label: 'All genres', checked: selected == null || selected!.isEmpty, onSelected: () => onSelect('')),
              for (final g in genres) GlassMenuEntry(label: g.label, checked: selected == g.id, onSelected: () => onSelect(g.id)),
            ],
          );
        },
      ),
    );
  }
}
