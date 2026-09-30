import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/settings/providers/a11y_prefs_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/edition/edition_picker.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Appearance (cinematic 8.30.2 row 2): the edition picker, reduced motion, Hyperlegible text and
/// the reading mode.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a11y = ref.watch(a11yPrefsProvider);
    final n = ref.read(a11yPrefsProvider.notifier);
    final scope = ref.watch(contentModeScopeProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const JumpRow(id: 'edition', child: EditionPicker(glassAvailable: Flags.glassAvailable)),
      const SettingsKicker('ACCESSIBILITY'),
      slugRow(
        'reduce-motion',
        'Reduce motion in the app',
        const [CineSlug('system', 'SYSTEM'), CineSlug('reduced', 'ON')],
        a11y.motion,
        n.setMotion,
        description: 'SYSTEM follows your phone. Saved for this profile.',
      ),
      switchRow('hyperlegible', 'Hyperlegible text', a11y.legible, n.setLegible, description: 'Easier-to-read text for decks, synopses, recaps and notices.'),
      if (scope.showSwitch) ...[
        const SettingsKicker('READING'),
        slugRow(
          'reading-mode',
          'Reading mode',
          const [CineSlug('manga', 'MANGA'), CineSlug('novel', 'NOVELS')],
          scope.mode.name,
          (v) => ref.read(contentModeControllerProvider.notifier).setMode(ContentMode.parse(v) ?? ContentMode.manga),
        ),
      ],
    ],);
  }
}
