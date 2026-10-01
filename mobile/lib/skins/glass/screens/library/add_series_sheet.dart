import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_detail_provider.dart';
import 'package:manhwamaniacs/features/library/models/collection_detail.dart' show CollectionSeriesRef;
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/row_shell.dart';
import 'package:manhwamaniacs/skins/glass/primitives/search_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart';

/// Where the collection page's header stack sits (global), so a Cover arc has somewhere to land. Set by the collection page.
final collectionHeaderRectProvider = StateProvider<Rect?>((ref) => null, name: 'collectionHeaderRect');

/// `?sheet=add-series&collection={id}` (large): a search well and the followed series not already in the collection.
final GlassSheetSpec glassAddSeriesSheetSpec = GlassSheetSpec(
  title: 'Add series',
  builder: (context) => GlassAddSeriesBody(collectionId: int.tryParse(sheetParams(context)['collection'] ?? '') ?? 0),
  opening: GlassDetent.large,
);

class GlassAddSeriesBody extends ConsumerStatefulWidget {
  const GlassAddSeriesBody({super.key, required this.collectionId});
  final int collectionId;

  @override
  ConsumerState<GlassAddSeriesBody> createState() => _GlassAddSeriesBodyState();
}

class _GlassAddSeriesBodyState extends ConsumerState<GlassAddSeriesBody> {
  final TextEditingController _search = TextEditingController();
  String _q = '';
  final Set<String> _adding = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _add(FollowedSeries s, Rect from) async {
    final key = '${s.sourceId}|${s.seriesKey}';
    if (!_adding.add(key)) return;
    final to = ref.read(collectionHeaderRectProvider);
    if (to != null && from != Rect.zero) unawaited(flyCover(context, from: from, to: to, cover: HomeCoverImage(url: s.coverUrl, width: 36)));
    unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.followAdd));
    final err = await ref.read(collectionDetailProvider(widget.collectionId).notifier).addSeries(sourceId: s.sourceId, seriesKey: s.seriesKey);
    if (!mounted) return;
    _adding.remove(key);
    if (err != null) showGlassToast(ref, GlassToastSpec("Couldn't add ${s.title}", kind: GlassToastKind.error));
  }

  @override
  Widget build(BuildContext context) {
    final on = sheetOnGlass(context);
    final followed = ref.watch(librarySeriesPickerProvider);
    final detail = ref.watch(collectionDetailProvider(widget.collectionId)).valueOrNull;
    final members = {for (final m in detail?.series ?? const <CollectionSeriesRef>[]) '${m.sourceId}|${m.seriesKey}'};
    final all = followed.valueOrNull ?? const <FollowedSeries>[];
    final avail = [
      for (final s in all)
        if (!members.contains('${s.sourceId}|${s.seriesKey}') && (_q.isEmpty || s.title.toLowerCase().contains(_q.toLowerCase()))) s,
    ];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: GlassSearchField(variant: GlassSearchVariant.filter, controller: _search, placeholder: 'Search your library', onQuery: (v) => setState(() => _q = v.trim())),
      ),
      Expanded(
        child: avail.isEmpty
            ? Center(child: GlassObjectLens(situation: all.isEmpty || _q.isEmpty ? LensSituation.collection : LensSituation.nothingFound, title: _q.isEmpty ? 'No series available' : 'No series match your search', placement: GlassLensPlacement.inline))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: avail.length,
                itemBuilder: (context, i) {
                  final s = avail[i];
                  return Builder(
                    builder: (context) => GlassRowShell(
                      semanticsLabel: 'Add ${s.title}',
                      minHeight: 66,
                      onTap: () => unawaited(_add(s, globalRectOf(context))),
                      builder: (context, stacked, info) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(width: 36, height: 54, child: HomeCoverImage(url: s.coverUrl, width: 36))),
                          const SizedBox(width: 12),
                          Expanded(child: GlassLabel(s.title, role: gt.typeBody, onGlass: on, maxLines: 2)),
                        ],),
                      ),
                    ),
                  );
                },
              ),
      ),
    ],);
  }
}

/// Cover arc (glass 4.10): a 36 x 54 copy of the cover flies 420 ms on a parabola from [from] into [to] (the header stack) and lands on
/// `springTick`. Reduced motion: a 150 ms fade at the destination.
Future<void> flyCover(BuildContext context, {required Rect from, required Rect to, required Widget cover}) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final c = AnimationController(vsync: Navigator.of(context), duration: const Duration(milliseconds: 420));
  final arc = math.max(60.0, (from.center - to.center).distance * 0.25);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(c.value);
        final p = Offset.lerp(from.center, to.center, t)! - Offset(0, arc * 4 * t * (1 - t));
        return Positioned(left: p.dx - 18, top: p.dy - 27, width: 36, height: 54, child: IgnorePointer(child: Opacity(opacity: 1 - 0.3 * t, child: ClipRRect(borderRadius: BorderRadius.circular(6), child: cover))));
      },
    ),
  );
  overlay.insert(entry);
  try {
    await GlassMotion.play(MotionName.coverArc, controller: c, target: 1);
  } finally {
    entry.remove();
    c.dispose();
  }
}
