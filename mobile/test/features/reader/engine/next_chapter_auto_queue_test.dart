import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/reader/engine/next_chapter_auto_queue.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingQueue extends DownloadQueueController {
  final List<ChapterIdentity> enqueued = [];

  @override
  DownloadQueueState build() => const DownloadQueueState();

  @override
  Future<void> enqueueChapter({
    required ChapterIdentity id,
    double? chapterNumber,
    String? title,
    String? seriesTitle,
    DownloadKind kind = DownloadKind.manga,
    bool automatic = false,
  }) async =>
      enqueued.add(id);
}

class _FixedConnectivity implements NetworkConnectivity {
  const _FixedConnectivity({required this.onWifi});
  final bool onWifi;

  @override
  Future<bool> isOnWifi() async => onWifi;
  @override
  Future<bool> isOnline() async => true;
}

/// Pumps a widget that calls [NextChapterAutoQueue.maybeQueue] [calls] times
/// for route chapter `c1`, then lets the deferred queue run.
Future<_RecordingQueue> _run(
  WidgetTester tester, {
  required String? scope,
  required bool wifiOnly,
  required bool onWifi,
  int calls = 1,
  List<String> nexts = const ['c2'],
}) async {
  SharedPreferences.setMockInitialValues({
    'settings_wifi_only_downloads': wifiOnly,
  });
  final prefs = await SharedPreferences.getInstance();
  final queue = _RecordingQueue();
  final autoQueue = NextChapterAutoQueue();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        activeDownloadsScopeIdProvider.overrideWithValue(scope),
        networkConnectivityProvider
            .overrideWithValue(_FixedConnectivity(onWifi: onWifi)),
        downloadQueueControllerProvider.overrideWith(() => queue),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          for (final next in nexts) {
            for (var i = 0; i < calls; i++) {
              autoQueue.maybeQueue(
                ref,
                sourceId: 'src',
                seriesKey: 'series',
                nextChapterId: next,
              );
            }
          }
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return queue;
}

void main() {
  testWidgets('no downloads scope: nothing is queued', (tester) async {
    final queue =
        await _run(tester, scope: null, wifiOnly: false, onWifi: true);
    expect(queue.enqueued, isEmpty);
  });

  testWidgets('Wi-Fi only and not on Wi-Fi: nothing is queued', (tester) async {
    final queue =
        await _run(tester, scope: 'u1p1', wifiOnly: true, onWifi: false);
    expect(queue.enqueued, isEmpty);
  });

  testWidgets('otherwise the next chapter is queued exactly once',
      (tester) async {
    final queue =
        await _run(tester, scope: 'u1p1', wifiOnly: true, onWifi: true);
    expect(queue.enqueued, [
      (sourceId: 'src', seriesKey: 'series', chapterKey: 'c2'),
    ]);
  });

  testWidgets('a second call for the same route chapter queues nothing more',
      (tester) async {
    final queue = await _run(
      tester,
      scope: 'u1p1',
      wifiOnly: false,
      onWifi: false,
      calls: 2,
    );
    expect(queue.enqueued, hasLength(1));
  });

  testWidgets('reading on across seams queues each new next chapter', (tester) async {
    final queue = await _run(tester, scope: 'u1p1', wifiOnly: false, onWifi: false, nexts: ['c2', 'c3']);
    expect(queue.enqueued.map((c) => c.chapterKey), ['c2', 'c3']);
  });
}
