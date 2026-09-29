// ignore_for_file: directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';

import 'downloads_rig.dart';

const gb = 1024 * 1024 * 1024;

void main() {
  group('saved library', () {
    testWidgets('masthead, meter line and series largest first', (tester) async {
      await pumpDownloads(
        tester,
        rig: Rig(
          bytes: 4 * gb,
          groups: [
            series([chapter(1, '1', bytes: 5 * 1024 * 1024)], seriesKey: 'small', title: 'Small Series'),
            series([chapter(2, '1', bytes: 900 * 1024 * 1024)], seriesKey: 'huge', title: 'Huge Series'),
          ],
        ),
      );
      expect(heading('Downloads'), findsOneWidget);
      expect(find.text('NO. 05 — ON THIS DEVICE'), findsOneWidget);
      expect(find.textContaining('FREE ON THIS PHONE'), findsOneWidget);
      expect(find.text('ON THIS PHONE — BIGGEST FIRST'), findsOneWidget);
      final huge = tester.getTopLeft(find.text('Huge Series').last).dy;
      final small = tester.getTopLeft(find.text('Small Series').last).dy;
      expect(huge, lessThan(small));
    });

    testWidgets('folio counts saved and total, and expanding lists chapter captions', (tester) async {
      await pumpDownloads(
        tester,
        rig: Rig(
          groups: [
            series([
              chapter(1, '1', bytes: 24 * 1024 * 1024),
              chapter(2, '2', state: DownloadChapterState.queued, bytes: 0),
              chapter(3, '3', state: DownloadChapterState.failed, error: 'offline', bytes: 0),
              chapter(4, '1:audio', kind: DownloadKind.audio, bytes: 3 * 1024 * 1024),
            ]),
          ],
        ),
      );
      expect(find.textContaining('1 OF 3 SAVED'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Expand chapters'));
      await settle(tester, ms: 400);
      expect(find.textContaining('SAVED · 24.0 MB'), findsOneWidget);
      expect(find.text('QUEUED'), findsOneWidget);
      expect(find.text('FAILED — offline'), findsOneWidget);
      expect(find.text('· AUDIO'), findsOneWidget);
    });
  });

  group('activity', () {
    Future<void> reason(WidgetTester tester, DownloadQueuePauseReason r, String note, {List<String>? buttons}) async {
      await pumpDownloads(
        tester,
        rig: Rig(
          groups: [series([chapter(1, '1'), chapter(2, '2', state: DownloadChapterState.queued, bytes: 0)])],
          queue: [chapter(2, '2', state: DownloadChapterState.queued, bytes: 0)],
          queueState: DownloadQueueState(pauseReason: r),
        ),
      );
      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.textContaining(note), findsOneWidget);
      for (final b in buttons ?? const <String>[]) {
        expect(find.text(b), findsOneWidget);
      }
    }

    testWidgets('paused by the user offers Resume all', (tester) async {
      await reason(tester, DownloadQueuePauseReason.userPaused, 'Paused by you.', buttons: ['Resume all']);
    });
    testWidgets('floor', (tester) async {
      await reason(tester, DownloadQueuePauseReason.freeSpaceFloor, 'this phone is almost full');
    });
    testWidgets('cap offers Storage settings', (tester) async {
      await reason(tester, DownloadQueuePauseReason.cap, 'limit is full', buttons: ['Storage settings']);
    });
    testWidgets('backgrounded', (tester) async {
      await reason(tester, DownloadQueuePauseReason.backgrounded, 'Paused while the app is in the background.');
    });

    testWidgets('downloading shows the page folio, determinate rule and tally', (tester) async {
      final cur = chapter(1, '12', state: DownloadChapterState.downloading, bytes: 0);
      await pumpDownloads(
        tester,
        rig: Rig(
          groups: [series([cur, chapter(2, '11')])],
          queue: [cur],
          queueState: const DownloadQueueState(
            isDownloading: true,
            currentChapter: (sourceId: 'asura', seriesKey: 'solo', chapterKey: '12'),
            pagesDone: 7,
            pageTotal: 40,
            activeChapterCount: 3,
          ),
        ),
      );
      expect(find.text('DOWNLOADING'), findsOneWidget);
      expect(find.text('CH 12 · PAGE 7 OF 40'), findsOneWidget);
      expect(find.text('2 more chapters downloading alongside'), findsOneWidget);
      expect(find.text('1 of 2 saved in this series'), findsOneWidget);
      expect(find.text('Pause all'), findsOneWidget);
      expect(find.textContaining('Downloads run while the app is open'), findsOneWidget);
    });

    testWidgets('Show queue lists rows with Retry and Remove from queue', (tester) async {
      final failed = chapter(3, '14', state: DownloadChapterState.failed, error: 'timeout', bytes: 0);
      final r = await pumpDownloads(
        tester,
        rig: Rig(
          groups: [series([failed])],
          queue: [chapter(2, '13', state: DownloadChapterState.queued, bytes: 0), failed],
          queueState: const DownloadQueueState(isDownloading: true),
        ),
      );
      await tester.tap(find.textContaining('Show queue'));
      await settle(tester, ms: 300);
      expect(find.text('Waiting'), findsOneWidget);
      expect(find.text('Failed — timeout'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(r.queueLog, contains('retry:14'));
      await tester.tap(find.bySemanticsLabel('Remove ch 13 from queue'));
      await tester.pump();
      expect(r.queueLog, contains('cancel:13'));
    });

    testWidgets('Cancel all asks first, keeps by default, and cancels after the arm delay', (tester) async {
      final r = await pumpDownloads(
        tester,
        rig: Rig(
          groups: [series([chapter(2, '13', state: DownloadChapterState.queued, bytes: 0)])],
          queue: [chapter(2, '13', state: DownloadChapterState.queued, bytes: 0)],
          queueState: const DownloadQueueState(isDownloading: true),
        ),
      );
      await tester.tap(find.text('Cancel all'));
      await settle(tester, ms: 500);
      expect(find.text('Cancel all downloads?'), findsOneWidget);
      expect(find.text('Keep them'), findsOneWidget);
      expect(find.text('Everything queued, downloading or failed is dropped. Finished chapters stay.'), findsOneWidget);
      await tester.tap(find.text('Keep them'));
      await settle(tester, ms: 500);
      expect(r.queueLog, isNot(contains('cancelAll')));
      await tester.tap(find.text('Cancel all'));
      await settle(tester);
      await tester.tap(find.byKey(const Key('confirm-commit')));
      await settle(tester, ms: 500);
      expect(r.queueLog, contains('cancelAll'));
    });
  });

  group('states', () {
    testWidgets('no profile', (tester) async {
      await pumpDownloads(tester, rig: Rig(profile: false));
      expect(typed('Choose a profile to see its downloads.'), findsOneWidget);
      expect(find.text('Choose a profile'), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      await pumpDownloads(tester);
      expect(find.text('NOTHING SAVED YET'), findsOneWidget);
      expect(typed('Chapters you save open with no connection.'), findsOneWidget);
    });

    testWidgets('offline banner', (tester) async {
      await pumpDownloads(tester, rig: Rig(online: false));
      expect(find.text('OFFLINE EDITION'), findsWidgets);
      expect(find.text("You're offline. Only saved chapters open."), findsOneWidget);
    });
  });

  group('storage tab', () {
    testWidgets('every control is present and the tab is the ?tab= query', (tester) async {
      await pumpDownloads(tester, tab: 'storage');
      for (final s in [
        'STORAGE CAP',
        'CHAPTERS AT ONCE',
        'DELETE AFTER READING',
        'Download on Wi-Fi only',
        'Save the next chapter while I read',
        'Download new chapters of followed series automatically',
        'BY SERIES',
        'Free up space',
        'IMAGE CACHE',
        'METADATA CACHE',
        'Clear metadata cache',
        "Files live in the app's private storage.",
      ]) {
        await tester.scrollUntilVisible(find.text(s), 200, scrollable: find.byType(Scrollable).last);
        expect(find.text(s), findsOneWidget, reason: s);
      }
    });
  });
}
