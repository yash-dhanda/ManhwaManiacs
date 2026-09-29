import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/collections/providers/collections_provider.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/series_shelves_provider.dart';
import 'package:manhwamaniacs/features/library/utils/bulk_runner.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_checkbox.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// `ADD TO SHELF`: one checkbox row per collection; toggling adds or removes the series (haptic
/// `follow.add` and the `impress` cue on add). No shelves: "No shelves yet." and `New shelf`.
Future<void> showAddToShelfSheet(BuildContext context, {required String sourceId, required String seriesKey, required String title}) {
  final router = GoRouter.maybeOf(context);
  return showCineSheet<void>(
    context,
    kicker: 'ADD TO SHELF',
    title: title,
    builder: (ctx) => _ShelfList(sourceId: sourceId, seriesKey: seriesKey, onNewShelf: () {
      Navigator.of(ctx).pop();
      router?.go(Routes.collections());
    },),
  );
}

class _ShelfList extends ConsumerStatefulWidget {
  const _ShelfList({required this.sourceId, required this.seriesKey, required this.onNewShelf});
  final String sourceId, seriesKey;
  final VoidCallback onNewShelf;

  @override
  ConsumerState<_ShelfList> createState() => _ShelfListState();
}

class _ShelfListState extends ConsumerState<_ShelfList> {
  final Set<int> _busy = {};
  final Map<int, bool> _override = {};

  ({String sourceId, String seriesKey}) get _key => (sourceId: widget.sourceId, seriesKey: widget.seriesKey);

  Future<void> _toggle(Collection c, bool now) async {
    final repo = ref.read(libraryRepositoryProvider);
    setState(() {
      _busy.add(c.id);
      _override[c.id] = now;
    });
    final r = now
        ? await repo.addSeriesToCollection(c.id, sourceId: widget.sourceId, seriesKey: widget.seriesKey)
        : await repo.removeSeriesFromCollection(c.id, sourceId: widget.sourceId, seriesKey: widget.seriesKey);
    if (!mounted) return;
    if (r.isErr) {
      setState(() => _override[c.id] = !now);
      ref.read(cineToastsProvider.notifier).error("Couldn't update ${c.name}.");
    } else if (now) {
      cineFeedback(context, HapticEvent.followAdd, sound: SoundEvent.followAdd);
    }
    ref.invalidate(seriesShelvesProvider(_key));
    setState(() => _busy.remove(c.id));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final shelves = ref.watch(collectionsProvider);
    final member = ref.watch(seriesShelvesProvider(_key)).valueOrNull ?? const <CollectionRef>[];
    return shelves.when(
      loading: () => Padding(padding: EdgeInsets.all(c.space4), child: CineRoleText('Loading…', c.typeCaption, color: c.colorInk60)),
      error: (e, _) => Padding(
        padding: EdgeInsets.all(c.space4),
        child: Wrap(spacing: c.space3, crossAxisAlignment: WrapCrossAlignment.center, children: [
          CineRoleText("This row didn't load.", c.typeCaption, color: c.colorProof),
          CineButton(label: 'Retry', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: () => ref.invalidate(collectionsProvider)),
        ],),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(c.space4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CineRoleText('No shelves yet.', c.typeBodyItalic, color: c.colorInk60),
              SizedBox(height: c.space3),
              CineButton(label: 'New shelf', variant: CineButtonVariant.secondary, onPressed: widget.onNewShelf),
            ],),
          );
        }
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final shelf in list)
            Builder(builder: (_) {
              final on = _override[shelf.id] ?? member.any((m) => m.id == shelf.id);
              return CineRow(
                key: Key('shelf-${shelf.id}'),
                title: shelf.name,
                caption: '${shelf.seriesCount} series',
                trailing: CineCheckbox(value: on, semanticLabel: shelf.name, onChanged: _busy.contains(shelf.id) ? null : (v) => _toggle(shelf, v)),
                onTap: _busy.contains(shelf.id) ? null : () => _toggle(shelf, !on),
              );
            },),
        ],);
      },
    );
  }
}

/// `ADD TO SHELF` for a whole selection (select mode): choosing a shelf adds every selected series
/// to it, four requests at a time, and says how many landed.
Future<void> showAddSeriesToShelfSheet(BuildContext context, {required List<FollowedSeries> series}) {
  final router = GoRouter.maybeOf(context);
  return showCineSheet<void>(
    context,
    kicker: 'ADD TO SHELF',
    title: '${series.length} series',
    builder: (ctx) => _BulkShelfList(series: series, onNewShelf: () {
      Navigator.of(ctx).pop();
      router?.go(Routes.collections());
    },),
  );
}

class _BulkShelfList extends ConsumerStatefulWidget {
  const _BulkShelfList({required this.series, required this.onNewShelf});
  final List<FollowedSeries> series;
  final VoidCallback onNewShelf;

  @override
  ConsumerState<_BulkShelfList> createState() => _BulkShelfListState();
}

class _BulkShelfListState extends ConsumerState<_BulkShelfList> {
  final Set<int> _busy = {};
  final Set<int> _added = {};

  Future<void> _add(Collection shelf) async {
    final repo = ref.read(libraryRepositoryProvider);
    setState(() => _busy.add(shelf.id));
    final o = await runBulk<FollowedSeries>(widget.series, (s) async {
      final r = await repo.addSeriesToCollection(shelf.id, sourceId: s.sourceId, seriesKey: s.seriesKey);
      return r.isErr ? Err(r.error) : const Ok(null);
    });
    if (!mounted) return;
    final toasts = ref.read(cineToastsProvider.notifier);
    if (o.failed > 0) {
      toasts.error('${o.done} of ${o.total} added to ${shelf.name}, ${o.failed} failed.');
    } else {
      cineFeedback(context, HapticEvent.followAdd, sound: SoundEvent.followAdd);
      toasts.success('Added ${o.done} series to ${shelf.name}.');
      _added.add(shelf.id);
    }
    ref.invalidate(collectionsProvider);
    setState(() => _busy.remove(shelf.id));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final shelves = ref.watch(collectionsProvider);
    return shelves.when(
      loading: () => Padding(padding: EdgeInsets.all(c.space4), child: CineRoleText('Loading…', c.typeCaption, color: c.colorInk60)),
      error: (e, _) => Padding(
        padding: EdgeInsets.all(c.space4),
        child: Wrap(spacing: c.space3, crossAxisAlignment: WrapCrossAlignment.center, children: [
          CineRoleText("This row didn't load.", c.typeCaption, color: c.colorProof),
          CineButton(label: 'Retry', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: () => ref.invalidate(collectionsProvider)),
        ],),
      ),
      data: (list) => list.isEmpty
          ? Padding(
              padding: EdgeInsets.all(c.space4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CineRoleText('No shelves yet.', c.typeBodyItalic, color: c.colorInk60),
                SizedBox(height: c.space3),
                CineButton(label: 'New shelf', variant: CineButtonVariant.secondary, onPressed: widget.onNewShelf),
              ],),
            )
          : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final shelf in list)
                CineRow(
                  key: Key('bulk-shelf-${shelf.id}'),
                  title: shelf.name,
                  caption: '${shelf.seriesCount} series',
                  trailingFolio: _added.contains(shelf.id) ? 'ADDED' : null,
                  onTap: _busy.contains(shelf.id) ? null : () => _add(shelf),
                ),
            ],),
    );
  }
}
