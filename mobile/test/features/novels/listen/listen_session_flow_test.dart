import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/novels/providers/listen_session_outbox_provider.dart';

import '../../../support/downloads_test_support.dart';
import '../../../support/narration_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  initSqfliteFfiForTests();
  late TestDownloadsHarness db;
  late NarrationHarness h;

  setUp(() async {
    db = await TestDownloadsHarness.create();
    h = await NarrationHarness.create(store: db.storeFor('u1p1'));
  });
  tearDown(() async {
    h.dispose();
    await db.dispose();
  });

  Future<int> pending() => h.store!.pendingListenSessions().then((r) => r.length);

  test('play, a 30 s pause and leaving the reader make one row, sent as one POST array', () async {
    // Network down so the row is observable in the outbox first.
    h.repo.listenSessionsResult = const Err(NetworkError(message: 'offline'));
    await h.startAndSettle(listenTarget());
    h.player.tick(1000);
    await h.settle();
    h.advance(40); // 40 s of wall-clock playing
    await h.controller.pause();
    await h.settle();
    // The 30 s pause timer fires: the session closes.
    final close = h.timers.last;
    expect(close.$1, const Duration(seconds: 30));
    close.$2();
    await h.waitFor(() => h.repo.listenBatches.isNotEmpty);
    expect(await pending(), 1);
    final row = (await h.store!.pendingListenSessions()).single.$2;
    expect(row['seconds'], 40);
    expect((row['voice_ids']! as List).length, lessThanOrEqualTo(3));
    expect(row['started_at'], '2026-09-30T12:00:00.000Z');
    expect(row['chapter_key'], 'c12');

    // Back online: one array.
    h.repo.listenSessionsResult = const Ok(null);
    await h.container.read(listenSessionOutboxControllerProvider).flush();
    expect(h.repo.listenBatches.last, hasLength(1));
    expect(h.repo.listenBatches.last.single['seconds'], 40);
    expect(await pending(), 0);
  });

  test('leaving the reader closes the open session', () async {
    await h.startAndSettle(listenTarget());
    h.advance(25);
    await h.controller.stop();
    await h.waitFor(() => h.repo.listenBatches.isNotEmpty);
    expect(h.repo.listenBatches.single.single['seconds'], 25);
  });

  test('a 7 s session produces no row', () async {
    await h.startAndSettle(listenTarget());
    h.advance(7);
    await h.controller.stop();
    await h.waitFor(() => h.repo.listenBatches.isNotEmpty);
    expect(h.repo.listenBatches, isEmpty);
    expect(await pending(), 0);
  });

  test('changing chapter closes the first session', () async {
    await h.startAndSettle(listenTarget());
    h.advance(20);
    await h.startAndSettle(listenTarget(chapter: 'c13'));
    await h.waitFor(() => h.repo.listenBatches.isNotEmpty);
    expect(h.repo.listenBatches.single.single['chapter_key'], 'c12');
  });

  test('a 400 drops the batch, a 429 and a 503 keep it', () async {
    final store = h.store!;
    final outbox = h.container.read(listenSessionOutboxControllerProvider);
    Future<void> queue() => store.enqueueListenSession({
          'source_id': 's',
          'series_key': 'b',
          'chapter_key': 'c',
          'seconds': 30,
          'voice_ids': ['v'],
          'started_at': '2026-09-30T12:00:00.000Z',
        });

    await queue();
    h.repo.listenSessionsResult = const Err(ApiError(statusCode: 429, code: 'rate', message: 'slow down'));
    await outbox.flush();
    expect(await pending(), 1);
    h.repo.listenSessionsResult = const Err(ApiError(statusCode: 503, code: 'busy', message: 'busy'));
    await outbox.flush();
    expect(await pending(), 1);
    h.repo.listenSessionsResult = const Err(ApiError(statusCode: 400, code: 'bad', message: 'no'));
    await outbox.flush();
    expect(await pending(), 0);
  });

  test('a backlog beyond 200 goes out in batches of at most 200, oldest first', () async {
    for (var i = 0; i < 205; i++) {
      await h.store!.enqueueListenSession({
        'source_id': 's',
        'series_key': 'b',
        'chapter_key': 'c$i',
        'seconds': 30,
        'voice_ids': <String>[],
        'started_at': '2026-09-30T12:00:00.000Z',
      });
    }
    await h.container.read(listenSessionOutboxControllerProvider).flush();
    expect(h.repo.listenBatches.map((b) => b.length), [200, 5]);
    expect(h.repo.listenBatches.first.first['chapter_key'], 'c0');
    expect(await pending(), 0);
  });
}
