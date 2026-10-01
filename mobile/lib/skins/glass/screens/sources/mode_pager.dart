import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';

/// The browse modes (arbitrary server labels) as a strip of choice chips; [onSwipe] steps a mode on a horizontal drag of the grid
/// (the owner of the horizontal drag, glass 8.0.5).
class ModeStrip extends StatelessWidget {
  const ModeStrip({super.key, required this.modes, required this.selected, required this.onSelect});
  final List<SourceBrowseMode> modes;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final m in modes) Padding(padding: const EdgeInsets.only(right: 8), child: GlassChip(label: m.label, kind: GlassChipKind.choice, selected: m.id == selected, onPressed: () => onSelect(m.id))),
        ],),
      );
}

/// Wraps [child] so a horizontal fling steps one mode.
class ModeSwipe extends StatelessWidget {
  const ModeSwipe({super.key, required this.onSwipe, required this.child});
  final ValueChanged<int> onSwipe;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -400) onSwipe(1);
          if (v > 400) onSwipe(-1);
        },
        child: child,
      );
}
