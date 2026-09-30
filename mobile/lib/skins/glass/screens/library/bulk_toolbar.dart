import 'dart:async';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/collections/providers/collections_provider.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart' show Collection;
import 'package:manhwamaniacs/features/library/utils/bulk_runner.dart' show BulkCancel;
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart' show GlassGlyph;
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart' show GlassGlyph28;
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/bulk_toolbar.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/floating_bar.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/select_mode.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/shelf_actions.dart';

/// A [BulkCancel] that follows a [CancelToken] (the floating toolbar's Stop).
BulkCancel _cancelOf(CancelToken t) {
  final c = BulkCancel();
  unawaited(t.whenCancel.then((_) => c.stop()));
  return c;
}

/// The Shelf's bulk toolbar (glass 7.35, 8.17): Favourite, Unfavourite, Mark read, Mark unread, Add to collection, Download next 10 and
/// Remove from library, on the floating bar in the accessory slot. Bulk concurrency is 4; the fill moves once per 4 series.
class GlassShelfBulkBar extends ConsumerWidget {
  const GlassShelfBulkBar({super.key, required this.controller});
  final GlassSelectModeController<int> controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.read(glassShelfActionsProvider);
    Future<BulkResult> pickCollection(Set<int> ids) async {
      List<Collection> cols;
      try {
        cols = await ref.read(collectionsProvider.future);
      } catch (_) {
        cols = const [];
      }
      if (!context.mounted || cols.isEmpty) return BulkResult(ok: 0, failed: [for (final i in ids) '$i']);
      final done = Completer<Collection?>();
      await showGlassMenu(
        context,
        anchor: globalRectOf(context),
        title: 'Add to collection',
        entries: [for (final c in cols.where((c) => c.rules == null).take(12)) GlassMenuEntry(label: c.name, onSelected: () => done.complete(c))],
        onClosed: () {
          if (!done.isCompleted) done.complete(null);
        },
      );
      final chosen = await done.future;
      if (chosen == null) return const BulkResult(ok: 0);
      await a.addToCollection(a.rowsOf(ids), chosen);
      return BulkResult(ok: ids.length);
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => GlassFloatingBar(
        visible: controller.active,
        child: GlassBulkToolbar<int>(
          controller: controller,
          chunk: 4,
          actions: [
            BulkAction<int>(id: 'favourite', label: 'Favourite', glyph: roleIcon(GlassIconRole.favourite, GlassIconWeight.fill), verb: 'favourited', run: (ids, c) => a.setFavourite(ids, true, cancel: _cancelOf(c))),
            BulkAction<int>(id: 'unfavourite', label: 'Unfavourite', glyph: roleIcon(GlassIconRole.favourite), verb: 'unfavourited', run: (ids, c) => a.setFavourite(ids, false, cancel: _cancelOf(c))),
            BulkAction<int>(id: 'mark-read', label: 'Mark read', glyph: GlassGlyph.check.regular, verb: 'marked read', run: (ids, c) => a.markRead(ids, cancel: _cancelOf(c)), undo: a.undoMarkRead),
            BulkAction<int>(id: 'mark-unread', label: 'Mark unread', glyph: GlassGlyph28.arrowCounterClockwise.regular, verb: 'marked unread', run: (ids, c) => a.markUnread(ids, cancel: _cancelOf(c)), undo: a.undoMarkUnread),
            BulkAction<int>(id: 'collection', label: 'Add to collection', glyph: GlassGlyph28.stack.regular, verb: 'added', run: (ids, c) => pickCollection(ids)),
            BulkAction<int>(id: 'download', label: 'Download next 10', glyph: roleIcon(GlassIconRole.download), verb: 'queued', run: (ids, c) => a.downloadNextTen(ids, cancel: _cancelOf(c))),
            BulkAction<int>(id: 'remove', label: 'Remove from library', glyph: roleIcon(GlassIconRole.delete), destructive: true, verb: 'removed', run: (ids, c) => a.unfollow(ids, cancel: _cancelOf(c)), undo: a.undoUnfollow),
          ],
        ),
      ),
    );
  }
}
