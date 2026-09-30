import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';
import 'package:manhwamaniacs/features/library/utils/shelf_labels.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/book_list_row.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/library_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/reorder_announce.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_reorderable_list.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_reorderable_wall.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Everything the wall, list and book list need from the shelf screen.
class ShelfEnv {
  const ShelfEnv({
    required this.query,
    required this.rows,
    required this.novels,
    required this.selectMode,
    required this.selected,
    required this.gateOpen,
    required this.savedKeys,
    required this.offline,
    required this.coverOf,
    required this.now,
    required this.tracker,
    required this.open,
    required this.quickLook,
    required this.toggleSelect,
    required this.favourite,
    required this.notify,
    required this.move,
    required this.nodes,
    this.onFocusIndex,
  });

  final ShelfQuery query;
  final List<FollowedSeries> rows;
  final bool novels, selectMode, gateOpen, offline;
  final Set<int> selected;

  /// `"$sourceId $seriesKey"` of every series with a chapter saved on this device.
  final Set<String> savedKeys;
  final String? Function(FollowedSeries) coverOf;
  final DateTime now;
  final ShelfSetTracker tracker;
  final void Function(FollowedSeries s) open;
  final void Function(FollowedSeries s, int index) quickLook;
  final void Function(FollowedSeries s, int index, {bool range}) toggleSelect;
  final void Function(FollowedSeries s) favourite, notify;
  final void Function(int from, int to) move;
  final List<FocusNode> nodes;
  final ValueChanged<int>? onFocusIndex;

  bool get reorder => query.canReorder && !offline && !selectMode;
}

/// Which posters have already run Set in the current epoch. A new epoch is a filter change (a
/// Cut); refetches and back navigation keep the epoch, so nothing replays.
class ShelfSetTracker {
  int epoch = 0;
  final Set<int> _played = {};

  void newEpoch() {
    epoch++;
    _played.clear();
  }

  /// True the first time [id] is built in this epoch and it is one of the first screenful.
  bool shouldAnimate(int id, int index) => index < 32 && _played.add(id);

  /// Set in reading order: +32 ms an item, +64 ms a row, capped at 480 ms (cinematic 4.6).
  static Duration delayFor(int index, int perRow) {
    final col = index % perRow, row = index ~/ perRow;
    return Duration(milliseconds: math.min(480, 32 * col + 64 * row));
  }
}

/// The wall's geometry: posters per row, gaps and the cell height (poster plus a measured caption).
class ShelfGeometry {
  const ShelfGeometry({required this.perRow, required this.gap, required this.rowGap, required this.cellWidth, required this.posterHeight, required this.captionHeight});
  final int perRow;
  final double gap, rowGap, cellWidth, posterHeight, captionHeight;

  double get cellHeight => posterHeight + captionHeight;

  SliverGridDelegate get delegate => SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: perRow,
        crossAxisSpacing: gap,
        mainAxisSpacing: rowGap,
        mainAxisExtent: cellHeight,
      );

  /// Phones (< 600) WALL 3, COMPACT 4; tablets WALL 5, COMPACT 7.
  static int perRowFor(double width, ShelfDensity d) => width >= 600 ? (d == ShelfDensity.compact ? 7 : 5) : (d == ShelfDensity.compact ? 4 : 3);

  static ShelfGeometry of(BuildContext context, ShelfDensity density) {
    final c = context.cine;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 600;
    final grid = CineGrid.of(context);
    final perRow = perRowFor(width, density);
    final gap = wide ? 12.0 : 8.0;
    final content = width - grid.left - grid.right - 16;
    final cell = (content - gap * (perRow - 1)) / perRow;
    final lines = CineReflow.of(context).railCompact ? 2 : 1;
    final caption = density == ShelfDensity.compact ? 0.0 : 8 + lines * roleLineHeight(context, c.typeTitle) + 2 + roleLineHeight(context, c.typeFolio) + 9; // 1 px over the measured lines: a scaled line can round up 0.2
    return ShelfGeometry(perRow: perRow, gap: gap, rowGap: wide ? 24 : 16, cellWidth: cell, posterHeight: cell * 1.5, captionHeight: caption);
  }
}

/// The shelf's content sliver: the wall (lazy `SliverGrid`), the list, the book list and, in Manual
/// order, the reorderable wall or list (cinematic 8.9, 8.9.1).
class ShelfWall extends StatelessWidget {
  const ShelfWall({super.key, required this.env});
  final ShelfEnv env;

  @override
  Widget build(BuildContext context) {
    final grid = CineGrid.of(context);
    final side = EdgeInsets.fromLTRB(grid.left, 0, grid.right, 24);
    if (env.novels) return _books(context, side);
    return switch (env.query.density) {
      ShelfDensity.list => _list(context, side),
      _ => _wall(context, side),
    };
  }

  // ---- WALL and COMPACT ----------------------------------------------------------------------

  Widget _poster(BuildContext context, ShelfGeometry g, FollowedSeries s, int i, {Widget? handle}) {
    final poster = LibraryPoster(
      key: ValueKey('poster-${s.id}'),
      series: s,
      coverUrl: env.coverOf(s),
      density: env.query.density,
      gateOpen: env.gateOpen,
      saved: env.savedKeys.contains('${s.sourceId} ${s.seriesKey}'),
      selectMode: env.selectMode,
      selected: env.selected.contains(s.id),
      groupIndex: i,
      flickerIndex: i,
      focusNode: i < env.nodes.length ? env.nodes[i] : null,
      dragHandle: handle,
      onTap: () => env.selectMode ? env.toggleSelect(s, i) : env.open(s),
      onQuickLook: env.selectMode ? null : () => env.quickLook(s, i),
      onFavourite: env.offline || env.selectMode ? null : () => env.favourite(s),
      onNotify: env.offline || env.selectMode ? null : () => env.notify(s),
    );
    return CineSetIn(
      key: ValueKey('set-${env.tracker.epoch}-${s.id}'),
      animate: env.tracker.shouldAnimate(s.id, i),
      delay: ShelfSetTracker.delayFor(i, g.perRow),
      child: poster,
    );
  }

  Widget _wall(BuildContext context, EdgeInsets side) {
    final g = ShelfGeometry.of(context, env.query.density);
    if (env.reorder) return _reorderWall(context, g, side);
    return SliverPadding(
      padding: side.copyWith(left: side.left + 8, right: side.right + 8, top: 8),
      sliver: SliverGrid(
        gridDelegate: g.delegate,
        delegate: SliverChildBuilderDelegate(
          (context, i) => _poster(context, g, env.rows[i], i),
          childCount: env.rows.length,
        ),
      ),
    );
  }

  /// ponytail: Manual order renders the reorderable wall non-lazily (the 200-row page is the
  /// ceiling); every other wall stays a lazy `SliverGrid`.
  Widget _reorderWall(BuildContext context, ShelfGeometry g, EdgeInsets side) => SliverPadding(
        padding: side.copyWith(left: side.left + 8, right: side.right + 8, top: 8),
        sliver: SliverToBoxAdapter(
          child: CinePosterGroup(
            child: CineReorderableWall<FollowedSeries>(
              items: env.rows,
              idOf: (s) => s.id,
              titleOf: (s) => s.title,
              crossAxisCount: g.perRow,
              spacing: g.gap,
              aspectRatio: g.cellWidth / (g.cellHeight + (g.rowGap - g.gap)),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onMove: env.move,
              itemBuilder: (context, s, i, handle, moveEntries, semantics) => Padding(
                padding: EdgeInsets.only(bottom: g.rowGap - g.gap),
                child: Semantics(
                  customSemanticsActions: semantics,
                  child: _poster(context, g, s, i, handle: handle),
                ),
              ),
            ),
          ),
        ),
      );

  // ---- LIST ----------------------------------------------------------------------------------

  Widget _row(BuildContext context, FollowedSeries s, int i, {bool reorder = false}) {
    final row = LibraryListRow(
      key: ValueKey('row-${s.id}'),
      series: s,
      index: i,
      coverUrl: env.coverOf(s),
      wide: MediaQuery.sizeOf(context).width >= 768,
      now: env.now,
      selectMode: env.selectMode,
      selected: env.selected.contains(s.id),
      reorder: reorder,
      offline: env.offline,
      focusNode: i < env.nodes.length ? env.nodes[i] : null,
      onTap: () => env.open(s),
      onSelect: (_) => env.toggleSelect(s, i),
      onQuickLook: () => env.quickLook(s, i),
      onFavourite: () => env.favourite(s),
      onNotify: () => env.notify(s),
      semanticActions: reorder
          ? cineMoveSemantics(context, title: s.title, index: i, count: env.rows.length, onMove: env.move)
          : null,
    );
    return CineSetIn(
      key: ValueKey('set-${env.tracker.epoch}-${s.id}'),
      animate: env.tracker.shouldAnimate(s.id, i),
      delay: Duration(milliseconds: math.min(480, 32 * i)),
      child: row,
    );
  }

  Widget _list(BuildContext context, EdgeInsets side) {
    final pad = EdgeInsets.fromLTRB(side.left - 16 < 0 ? 0 : side.left - 16, 8, side.right - 16 < 0 ? 0 : side.right - 16, 24);
    if (env.reorder) {
      return SliverPadding(
        padding: pad,
        sliver: SliverReorderableList(
          itemCount: env.rows.length,
          onReorderItem: env.move,
          itemBuilder: (context, i) => KeyedSubtree(key: ValueKey('reorder-${env.rows[i].id}'), child: _row(context, env.rows[i], i, reorder: true)),
        ),
      );
    }
    return SliverPadding(
      padding: pad,
      sliver: SliverList.builder(itemCount: env.rows.length, itemBuilder: (context, i) => _row(context, env.rows[i], i)),
    );
  }

  // ---- BOOKS ---------------------------------------------------------------------------------

  Widget _book(BuildContext context, FollowedSeries s, int i) => CineSetIn(
        key: ValueKey('set-${env.tracker.epoch}-${s.id}'),
        animate: env.tracker.shouldAnimate(s.id, i),
        delay: Duration(milliseconds: math.min(480, 32 * i)),
        child: BookListRow(
          key: ValueKey('book-${s.id}'),
          title: s.title,
          credits: bookCredits(s),
          note: bookNote(s) ?? readingStatusLabel(s.readingStatus),
          coverUrl: env.coverOf(s),
          heroTag: (s.sourceId, s.seriesKey),
          selectMode: env.selectMode,
          selected: env.selected.contains(s.id),
          focusNode: i < env.nodes.length ? env.nodes[i] : null,
          onTap: () => env.open(s),
          onSelectedChanged: (_) => env.toggleSelect(s, i),
          trailing: env.selectMode
              ? null
              : Builder(builder: (b) => CineIconButton(label: 'More actions', codepoint: CineGlyph.dotsThree, onPressed: () => env.quickLook(s, i))),
        ),
      );

  Widget _books(BuildContext context, EdgeInsets side) {
    final wide = MediaQuery.sizeOf(context).width >= 768;
    final pad = EdgeInsets.fromLTRB(side.left - 16 < 0 ? 0 : side.left - 16, 8, side.right - 16 < 0 ? 0 : side.right - 16, 24);
    if (!wide) {
      return SliverPadding(padding: pad, sliver: SliverList.builder(itemCount: env.rows.length, itemBuilder: (context, i) => _book(context, env.rows[i], i)));
    }
    final c = context.cine;
    return SliverPadding(
      padding: pad,
      sliver: SliverLayoutBuilder(
        builder: (context, sc) => SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisExtent: 128, crossAxisSpacing: 33),
          delegate: SliverChildBuilderDelegate(
            (context, i) => DecoratedBox(
              // The 1 px column rule sits in the gutter between the two columns.
              decoration: BoxDecoration(border: i.isOdd ? Border(left: BorderSide(color: c.colorRule1)) : null),
              child: _book(context, env.rows[i], i),
            ),
            childCount: env.rows.length,
          ),
        ),
      ),
    );
  }
}

/// A LIST row (cinematic 8.9, 7.16): 72 px, a 48 x 72 cover, title over the folio caption and the
/// reading-status badge on phones; columns for title, status, progress, new count, last read and
/// the favourite and notify buttons from 768 px.
class LibraryListRow extends StatelessWidget {
  const LibraryListRow({
    super.key,
    required this.series,
    required this.index,
    required this.coverUrl,
    required this.wide,
    required this.now,
    required this.selectMode,
    required this.selected,
    required this.reorder,
    required this.offline,
    required this.onTap,
    required this.onSelect,
    required this.onQuickLook,
    required this.onFavourite,
    required this.onNotify,
    this.focusNode,
    this.semanticActions,
  });

  final FollowedSeries series;
  final int index;
  final String? coverUrl;
  final bool wide, selectMode, selected, reorder, offline;
  final DateTime now;
  final FocusNode? focusNode;
  final VoidCallback onTap, onQuickLook, onFavourite, onNotify;
  final ValueChanged<bool> onSelect;
  final Map<CustomSemanticsAction, VoidCallback>? semanticActions;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final s = series;
    final fresh = s.readState?.newCount ?? 0;
    final cover = Hero(
      tag: (s.sourceId, s.seriesKey),
      child: SizedBox(width: 48, height: 72, child: CineImage(url: coverUrl, title: s.title)),
    );
    final status = s.readingStatus == 'unread' ? null : CineBadge.reading(s.readingStatus);
    Widget body;
    if (wide) {
      body = Row(children: [
        cover,
        SizedBox(width: c.space4),
        Expanded(flex: 4, child: CineRoleText(s.title, c.typeTitle, maxLines: 2, overflow: TextOverflow.ellipsis)),
        SizedBox(width: 112, child: Align(alignment: Alignment.centerLeft, child: status ?? const SizedBox())),
        SizedBox(width: 132, child: CineRoleText(shelfProgress(s), c.typeFolio, color: c.colorInk60)),
        SizedBox(width: 80, child: Align(alignment: Alignment.centerLeft, child: fresh > 0 ? CineBadge.newCount(fresh) : const SizedBox())),
        SizedBox(width: 100, child: CineRoleText(lastReadCaption(s.readState?.lastReadAt, now), c.typeFolio, color: c.colorInk45)),
        if (!selectMode && !offline) ...[
          CineIconButton(
            label: s.isFavorite ? 'Remove from favourites' : 'Favourite',
            codepoint: CineGlyph.star,
            selected: s.isFavorite,
            onPressed: onFavourite,
          ),
          CineIconButton(
            label: s.notify ? 'Turn off notifications' : 'Notify me of new chapters',
            codepoint: CineGlyph.bellRinging,
            selected: s.notify,
            onPressed: onNotify,
          ),
        ],
      ],);
    } else {
      body = Row(children: [
        cover,
        SizedBox(width: c.space3),
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            CineRoleText(s.title, c.typeTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
            CineRoleText(shelfListCaption(s), c.typeFolio, color: c.colorInk45, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],),
        ),
        if (status != null) Padding(padding: EdgeInsets.only(left: c.space2), child: status),
      ],);
    }
    return CineQuickLookTarget(
      onOpen: onQuickLook,
      child: CineRowShell(
        minHeight: 72,
        tight: true,
        onTap: onTap,
        selectMode: selectMode,
        selected: selected,
        onSelectedChanged: onSelect,
        focusNode: focusNode,
        semanticLabel: '${s.title}, ${shelfListCaption(s)}',
        semanticActions: {
          ...?semanticActions,
          if (!selectMode) const CustomSemanticsAction(label: 'Quick look'): onQuickLook,
        },
        handle: selectMode
            ? null
            : Row(mainAxisSize: MainAxisSize.min, children: [
                CineIconButton(label: 'More actions', codepoint: CineGlyph.dotsThree, onPressed: onQuickLook),
                if (reorder) CineDragHandle(index: index),
              ],),
        child: body,
      ),
    );
  }
}

/// A quick look `Move` action (disabled at the ends), for Manual order.
List<QuickLookMove> shelfMoves(int index, int count) => [for (final m in CineMove.values) (move: m, to: m.target(index, count))];

typedef QuickLookMove = ({CineMove move, int? to});
