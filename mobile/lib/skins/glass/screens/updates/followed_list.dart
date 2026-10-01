import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/library_series_actions.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/row_shell.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart' show openSeries;
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart' show globalRectOf, roleButtonIcon, roleIcon;
import 'package:manhwamaniacs/skins/glass/screens/updates/notification_list.dart' show glassUpdatesNotifyProvider;
import 'package:manhwamaniacs/skins/glass/skin_glass.dart' show GlassTwin;

/// The Followed segment (glass 8.21): title, source capsule, "412 chapters" or "Not checked yet", a notify bell, swipe left or the
/// menu to Unfollow (Undo), and "Check this series now".
class GlassFollowedList extends ConsumerWidget {
  const GlassFollowedList({super.key, required this.rows, this.onCheck});
  final List<FollowedSeries> rows;
  final Future<void> Function(FollowedSeries)? onCheck;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassSwipeGroup(
        child: Column(children: [
          for (final s in rows)
            GlassSwipeRow(
              key: ValueKey('f-${s.id}'),
              name: s.title,
              // The row's own "More actions" menu already carries Unfollow: no second dots button.
              showMore: false,
              trailing: [
                SwipeAction(id: 'unfollow', label: 'Unfollow', glyph: roleIcon(GlassIconRole.following), tone: SwipeTone.danger, destructive: true, run: () => _unfollow(ref, s)),
              ],
              child: Builder(builder: (context) {
                return GlassRowShell(
                  semanticsLabel: '${s.title}, ${s.sourceId}',
                  minHeight: 72,
                  onTap: () => unawaited(openSeries(ref, s.sourceId, s.seriesKey, from: globalRectOf(context))),
                  builder: (context, stacked, info) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 40, height: 60, child: HomeCoverImage(url: s.coverUrl, width: 40))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          GlassLabel(s.title, role: gt.typeHeadline, maxLines: 2),
                          Row(children: [
                            DecoratedBox(
                              decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(999)),
                              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), child: GlassLabel(s.sourceId, role: gt.typeCaption1)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: GlassLabel(s.lastCheckedAt == null ? 'Not checked yet' : '${s.chapterCount} chapters', role: gt.typeFootnote, color: gt.colorLabel2, maxLines: 2)),
                          ],),
                        ],),
                      ),
                      GlassIconButton(
                        icon: roleButtonIcon(GlassIconRole.notify),
                        label: s.notify ? 'Turn off notifications for ${s.title}' : 'Turn on notifications for ${s.title}',
                        toggle: s.notify,
                        kind: GlassIconButtonKind.row,
                        twin: GlassTwin.content,
                        onPressed: () => unawaited(ref.read(glassUpdatesNotifyProvider)(s.id, !s.notify)),
                      ),
                      GlassIconButton(
                        icon: roleButtonIcon(GlassIconRole.overflow),
                        label: 'More actions for ${s.title}',
                        kind: GlassIconButtonKind.row,
                        twin: GlassTwin.content,
                        onPressed: () => unawaited(showGlassMenu(context, anchor: globalRectOf(context), title: s.title, entries: [
                          if (onCheck != null) GlassMenuEntry(label: 'Check this series now', run: () => onCheck!(s)),
                          GlassMenuEntry(label: 'Unfollow', destructive: true, onSelected: () => unawaited(_unfollow(ref, s))),
                        ],),),
                      ),
                    ],),
                  ),
                );
              },),
            ),
        ],),
      );

  Future<void> _unfollow(WidgetRef ref, FollowedSeries s) async {
    final actions = ref.read(librarySeriesActionsProvider);
    final removed = await actions.remove(s);
    if (removed.error != null) {
      showGlassToast(ref, GlassToastSpec("Couldn't unfollow ${s.title}", kind: GlassToastKind.error));
      return;
    }
    ref.read(updatesProvider.notifier).forgetFollowed(s.id);
    showGlassToast(ref, GlassToastSpec('Unfollowed ${s.title}', undo: () => unawaited(() async {
      await actions.restore(s, slots: removed.slots);
      await ref.read(updatesProvider.notifier).refresh();
    }()),),);
  }
}
