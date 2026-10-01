import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/edition/edition_card.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/skin.dart';

/// Step 1, Edition (cinematic 8.7): both editions as live miniatures ([EditionCard], still under
/// reduced motion), stacked on phones and side by side from 600 px.
/// Cinematic is this edition (the footer keeps it); `Choose Glass` hands the run to Glass.
class EditionStep extends StatelessWidget {
  const EditionStep({super.key, required this.onGlass});
  final VoidCallback onGlass;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final cinematic = EditionCard(
      skinFolder: 'cinematic',
      name: 'Cinematic',
      family: SkinId.cinematic.displayFamily,
      description: 'Black stock, film titles, a magazine\'s rhythm.',
      current: true,
    );
    final glass = EditionCard(
      skinFolder: 'glass',
      name: 'Glass',
      family: SkinId.glass.displayFamily,
      description: 'Layered glass, springs and depth. The app restarts in Glass and carries on here.',
      switchLabel: 'Choose Glass',
      onSwitch: onGlass,
    );
    final wide = MediaQuery.sizeOf(context).width >= 600;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: cinematic), SizedBox(width: c.space4), Expanded(child: glass)])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [cinematic, SizedBox(height: c.space6), glass]),
    );
  }
}
