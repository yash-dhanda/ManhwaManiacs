import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/depth_glyph.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/snapshot_store.dart';
import 'package:manhwamaniacs/skins/glass/shell/bar_icon.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/stack_overview_host.dart';

/// The label of a back button: "Back to {previous title}", with the depth ("Back, level 3 of 3") when it shows the strata glyph.
String backLabel(
    {String? previousTitle, int depth = 0, bool showDepth = false,}) {
  if (showDepth && depth > 0) return 'Back, level $depth of $depth';
  return previousTitle == null || previousTitle.isEmpty
      ? 'Back'
      : 'Back to $previousTitle';
}

/// Back: `caret-left`, or the strata glyph in readers and full-height sheets. A tap pops; a long-press (450 ms) or `Ctrl+\` opens the
/// stack overview; every back button carries the "All levels" custom semantics action.
class GlassBackButton extends ConsumerWidget {
  const GlassBackButton(
      {super.key,
      this.showDepth = false,
      this.inGroup = false,
      this.currentKey,});
  final bool showDepth;

  /// Drawn inside a bar group (no own glass layer).
  final bool inGroup;
  final String? currentKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(glassActiveTabProvider);
    final depth = ref.watch(glassDepthProvider)[tab] ?? 0;
    final levels = ref.watch(glassSnapshotStoreProvider.select((m) => [
          for (final s in m.values)
            if (s.tab == tab) s,
        ],),)
      ..sort((a, b) => a.depth.compareTo(b.depth));
    final previous = levels.isEmpty ? null : levels.last.title;
    final key = GlobalKey();
    void open() => unawaited(openGlassOverviewFor(context, ref,
        backButtonRect: globalRectOf(key.currentContext ?? context),
        currentKey: currentKey,),);
    final label =
        backLabel(previousTitle: previous, depth: depth, showDepth: showDepth);
    return Semantics(
      hint: 'Double-tap and hold for all levels',
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'All levels'): open,
      },
      child: KeyedSubtree(
        key: key,
        child: showDepth && depth > 0
            ? _DepthBack(
                label: label,
                onPressed: () => Navigator.of(context).maybePop(),
                onLongPress: open,
                depth: depth,
                tints: [for (final l in levels) l.rimTint],)
            : inGroup
                ? GlassBarIcon(
                    icon: roleIcon(GlassIconRole.back),
                    label: label,
                    onPressed: () => Navigator.of(context).maybePop(),
                    onLongPress: open,)
                : GlassIconButton(
                    icon: roleIcon(GlassIconRole.back),
                    label: label,
                    kind: GlassIconButtonKind.nav,
                    onPressed: () => Navigator.of(context).maybePop(),
                    onLongPress: open,
                    haptic: HapticEvent.navPop,
                  ),
      ),
    );
  }
}

class _DepthBack extends StatelessWidget {
  const _DepthBack(
      {required this.label,
      required this.onPressed,
      required this.onLongPress,
      required this.depth,
      required this.tints,});
  final String label;
  final VoidCallback onPressed;
  final VoidCallback onLongPress;
  final int depth;
  final List<Color> tints;

  @override
  Widget build(BuildContext context) {
    final hit = GlassFrame.hitMin(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      onLongPress: onLongPress,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        onLongPress: onLongPress,
        child: SizedBox(
            width: hit < 44 ? 44 : hit,
            height: hit < 44 ? 44 : hit,
            child: Center(child: DepthGlyph(depth: depth, tints: tints)),),
      ),
    );
  }
}
