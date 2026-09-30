import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/keycap.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

const List<String> kShortcutGroups = ['General', 'Navigation', 'Library', 'Search', 'Sources', 'Reader', 'Novel reader', 'Listen'];

/// Settings -> Shortcuts (glass 8.25.13): the live registry grouped, each row a description and keycaps; the single-key switch.
class ShortcutsSection extends ConsumerWidget {
  const ShortcutsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(shortcutRegistryProvider);
    final live = {for (final g in ref.read(shortcutRegistryProvider.notifier).registeredGroups()) g.name: g};
    final single = ref.watch(singleKeyShortcutsProvider);
    return Column(children: [
      SettingsGroup(children: [
        SettingsSwitchRow(id: 'single-key-shortcuts', title: 'Single-key shortcuts', value: single, onChanged: (v) => unawaited(ref.read(singleKeyShortcutsProvider.notifier).set(v))),
      ],),
      SettingsAnchor(
        id: 'shortcuts',
        child: Column(children: [
          for (final name in {...kShortcutGroups, ...live.keys})
            SettingsGroup(header: name, children: [
              if ((live[name]?.entries ?? const []).isEmpty)
                Padding(padding: const EdgeInsets.all(16), child: GlassText('No shortcuts are active on this screen', role: gt.typeFootnote, color: gt.colorLabel2))
              else
                for (final e in live[name]!.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      Expanded(child: GlassText(e.description, role: gt.typeBody)),
                      if (e.keys != null) GlassKeycaps(e.keys!),
                    ],),
                  ),
            ],),
        ],),
      ),
    ],);
  }
}
