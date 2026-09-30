import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/dispatch.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/motion_math.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/circle_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/dispatch_row.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// `TODAY` / `YESTERDAY` / `MON 21 SEP` in `type.kicker` `ink.45` over a `rule.hair`.
class CircleDayRule extends StatelessWidget {
  const CircleDayRule(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Padding(
      padding: EdgeInsets.only(top: c.space6, bottom: c.space2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(header: true, child: CineRoleText(label, c.typeKicker, color: c.colorInk45)),
        SizedBox(height: c.space2),
        DecoratedBox(decoration: BoxDecoration(border: Border(top: c.ruleHair)), child: const SizedBox(width: double.infinity)),
      ],),
    );
  }
}

/// The dispatches of one feed kind, grouped by day, paging on `next_cursor` (cinematic 9.3.2). The
/// first page runs Set (24 ms per row, capped at 360 ms); appended pages fade in as one block over
/// 160 ms. [focusNodes] lets the screen step through the rows by key.
class ActivityList extends ConsumerStatefulWidget {
  const ActivityList({super.key, required this.kind, required this.scrollController, required this.focusNodes, this.emptyText, this.emptyAction, this.onEmptyAction, this.leading = const [], this.trailing = const [], this.duplicateNames = const {}});

  final String? kind;
  final ScrollController? scrollController;
  final List<FocusNode> focusNodes;
  final String? emptyText, emptyAction;
  final VoidCallback? onEmptyAction;

  /// Slivers before and after the rows (the private banner, the trailing gap).
  final List<Widget> leading, trailing;
  final Set<String> duplicateNames;

  @override
  ConsumerState<ActivityList> createState() => _ActivityListState();
}

class _ActivityListState extends ConsumerState<ActivityList> {
  int _firstPage = -1;

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.extentAfter < 400) unawaited(ref.read(circleFeedProvider(widget.kind).notifier).loadMore());
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(circleFeedProvider(widget.kind));
    final state = async.valueOrNull;
    final grid = CineGrid.of(context);
    final now = ref.watch(clockProvider)();
    final reduced = CineMotion.reduced(context);
    if (state == null) {
      return CustomScrollView(slivers: [
        ...widget.leading,
        SliverToBoxAdapter(child: async.hasError ? CircleErrorNotice(error: async.error!, onRetry: () => ref.invalidate(circleFeedProvider(widget.kind))) : const CircleGalley()),
      ],);
    }
    final groups = dayGroups(state.items, now);
    final entries = <Object>[];
    var index = 0;
    for (final g in groups) {
      entries.add(g.label);
      for (final i in g.items) {
        entries.add((item: i, index: index++));
      }
    }
    final seenSeries = <String>{};
    if (_firstPage < 0) _firstPage = state.items.length;
    final firstCount = _firstPage;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: CustomScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ...widget.leading,
          if (state.items.isEmpty)
            SliverToBoxAdapter(child: CircleTabEmpty(text: widget.emptyText ?? CircleCopy.emptyAll, action: widget.emptyAction, onAction: widget.onEmptyAction))
          else
            SliverPadding(
              padding: EdgeInsets.only(left: grid.left, right: grid.right),
              sliver: SliverList.builder(
                itemCount: entries.length,
                itemBuilder: (context, k) {
                  final e = entries[k];
                  if (e is String) return CircleDayRule(e);
                  final r = e as ({FeedItem item, int index});
                  while (widget.focusNodes.length <= r.index) {
                    widget.focusNodes.add(FocusNode(debugLabel: 'dispatch-${widget.focusNodes.length}'));
                  }
                  final tag = seenSeries.add('${r.item.sourceId}:${r.item.seriesKey}') ? 'cover-${r.item.sourceId}-${r.item.seriesKey}' : null;
                  Widget row = DispatchRow(
                    key: ValueKey('dispatch-${r.item.id}'),
                    item: r.item,
                    now: now,
                    focusNode: widget.focusNodes[r.index],
                    heroTag: tag,
                    unsealIndex: r.index,
                    duplicateNames: widget.duplicateNames.contains(r.item.actor.name),
                  );
                  if (r.index < firstCount) {
                    if (!reduced) row = _SetIn(delay: Duration(milliseconds: listDelay(r.index)), child: row);
                  } else {
                    row = _FadeIn(child: row);
                  }
                  return row;
                },
              ),
            ),
          if (state.loadingMore) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: SizedBox(height: 4)))),
          if (state.hasMore && !state.loadingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(grid.left, context.cine.space4, grid.right, 0),
                child: Align(alignment: Alignment.centerLeft, child: CineButton(label: 'Load more', variant: CineButtonVariant.quiet, onPressed: () => unawaited(ref.read(circleFeedProvider(widget.kind).notifier).loadMore()))),
              ),
            ),
          ...widget.trailing,
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}

/// Set: a row fades and rises on its 24 ms stagger (first page only).
class _SetIn extends StatefulWidget {
  const _SetIn({required this.delay, required this.child});
  final Duration delay;
  final Widget child;

  @override
  State<_SetIn> createState() => _SetInState();
}

class _SetInState extends State<_SetIn> {
  double _t = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _t = 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSlide(
        offset: Offset(0, _t == 1 ? 0 : 0.08),
        duration: CineDur.column,
        curve: CineCurves.settle,
        child: AnimatedOpacity(opacity: _t, duration: CineDur.column, curve: CineCurves.settle, child: widget.child),
      );
}

/// Appended pages: one 160 ms fade, no stagger.
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: CineMotion.reduced(context) ? Duration.zero : CineDur.beat,
        builder: (_, v, child) => Opacity(opacity: v, child: child),
        child: child,
      );
}
