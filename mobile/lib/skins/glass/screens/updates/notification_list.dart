import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart' show contentModeScopeProvider;
import 'package:manhwamaniacs/features/library/utils/relative_read_time.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/features/updates/utils/notification_grouping.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/context_menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart' show openSeries;
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart' show globalRectOf, roleIcon;
import 'package:manhwamaniacs/skins/glass/transitions/dive.dart';

String _n(double? v) => v == null ? '' : (v % 1 == 0 ? '${v.toInt()}' : '$v');

/// "3 new · Ch 141–143".
String updateSummary(SeriesUpdate g) {
  final nums = [for (final c in g.chapters) if (c.chapterNumber != null) c.chapterNumber!]..sort();
  final range = nums.isEmpty ? '' : (nums.first == nums.last ? ' · Ch ${_n(nums.first)}' : ' · Ch ${_n(nums.first)}–${_n(nums.last)}');
  return '${g.chapters.length} new$range';
}

/// The notification groups of [days], one card per series (glass 8.21), under day headers.
class GlassNotificationList extends ConsumerWidget {
  const GlassNotificationList({super.key, required this.days, this.focusedKey});
  final List<UpdateDay> days;
  final ValueChanged<SeriesUpdate>? focusedKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassSwipeGroup(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final d in days) ...[
            Padding(padding: const EdgeInsets.only(top: 12, bottom: 8), child: Semantics(header: true, child: GlassLabel(d.label[0] + d.label.substring(1).toLowerCase(), role: gt.typeFootnote, wght: 600, upper: true, color: gt.colorLabel2))),
            for (final g in d.groups)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: UpdateCard(key: ValueKey('${g.sourceId}|${g.seriesKey}|${d.label}'), group: g, onFocus: () => focusedKey?.call(g))),
          ],
        ],),
      );
}

Future<void> markGroupRead(WidgetRef ref, SeriesUpdate g) async {
  for (final c in g.chapters) {
    if (!c.read) await ref.read(updatesProvider.notifier).markRead(c.notificationId);
  }
}

/// One series' new chapters: cover, title, the summary, the time, and chapter chips. Unread carries an 8 px `iris400` dot and a 2 px
/// leading bar; read cards dim by role (title `label2`, meta `label3`), only the cover image drops to 70 %.
class UpdateCard extends ConsumerWidget {
  const UpdateCard({super.key, required this.group, this.onFocus});
  final SeriesUpdate group;
  final VoidCallback? onFocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = group;
    final read = g.allRead;
    final now = ref.watch(clockProvider)();
    final scope = ref.watch(contentModeScopeProvider);
    final novel = scope.novelsEnabled && scope.modeOf(g.sourceId) == ContentMode.novel;
    final time = g.newestAt == null ? '' : relativeReadTime(g.newestAt!, now: now);
    return Builder(builder: (context) {
      Rect rect() => globalRectOf(context);
      String loc(UpdateChapter c) => novel ? Routes.novel(g.sourceId, g.seriesKey, c.chapterKey) : Routes.reader(g.sourceId, g.seriesKey, c.chapterKey);
      Future<void> openChapter(UpdateChapter c) async {
        unawaited(ref.read(updatesProvider.notifier).markRead(c.notificationId));
        await enterReader(context, ref, loc(c), fromRect: rect());
      }

      return GlassSwipeRow(
        name: g.title,
        leading: [
          SwipeAction(id: 'read', label: 'Mark read', glyph: roleIcon(GlassIconRole.select), tone: SwipeTone.success, run: () => markGroupRead(ref, g)),
        ],
        trailing: [
          SwipeAction(id: 'open', label: 'Open series', glyph: roleIcon(GlassIconRole.external), tone: SwipeTone.iris, run: () => openSeries(ref, g.sourceId, g.seriesKey, from: rect())),
        ],
        child: Focus(
          canRequestFocus: false,
          onFocusChange: (f) {
            if (f) onFocus?.call();
          },
          child: Stack(children: [
            GlassSlab(
              semanticsLabel: '${g.title}, ${updateSummary(g)}, $time${read ? '' : ', unread'}',
              onTap: () => unawaited(openSeries(ref, g.sourceId, g.seriesKey, from: rect())),
              onLongPress: () => unawaited(showGlassContextMenu(
                context,
                sourceRect: rect(),
                preview: ClipRRect(borderRadius: BorderRadius.circular(14), child: HomeCoverImage(url: g.coverUrl, width: 96)),
                kind: GlassPreviewKind.row,
                title: g.title,
                entries: [
                  if (!read) GlassMenuEntry(label: 'Mark read', run: () => markGroupRead(ref, g)),
                  GlassMenuEntry(label: 'Open series', onSelected: () => unawaited(openSeries(ref, g.sourceId, g.seriesKey, from: rect()))),
                  if (g.followedId != null) GlassMenuEntry(label: 'Turn off notifications for this series', onSelected: () => unawaited(ref.read(glassUpdatesNotifyProvider)(g.followedId!, false))),
                ],
              ),),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Opacity(opacity: read ? 0.7 : 1, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 44, height: 66, child: HomeCoverImage(url: g.coverUrl, width: 44)))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: GlassLabel(g.title, role: gt.typeHeadline, color: read ? gt.colorLabel2 : gt.colorLabel1, maxLines: 2)),
                      const SizedBox(width: 8),
                      GlassLabel(time, role: gt.typeCaption1, color: gt.colorLabel3),
                      if (!read) ...[const SizedBox(width: 8), DecoratedBox(decoration: BoxDecoration(color: gt.colorIris400, shape: BoxShape.circle), child: const SizedBox.square(dimension: 8))],
                    ],),
                    GlassLabel(updateSummary(g), role: gt.typeFootnote, color: read ? gt.colorLabel3 : gt.colorIris400),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final c in g.chapters.take(6))
                        GlassChip(label: c.chapterNumber == null ? c.title : 'Ch ${_n(c.chapterNumber)}', selected: !c.read, kind: GlassChipKind.assist, onPressed: () => unawaited(openChapter(c))),
                    ],),
                  ],),
                ),
              ],),
            ),
            if (!read) Positioned(left: 0, top: 14, bottom: 14, child: DecoratedBox(decoration: BoxDecoration(color: gt.colorIris400, borderRadius: BorderRadius.circular(1)), child: const SizedBox(width: 2))),
          ],),
        ),
      );
    },);
  }
}

/// `PATCH /library/series/{id} {notify}`.
final glassUpdatesNotifyProvider = Provider<Future<void> Function(int, bool)>((ref) => (id, on) async {
      await ref.read(libraryRepositoryProvider).patchSeries(id, notify: on);
      await ref.read(updatesProvider.notifier).refresh();
    },);
