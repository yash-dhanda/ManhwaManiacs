// ignore_for_file: directives_ordering
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_storage_providers.dart';
import 'package:manhwamaniacs/features/downloads/store/downloads_store.dart';
import 'package:manhwamaniacs/features/library/providers/dashboard_providers.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/downloads_screen.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';

import '../../../features/downloads/mature_gate_support.dart';
import '../../../support/downloads_test_support.dart';
import '../../../support/test_overrides.dart';
import 'downloads_rig.dart' show HapticLog, rigTheme;

final _pixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, //
  0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F, 0x00, 0x05, 0xFE, 0x02, 0xFE, 0xA7, 0x35, 0x81, 0x84, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

const _hot1 = (sourceId: 'src', seriesKey: 'hot', chapterKey: 'c1');
const _hot2 = (sourceId: 'src', seriesKey: 'hot', chapterKey: 'c2');
const _plain = (sourceId: 'src', seriesKey: 'plain', chapterKey: 'p1');

Future<void> _complete(DownloadsStore s, ChapterIdentity id, String title) async {
  final row = await s.ensureQueued(id: id, seriesTitle: title, chapterNumber: 1);
  await s.updateManifestInfo(rowId: row, pageCount: 1);
  await s.savePage(rowId: row, pageNumber: 1, bytes: [1, 2, 3, ...id.chapterKey.codeUnits]);
  await s.markCompleteIfAllPagesPresent(row);
}

/// Runs real I/O (sqflite over FFI) to completion between frames.
Future<void> pumpReal(WidgetTester t, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  initSqfliteFfiForTests();

  testWidgets('with the gate closed a mature series is absent from the list, the count and the queue; the meter keeps its bytes; reopening brings it back', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1600);
    addTearDown(tester.view.reset);
    // Covers never touch the disk cache (no path_provider in a host test).
    final oldProbe = CineImage.cacheProbe, oldBuilder = CineImage.providerBuilder;
    CineImage.cacheProbe = (_) async => false;
    CineImage.providerBuilder = (url, headers) => MemoryImage(_pixel);
    addTearDown(() {
      CineImage.cacheProbe = oldProbe;
      CineImage.providerBuilder = oldBuilder;
    });
    final log = <String>[];
    final rig = (await tester.runAsync(
      () => gateRig(
        follows: [follow(1, 'hot', rating: 'mature', override: true), follow(2, 'plain', rating: 'safe')],
        extra: [
          authenticatedAuthOverride(),
          activeProfileOverride(),
          ...contentModeOverrides(),
          continueReadingProvider.overrideWith((ref) async => const []),
          updatesProvider.overrideWith(_NoUpdates.new),
          deviceOnlineProvider.overrideWith((ref) => Stream.value(true)),
          skinHapticsProvider.overrideWithValue(HapticLog(log)),
          deviceSpaceProvider.overrideWith((ref) async => (free: 20 * 1024 * 1024 * 1024, total: 100 * 1024 * 1024 * 1024)),
          // The meter names no series: it reads the store's whole scope, never the gated list.
          totalDeviceDownloadBytesProvider.overrideWith((ref) async => ref.watch(downloadsStoreProvider)!.scopeBytes()),
        ],
      ),
    ))!;
    final c = rig.container;
    // The store opens its database when first read: read it where real I/O can complete.
    final store = (await tester.runAsync(() async => c.read(downloadsStoreProvider)!))!;
    await tester.runAsync(() async {
      await _complete(store, _hot1, 'Hot Series');
      await _complete(store, _hot2, 'Hot Series');
      await _complete(store, _plain, 'Plain Series');
      await store.ensureQueued(id: (sourceId: 'src', seriesKey: 'hot', chapterKey: 'c3'), seriesTitle: 'Hot Series');
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          theme: rigTheme(TargetPlatform.android),
          routerConfig: GoRouter(routes: [GoRoute(path: '/', builder: (context, state) => const DownloadsScreen())]),
        ),
      ),
    );
    await pumpReal(tester);
    String meterLine() => tester.widget<Text>(find.textContaining('FREE ON THIS PHONE')).data!;

    // Open: everything is there, and the queued chapter is owed.
    expect(find.text('Hot Series'), findsWidgets);
    expect(find.text('Plain Series'), findsWidgets);
    expect(c.read(activeDownloadCountProvider), greaterThan(0));
    final open = meterLine();

    // Closed: absence, never a lock. Nothing names what is hidden.
    rig.gate(false);
    await pumpReal(tester);
    expect(find.text('Hot Series'), findsNothing);
    expect(find.textContaining('Hot'), findsNothing);
    expect(find.text('Plain Series'), findsWidgets);
    expect(c.read(activeDownloadCountProvider), 0, reason: 'the thumb-index badge counts only visible chapters');
    expect(find.byKey(const Key('activity-block')), findsNothing, reason: 'the hidden queued chapter pauses silently');
    expect(meterLine(), open, reason: 'the meter still includes the hidden bytes');
    expect(find.textContaining('hidden'), findsNothing);

    // Reopened: everything is back at once.
    rig.gate(true);
    await pumpReal(tester);
    expect(find.text('Hot Series'), findsWidgets);
    expect(c.read(activeDownloadCountProvider), greaterThan(0));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    c.dispose();
    await tester.runAsync(rig.harness.dispose);
  });
}

class _NoUpdates extends UpdatesNotifier {
  @override
  Future<UpdatesState> build() async => const UpdatesState(notifications: [], unreadCount: 0, followed: []);
}
