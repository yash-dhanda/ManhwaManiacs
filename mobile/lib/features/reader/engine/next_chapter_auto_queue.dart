import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/features/downloads/providers/download_switches_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// Queues the next chapter for download the moment a chapter is read — gated
/// on the "Wi-Fi only downloads" setting so idly reading never burns mobile
/// data the user didn't ask to spend — via the same on-device queue a manual
/// "Download" tap uses (spec §3).
///
/// One instance per reader screen; fires at most once per route chapter.
class NextChapterAutoQueue {
  /// [saveNextEnabled] is the per-profile "Save the next chapter while I read" switch (default
  /// on); null reads `saveNextProvider`, which is what `mobile/17` wired.
  NextChapterAutoQueue({this.saveNextEnabled});

  final bool Function()? saveNextEnabled;

  /// Guards the eager next-chapter queue so it fires once per chapter shown,
  /// not on every unrelated rebuild of the screen.
  String? _prefetchedFor;

  void maybeQueue(
    WidgetRef ref, {
    required String sourceId,
    required String seriesKey,
    required String routeChapterId,
    required String? nextChapterId,
  }) {
    // Guarded on the id being *known*, not merely on the chapter having
    // been shown: a downloaded chapter paints from disk before anything
    // knows what comes next, and the eager queue must still fire once the
    // neighbours land rather than being marked done against a null.
    if (nextChapterId != null && _prefetchedFor != routeChapterId) {
      _prefetchedFor = routeChapterId;
      // Deferred past this build, like every other one-shot side effect
      // triggered from a build method in this codebase (see
      // OpenChapterScope._claim) — reading providers is safe mid-build,
      // but a network/DB-touching side effect belongs after it.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(
          _queue(
            ref,
            sourceId: sourceId,
            seriesKey: seriesKey,
            nextId: nextChapterId,
          ),
        ),
      );
    }
  }

  Future<void> _queue(
    WidgetRef ref, {
    required String sourceId,
    required String seriesKey,
    required String nextId,
  }) async {
    if (ref.read(activeDownloadsScopeIdProvider) == null) return;
    // The per-profile "Save the next chapter while I read" switch (default on).
    if (!(saveNextEnabled?.call() ?? ref.read(saveNextProvider))) return;

    if (ref.read(preferencesProvider).wifiOnlyDownloads) {
      final onWifi = await ref.read(networkConnectivityProvider).isOnWifi();
      if (!onWifi) return;
    }

    await ref.read(downloadQueueControllerProvider.notifier).enqueueChapter(
          id: (
            sourceId: sourceId,
            seriesKey: seriesKey,
            chapterKey: nextId,
          ),
          automatic: true,
        );
  }
}
