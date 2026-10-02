import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/collections/providers/collections_provider.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_selection.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/providers/library_series_actions.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_chapter_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/source_page.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/features/updates/utils/check_series.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/follow_ring.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart' show glassNarrationActionsProvider;
import 'package:manhwamaniacs/skins/glass/parts/circle/series_circle_row.dart' show hideFromCircleEntry;
import 'package:manhwamaniacs/skins/glass/parts/recommend/recommend_sheet.dart' show recommendMenuEntry;
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_group.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/split_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart' show GlassDetent;
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/move_source_sheet.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_data.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_header.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/tags_sheet.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/transitions/dive.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// The page's commands, shared by the buttons, the ⋯ menu and the hardware keys (glass 8.12 Keys).
class SeriesCommands {
  VoidCallback? continueReading, readAll, toggleFollow, favorite, notify, downloadNext10, pickChapter, previouslyOn, tags, share, toggleSort, select, focusGoTo, more, recommend;
}

/// Where the reader opens for [chapterKey] (manga reader, or the novel reader for books).
/// [page] is a page for manga and the progress bucket for a novel; both readers take it as `page`.
String readerLocation(GlassSeriesData d, String chapterKey, {int? page}) => d.novel
    ? Routes.novel(d.sourceId, d.seriesKey, chapterKey, {if (page != null && page > 1) 'page': page})
    : Routes.reader(d.sourceId, d.seriesKey, chapterKey, {if (page != null && page > 1) 'page': page});

/// Warms the Continue chapter's manifest when the sheet first settles (errors ignored).
void warmContinue(WidgetRef ref, GlassSeriesData d, String? chapterKey) {
  if (chapterKey == null || d.novel) return;
  ref.read(chapterManifestProvider((sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKey: chapterKey)).future).ignore();
}

/// Follow, unfollow with Undo, favourite and notify (glass 8.12 Actions).
class SeriesActionsLogic {
  SeriesActionsLogic(this.context, this.ref, this.d, {this.ring, this.bandKey, this.followKey});
  final BuildContext context;
  final WidgetRef ref;
  final GlassSeriesData d;
  final GlassFollowRingController? ring;
  final GlobalKey? bandKey, followKey;

  bool get _online => ref.read(deviceOnlineProvider).valueOrNull ?? true;

  Future<void> toggleFollow() async {
    if (!_online) return;
    final f = d.followed;
    if (f == null) {
      final err = await ref.read(updatesProvider.notifier).followSeries(sourceId: d.sourceId, seriesKey: d.seriesKey);
      if (err != null) {
        showGlassToast(ref, GlassToastSpec(err is ApiError && err.code == 'follow_limit_reached' ? "You're following 1,000 series, the limit for a profile." : err.userMessage, kind: GlassToastKind.error));
        return;
      }
      fire(ref.read(glassHapticsProvider).fire(HapticEvent.followAdd));
      _ring();
      final added = ref.read(updatesProvider).valueOrNull?.followed.where((x) => x.sourceId == d.sourceId && x.seriesKey == d.seriesKey).firstOrNull;
      showGlassToast(
        ref,
        GlassToastSpec('Added ${d.title} to your library. New chapters will notify you.', undo: added == null ? null : () => fire(ref.read(updatesProvider.notifier).unfollow(added.id))),
      );
    } else {
      final actions = ref.read(librarySeriesActionsProvider);
      final r = await actions.remove(f);
      ref.invalidate(updatesProvider);
      if (r.error != null) {
        showGlassToast(ref, GlassToastSpec(r.error!.userMessage, kind: GlassToastKind.error));
        return;
      }
      fire(ref.read(glassHapticsProvider).fire(HapticEvent.followRemove));
      showGlassToast(ref, GlassToastSpec('Removed ${d.title} from your library.', undo: () => fire(actions.restore(f, slots: r.slots).then((_) => ref.invalidate(updatesProvider)))));
    }
  }

  void _ring() {
    final band = bandKey?.currentContext, btn = followKey?.currentContext;
    final c = ring;
    if (c == null || band == null || btn == null) return;
    final b = rectOf(band), o = rectOf(btn);
    c.play(Offset.zero & b.size, o.center - b.topLeft);
  }

  Future<void> favorite() async {
    final f = d.followed;
    if (f == null || !_online) return;
    fire(ref.read(glassHapticsProvider).fire(HapticEvent.favorite));
    final err = await ref.read(librarySeriesActionsProvider).setFavorite(f, favorite: !f.isFavorite);
    if (err != null) showGlassToast(ref, GlassToastSpec(err.userMessage, kind: GlassToastKind.error));
    ref.invalidate(updatesProvider);
  }

  Future<void> notify() async {
    final f = d.followed;
    if (f == null || !_online) return;
    final r = await ref.read(libraryRepositoryProvider).patchSeries(f.id, notify: !f.notify);
    if (r.isErr) showGlassToast(ref, GlassToastSpec(r.error.userMessage, kind: GlassToastKind.error));
    ref.invalidate(updatesProvider);
  }
}

/// The split primary and the secondary group (glass 8.12 Actions; the two page-level glass controls of 2.4.1 rule 2).
class SeriesActions extends ConsumerWidget {
  const SeriesActions({super.key, required this.data, required this.resume, required this.commands, required this.logic, required this.onDownloadSeries, this.followKey, this.stacked = false});
  final GlassSeriesData data;
  final SeriesResume resume;
  final SeriesCommands commands;
  final SeriesActionsLogic logic;
  final VoidCallback onDownloadSeries;
  final GlobalKey? followKey;

  /// The desktop frame's left column: primary and secondary stacked full width.
  final bool stacked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = data;
    final f = d.followed;
    final online = isOnline(ref);
    final pending = followPending(ref);
    final statuses = ref.watch(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};
    final saved = statuses.values.where((s) => s.state == DownloadChapterState.complete).length;
    final unsaved = d.chapters.length - saved;
    // The split button is sized by its label; at large text it scales down rather than overflow the column.
    final split = FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: GlassSplitButton(
      key: const ValueKey('series-continue'),
      twin: windowTwin(context),
      label: resume.label,
      semanticsLabel: resume.label.replaceAll(' · Ch ', ', chapter '),
      onPressed: resume.chapterKey == null ? null : commands.continueReading,
      onMore: (anchor) => unawaited(showGlassMenu(context, anchor: anchor, title: 'More ways to read', entries: [
        GlassMenuEntry(label: 'Read from the start', onSelected: () => _openFirst(context, ref)),
        if (d.chapters.length > 1 && !d.novel) GlassMenuEntry(label: 'Read all', onSelected: commands.readAll),
        GlassMenuEntry(label: 'Pick a chapter', onSelected: commands.pickChapter),
        GlassMenuEntry(label: 'Download next 10', onSelected: commands.downloadNext10, enabled: ref.read(activeProfileProvider) != null),
      ],),),
    ),);
    final follow = GlassButton(
      key: followKey ?? const ValueKey('series-follow'),
      label: pending && f == null ? 'Adding…' : (f == null ? 'Add to library' : 'In library'),
      icon: GlassButtonIcon(f == null ? GlassGlyph.plus.regular : GlassGlyph.check.regular),
      selected: f != null,
      loading: pending,
      role: GlassRole.pageControl,
      twin: windowTwin(context),
      fullWidth: stacked,
      disabledReason: online ? null : 'Needs a connection',
      onPressed: online ? commands.toggleFollow : null,
    );
    final group = GlassGroup(
      key: const ValueKey('series-secondary-group'),
      twin: windowTwin(context),
      items: [
        if (f != null) GlassGroupItem(icon: GlassButtonIcon(GlassGlyph.star.regular, fill: GlassGlyph.star.fill), label: 'Favourite', toggle: f.isFavorite, onPressed: online ? commands.favorite : null),
        if (f != null) GlassGroupItem(icon: GlassButtonIcon(GlassGlyph.bellSimple.regular, fill: GlassGlyph.bellRinging.fill), label: 'Notifications', toggle: f.notify, onPressed: online ? commands.notify : null),
        GlassGroupItem(icon: GlassButtonIcon(GlassGlyph.cloudArrowDown.regular), label: unsaved > 0 ? 'Download $unsaved chapters' : 'All chapters downloaded', onPressed: unsaved > 0 ? onDownloadSeries : null),
        GlassGroupItem(icon: GlassButtonIcon(GlassGlyph.dotsThree.regular), label: 'More', onPressed: commands.more),
      ],
    );
    if (stacked) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [split, const SizedBox(height: 8), follow, const SizedBox(height: 8), Align(alignment: Alignment.centerLeft, child: group)]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        split,
        const SizedBox(height: 8),
        // A Wrap, not a Row: at large text the group moves under the follow button instead of truncating its label.
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [follow, group]),
      ],
    );
  }

  void _openFirst(BuildContext context, WidgetRef ref) {
    final order = data.readingOrder;
    if (order.isEmpty) return;
    unawaited(enterReader(context, ref, readerLocation(data, order.first.id), fromRect: rectOf(context)));
  }
}

const _statuses = [('unread', 'Unread'), ('reading', 'Reading'), ('completed', 'Completed'), ('on_hold', 'On hold'), ('plan_to_read', 'Plan to read'), ('dropped', 'Dropped')];

/// The ⋯ menu (glass 8.12): Reading status, Add to collection, Tags…, Previously on, Check for new chapters, Move to another source…,
/// Content rating (gate open only), Recommend to…, Hide from my Circle, Open source page in browser (when the source has one).
Future<void> showSeriesMenu(BuildContext context, WidgetRef ref, GlassSeriesData d, Rect anchor) {
  final f = d.followed;
  final online = onlineNow(ref);
  final hasProgress = ref.read(sourceSeriesProgressProvider(d.progressKey)).isNotEmpty;
  final gateOpen = ref.read(matureContentProvider).valueOrNull ?? false;
  return showGlassMenu(
    context,
    anchor: anchor,
    title: 'More',
    entries: [
      if (f != null) GlassMenuEntry(label: 'Reading status…', enabled: online, onSelected: () => _statusMenu(context, ref, f, anchor)),
      if (f != null) GlassMenuEntry(label: 'Add to collection…', enabled: online, onSelected: () => _collectionMenu(context, ref, d, anchor)),
      GlassMenuEntry(label: 'Tags…', enabled: online, keyHint: const SingleActivator(LogicalKeyboardKey.keyT, shift: true), onSelected: () => openTagsSheet(context, d)),
      if (hasProgress) GlassMenuEntry(label: 'Previously on', onSelected: () => openPreviouslyOn(ref, d)),
      if (d.novel && d.readingOrder.isNotEmpty) GlassMenuEntry(label: 'Voices for this book', onSelected: () => ref.read(glassNarrationActionsProvider).openSheet('cast', extra: {'series': '${d.sourceId}:${d.seriesKey}', 'chapter': d.readingOrder.first.id})),
      if (f != null) GlassMenuEntry(label: 'Check for new chapters', enabled: online, onSelected: () => fire(checkNewChapters(ref, d, f))),
      if (f != null) GlassMenuEntry(label: 'Move to another source…', enabled: online, onSelected: () => openMoveSource(context, d)),
      if (f != null && gateOpen) GlassMenuEntry(label: 'Content rating…', separatorBefore: true, enabled: online, onSelected: () => _ratingMenu(context, ref, f, anchor)),
      // The Circle (mobile/43, glass 8.12, 8.13, 9.3.4, 9.3.6).
      if (recommendMenuEntry(ref, sourceId: d.sourceId, seriesKey: d.seriesKey, title: d.title, keyHint: const SingleActivator(LogicalKeyboardKey.keyR, shift: true)) case final e?) e,
      if (hideFromCircleEntry(ref, sourceId: d.sourceId, seriesKey: d.seriesKey, title: d.title) case final e?) e,
      if (d.series.sourceUrl case final url?) GlassMenuEntry(label: 'Open source page in browser', separatorBefore: true, onSelected: () => fire(_openSourcePage(ref, url))),
    ],
  );
}

Future<void> _openSourcePage(WidgetRef ref, String url) async {
  if (!await openSourcePage(url)) showGlassToast(ref, const GlassToastSpec("Couldn't open the source page", kind: GlassToastKind.error));
}

void openTagsSheet(BuildContext context, GlassSeriesData d) => unawaited(pushSeriesSheet(context, title: 'Tags', builder: (_) => SeriesTagsSheet(data: d)));

void openMoveSource(BuildContext context, GlassSeriesData d) =>
    unawaited(pushSeriesSheet(context, title: 'Move to another source', builder: (_) => MoveSourceSheet(data: d), detents: const [GlassDetent.large], opening: GlassDetent.large));

/// The `recap` route (glass 9.1.3 "Previously on"), up to the Continue chapter.
void openPreviouslyOn(WidgetRef ref, GlassSeriesData d) {
  final order = d.readingOrder;
  final r = seriesResume(order, ref.read(sourceSeriesProgressProvider(d.progressKey)), novel: d.novel);
  final to = r.chapterKey ?? (order.isEmpty ? null : order.last.id);
  unawaited(ref.read(skinRouterProvider).push<void>(Routes.recap(d.sourceId, d.seriesKey, {'to': to}), extra: const GlassNavExtra()));
}

Future<void> checkNewChapters(WidgetRef ref, GlassSeriesData d, FollowedSeries f) async {
  final r = await checkSeriesForNew(ref, followedId: f.id, sourceId: d.sourceId, seriesKey: d.seriesKey);
  if (r.isErr) {
    showGlassToast(ref, GlassToastSpec(r.error.userMessage, kind: GlassToastKind.error));
    return;
  }
  final n = r.value;
  showGlassToast(ref, GlassToastSpec(n > 0 ? 'Checked: $n new chapter${n == 1 ? '' : 's'}' : 'No new chapters'));
}

void _statusMenu(BuildContext context, WidgetRef ref, FollowedSeries f, Rect anchor) => unawaited(showGlassMenu(
      context,
      anchor: anchor,
      title: 'Reading status',
      entries: [
        for (final (v, label) in _statuses)
          GlassMenuEntry(
            label: label,
            checked: f.readingStatus == v,
            onSelected: () async {
              final r = await ref.read(libraryRepositoryProvider).patchSeries(f.id, readingStatus: v);
              if (r.isErr) {
                showGlassToast(ref, const GlassToastSpec("Couldn't change the reading status", kind: GlassToastKind.error));
                if (context.mounted) _statusMenu(context, ref, f, anchor);
                return;
              }
              ref.invalidate(updatesProvider);
            },
          ),
      ],
    ),);

void _ratingMenu(BuildContext context, WidgetRef ref, FollowedSeries f, Rect anchor) {
  final a = ref.read(librarySeriesActionsProvider);
  unawaited(showGlassMenu(context, anchor: anchor, title: 'Content rating', entries: [
    GlassMenuEntry(label: 'Automatic', checked: f.matureOverride == null, onSelected: () => fire(a.setMatureOverride(f, clear: true).then((_) => ref.invalidate(updatesProvider)))),
    GlassMenuEntry(label: 'Always mature', checked: f.matureOverride ?? false, onSelected: () => fire(a.setMatureOverride(f, value: true).then((_) => ref.invalidate(updatesProvider)))),
    GlassMenuEntry(label: 'Never mature', checked: f.matureOverride == false, onSelected: () => fire(a.setMatureOverride(f, value: false).then((_) => ref.invalidate(updatesProvider)))),
  ],),);
}

void _collectionMenu(BuildContext context, WidgetRef ref, GlassSeriesData d, Rect anchor) {
  final cols = ref.read(collectionsProvider).valueOrNull ?? const [];
  unawaited(showGlassMenu(context, anchor: anchor, title: 'Add to collection', entries: [
    for (final c in cols)
      GlassMenuEntry(
        label: c.name,
        onSelected: () async {
          final r = await ref.read(libraryRepositoryProvider).addSeriesToCollection(c.id, sourceId: d.sourceId, seriesKey: d.seriesKey);
          showGlassToast(ref, GlassToastSpec(r.isErr ? "Couldn't add it to ${c.name}" : 'Added to ${c.name}', kind: r.isErr ? GlassToastKind.error : GlassToastKind.info));
          ref.invalidate(collectionsProvider);
        },
      ),
    GlassMenuEntry(label: 'New collection', separatorBefore: cols.isNotEmpty, onSelected: () => unawaited(ref.read(skinRouterProvider).push<void>(Routes.collections({'sheet': 'collection-new'})))),
  ],),);
}

/// Download the unsaved chapters of [chapters] (or the whole series).
Future<void> enqueueSeriesChapters(WidgetRef ref, GlassSeriesData d, Iterable<String> keys) async {
  final want = keys.toSet();
  final chapters = d.chapters.where((c) => want.contains(c.id));
  fire(ref.read(glassHapticsProvider).fire(HapticEvent.downloadStart));
  await ref.read(downloadQueueControllerProvider.notifier).enqueueChapters(seriesQueueRequests(d, chapters));
}

/// The keys "Next 10" picks for this series now.
List<String> next10Keys(WidgetRef ref, GlassSeriesData d) {
  final statuses = ref.read(seriesChapterDownloadStatusProvider(d.identity)).valueOrNull ?? const {};
  final saved = {for (final e in statuses.entries) if (e.value.state == DownloadChapterState.complete) e.key};
  return nextUnreadUndownloadedKeys(selectableChapters(d.readingOrder, ref.read(sourceSeriesProgressProvider(d.progressKey)), saved));
}
