import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/keycap.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The body of the `?sheet=shortcuts` sheet: the live registry's groups with keycaps. "No shortcuts are active on this screen" when
/// empty. Secondary combos read `onGlass` at `wght` 460 in the window, `label2` on the phone's `solid1` sheet.
class GlassShortcutsBody extends ConsumerWidget {
  const GlassShortcutsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(shortcutRegistryProvider);
    final groups = ref.read(shortcutRegistryProvider.notifier).registeredGroups();
    final wide = GlassFrame.of(context) != GlassFrameKind.phone;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        GlassText('Only what works here is listed. Shortcuts pause while you type. Press ? to reopen, Esc to close.', role: gt.typeCallout, onGlass: wide),
        const SizedBox(height: 16),
        if (groups.isEmpty)
          GlassText('No shortcuts are active on this screen', role: gt.typeBody, onGlass: wide)
        else
          for (final g in groups) ...[
            GlassText(g.name.toUpperCase(), role: gt.typeCaption1, wght: 600, onGlass: wide),
            const SizedBox(height: 8),
            for (final e in g.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: GlassText(e.description, role: gt.typeBody, wght: wide ? 460 : 400, onGlass: wide, color: wide ? null : gt.colorLabel2)),
                    if (e.keys != null) GlassKeycaps(e.keys!),
                  ],
                ),
              ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
