import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/keyboard_sheet.dart';

/// Keyboard (tablets, cinematic 8.30.2 row 11): the live hardware-keyboard registry as credits
/// rows, and the single-key switch.
class KeyboardSection extends ConsumerWidget {
  const KeyboardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final single = ref.watch(singleKeyShortcutsProvider);
    ref.watch(shortcutRegistryProvider);
    final groups = ref.read(shortcutRegistryProvider.notifier).registeredGroups();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      switchRow('single-key', 'Single-key shortcuts', single, ref.read(singleKeyShortcutsProvider.notifier).set,
          description: 'Keys that work without a modifier. Shortcuts pause while you type in a field. Saved for this profile.',),
      CineKeyboardSheetBody(groups: groups, platform: Theme.of(context).platform),
    ],);
  }
}
