import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/collections/providers/shared_collections_provider.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cards/cine_collection_plate.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/circle_states.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The plate of a shared shelf: the shelf's own mosaic, `N SERIES · SHARED`, the members' avatars.
class SharedShelfPlate extends ConsumerWidget {
  const SharedShelfPlate({super.key, required this.shelf, this.focusNode});
  final SharedShelf shelf;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(apiBaseUrlProvider);
    final avatars = <String>[
      if (shelf.role != 'owner' && shelf.owner?.avatarKey != null) shelf.owner!.avatarKey!,
      for (final m in shelf.shared?.members ?? const <ProfileRef>[])
        if (m.avatarKey != null) m.avatarKey!,
    ];
    final credit = '${shelf.seriesCount} SERIES · SHARED${shelf.role == 'owner' ? '' : shelf.role == 'can_add' ? ' · CAN ADD' : ' · VIEW ONLY'}';
    return CineCollectionPlate(
      name: shelf.name,
      credit: credit,
      coverUrls: [for (final u in shelf.previewCovers) if (historyCoverUrl(base, u) case final r?) r],
      sharedWith: avatars,
      focusNode: focusNode,
      menuOnLongPress: false,
      onTap: () => unawaited(context.push(Routes.collection(shelf.id))),
    );
  }
}

/// SHELVES: the shelves shared with the viewer and the viewer's own shared shelves, as plates.
class ShelvesTab extends ConsumerWidget {
  const ShelvesTab({super.key, required this.leadingSlivers});
  final List<Widget> leadingSlivers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sharedCollectionsProvider);
    final grid = CineGrid.of(context);
    final c = context.cine;
    final data = async.valueOrNull;
    if (data == null) {
      return CustomScrollView(slivers: [
        ...leadingSlivers,
        SliverToBoxAdapter(child: async.hasError ? CircleErrorNotice(error: async.error!, onRetry: () => ref.invalidate(sharedCollectionsProvider)) : const CircleGalley(count: 3)),
      ],);
    }
    final shelves = [...data.sharedWithMe, for (final s in data.collections) if (s.shared != null) s];
    if (shelves.isEmpty) {
      return CustomScrollView(slivers: [
        ...leadingSlivers,
        SliverToBoxAdapter(
          child: CircleTabEmpty(text: CircleCopy.emptyShelves, action: CircleCopy.newShelf, onAction: () => unawaited(context.push(Routes.collections({'sheet': SheetIds.collectionNew, 'view': 'shared'})))),
        ),
      ],);
    }
    final cols = MediaQuery.sizeOf(context).width >= 600 ? 3 : 1;
    return CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
      ...leadingSlivers,
      SliverPadding(
        padding: EdgeInsets.fromLTRB(grid.left, c.space4, grid.right, 96),
        sliver: SliverGrid.count(
          crossAxisCount: cols,
          mainAxisSpacing: c.space4,
          crossAxisSpacing: grid.gutter,
          childAspectRatio: 16 / 10,
          children: [for (final s in shelves) SharedShelfPlate(key: ValueKey('shelf-${s.id}'), shelf: s)],
        ),
      ),
    ],);
  }
}
