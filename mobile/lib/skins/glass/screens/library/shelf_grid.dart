import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/collections/providers/collections_provider.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart' show contentModeScopeProvider;
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/glass_density_provider.dart';
import 'package:manhwamaniacs/features/library/utils/glass_density.dart';
import 'package:manhwamaniacs/features/sources/utils/series_content_kind.dart' show isNovelSource;
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/parts/recap/continue_series.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/series_card.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/context_menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/reorder_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/row_shell.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/select_mode.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/selectable_group.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/density_pinch.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/flip_grid.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/shelf_actions.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart' show GlassTwin;
import 'package:manhwamaniacs/skins/glass/transitions/poster_zoom.dart';

/// The entrance wave of the shelf (glass 4.8): [replay] starts a new one from [cause]; each tile built within the next 600 ms enters
/// `min(distance / 1.6, 240)` ms after it, a 12 px translate and scale 0.98 to 1 on `springSnappy`; tiles built later just appear.
class ShelfWave {
  int epoch = 0;
  Offset cause = Offset.zero;
  DateTime _at = DateTime.fromMillisecondsSinceEpoch(0);

  void replay(Offset from) {
    epoch++;
    cause = from;
    _at = DateTime.now();
  }

  bool get running => DateTime.now().difference(_at).inMilliseconds < 600;
}

/// What a shelf item needs from the page, bundled so the grid and the list pass one object.
class ShelfUi {
  ShelfUi({required this.select, required this.flip, required this.live, required this.wave, required this.focused, required this.downloaded, required this.gateOpen});
  final GlassSelectModeController<int> select;
  final FlipRegistry flip;
  final ValueNotifier<PinchState?> live;
  final ShelfWave wave;
  final ValueNotifier<int?> focused;
  final Set<String> downloaded;
  final bool gateOpen;
}

class _WaveTile extends ConsumerStatefulWidget {
  const _WaveTile({required this.wave, required this.child});
  final ShelfWave wave;
  final Widget child;

  @override
  ConsumerState<_WaveTile> createState() => _WaveTileState();
}

class _WaveTileState extends ConsumerState<_WaveTile> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Offset _dir = Offset.zero;
  bool _fade = false;
  int _seen = -1;

  @override
  void initState() {
    super.initState();
    _c = AnimationController.unbounded(vsync: this, value: 1);
    if (widget.wave.running) {
      _seen = widget.wave.epoch;
      _c.value = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  void _start() {
    if (!mounted) return;
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    final ro = context.findRenderObject();
    final rect = ro is RenderBox && ro.attached ? ro.localToGlobal(Offset.zero) & ro.size : Rect.zero;
    final d = widget.wave.cause - rect.center;
    final delay = Duration(microseconds: (math.min(d.distance / GlassPhysics.waveSpeed, GlassPhysics.waveMaxDelay) * 1000).round());
    _dir = d.distance == 0 ? Offset.zero : d / d.distance * 12;
    _fade = reduced;
    Timer(reduced ? Duration.zero : delay, () {
      if (!mounted) return;
      if (reduced) {
        unawaited(_c.animateTo(1, duration: const Duration(milliseconds: 150)));
      } else {
        unawaited(_c.animateWith(SpringSimulation(springOf(gt.springSnappy), 0, 1, 0)));
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_seen < 0) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        if (t >= 1) return child!;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: _fade ? child : Transform.translate(offset: _dir * (1 - t), child: Transform.scale(scale: 0.98 + 0.02 * t, child: child)),
        );
      },
    );
  }
}

/// The context menu entries of a shelf series (glass 8.17): Continue, Details, Favourite, Mark read, Add to collection, Download next
/// 10, Previously on, Remove from library.
List<GlassMenuEntry> shelfMenuEntries(BuildContext context, WidgetRef ref, FollowedSeries s, Rect from, {List<GlassMenuEntry> first = const []}) {
  final a = ref.read(glassShelfActionsProvider);
  final r = s.readState;
  final novel = isNovelSource(ref.read(contentModeScopeProvider), s.sourceId) ?? false;
  final chapterKey = r?.chapterKey;
  final target = chapterKey == null ? null : HomeContinueTarget(sourceId: s.sourceId, seriesKey: s.seriesKey, chapterKey: chapterKey, isNovel: novel, chapterNumber: r?.chapterNumber, lastReadAt: r?.lastReadAt);
  return [
    ...first,
    if (target != null) GlassMenuEntry(label: 'Continue', onSelected: () => unawaited(continueSeries(context, ref, target, from))),
    GlassMenuEntry(label: 'Details', onSelected: () => unawaited(openSeries(ref, s.sourceId, s.seriesKey, from: from))),
    GlassMenuEntry(label: s.isFavorite ? 'Unfavourite' : 'Favourite', onSelected: () => unawaited(a.favourite(s))),
    GlassMenuEntry(label: 'Mark read', run: () async {
      await a.markRead({s.id});
    },),
    GlassMenuEntry(label: 'Add to collection', onSelected: () => unawaited(_pickCollection(context, ref, s, from))),
    GlassMenuEntry(label: 'Download next 10', onSelected: () => unawaited(downloadNextTen(ref, sourceId: s.sourceId, seriesKey: s.seriesKey, title: s.title, readNumber: r?.chapterNumber, novel: novel))),
    if (target != null) GlassMenuEntry(label: 'Previously on', onSelected: () => unawaited(openRecap(ref, s.sourceId, s.seriesKey, chapterKey!, from: from))),
    GlassMenuEntry(label: 'Remove from library', destructive: true, separatorBefore: true, onSelected: () => unawaited(a.remove(s))),
  ];
}

Future<void> _pickCollection(BuildContext context, WidgetRef ref, FollowedSeries s, Rect from) async {
  final all = await ref.read(collectionsProvider.future);
  final cols = [for (final c in all) if (c.rules == null) c];
  if (!context.mounted) return;
  if (cols.isEmpty) {
    showGlassToast(ref, const GlassToastSpec('No collections yet. Create one in Collections.'));
    return;
  }
  await showGlassMenu(
    context,
    anchor: from,
    title: 'Add to collection',
    entries: [for (final c in cols.take(12)) GlassMenuEntry(label: c.name, onSelected: () => unawaited(ref.read(glassShelfActionsProvider).addToCollection([s], c)))],
  );
}

/// One series of the shelf as a poster card (glass 7.7, 7.8). Select mode, the context menu, the hover buttons and the zoom are the
/// poster's; this wires them to the shelf's data and actions.
class ShelfTile extends ConsumerWidget {
  const ShelfTile({super.key, required this.series, required this.ui, required this.width, required this.compact});
  final FollowedSeries series;
  final ShelfUi ui;
  final double width;

  /// Compact tiles (4 and 5 columns, desktop Compact) carry the title only.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = series;
    final a = ref.read(glassShelfActionsProvider);
    final wide = GlassFrame.of(context) != GlassFrameKind.phone;
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
          child: Builder(
            builder: (context) {
              Rect rect() => globalRectOf(context);
              final poster = GlassPoster(
                cover: GlassCoverHero(sourceId: s.sourceId, seriesKey: s.seriesKey, child: HomeCoverImage(url: s.coverUrl, width: width)),
                title: s.title,
                width: width,
                lMax: s.ambient == null ? 0.5 : 0.6,
                meta: shelfPosterMeta(s, downloaded: downloaded, gateOpen: ui.gateOpen),
                selectMode: ui.select.active,
                selected: ui.select.isSelected(s.id),
                onTap: () => unawaited(openSeries(ref, s.sourceId, s.seriesKey, from: rect())),
                onContextPreview: () => unawaited(showGlassContextMenu(
                  context,
                  sourceRect: rect(),
                  preview: ClipRRect(borderRadius: BorderRadius.circular(14), child: HomeCoverImage(url: s.coverUrl, width: width)),
                  kind: GlassPreviewKind.poster,
                  title: s.title,
                  entries: shelfMenuEntries(context, ref, s, rect(), first: [GlassMenuEntry(label: 'Select', onSelected: () => ui.select.enter(s.id))]),
                ),),
                onFavourite: wide ? () => unawaited(a.favourite(s)) : null,
                onFollow: wide ? () => unawaited(a.toggleFollow(s)) : null,
                following: true,
              );
              return _WaveTile(wave: ui.wave, child: FlipTile(id: s.id, registry: ui.flip, child: GlassSeriesCard(poster: poster, title: s.title, meta: compact ? null : shelfCaption(s), width: width)));
            },
          ),
        ),
      ),
    );
  }
}

/// A series as a List row: a 64 px square cover, the title and status, the meta, and favourite and follow buttons.
class ShelfListRow extends ConsumerWidget {
  const ShelfListRow({super.key, required this.series, required this.ui});
  final FollowedSeries series;
  final ShelfUi ui;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = series;
    final a = ref.read(glassShelfActionsProvider);
    final status = glassStatusOf(s.readingStatus);
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
          child: Builder(
            builder: (context) {
              Rect rect() => globalRectOf(context);
              final selected = ui.select.isSelected(s.id);
              final meta = [shelfCaption(s), if (downloaded) 'Downloaded'].where((e) => e.isNotEmpty).join(' \u00b7 ');
              return _WaveTile(
                wave: ui.wave,
                child: FlipTile(
                  id: s.id,
                  registry: ui.flip,
                  child: GlassRowShell(
                    semanticsLabel: '${s.title}, ${status?.spoken ?? 'not started'}',
                    minHeight: 76,
                    selectMode: ui.select.active,
                    selected: selected,
                    onTap: () => unawaited(openSeries(ref, s.sourceId, s.seriesKey, from: rect())),
                    onLongPress: () => unawaited(showGlassContextMenu(
                      context,
                      sourceRect: rect(),
                      preview: ClipRRect(borderRadius: BorderRadius.circular(14), child: HomeCoverImage(url: s.coverUrl, width: 64)),
                      kind: GlassPreviewKind.row,
                      title: s.title,
                      entries: shelfMenuEntries(context, ref, s, rect(), first: [GlassMenuEntry(label: 'Select', onSelected: () => ui.select.enter(s.id))]),
                    ),),
                    builder: (context, stacked, info) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox.square(dimension: 64, child: GlassCoverHero(sourceId: s.sourceId, seriesKey: s.seriesKey, child: HomeCoverImage(url: s.coverUrl, width: 64)))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          GlassLabel(s.title, role: gt.typeHeadline, maxLines: 2),
                          if (status != null) GlassLabel(status.text, role: gt.typeCaption1, wght: 600, color: status.color),
                          if (meta.isNotEmpty) GlassLabel(meta, role: gt.typeFootnote, color: gt.colorLabel2),
                        ],),
                      ),
                      if (!ui.select.active) ...[
                        GlassIconButton(icon: roleButtonIcon(GlassIconRole.favourite), label: s.isFavorite ? 'Unfavourite ${s.title}' : 'Favourite ${s.title}', toggle: s.isFavorite, kind: GlassIconButtonKind.row, twin: GlassTwin.content, onPressed: () => unawaited(a.favourite(s))),
                        GlassIconButton(icon: roleButtonIcon(GlassIconRole.following), label: 'Remove ${s.title} from library', toggle: true, kind: GlassIconButtonKind.row, twin: GlassTwin.content, onPressed: () => unawaited(a.toggleFollow(s))),
                      ],
                    ],),),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A pinch row: paints the live scale of the pinch around the fingers' midpoint while one is down (the rows are a lazy list, so each
/// row computes where the midpoint sits in its own space).
class _PinchRow extends StatelessWidget {
  const _PinchRow({required this.live, required this.child});
  final ValueNotifier<PinchState?> live;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<PinchState?>(
        valueListenable: live,
        child: child,
        builder: (context, p, child) {
          if (p == null) return child!;
          final ro = context.findRenderObject();
          final origin = ro is RenderBox && ro.attached ? ro.localToGlobal(Offset.zero) : Offset.zero;
          final f = p.focal - origin;
          final s = p.scale.clamp(0.6, 1.6);
          return Transform(
            transform: Matrix4.identity()
              ..translateByDouble(f.dx, f.dy, 0, 1)
              ..scaleByDouble(s, s, 1, 1)
              ..translateByDouble(-f.dx, -f.dy, 0, 1),
            child: child,
          );
        },
      );
}

/// The shelf's series as a sliver (glass 8.17): phones use the stored column count (List, 2-5), tablet and desktop frames
/// `gridColumns(width, gridMin, 20)`; List is rows. Rows are built lazily. With [manual] the grid is a [GlassReorderList].
class SliverShelfGrid extends ConsumerWidget {
  const SliverShelfGrid({super.key, required this.rows, required this.ui, required this.manual, required this.onReorder});
  final List<FollowedSeries> rows;
  final ShelfUi ui;
  final bool manual;
  final void Function(int from, int to) onReorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = ref.watch(glassDensityProvider);
    final frame = GlassFrame.of(context);
    final phone = frame == GlassFrameKind.phone;
    final list = phone ? density.phone.isList : density.wide == GlassDensityWide.list;
    return SliverLayoutBuilder(
      builder: (context, c) {
        final w = c.crossAxisExtent;
        if (list) {
          if (manual) {
            return SliverToBoxAdapter(
              child: GlassReorderList<FollowedSeries>(
                items: rows,
                nameOf: (s) => s.title,
                onReorder: onReorder,
                itemBuilder: (context, s, i, info) => ShelfListRow(series: s, ui: ui),
              ),
            );
          }
          return SliverList.builder(itemCount: rows.length, itemBuilder: (context, i) => _PinchRow(live: ui.live, child: ShelfListRow(series: rows[i], ui: ui)));
        }
        final gap = phone ? 12.0 : 20.0;
        final cols = phone ? density.phone.columns : gridColumns(w, gridMin(density.wide, desktop: frame.index >= GlassFrameKind.desktop.index), gap);
        final compact = phone ? cols >= 4 : density.wide == GlassDensityWide.compact;
        final cell = (w - gap * (cols - 1)) / cols;
        if (manual) {
          return SliverToBoxAdapter(
            child: GlassReorderList<FollowedSeries>(
              items: rows,
              layout: GlassReorderLayout.grid,
              columns: cols,
              spacing: gap,
              nameOf: (s) => s.title,
              onReorder: onReorder,
              itemBuilder: (context, s, i, info) => ShelfTile(series: s, ui: ui, width: cell, compact: compact),
            ),
          );
        }
        final rowCount = (rows.length / cols).ceil();
        return SliverList.builder(
          itemCount: rowCount,
          itemBuilder: (context, r) => _PinchRow(
            live: ui.live,
            child: Padding(
              padding: EdgeInsets.only(bottom: gap),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (var k = 0; k < cols; k++) ...[
                  if (k > 0) SizedBox(width: gap),
                  SizedBox(width: cell, child: r * cols + k < rows.length ? ShelfTile(key: ValueKey(rows[r * cols + k].id), series: rows[r * cols + k], ui: ui, width: cell, compact: compact) : null),
                ],
              ],),
            ),
          ),
        );
      },
    );
  }
}
