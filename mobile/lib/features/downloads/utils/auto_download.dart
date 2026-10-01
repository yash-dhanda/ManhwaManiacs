import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/features/auth/providers/session_offline_provider.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/download_switches_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_storage_providers.dart';
import 'package:manhwamaniacs/features/downloads/providers/storage_settings_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/services/device_storage_info.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/series_content_kind.dart';
import 'package:manhwamaniacs/features/updates/models/update_notification.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';

const int kAutoDownloadLimit = 20;
const int kFreeSpaceFloorBytes = 1610612736; // 1.5 GB
const int kMangaChapterEstimate = 8 * 1024 * 1024;
const int kNovelChapterEstimate = 209715; // 0.2 MB

/// The chapters "Download new chapters of followed series automatically" queues: at most
/// [kAutoDownloadLimit], from unread new-chapter notifications of followed series whose per-series
/// `notify` is on, skipping saved chapters, stopping before the estimated size would push free
/// space under the 1.5 GB floor or the used total over the cap. Nothing when Wi-Fi only and off
/// Wi-Fi. [novelSourceIds] names the sources whose chapters are prose (a fifth of a megabyte).
List<ChapterQueueRequest> planAutoDownload({
  required List<UpdateNotification> unread,
  required List<FollowedSeries> follows,
  required Set<String> savedKeys,
  required int? freeBytes,
  required int? capBytes,
  required int usedBytes,
  required bool wifiOnly,
  required bool onWifi,
  Set<String> novelSourceIds = const {},
}) {
  if (wifiOnly && !onWifi) return const [];
  final byId = {for (final f in follows) f.id: f};
  final out = <ChapterQueueRequest>[];
  final seen = <String>{};
  var used = usedBytes;
  var free = freeBytes;
  for (final n in unread) {
    if (out.length >= kAutoDownloadLimit) break;
    if (n.isRead) continue;
    final follow = n.followedSeriesId == null ? null : byId[n.followedSeriesId];
    if (follow == null || !follow.notify) continue;
    final key = '${n.sourceId} ${n.seriesKey} ${n.chapterKey}';
    if (savedKeys.contains(key) || !seen.add(key)) continue;
    final novel = novelSourceIds.contains(n.sourceId);
    final size = novel ? kNovelChapterEstimate : kMangaChapterEstimate;
    if (free != null && free - size < kFreeSpaceFloorBytes) break;
    if (capBytes != null && used + size > capBytes) break;
    used += size;
    if (free != null) free -= size;
    out.add((
      id: (sourceId: n.sourceId, seriesKey: n.seriesKey, chapterKey: n.chapterKey),
      chapterNumber: n.chapterNumber,
      title: n.chapterTitle,
      seriesTitle: follow.title,
      kind: novel ? DownloadKind.novel : DownloadKind.manga,
    ),);
  }
  return out;
}

/// Runs [planAutoDownload] on app open and on every resume while the switch is on, a profile is
/// active and the device is online. Calls [onQueued] with the count it queued.
class AutoDownloadRunner {
  AutoDownloadRunner(this._ref);
  final Ref _ref;

  Future<int> run() async {
    if (!_ref.read(autoNewProvider)) return 0;
    if (_ref.read(activeProfileProvider) == null || _ref.read(sessionOfflineProvider)) return 0;
    final store = _ref.read(downloadsStoreProvider);
    if (store == null) return 0;
    final updates = await _ref.read(updatesProvider.future);
    final saved = await store.listChapters();
    final scope = _ref.read(contentModeScopeProvider);
    final wifi = _ref.read(wifiOnlyDownloadsProvider);
    final queue = _ref.read(downloadQueueControllerProvider.notifier);
    final plan = planAutoDownload(
      unread: [for (final n in updates.notifications) if (!n.isRead) n],
      follows: updates.followed,
      // Plus everything auto-queued before: a chapter the user removed or cancelled stays gone.
      savedKeys: {
        for (final c in saved) '${c.sourceId} ${c.seriesKey} ${c.chapterKey}',
        ...queue.autoQueuedKeys(),
      },
      freeBytes: await _ref.read(deviceStorageInfoProvider).freeSpaceBytes(),
      capBytes: _ref.read(storageCapProvider).bytes,
      usedBytes: await _ref.read(totalDeviceDownloadBytesProvider.future),
      wifiOnly: wifi,
      onWifi: wifi ? await _ref.read(networkConnectivityProvider).isOnWifi() : true,
      novelSourceIds: {
        for (final n in updates.notifications)
          if (isNovelSource(scope, n.sourceId) ?? false) n.sourceId,
      },
    );
    if (plan.isEmpty) return 0;
    await queue.enqueueChapters(plan, automatic: true);
    return plan.length;
  }
}

final autoDownloadRunnerProvider = Provider<AutoDownloadRunner>(AutoDownloadRunner.new, name: 'autoDownloadRunner');

/// "Queued 6 new chapters." / "Queued 1 new chapter."
String queuedNewChaptersLine(int n) => 'Queued $n new ${n == 1 ? 'chapter' : 'chapters'}.';

/// Widgets binding observer the shell mounts: runs the runner on open and on every resume, right
/// after the unread poll settles, and hands the count to [onQueued].
class AutoDownloadTrigger extends ConsumerStatefulWidget {
  const AutoDownloadTrigger({super.key, required this.child, required this.onQueued});
  final Widget child;
  final void Function(int count) onQueued;

  @override
  ConsumerState<AutoDownloadTrigger> createState() => _AutoDownloadTriggerState();
}

class _AutoDownloadTriggerState extends ConsumerState<AutoDownloadTrigger> with WidgetsBindingObserver {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_go()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_go());
  }

  Future<void> _go() async {
    if (_busy || !mounted || !ref.read(autoNewProvider)) return;
    _busy = true;
    try {
      // Right after the unread poll settles: re-read the notifications first.
      ref.invalidate(updatesProvider);
      final n = await ref.read(autoDownloadRunnerProvider).run();
      if (n > 0 && mounted) widget.onQueued(n);
    } catch (_) {
      // best effort: a failed poll queues nothing
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
