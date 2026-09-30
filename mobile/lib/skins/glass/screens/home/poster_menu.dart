import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/collections/providers/collections_provider.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart' show Collection;
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/context_menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/continue_with_recap.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Everything a series' long-press menu on Home needs.
class SeriesMenuSpec {
  const SeriesMenuSpec({required this.sourceId, required this.seriesKey, required this.title, this.coverUrl, this.target, this.readNumber, this.novel = false, this.showContinue = true, this.showMarkRead = true, this.showDownload = true});
  final String sourceId, seriesKey, title;
  final String? coverUrl;

  /// What Continue and Previously on act on; null for a series the reader has no progress in.
  final HomeContinueTarget? target;
  final double? readNumber;
  final bool novel;
  final bool showContinue, showMarkRead, showDownload;
}

Future<void> _collectionsMenu(BuildContext context, WidgetRef ref, SeriesMenuSpec s, Rect anchor) async {
  List<Collection> cols;
  try {
    cols = await ref.read(collectionsProvider.future);
  } catch (_) {
    cols = const [];
  }
  if (!context.mounted) return;
  if (cols.isEmpty) {
    unawaited(ref.read(skinRouterProvider).push<void>(Routes.collections()));
    return;
  }
  await showGlassMenu(
    context,
    anchor: anchor,
    title: 'Add to collection',
    entries: [
      for (final c in cols.take(12))
        GlassMenuEntry(
          label: c.name,
          onSelected: () => unawaited(() async {
            final r = await ref.read(libraryRepositoryProvider).addSeriesToCollection(c.id, sourceId: s.sourceId, seriesKey: s.seriesKey);
            if (r is Ok) {
              glassFire(ref, HapticEvent.followAdd);
              showGlassToast(ref, GlassToastSpec('Added to ${c.name}', kind: GlassToastKind.success));
            } else {
              showGlassToast(ref, const GlassToastSpec("Couldn't add that", kind: GlassToastKind.error));
            }
          }()),
        ),
    ],
  );
}

/// The entries of a poster's or a stack's menu (glass 8.8, poster menu), in the spec order; [first] rows come before them (Continue's
/// menu opens with "Previously on").
List<GlassMenuEntry> seriesMenuEntries(BuildContext context, WidgetRef ref, SeriesMenuSpec s, Rect from, {List<GlassMenuEntry> first = const [], List<GlassMenuEntry> extra = const []}) {
  final hasProgress = s.target != null;
  return [
    ...first,
    if (s.showContinue && s.target != null)
      GlassMenuEntry(label: 'Continue', onSelected: () => unawaited(continueWithRecap(context, ref, s.target!, from))),
    GlassMenuEntry(label: 'Details', onSelected: () => unawaited(openSeries(ref, s.sourceId, s.seriesKey, from: from))),
    GlassMenuEntry(label: 'Add to collection', onSelected: () => unawaited(_collectionsMenu(context, ref, s, from))),
    if (s.showMarkRead) GlassMenuEntry(label: 'Mark read', onSelected: () => unawaited(markSeriesRead(ref, sourceId: s.sourceId, seriesKey: s.seriesKey, upTo: s.readNumber))),
    if (s.showDownload) GlassMenuEntry(label: 'Download next 10', onSelected: () => unawaited(downloadNextTen(ref, sourceId: s.sourceId, seriesKey: s.seriesKey, title: s.title, readNumber: s.readNumber, novel: s.novel))),
    if (hasProgress && first.every((e) => e.label != 'Previously on'))
      GlassMenuEntry(label: 'Previously on', onSelected: () => unawaited(openRecap(ref, s.sourceId, s.seriesKey, s.target!.recap?.toKey ?? s.target!.chapterKey, from: from))),
    if (recommendSheetRegistered) GlassMenuEntry(label: 'Recommend to…', onSelected: () => openRecommendSheet(ref, s.sourceId, s.seriesKey)),
    ...extra,
  ];
}

/// Opens the poster menu over [from] with the cover lifted as its preview.
Future<void> showSeriesMenu(BuildContext context, WidgetRef ref, SeriesMenuSpec s, Rect from, {List<GlassMenuEntry> first = const [], List<GlassMenuEntry> extra = const []}) =>
    showGlassContextMenu(
      context,
      sourceRect: from,
      preview: ClipRRect(borderRadius: BorderRadius.circular(14), child: HomeCoverImage(url: s.coverUrl, width: from.width)),
      kind: GlassPreviewKind.poster,
      title: s.title,
      entries: seriesMenuEntries(context, ref, s, from, first: first, extra: extra),
    );
