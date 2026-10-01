import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/collections/providers/collections_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/shared_collections_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// What a viewer may do on a shelf (glass 9.3.3): the owner everything; `can_add` adds and removes their own additions (and
/// others' after a confirm); `view_only` nothing but Save a copy and Leave shelf.
class ShelfRights {
  const ShelfRights(this.role);
  final String role;

  bool get owner => role == 'owner';
  bool get canAdd => owner || role == 'can_add';
  bool get canEdit => owner;
  bool get canReorder => owner;
  bool get canDelete => owner;
  bool get canRemove => canAdd;
  bool get canLeave => !owner;
  bool get canSaveCopy => !owner;
  bool get canShare => owner;
}

/// "Remove {title}? Aarav added it." before removing someone else's addition; true to go ahead.
Future<bool> confirmRemoveAddition(BuildContext context, {required String title, required ProfileRef? adder, required int? viewerProfileId}) async {
  if (adder == null || adder.profileId == viewerProfileId) return true;
  final r = await showGlassAlert<bool>(
    context,
    title: 'Remove $title? ${adder.name} added it.',
    actions: const [
      GlassAlertAction<bool>('Keep', role: GlassAlertRole.cancel, value: false),
      GlassAlertAction<bool>('Remove', role: GlassAlertRole.destructive, value: true),
    ],
  );
  return r ?? false;
}

/// Leave shelf (glass 9.3.3): the alert, then `DELETE /library/collections/{id}/share/me` (the path the handler serves; it also
/// takes a numeric profile id) and the toast "You left {name}". Returns whether the viewer left.
Future<bool> leaveShelf(BuildContext context, WidgetRef ref, SharedShelf shelf) async {
  final owner = shelf.owner?.name ?? 'The owner';
  final go = await showGlassAlert<bool>(
    context,
    title: 'Leave ${shelf.name}?',
    body: 'It disappears from your Collections; $owner keeps it.',
    actions: const [
      GlassAlertAction<bool>('Stay', role: GlassAlertRole.cancel, value: false),
      GlassAlertAction<bool>('Leave', role: GlassAlertRole.destructive, value: true),
    ],
  );
  if (go != true) return false;
  final r = await ref.read(circleRepositoryProvider).unshareMember(shelf.id, 'me');
  final toasts = ref.read(glassToastProvider.notifier);
  if (r.isErr) {
    glassFire(ref, HapticEvent.error);
    toasts.show(GlassToastSpec("Couldn't leave ${shelf.name}", kind: GlassToastKind.error));
    return false;
  }
  ref
    ..invalidate(sharedCollectionsProvider)
    ..invalidate(sharedShelfDetailProvider(shelf.id));
  toasts.show(GlassToastSpec('You left ${shelf.name}', kind: GlassToastKind.success));
  return true;
}

/// Save a copy: a new collection with the same members the viewer can see, then "Saved a copy".
Future<bool> saveShelfCopy(WidgetRef ref, SharedShelfDetail d) async {
  final repo = ref.read(libraryRepositoryProvider);
  final toasts = ref.read(glassToastProvider.notifier);
  final made = await repo.createCollection(name: d.shelf.name, description: d.shelf.description);
  if (made.isErr) {
    toasts.show(const GlassToastSpec("Couldn't save a copy", kind: GlassToastKind.error));
    return false;
  }
  for (final s in d.series) {
    await repo.addSeriesToCollection(made.value.id, sourceId: s.sourceId, seriesKey: s.seriesKey);
  }
  ref
    ..invalidate(collectionsProvider)
    ..invalidate(sharedCollectionsProvider);
  toasts.show(const GlassToastSpec('Saved a copy', kind: GlassToastKind.success));
  return true;
}

/// The shelf's ⋯ entries for a member (view only: Save a copy, Leave shelf; can add: Add series, Leave shelf) or the owner
/// (Share). [onAddSeries] is the collection screen's own add flow.
List<GlassMenuEntry> sharedShelfMenu(BuildContext context, WidgetRef ref, SharedShelfDetail d, {VoidCallback? onAddSeries}) {
  final r = ShelfRights(d.shelf.role);
  return [
    if (r.canShare) GlassMenuEntry(label: 'Share', onSelected: () => ref.read(skinRouterProvider).go(Routes.collection(d.shelf.id, {'sheet': 'collection-share'}))),
    if (!r.owner && r.canAdd && onAddSeries != null) GlassMenuEntry(label: 'Add series', onSelected: onAddSeries),
    if (r.canSaveCopy) GlassMenuEntry(label: 'Save a copy', onSelected: () => unawaited(saveShelfCopy(ref, d))),
    if (r.canLeave) GlassMenuEntry(label: 'Leave shelf', destructive: true, onSelected: () => unawaited(leaveShelf(context, ref, d.shelf))),
  ];
}
