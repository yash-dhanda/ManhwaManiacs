import 'dart:async';

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

class _GatedConnectivity implements NetworkConnectivity {
  final Completer<bool> wifi = Completer<bool>();

  @override
  Future<bool> isOnWifi() => wifi.future;
  @override
  Future<bool> isOnline() async => true;
}

/// Pumps a widget that arms [NextChapterAutoQueue] for route chapter `c1` (next `c2`) and hands back
/// its `ref`, so a test can report the reader's position.
class _Reader {
  _Reader(this.queue, this.autoQueue);
  final _RecordingQueue queue;
  final NextChapterAutoQueue autoQueue;
  late WidgetRef ref;

  void readTo(String chapter, int page, int count) => autoQueue.readTo(ref, chapterId: chapter, page: page, pageCount: count);
}

Future<_Reader> _open(
  WidgetTester tester, {
  required String? scope,
  required bool wifiOnly,
  required bool onWifi,
  String? next = 'c2',
}) async {
  SharedPreferences.setMockInitialValues({
    'settings_wifi_only_downloads': wifiOnly,
  });
  final prefs = await SharedPreferences.getInstance();
  final reader = _Reader(_RecordingQueue(), NextChapterAutoQueue());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        activeDownloadsScopeIdProvider.overrideWithValue(scope),
        networkConnectivityProvider.overrideWithValue(_FixedConnectivity(onWifi: onWifi)),
        downloadQueueControllerProvider.overrideWith(() => reader.queue),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          reader.ref = ref;
          reader.autoQueue.arm(sourceId: 'src', seriesKey: 'series', nextChapterId: next, afterChapterId: 'c1');
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return reader;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

const _c2 = (sourceId: 'src', seriesKey: 'series', chapterKey: 'c2');

void main() {
  testWidgets('nothing is queued on open, however long the wait', (tester) async {
    final r = await _open(tester, scope: 'u1p1', wifiOnly: false, onWifi: true);
    await tester.pump(const Duration(minutes: 1));
    expect(r.queue.enqueued, isEmpty);
  });

  testWidgets('it is queued once the read share crosses the neighbour preload mark', (tester) async {
    final r = await _open(tester, scope: 'u1p1', wifiOnly: false, onWifi: true);
    r.readTo('c1', 1, 10);
    r.readTo('c1', 6, 10);
    await _settle(tester);
    expect(r.queue.enqueued, isEmpty);
    r.readTo('c1', 7, 10);
    await _settle(tester);
    expect(r.queue.enqueued, [_c2]);
  });

  testWidgets('only once, however much more is read', (tester) async {
    final r = await _open(tester, scope: 'u1p1', wifiOnly: false, onWifi: true);
    r.readTo('c1', 7, 10);
    r.readTo('c1', 8, 10);
    await _settle(tester);
    r.readTo('c1', 10, 10);
    await _settle(tester);
    expect(r.queue.enqueued, hasLength(1));
  });

  testWidgets('a chapter of a few pages still gets its next chapter queued', (tester) async {
    final r = await _open(tester, scope: 'u1p1', wifiOnly: false, onWifi: true);
    r.readTo('c1', 1, 3);
    await _settle(tester);
    expect(r.queue.enqueued, isEmpty);
    r.readTo('c1', 3, 3);
    await _settle(tester);
    expect(r.queue.enqueued, [_c2]);
  });

  testWidgets('progress in another chapter of the feed queues nothing', (tester) async {
    final r = await _open(tester, scope: 'u1p1', wifiOnly: false, onWifi: true);
    r.readTo('c0', 10, 10);
    await _settle(tester);
    expect(r.queue.enqueued, isEmpty);
  });

  testWidgets('no next chapter known: nothing is queued', (tester) async {
    final r = await _open(tester, scope: 'u1p1', wifiOnly: false, onWifi: true, next: null);
    r.readTo('c1', 10, 10);
    await _settle(tester);
    expect(r.queue.enqueued, isEmpty);
  });

  testWidgets('no downloads scope: nothing is queued', (tester) async {
    final r = await _open(tester, scope: null, wifiOnly: false, onWifi: true);
    r.readTo('c1', 10, 10);
    await _settle(tester);
    expect(r.queue.enqueued, isEmpty);
  });

  testWidgets('Wi-Fi only and not on Wi-Fi: nothing is queued', (tester) async {
    final r = await _open(tester, scope: 'u1p1', wifiOnly: true, onWifi: false);
    r.readTo('c1', 10, 10);
    await _settle(tester);
    expect(r.queue.enqueued, isEmpty);
  });

  testWidgets('Wi-Fi only and on Wi-Fi: it is queued', (tester) async {
    final r = await _open(tester, scope: 'u1p1', wifiOnly: true, onWifi: true);
    r.readTo('c1', 10, 10);
    await _settle(tester);
    expect(r.queue.enqueued, [_c2]);
  });

  testWidgets('reading on across seams queues each new next chapter', (tester) async {
    final r = await _open(tester, scope: 'u1p1', wifiOnly: false, onWifi: false);
    r.readTo('c1', 10, 10);
    await _settle(tester);
    // The feed grew to hold c2; the next chapter past it is c3, saved once c2 is read far enough.
    r.autoQueue.arm(sourceId: 'src', seriesKey: 'series', nextChapterId: 'c3', afterChapterId: 'c2');
    r.readTo('c2', 3, 10);
    await _settle(tester);
    expect(r.queue.enqueued.map((c) => c.chapterKey), ['c2']);
    r.readTo('c2', 8, 10);
    await _settle(tester);
    expect(r.queue.enqueued.map((c) => c.chapterKey), ['c2', 'c3']);
  });

  testWidgets('leaving the reader while the Wi-Fi check is out raises no error', (tester) async {
    SharedPreferences.setMockInitialValues({'settings_wifi_only_downloads': true});
    final prefs = await SharedPreferences.getInstance();
    final connectivity = _GatedConnectivity();
    final queue = _RecordingQueue();
    final autoQueue = NextChapterAutoQueue();
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          activeDownloadsScopeIdProvider.overrideWithValue('u1p1'),
          networkConnectivityProvider.overrideWithValue(connectivity),
          downloadQueueControllerProvider.overrideWith(() => queue),
        ],
        child: Consumer(
          builder: (context, r, _) {
            ref = r;
            autoQueue.arm(sourceId: 'src', seriesKey: 'series', nextChapterId: 'c2', afterChapterId: 'c1');
            return const SizedBox();
          },
        ),
      ),
    );
    autoQueue.readTo(ref, chapterId: 'c1', page: 10, pageCount: 10);
    await tester.pump();
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    connectivity.wifi.complete(true);
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a position reported after the reader is gone raises no error and queues nothing', (tester) async {
    final r = await _open(tester, scope: 'u1p1', wifiOnly: false, onWifi: true);
    await tester.pumpWidget(const SizedBox.shrink());
    r.readTo('c1', 10, 10);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(r.queue.enqueued, isEmpty);
  });
}
