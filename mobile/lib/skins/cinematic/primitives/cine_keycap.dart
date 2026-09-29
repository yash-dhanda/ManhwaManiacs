import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/core/keyboard/key_labels.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A hardware-keyboard shortcut label (cinematic 7.26): `typeFolio` 12 in a 1 px `ink.30` box.
class CineKeycap extends StatelessWidget {
  const CineKeycap({super.key, required this.keys, this.secondary = false});
  final List<LogicalKeyboardKey> keys;

  /// Secondary combos sit at 60 % opacity.
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final text = formatKeyCombo(keys, Theme.of(context).platform);
    return Opacity(
      opacity: secondary ? 0.6 : 1,
      child: Semantics(
        label: 'Shortcut $text',
        excludeSemantics: true,
        child: Container(
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(border: Border.all(color: c.colorInk30)),
          child: Center(widthFactor: 1, heightFactor: 1, child: CineLit(text, CineFace.plexMono, 12, 16, color: c.colorInk100)),
        ),
      ),
    );
  }
}
