import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart' show CircleFeedState;
import 'package:manhwamaniacs/features/circle/utils/collapse_feed.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/activity_row.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "Today", "Yesterday", else "Mon 21 Sep", in the viewer's local day.
String circleDayLabel(DateTime? t, DateTime now) {
  if (t == null) return 'Today';
  final d = t.toLocal(), n = now.toLocal();
  final diff = DateTime(n.year, n.month, n.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (diff <= 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
}

/// Collapsed entries grouped under their day label, newest first.
List<({String label, List<FeedEntry> entries})> activityDays(List<FeedItem> items, DateTime now) {
  final out = <({String label, List<FeedEntry> entries})>[];
  for (final e in collapseReads(items, utcOffset: now.timeZoneOffset)) {
    final l = circleDayLabel(e.item.createdAt, now);
    if (out.isNotEmpty && out.last.label == l) {
      out.last.entries.add(e);
    } else {
      out.add((label: l, entries: [e]));
    }
  }
  return out;
}

/// The activity slivers (glass 9.3.1): each day a group under a sticky header with a hard edge, the rows, and at the end a
/// skeleton row that asks for the next page.
List<Widget> activitySlivers({
  required List<({String label, List<FeedEntry> entries})> days,
  required CircleFeedState feed,
  required VoidCallback onLoadMore,
  required FocusNode Function(String id) focusOf,
  required Listenable Function(String id) reactOf,
}) =>
    [
      for (final d in days)
        SliverMainAxisGroup(
          slivers: [
            SliverPersistentHeader(pinned: true, delegate: _DayHeader(d.label)),
            SliverList.list(children: [for (final e in d.entries) ActivityRow(key: ValueKey(e.item.id), entry: e, focusNode: focusOf(e.item.id), reactRequest: reactOf(e.item.id))]),
          ],
        ),
      if (feed.hasMore) loadMoreSliver(feed, onLoadMore),
    ];

/// The trailing skeleton row that asks for the next page. A lazy sliver, so it is built (and asks) only once scrolled near;
/// keyed by the cursor, so every new page gets a fresh ask; a failed ask is retried after a pause while it stays built.
Widget loadMoreSliver(CircleFeedState feed, VoidCallback onLoadMore) =>
    SliverList.list(children: [_LoadMore(key: ValueKey(feed.nextCursor), loading: feed.loadingMore, onLoadMore: onLoadMore)]);

class _DayHeader extends SliverPersistentHeaderDelegate {
  _DayHeader(this.label);
  final String label;

  @override
  double get minExtent => 36;
  @override
  double get maxExtent => 36;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Semantics(
        header: true,
        headingLevel: 2,
        child: Container(
          height: 36,
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(horizontal: GlassFrame.screenMargin(context)),
          decoration: BoxDecoration(
            color: gt.colorSurface1,
            border: Border(bottom: BorderSide(color: gt.colorSeparator, width: 0.5)),
          ),
          child: GlassText(label, role: gt.typeFootnote, wght: 600, color: gt.colorLabel2, maxScale: 1.6),
        ),
      );

  @override
  bool shouldRebuild(_DayHeader old) => old.label != label;
}

class _LoadMore extends StatefulWidget {
  const _LoadMore({super.key, required this.loading, required this.onLoadMore});
  final bool loading;
  final VoidCallback onLoadMore;

  @override
  State<_LoadMore> createState() => _LoadMoreState();
}

class _LoadMoreState extends State<_LoadMore> {
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(widget.onLoadMore);
  }

  @override
  void didUpdateWidget(_LoadMore old) {
    super.didUpdateWidget(old);
    // Same cursor, no longer loading: that page failed.
    if (old.loading && !widget.loading) {
      _retry?.cancel();
      _retry = Timer(const Duration(seconds: 3), () => widget.onLoadMore());
    }
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const ActivitySkeletonRow(index: 0);
}

/// A skeleton activity row (orb, two lines, cover).
class ActivitySkeletonRow extends StatelessWidget {
  const ActivitySkeletonRow({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: GlassFrame.screenMargin(context), vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GlassSkeleton(width: 32, height: 32, circle: true, index: index),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [GlassSkeleton(height: 16, index: index, radius: 6), const SizedBox(height: 8), GlassSkeleton(width: 120, height: 12, index: index, radius: 6)])),
          const SizedBox(width: 12),
          GlassSkeleton(width: 44, height: 66, radius: 8, index: index),
        ],),
      );
}

/// Six skeleton rows (the loading state).
class ActivitySkeleton extends StatelessWidget {
  const ActivitySkeleton({super.key});

  @override
  Widget build(BuildContext context) => GlassSkeletonGroup(label: 'Loading activity', child: Column(children: [for (var i = 0; i < 6; i++) ActivitySkeletonRow(index: i)]));
}

/// Keeps a stable [FocusNode] and a react trigger per row id (the `j`/`k`/`e`/`f` keys).
class RowHandles {
  final Map<String, FocusNode> _focus = {};
  final Map<String, ChangeNotifier> _react = {};
  final List<String> order = [];

  FocusNode focusOf(String id) => _focus.putIfAbsent(id, () => FocusNode(debugLabel: 'activity $id'));
  Listenable reactOf(String id) => _react.putIfAbsent(id, _Trigger.new);

  String? get focusedId {
    for (final id in order) {
      if (_focus[id]?.hasFocus ?? false) return id;
    }
    return null;
  }

  void move(int delta) {
    if (order.isEmpty) return;
    final cur = focusedId;
    final i = cur == null ? (delta > 0 ? 0 : order.length - 1) : (order.indexOf(cur) + delta).clamp(0, order.length - 1);
    final n = focusOf(order[i]);
    n.requestFocus();
    final c = n.context;
    if (c != null) unawaited(Scrollable.ensureVisible(c, alignment: 0.3, duration: const Duration(milliseconds: 200)));
  }

  void react() {
    final id = focusedId;
    if (id != null) (_react[id] as _Trigger?)?.fire();
  }

  void dispose() {
    for (final n in _focus.values) {
      n.dispose();
    }
    for (final t in _react.values) {
      t.dispose();
    }
  }
}

class _Trigger extends ChangeNotifier {
  void fire() => notifyListeners();
}
