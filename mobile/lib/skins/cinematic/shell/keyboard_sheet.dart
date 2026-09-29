import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/keyboard/key_labels.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/dialog_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_dot_leader.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The order the sheet lists groups in (cinematic 8.33.2). Later steps register their groups under
/// these names.
const List<String> cinematicShortcutGroupOrder = [
  'General',
  'Navigation',
  'Tonight',
  'Library',
  'Updates',
  'Discover',
  'Sources',
  'Catalogue',
  'Downloads',
  'Collections',
  'History',
  'Bookmarks',
  'Dialogue',
  'The Numbers',
  'Circle',
  'Picks',
  'Profiles',
  'Settings',
  'System status',
  'Series page',
  'Reader',
  'Novel reader',
  'Listen',
  'Recap',
  'The Annual',
];

/// Registered groups in [cinematicShortcutGroupOrder]; unknown names last, in registration order.
List<ShortcutGroup> orderedShortcutGroups(List<ShortcutGroup> groups) {
  int rank(ShortcutGroup g) {
    final i = cinematicShortcutGroupOrder.indexOf(g.name);
    return i < 0 ? cinematicShortcutGroupOrder.length : i;
  }

  final indexed = [for (var i = 0; i < groups.length; i++) (i, groups[i])];
  indexed.sort((a, b) {
    final d = rank(a.$2).compareTo(rank(b.$2));
    return d != 0 ? d : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

/// The keycap texts of an entry.
List<String> keycapsOf(ShortcutEntry e, TargetPlatform platform) {
  if (e.keys != null) return e.keys!;
  final a = e.activator;
  if (a is SingleActivator) {
    final k = <LogicalKeyboardKey>[
      if (a.control) LogicalKeyboardKey.control,
      if (a.meta) LogicalKeyboardKey.meta,
      if (a.alt) LogicalKeyboardKey.alt,
      if (a.shift) LogicalKeyboardKey.shift,
      a.trigger,
    ];
    return [formatKeyCombo(k, platform)];
  }
  return const [''];
}

class _Keycap extends StatelessWidget {
  const _Keycap(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(border: Border.all(color: c.colorInk30)),
      alignment: Alignment.center,
      child: CineLit(text, CineFace.plexMono, 12, 16, color: c.colorInk100),
    );
  }
}

/// The `?` sheet body: what works on this screen, as two-column credits rows.
class CineKeyboardSheetBody extends StatelessWidget {
  const CineKeyboardSheetBody({super.key, required this.groups, required this.platform});
  final List<ShortcutGroup> groups;
  final TargetPlatform platform;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final ordered = orderedShortcutGroups(groups);
    if (ordered.isEmpty) return CineRoleText('No shortcuts on this screen.', c.typeBody, color: c.colorInk60);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      for (final g in ordered) ...[
        Padding(
          padding: EdgeInsets.only(top: c.space4, bottom: c.space1),
          child: CineRoleText(g.name.toUpperCase(), c.typeKicker, color: c.colorInk45),
        ),
        for (final e in g.entries)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Semantics(
              container: true,
              label: '${e.description}, ${keycapsOf(e, platform).join(' ')}',
              excludeSemantics: true,
              child: Row(children: [
                Flexible(child: CineRoleText(e.description, c.typeUi, color: c.colorInk60)),
                SizedBox(width: c.space2),
                const Expanded(child: Padding(padding: EdgeInsets.only(top: 6), child: CineDotLeader())),
                SizedBox(width: c.space2),
                for (final k in keycapsOf(e, platform)) Padding(padding: const EdgeInsets.only(left: 4), child: _Keycap(k)),
              ],),
            ),
          ),
      ],
    ],);
  }
}

/// The `?` sheet (cinematic 8.33.2): a `CineDialog` (max 720) titled "Keyboard".
Future<void> showCineKeyboardSheet(BuildContext context, WidgetRef ref) {
  final groups = ref.read(shortcutRegistryProvider.notifier).registeredGroups();
  final platform = Theme.of(context).platform;
  return showCineDialog<void>(
    context,
    builder: (ctx) => CineDialog(
      title: 'Keyboard',
      body: 'Only what works on this screen is listed. Shortcuts pause while you type in a field.',
      maxWidth: 720,
      content: CineKeyboardSheetBody(groups: groups, platform: platform),
      onCancel: () => Navigator.of(ctx).maybePop(),
      actions: [CineButton(label: 'Close', variant: CineButtonVariant.quiet, onPressed: () => Navigator.of(ctx).maybePop())],
    ),
  );
}
