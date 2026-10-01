import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_selection.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart' show DownloadKind;
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/library/utils/mark_read.dart';
import 'package:manhwamaniacs/features/library/utils/series_chapter_sort.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/letter_schedule.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/lift_provider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Opens the series as the `feature` sheet route, with the poster zoom growing out of [from] and the throw's [velocity] if any.
Future<void> openSeries(WidgetRef ref, String sourceId, String seriesKey, {Rect? from, Offset? velocity, String? query}) async {
  final base = Routes.feature(sourceId, seriesKey);
  await ref.read(skinRouterProvider).push<void>(query == null ? base : '$base?$query', extra: GlassNavExtra(originRect: from, velocity: velocity));
}

/// "Previously on": the recap route as a sheet, up to [toKey].
Future<void> openRecap(WidgetRef ref, String sourceId, String seriesKey, String toKey, {Rect? from}) =>
    ref.read(skinRouterProvider).push<void>(Routes.recap(sourceId, seriesKey, {'to': toKey}), extra: GlassNavExtra(originRect: from));

/// The recommend sheet for a series (shown only when the global sheet is registered).
bool get recommendSheetRegistered => glassSheetRegistered('recommend');

/// A poster, card or spotlight cover dropped on a friend orb: `recommend.send` with the `send` sound and the deferred recommendation
/// with its toast (the shared `pendingLettersProvider`). "Add a note" holds the letter for `?sheet=letter-note`.
void recommendTo(BuildContext context, WidgetRef ref, {required String sourceId, required String seriesKey, required Object? profileId}) {
  final id = profileId is int ? profileId : int.tryParse('$profileId');
  if (id == null) return;
  final members = ref.read(recipientsProvider((sourceId: sourceId, seriesKey: seriesKey))).valueOrNull ?? const <CircleMember>[];
  final name = members.where((m) => m.profileId == id).map((m) => m.name).firstOrNull ?? 'your friend';
  final lift = ref.read(liftProvider);
  final mature = lift != null && lift.sourceId == sourceId && lift.seriesKey == seriesKey && lift.mature;
  glassFire(ref, HapticEvent.recommendSend);
  glassSound(ref, SoundEvent.recommendSend);
  ref.read(orbPulseProvider.notifier).state = id;
  Timer(const Duration(milliseconds: 700), () {
    try {
      ref.read(orbPulseProvider.notifier).state = null;
    } catch (_) {}
  });
  ref.read(magnetHeldProvider.notifier).state = null;
  final container = ProviderScope.containerOf(context, listen: false);
  final router = ref.read(skinRouterProvider);
  scheduleLetter(
    container,
    toProfileId: id,
    toName: name,
    sourceId: sourceId,
    seriesKey: seriesKey,
    mature: mature,
    onAddNote: glassSheetRegistered('letter-note')
        ? () {
            final uri = router.routerDelegate.currentConfiguration.uri;
            router.go(uri.replace(queryParameters: {...uri.queryParameters, 'sheet': 'letter-note', 'to': '$id', 'series': '$sourceId:$seriesKey'}).toString());
          }
        : null,
  );
}

/// "Download next 10": the next ten unread chapters after [readNumber] go into the download queue.
Future<void> downloadNextTen(WidgetRef ref, {required String sourceId, required String seriesKey, required String title, double? readNumber, bool novel = false}) async {
  try {
    final detail = await ref.read(sourceSeriesDetailProvider((sourceId: sourceId, seriesId: seriesKey)).future);
    final ordered = sortSeriesChapters(detail.chapters, numberOf: (c) => c.number, order: SeriesChapterSortOrder.oldest);
    final keys = nextUnreadUndownloadedKeys([
      for (final c in ordered) (key: c.id, number: c.number, title: c.title, isRead: readNumber != null && c.number != null && c.number! <= readNumber, isDownloaded: false),
    ]);
    final byKey = {for (final c in ordered) c.id: c};
    await ref.read(downloadQueueControllerProvider.notifier).enqueueChapters([
      for (final k in keys)
        (
          id: (sourceId: sourceId, seriesKey: seriesKey, chapterKey: k),
          chapterNumber: byKey[k]?.number,
          title: byKey[k]?.title,
          seriesTitle: title,
          kind: novel ? DownloadKind.novel : DownloadKind.manga,
        ),
    ]);
    showGlassToast(ref, GlassToastSpec(keys.isEmpty ? 'Nothing new to download' : (keys.length == 1 ? 'Queued 1 chapter for download' : 'Queued ${keys.length} chapters for download')));
  } catch (_) {
    showGlassToast(ref, const GlassToastSpec("Couldn't queue those chapters", kind: GlassToastKind.error));
  }
}

/// "Mark read" through the shared `mark_read.dart` path: the chapters up to [upTo] (else every chapter), as manual rows.
Future<void> markSeriesRead(WidgetRef ref, {required String sourceId, required String seriesKey, double? upTo}) async {
  try {
    final detail = await ref.read(sourceSeriesDetailProvider((sourceId: sourceId, seriesId: seriesKey)).future);
    final chapters = <ChapterRef>[
      for (final c in detail.chapters)
        if (upTo == null || (c.number != null && c.number! <= upTo)) (sourceId: sourceId, seriesKey: seriesKey, chapterKey: c.id, chapterNumber: c.number, pageCount: c.pageCount, completed: false),
    ];
    final repo = ref.read(readerRepositoryProvider);
    for (final chunk in chunksOf200(manualReadRows(chapters))) {
      final r = await repo.saveProgressBatch(chunk);
      if (r is Err) throw (r as Err).error;
    }
    showGlassToast(ref, const GlassToastSpec('Marked as read', kind: GlassToastKind.success));
  } catch (_) {
    showGlassToast(ref, const GlassToastSpec("Couldn't mark that as read", kind: GlassToastKind.error));
  }
}
