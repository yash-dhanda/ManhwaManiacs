import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/context_menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/row_shell.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/selectable_group.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/shelf_grid.dart';

/// The novels shelf (glass 8.17, "Novels mode"): rows with a 48 x 68 book plate, a Literata title, the genres and the reading note.
/// Select mode works on rows like on posters.
class SliverBookShelf extends ConsumerWidget {
  const SliverBookShelf({super.key, required this.rows, required this.ui});
  final List<FollowedSeries> rows;
  final ShelfUi ui;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (context, i) => _BookRow(series: rows[i], ui: ui),
      );
}

class _BookRow extends ConsumerWidget {
  const _BookRow({required this.series, required this.ui});
  final FollowedSeries series;
  final ShelfUi ui;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = series;
    final genres = [for (final t in s.tags.take(3)) t.name].join(' · ');
    final note = shelfCaption(s);
    final downloaded = ui.downloaded.contains('${s.sourceId}|${s.seriesKey}');
    return Focus(
      canRequestFocus: false,
      onFocusChange: (f) {
        if (f) ui.focused.value = s.id;
      },
      child: ListenableBuilder(
        listenable: ui.select,
        builder: (context, _) => GlassSelectableItem<int>(
          id: s.id,
          child: Builder(builder: (context) {
            Rect rect() => globalRectOf(context);
            return GlassRowShell(
              semanticsLabel: '${s.title}, $note',
              minHeight: 92,
              selectMode: ui.select.active,
              selected: ui.select.isSelected(s.id),
              onTap: () => unawaited(openSeries(ref, s.sourceId, s.seriesKey, from: rect())),
              onLongPress: () => unawaited(showGlassContextMenu(
                context,
                sourceRect: rect(),
                preview: ClipRRect(borderRadius: BorderRadius.circular(8), child: HomeCoverImage(url: s.coverUrl, width: 96)),
                kind: GlassPreviewKind.row,
                title: s.title,
                entries: shelfMenuEntries(context, ref, s, rect(), first: [GlassMenuEntry(label: 'Select', onSelected: () => ui.select.enter(s.id))]),
              ),),
              builder: (context, stacked, info) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(width: 48, height: 68, child: HomeCoverImage(url: s.coverUrl, width: 48))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      BookTitle(s.title),
                      if (genres.isNotEmpty) GlassLabel(genres, role: gt.typeFootnote, color: gt.colorLabel2),
                      if (note.isNotEmpty || downloaded) GlassLabel([note, if (downloaded) 'On this device'].where((e) => e.isNotEmpty).join(' · '), role: gt.typeCaption1, color: gt.colorLabel3),
                    ],),
                  ),
                  if (!ui.select.active && GlassFrame.of(context) != GlassFrameKind.phone) const SizedBox(width: 8),
                ],),
              ),
            );
          },),
        ),
      ),
    );
  }
}
