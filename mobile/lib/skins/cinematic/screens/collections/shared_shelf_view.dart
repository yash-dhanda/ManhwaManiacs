import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_detail_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/shared_collections_provider.dart';
import 'package:manhwamaniacs/features/library/models/collection_detail.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart' show ShelfDensity;
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_avatar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_pull_to_reprint.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look_actions.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/collections/add_series_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/collections/collection_screen.dart' show CollectionHeader;
import 'package:manhwamaniacs/skins/cinematic/screens/library/shelf_wall.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// A shelf someone else owns (cinematic 9.3.5, 8.11): every row from the shelf's own title, cover
/// and ambient (never the viewer's library, never `NO LONGER FOLLOWED`), and the actions the role
/// allows, the rest hidden: `can_add` adds series from their own library, removes what they added
/// and leaves; `view_only` opens, reads and leaves.
class SharedShelfView extends ConsumerStatefulWidget {
  const SharedShelfView({super.key, required this.detail});
  final SharedShelfDetail detail;

  @override
  ConsumerState<SharedShelfView> createState() => _SharedShelfViewState();
}

class _SharedShelfViewState extends ConsumerState<SharedShelfView> {
  final _headerFocus = FocusNode(debugLabel: 'shared-shelf-header');

  SharedShelf get _shelf => widget.detail.shelf;

  @override
  void dispose() {
    _headerFocus.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    final name = _shelf.name;
    final ok = await showCineConfirm(
      context,
      title: 'Leave $name? It disappears from your Collections. The series stay in your library.',
      confirmLabel: 'Leave shelf',
      destructive: true,
      filled: true,
      onConfirm: () async {
        final r = await ref.read(circleRepositoryProvider).unshareMember(_shelf.id, 'me');
        if (r.isErr) throw r.error;
      },
    );
    if (!ok || !mounted) return;
    cineFeedback(context, HapticEvent.deleteConfirm);
    ref.read(cineToastsProvider.notifier).info('Left $name.');
    ref.invalidate(sharedCollectionsProvider);
    context.go(Routes.collections());
  }

  Future<void> _add() async {
    await showAddSeriesSheet(context, collectionId: _shelf.id, memberKeys: {for (final r in widget.detail.series) '${r.sourceId}\u0000${r.seriesKey}'});
    if (mounted) ref.invalidate(sharedShelfDetailProvider(_shelf.id));
  }

  Future<void> _remove(ShelfSeriesRow r) async {
    final res = await ref.read(libraryRepositoryProvider).removeSeriesFromCollection(_shelf.id, sourceId: r.sourceId, seriesKey: r.seriesKey);
    if (!mounted) return;
    if (res.isErr) {
      ref.read(cineToastsProvider.notifier).error("Couldn't remove ${r.title}.");
      return;
    }
    ref.invalidate(collectionDetailProvider(_shelf.id));
    ref.invalidate(sharedShelfDetailProvider(_shelf.id));
  }

  void _quickLook(ShelfSeriesRow r, {required bool mine}) {
    unawaited(openQuickLook(
      context,
      title: r.title,
      kicker: 'QUICK LOOK',
      heroTag: (r.sourceId, r.seriesKey),
      cover: const SizedBox.shrink(),
      credits: 'ON THIS SHELF',
      actions: [
        QuickLookAction(QuickLookId.open, 'Open', CineIconRole.external, onSelected: () => unawaited(context.push(Routes.feature(r.sourceId, r.seriesKey)))),
        if (mine) QuickLookAction('remove-from-shelf', 'Remove from shelf', CineIconRole.delete, destructive: true, onSelected: () => unawaited(_remove(r))),
      ],
    ),);
  }

  static Color? _hex(String? h) {
    if (h == null) return null;
    final s = h.startsWith('#') ? h.substring(1) : h;
    final n = s.length == 6 ? int.tryParse(s, radix: 16) : null;
    return n == null ? null : Color(0xFF000000 | n);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final grid = CineGrid.of(context);
    final base = ref.watch(apiBaseUrlProvider);
    final me = ref.watch(activeProfileProvider)?.id;
    final rows = widget.detail.series;
    final shelf = _shelf;
    final canAdd = shelf.role == 'can_add';
    final geo = ShelfGeometry.of(context, ShelfDensity.wall);
    final synthetic = CollectionDetail(id: shelf.id, name: shelf.name, description: shelf.description, seriesCount: rows.length, sortOrder: 0, series: const []);
    final covers = [for (final r in rows.take(4)) if (historyCoverUrl(base, r.coverUrl) case final u?) u];
    final by = shelf.owner == null ? '' : 'SHARED BY ${shelf.owner!.name.toUpperCase()} · ${canAdd ? 'CAN ADD' : 'VIEW ONLY'}';
    return CineScaffold(
      runningTitle: shelf.name,
      back: const CineBack(),
      firstRunNote: false,
      mastheadFocusNode: _headerFocus,
      body: CinePullToReprint(
        onRefresh: () async {
          ref.invalidate(sharedShelfDetailProvider(shelf.id));
          try {
            await ref.read(sharedShelfDetailProvider(shelf.id).future);
          } catch (_) {}
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 48),
          children: [
            CollectionHeader(detail: synthetic, covers: covers, duo: _hex(shelf.previewAmbientDuo), tint: null, count: rows.length, focus: _headerFocus, credits: by),
            Padding(
              padding: EdgeInsets.fromLTRB(grid.left, c.space4, grid.right, 0),
              child: Wrap(spacing: c.space2, runSpacing: c.space2, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (canAdd) CineButton(key: const Key('shared-add'), label: 'Add series', variant: CineButtonVariant.secondary, onPressed: () => unawaited(_add())),
                Builder(
                  builder: (ctx) => CineButton(
                    key: const Key('shared-more'),
                    label: 'More',
                    variant: CineButtonVariant.quiet,
                    onPressed: () => unawaited(showCineMenu<Object?>(ctx, anchor: cineAnchorRect(ctx), entries: [
                      CineMenuEntry<Object?>(label: 'Leave shelf', destructive: true, onSelected: () => unawaited(_leave())),
                    ],),),
                  ),
                ),
              ],),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(grid.left, c.space4, grid.right, 0),
              child: rows.isEmpty
                  ? CineNotice(key: const Key('shared-empty'), tone: CineNoticeTone.empty, kicker: 'EMPTY SHELF', headline: 'This shelf is empty.', deck: canAdd ? null : 'Nothing has been added to it yet.', primary: canAdd ? CineNoticeAction('Add series', () => unawaited(_add())) : null)
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: geo.delegate,
                      itemCount: rows.length,
                      itemBuilder: (ctx, i) {
                        final r = rows[i];
                        final mine = canAdd && r.addedByProfileId != null && r.addedByProfileId == me;
                        return Stack(clipBehavior: Clip.none, children: [
                          CinePoster(
                            key: ValueKey('shared-row-${r.sourceId}-${r.seriesKey}'),
                            title: r.title,
                            url: historyCoverUrl(base, r.coverUrl),
                            duo: r.ambient?.duo,
                            flickerIndex: i,
                            onTap: () => unawaited(context.push(Routes.feature(r.sourceId, r.seriesKey))),
                            onQuickLook: () => _quickLook(r, mine: mine),
                          ),
                          if (r.addedBy != null) Positioned(left: 4, bottom: 44, child: IgnorePointer(child: CineAvatar(avatarKey: r.addedBy!.avatarKey, size: 20, semanticName: 'Added by ${r.addedBy!.name}'))),
                        ],);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
