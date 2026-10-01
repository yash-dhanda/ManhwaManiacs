import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart';
import 'package:manhwamaniacs/features/auth/providers/session_offline_provider.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_selection.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/utils/continue_hidden.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/library_series_actions.dart';
import 'package:manhwamaniacs/features/library/utils/mark_read.dart';
import 'package:manhwamaniacs/features/recap/models/recap_origin.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/library/utils/series_chapter_sort.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/series_content_kind.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/add_to_shelf_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/pass_it_on_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/source_picker_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look_actions.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/recap/continue_to.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:url_launcher/url_launcher.dart';

/// The per-item Quick look action builders (cinematic 7.22), shared by Tonight and, later,
/// Library, History and the rest. Each takes the [ReaderEntry] its `Continue` uses: Tonight passes
/// `wipe`, every other caller `dip` (cinematic 8.14.2). The action ids, labels and icons are
/// `quick_look_actions.dart`'s; nothing here is a second list.

String? _abs(WidgetRef ref, String? url) => url == null || url.isEmpty ? null : resolveApiResourceUrl(ref.read(apiBaseUrlProvider), url);

Widget _cover(WidgetRef ref, String? url, String title) => CineImage(url: _abs(ref, url), title: title);

String _chapterLabel(double? n) => n == null ? '' : ' ${n % 1 == 0 ? n.toInt() : n}';

/// The chapter `Continue` opens for a followed series: the furthest one opened, else the first.
String? continueChapterKey(FollowedSeries s) => s.readState?.chapterKey ?? (s.knownChapters.isEmpty ? null : s.knownChapters.first.key);

/// The reader target of [chapterKey] for a source of [kind] (manga reader or novel reader).
ReaderTarget readerTargetFor(String sourceId, String seriesKey, String chapterKey, {required bool novel}) =>
    novel ? ReaderTarget.novel(sourceId, seriesKey, chapterKey) : ReaderTarget.manifest(sourceId, seriesKey, chapterKey);

/// Whether the Circle has members to recommend to (`Recommend to…` renders only then).
bool _hasCircle(WidgetRef ref) => (ref.read(circleMembersProvider).valueOrNull ?? const []).isNotEmpty;

bool _novel(WidgetRef ref, String sourceId) => isNovelSource(ref.read(contentModeScopeProvider), sourceId) ?? false;

/// Open the reader on [chapterKey] with [entry], warming the chapter first. Screens call
/// `continueTo` (`recap/continue_to.dart`), which opens a recap first when the setting asks.
void openReaderAt(BuildContext context, WidgetRef ref, String sourceId, String seriesKey, String chapterKey, {required ReaderEntry entry, bool replace = false}) {
  final target = readerTargetFor(sourceId, seriesKey, chapterKey, novel: _novel(ref, sourceId));
  readerPrefetchOf(ref).onPress(target);
  enterReader(context, target, entry: entry, replace: replace);
}

/// The recap takeover for `to`; [origin] says how it leaves (Column wipe, Dip, or back to the page).
void openRecap(BuildContext context, String sourceId, String seriesKey, String chapterKey, {RecapEntry origin = RecapEntry.wipe}) {
  final router = GoRouter.of(context);
  unawaited(router.push<void>(Routes.recap(sourceId, seriesKey, {'to': chapterKey}), extra: RecapOrigin(origin, returnTo: cineLocationOf(router))));
}

RecapEntry _origin(ReaderEntry e) => e == ReaderEntry.wipe ? RecapEntry.wipe : RecapEntry.dip;

/// The feature page by the match cut.
void openSeries(BuildContext context, String sourceId, String seriesKey) => unawaited(context.push<void>(Routes.feature(sourceId, seriesKey)));

/// A world or source pick: the feature page when the reader's sources carry it, a source picker
/// when several do, else Discover with `?q={title}`.
void openPick(BuildContext context, HomePickItem item) {
  final w = item.world;
  if (w == null) {
    openSeries(context, item.source!.sourceId, item.source!.id);
    return;
  }
  if (w.available.length > 1) {
    unawaited(showSourcePickerSheet(context, title: w.title, sources: w.available, onOpen: (s) => openSeries(context, s.sourceId, s.seriesKey)));
  } else if (w.available.length == 1) {
    openSeries(context, w.available.first.sourceId, w.available.first.seriesKey);
  } else {
    context.go(Routes.discover({'q': w.title}));
  }
}

Future<void> _markRead(BuildContext context, WidgetRef ref, HomeContinueItem item) async {
  final r = item.row;
  final repo = ref.read(readerRepositoryProvider);
  final done = await repo.saveProgressBatch(manualReadRows([
    (sourceId: r.sourceId, seriesKey: r.seriesKey, chapterKey: r.chapterKey, chapterNumber: r.chapterNumber, pageCount: r.pageCount, completed: false),
  ]),);
  final toasts = ref.read(cineToastsProvider.notifier);
  if (done.isErr) {
    toasts.error("Couldn't mark it read.");
    return;
  }
  if (context.mounted) cineFeedback(context, HapticEvent.select, sound: SoundEvent.select);
  toasts.undo(
    'Marked chapter${_chapterLabel(r.chapterNumber)} read.',
    onUndo: () => unawaited(repo.deleteProgress(sourceId: r.sourceId, seriesKey: r.seriesKey, chapterKeys: [r.chapterKey])),
  );
}

/// A Continue reading cutting: Open series, Continue, Previously on, Mark read, Remove from row.
Future<void> openCuttingQuickLook(BuildContext context, WidgetRef ref, HomeContinueItem item, {required ReaderEntry entry, Object? heroTag}) {
  final r = item.row;
  final title = r.title ?? 'This series';
  final offline = ref.read(sessionOfflineProvider);
  return openQuickLook(
    context,
    title: title,
    kicker: 'QUICK LOOK',
    credits: 'CH${_chapterLabel(r.chapterNumber)}',
    heroTag: heroTag,
    cover: _cover(ref, r.coverUrl, title),
    actions: quickLookActions({
      QuickLookId.open: () => openSeries(context, r.sourceId, r.seriesKey),
      if (_hasCircle(ref)) QuickLookId.recommend: () => unawaited(showPassItOnSheet(context, sourceId: r.sourceId, seriesKey: r.seriesKey, title: title, coverUrl: r.coverUrl)),
      QuickLookId.continueReading: () => unawaited(continueTo(context, ref, sourceId: r.sourceId, seriesKey: r.seriesKey, chapterKey: r.chapterKey, title: title, lastReadAt: r.lastReadAt, recap: item.recap, origin: _origin(entry))),
      if (item.recap?.available ?? false) QuickLookId.previouslyOn: () => openRecap(context, r.sourceId, r.seriesKey, r.chapterKey, origin: _origin(entry)),
      if (!offline) QuickLookId.markRead: () => unawaited(_markRead(context, ref, item)),
      QuickLookId.removeFromRow: () {
        hideContinue(ref.read, r);
        ref.read(cineToastsProvider.notifier).action('Removed from Continue reading.', label: 'Undo', onAction: () {
          unhideContinue(ref.read, r);
          if (context.mounted) cineFeedback(context, HapticEvent.undo, sound: SoundEvent.undo);
        },);
      },
    }),
  );
}

/// The next five unread chapters of a followed series, queued for download.
Future<void> downloadNextFive(BuildContext context, WidgetRef ref, FollowedSeries s, {bool haptic = true}) async {
  final key = (sourceId: s.sourceId, seriesId: s.seriesKey);
  final detail = await ref.read(sourceSeriesDetailProvider(key).future);
  // Where the server says the reader is (the same readState Glass plans from), not the device-local
  // Sources-tab map, which the library reader never writes; saved or queued chapters are skipped.
  final readNumber = s.readState?.chapterNumber;
  final saved = await savedOrQueuedChapterKeys(ref.read(downloadsStoreProvider), (sourceId: s.sourceId, seriesKey: s.seriesKey));
  final ordered = sortSeriesChapters(detail.chapters, numberOf: (c) => c.number, order: SeriesChapterSortOrder.oldest);
  final byKey = {for (final c in ordered) c.id: c};
  final unread = [
    for (final k in nextUnreadUndownloadedKeys([
      for (final c in ordered) (key: c.id, number: c.number, title: c.title, isRead: readNumber != null && c.number != null && c.number! <= readNumber, isDownloaded: saved.contains(c.id)),
    ], count: 5,))
      byKey[k]!,
  ];
  if (unread.isEmpty) return;
  final novel = _novel(ref, s.sourceId);
  if (haptic && context.mounted) cineFeedback(context, HapticEvent.downloadStart);
  await ref.read(downloadQueueControllerProvider.notifier).enqueueChapters([
    for (final c in unread)
      (
        id: (sourceId: s.sourceId, seriesKey: s.seriesKey, chapterKey: c.id),
        chapterNumber: c.number,
        title: c.title,
        seriesTitle: s.title,
        kind: novel ? DownloadKind.novel : DownloadKind.manga,
      ),
  ]);
}

/// A followed poster: Open, Continue, Previously on, Add to collection, Favourite, Download next 5,
/// Unfollow. [recapFirst] puts Previously on first (Where were we?).
Future<void> openFollowedQuickLook(BuildContext context, WidgetRef ref, HomeSeriesItem item, {required ReaderEntry entry, bool recapFirst = false, Object? heroTag}) {
  final s = item.series;
  final chapter = continueChapterKey(s);
  final canRecap = (item.recap?.available ?? false) && chapter != null;
  final actions = quickLookActions({
    QuickLookId.open: () => openSeries(context, s.sourceId, s.seriesKey),
    if (chapter != null) QuickLookId.continueReading: () => unawaited(continueTo(context, ref, sourceId: s.sourceId, seriesKey: s.seriesKey, chapterKey: chapter, title: s.title, lastReadAt: item.lastReadAt ?? s.readState?.lastReadAt, recap: item.recap, origin: _origin(entry))),
    if (canRecap) QuickLookId.previouslyOn: () => openRecap(context, s.sourceId, s.seriesKey, chapter, origin: _origin(entry)),
    QuickLookId.addToCollection: () => unawaited(showAddToShelfSheet(context, sourceId: s.sourceId, seriesKey: s.seriesKey, title: s.title)),
    if (_hasCircle(ref)) QuickLookId.recommend: () => unawaited(showPassItOnSheet(context, sourceId: s.sourceId, seriesKey: s.seriesKey, title: s.title, coverUrl: s.coverUrl)),
    QuickLookId.favourite: () async {
      final err = await ref.read(librarySeriesActionsProvider).setFavorite(s, favorite: !s.isFavorite);
      if (err != null) {
        ref.read(cineToastsProvider.notifier).error("Couldn't update the favourite.");
      } else if (context.mounted) {
        cineFeedback(context, HapticEvent.favorite, sound: SoundEvent.favorite);
      }
    },
    QuickLookId.downloadNext: () => unawaited(downloadNextFive(context, ref, s)),
    QuickLookId.unfollow: () async {
      final actionsProvider = ref.read(librarySeriesActionsProvider);
      final removed = await actionsProvider.remove(s);
      final toasts = ref.read(cineToastsProvider.notifier);
      if (removed.error != null) {
        toasts.error("Couldn't remove ${s.title}.");
        return;
      }
      toasts.action('Removed ${s.title}.', label: 'Undo', onAction: () => unawaited(actionsProvider.restore(s, slots: removed.slots)));
    },
  });
  final ordered = recapFirst && canRecap
      ? [actions.firstWhere((a) => a.id == QuickLookId.previouslyOn), ...actions.where((a) => a.id != QuickLookId.previouslyOn)]
      : actions;
  return openQuickLook(
    context,
    title: s.title,
    heroTag: heroTag,
    cover: _cover(ref, s.coverUrl, s.title),
    credits: item.chaptersLeft == null ? null : '${item.chaptersLeft} left',
    actions: ordered,
  );
}

/// A world or source pick: Open, Not for me, and for information-only titles Search my sources and
/// Read on {site}. [onNotForMe] lets the rail drop the poster (it fades over 240 ms).
Future<void> openPickQuickLook(BuildContext context, WidgetRef ref, HomePickItem item, {required ReaderEntry entry, VoidCallback? onNotForMe, Object? heroTag}) {
  final container = ProviderScope.containerOf(context, listen: false);
  final w = item.world;
  final title = item.title;
  final info = w != null && w.available.isEmpty;
  final site = w?.readElsewhere;
  final actions = quickLookActions({
    if (!info) QuickLookId.open: () => openPick(context, item),
    if (!info && _hasCircle(ref)) QuickLookId.recommend: () => unawaited(showPassItOnSheet(context, sourceId: w?.available.first.sourceId ?? item.source!.sourceId, seriesKey: w?.available.first.seriesKey ?? item.source!.id, title: title, coverUrl: w?.coverUrl ?? item.source?.coverUrl)),
    // More like this: the feature page's tab (an item on the reader's sources only).
    if (!info) QuickLookId.moreLikeThis: () => context.push(featureMoreLikeThis(w?.available.first.sourceId ?? item.source!.sourceId, w?.available.first.seriesKey ?? item.source!.id)),
    QuickLookId.notForMe: () async {
      final ai = ref.read(aiRepositoryProvider);
      final src = item.source;
      final res = await ai.sendFeedback(
        signal: 'not_interested',
        anilistId: w?.anilistId == 0 ? null : w?.anilistId,
        sourceId: w == null ? src!.sourceId : null,
        seriesKey: w == null ? src!.id : null,
      );
      if (res.isOk) {
        // The rail fades the poster over 240 ms first; then it joins the session's dismissed set.
        final id = w != null ? pickId(w) : 's${src!.sourceId}:${src.id}';
        onNotForMe?.call();
        unawaited(Future<void>.delayed(onNotForMe == null ? Duration.zero : const Duration(milliseconds: 250), () => container.read(dismissedPicksProvider.notifier).add(id)));
      }
    },
  });
  return openQuickLook(
    context,
    title: title,
    heroTag: heroTag,
    kicker: item.why == null ? 'QUICK LOOK' : 'WHY THIS ONE',
    credits: item.why ?? w?.badgeLine,
    cover: _cover(ref, w?.coverUrl ?? item.source?.coverUrl, title),
    actions: [
      ...actions,
      if (info) ...[
        QuickLookAction('search-my-sources', 'Search my sources', CineIconRole.search, onSelected: () => context.go(Routes.discover({'q': title}))),
        if (site != null)
          QuickLookAction('read-on', 'Read on ${site.site} ↗', CineIconRole.external, onSelected: () async {
            final ok = await launchUrl(Uri.parse(site.url), mode: LaunchMode.externalApplication).catchError((Object _) => false);
            if (!ok) ref.read(cineToastsProvider.notifier).error("Couldn't open ${site.url}");
          },),
      ],
    ],
  );
}

/// A source tile: Open.
Future<void> openSourceQuickLook(BuildContext context, WidgetRef ref, HomeSourceItem item) => openQuickLook(
      context,
      title: item.name,
      kicker: 'SOURCE',
      cover: _cover(ref, item.latestCovers.isEmpty ? null : item.latestCovers.first, item.name),
      actions: quickLookActions({QuickLookId.open: () => context.go(Routes.source(item.sourceId))}),
    );

/// A world item on any AI surface (Picks, More like this): the feature page when the reader's
/// sources carry it, a source picker when several do, else Discover with `?q={title}`.
void openWorldItem(BuildContext context, WorldItem w) {
  if (w.available.length > 1) {
    unawaited(showSourcePickerSheet(context, title: w.title, sources: w.available, onOpen: (s) => openSeries(context, s.sourceId, s.seriesKey)));
  } else if (w.available.length == 1) {
    openSeries(context, w.available.first.sourceId, w.available.first.seriesKey);
  } else {
    context.go(Routes.discover({'q': w.title}));
  }
}

/// Quick look of a world item: Open (or Search my sources and Read on for information-only
/// titles), More like this and Not for me. The `why` shows as the credits line.
Future<void> openWorldQuickLook(BuildContext context, WidgetRef ref, WorldItem w, {VoidCallback? onNotForMe, VoidCallback? onMoreLikeThis, Object? heroTag}) {
  final info = w.available.isEmpty;
  final site = w.readElsewhere;
  return openQuickLook(
    context,
    title: w.title,
    heroTag: heroTag,
    kicker: w.why == null ? 'QUICK LOOK' : 'WHY THIS ONE',
    credits: w.why ?? w.badgeLine,
    cover: _cover(ref, w.coverUrl, w.title),
    actions: [
      ...quickLookActions({
        if (!info) QuickLookId.open: () => openWorldItem(context, w),
        if (!info && _hasCircle(ref)) QuickLookId.recommend: () => unawaited(showPassItOnSheet(context, sourceId: w.available.first.sourceId, seriesKey: w.available.first.seriesKey, title: w.title, coverUrl: w.coverUrl)),
        if (onMoreLikeThis != null) QuickLookId.moreLikeThis: onMoreLikeThis,
        if (onNotForMe != null) QuickLookId.notForMe: onNotForMe,
      }),
      if (info) ...[
        QuickLookAction('search-my-sources', 'Search my sources', CineIconRole.search, onSelected: () => context.go(Routes.discover({'q': w.title}))),
        if (site != null)
          QuickLookAction('read-on', 'Read on ${site.site} ↗', CineIconRole.external, onSelected: () async {
            final ok = await launchUrl(Uri.parse(site.url), mode: LaunchMode.externalApplication).catchError((Object _) => false);
            if (!ok) ref.read(cineToastsProvider.notifier).error("Couldn't open ${site.url}");
          },),
      ],
    ],
  );
}
