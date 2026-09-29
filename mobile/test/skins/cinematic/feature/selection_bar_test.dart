// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_selection.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_summary_provider.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/download_mark.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_download_mark.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/run_summary_line.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/selection_bar.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/series_download_card.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';

import 'feature_test_support.dart';

List<SelectableChapter> _chapters() => [
      for (var i = 1; i <= 30; i++)
        (
          key: 'c$i',
          number: i.toDouble(),
          title: 'Chapter $i',
          isRead: i <= 12,
          isDownloaded: i == 20 || i == 21,
        ),
    ];

void main() {
  testWidgets('the bar counts the selection and its quick picks carry counts', (tester) async {
    final ctl = ChapterSelectionController()..begin();
    var downloads = 0;
    await pumpFeature(tester,
        child: Scaffold(body: SelectionBar(controller: ctl, chapters: _chapters(), onDownload: () => downloads++)));
    expect(find.text('Select chapters to download'), findsOneWidget);
    expect(find.text('NEXT 10'), findsOneWidget);
    expect(find.text('ALL UNREAD${superscript(16)}'), findsOneWidget);
    expect(find.text('ALL${superscript(30)}'), findsOneWidget);
    expect(find.text('NONE'), findsOneWidget);
    expect(find.text('WHOLE BOOK'), findsNothing);
    final primary = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(primary.onPressed, isNull);

    await tester.tap(find.text('NEXT 10'));
    await tester.pump();
    expect(find.text('10 SELECTED · 2 ALREADY SAVED'), findsOneWidget);
    expect(find.text('Download 10'), findsOneWidget);
    await tester.tap(find.text('Download 10'));
    expect(downloads, 1);

    await tester.tap(find.text('NONE'));
    await tester.pump();
    expect(find.text('Select chapters to download'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(ctl.isActive, isFalse);
  });

  testWidgets('novels get WHOLE BOOK', (tester) async {
    final ctl = ChapterSelectionController()..begin();
    await pumpFeature(tester,
        child: Scaffold(body: SelectionBar(controller: ctl, chapters: _chapters(), onDownload: () {}, showWholeBook: true)));
    await tester.tap(find.text('WHOLE BOOK'));
    await tester.pump();
    expect(find.text('28 SELECTED · 2 ALREADY SAVED'), findsOneWidget);
  });

  testWidgets('the seven download marks, each with its tooltip and semantics name', (tester) async {
    final h = tester.ensureSemantics();
    final cases = <(DownloadMarkState, String, String)>[
      (const MarkNone(), 'Not downloaded', 'Download this chapter'),
      (const MarkQueued(), 'Queued', 'Queued to download'),
      (const MarkDownloading(0.3), 'Downloading, 30 percent', 'Downloading'),
      (const MarkSaved(), 'Saved', 'Downloaded — opens with no connection'),
      (const MarkFailed(), 'Failed, tap to retry', 'Failed — tap to try again'),
      (const MarkPaused(), 'Paused', 'Paused — this phone is almost full'),
      (const MarkStale(), 'Saved copy is out of date, download again', 'The source changed these pages — download it again'),
    ];
    await pumpFeature(
      tester,
      child: Scaffold(
        body: Wrap(children: [
          for (final (m, _, _) in cases)
            CineDownloadMark(state: m, reason: m is MarkPaused ? DownloadQueuePauseReason.freeSpaceFloor : null, onTap: () {}),
        ]),
      ),
    );
    for (final (_, label, tip) in cases) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      expect(find.byTooltip(tip), findsOneWidget, reason: tip);
    }
    for (final e in find.byType(CineDownloadMark).evaluate()) {
      final size = tester.getSize(find.byWidget(e.widget));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    h.dispose();
  });

  testWidgets('a paused mark says why: the storage limit', (tester) async {
    await pumpFeature(tester,
        child: const Scaffold(body: CineDownloadMark(state: MarkPaused(), reason: DownloadQueuePauseReason.cap)));
    expect(find.byTooltip('Paused — your 10 GB limit is full'), findsOneWidget);
  });

  Future<void> card(WidgetTester tester, SeriesDownloadSummary? s) => pumpFeature(
        tester,
        rig: FeatureRig(extra: [
          seriesDownloadSummaryProvider.overrideWith((ref, k) => s),
        ]),
        child: Scaffold(
          body: SeriesDownloadCard(series: (sourceId: 'demo', seriesKey: 'k'), listed: 201, onStorage: () {}),
        ),
      );

  testWidgets('the series card: ON THIS DEVICE, saved of total, now, waiting, failed and the foreground note', (tester) async {
    await card(tester, (saved: 12, total: 201, downloadingPage: 7, pageTotal: 40, waiting: 3, failed: 1, pauseReason: null));
    expect(find.text('ON THIS DEVICE'), findsOneWidget);
    expect(find.text('12 OF 201 CHAPTERS SAVED'), findsOneWidget);
    expect(find.text('DOWNLOADING NOW · PAGE 7 OF 40'), findsOneWidget);
    expect(find.text('3 WAITING · 1 FAILED'), findsOneWidget);
    expect(find.textContaining('Downloads run while the app is open'), findsOneWidget);
  });

  testWidgets('the series card is absent when nothing is saved or queued', (tester) async {
    await card(tester, null);
    expect(find.text('ON THIS DEVICE'), findsNothing);
  });

  testWidgets('a blocked queue puts a NOTE with Storage settings on the card', (tester) async {
    await card(tester, (saved: 1, total: 5, downloadingPage: null, pageTotal: null, waiting: 2, failed: 0, pauseReason: DownloadQueuePauseReason.freeSpaceFloor));
    expect(find.text('NOTE'), findsOneWidget);
    expect(find.text('Paused: this phone is almost full.'), findsOneWidget);
    expect(find.text('Storage settings'), findsOneWidget);
  });

  Future<void> run(WidgetTester tester, Map<String, ChapterDownloadStatus> statuses,
          {int already = 0, DownloadQueuePauseReason? pause, int? free}) =>
      pumpFeature(
        tester,
        rig: FeatureRig(statuses: statuses, pauseReason: pause, freeBytes: free),
        child: Scaffold(
          body: DownloadRunLine(
            series: (sourceId: 'demo', seriesKey: 'k'),
            runKeys: const {'c1', 'c2', 'c3'},
            alreadySaved: already,
            onDismiss: () {},
            onManage: () {},
          ),
        ),
      );

  testWidgets('running: DOWNLOADING n OF m with Stop', (tester) async {
    await run(tester, {
      'c1': (state: DownloadChapterState.complete, error: null),
      'c2': (state: DownloadChapterState.downloading, error: null),
      'c3': (state: DownloadChapterState.queued, error: null),
    });
    await tester.pump();
    expect(find.text('DOWNLOADING 1 OF 3'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
  });

  testWidgets('finished: 3 chapters saved, with Dismiss', (tester) async {
    await run(tester, {
      for (final k in ['c1', 'c2', 'c3']) k: (state: DownloadChapterState.complete, error: null),
    });
    await tester.pump();
    expect(find.text('3 chapters saved.'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
  });

  testWidgets('finished with a failure: the NOTE tone and the count', (tester) async {
    await run(tester, {
      'c1': (state: DownloadChapterState.complete, error: null),
      'c2': (state: DownloadChapterState.complete, error: null),
      'c3': (state: DownloadChapterState.failed, error: 'x'),
    });
    await tester.pump();
    expect(find.text('NOTE'), findsOneWidget);
    expect(find.text('2 of 3 saved, 1 failed.'), findsOneWidget);
  });

  testWidgets('everything already saved: nothing to download', (tester) async {
    await run(tester, {
      for (final k in ['c1', 'c2', 'c3']) k: (state: DownloadChapterState.complete, error: null),
    }, already: 3);
    await tester.pump();
    expect(find.text('Nothing to download — those are already saved.'), findsOneWidget);
  });

  testWidgets('out of room: the free-space figure and Manage downloads', (tester) async {
    await run(
      tester,
      {
        'c1': (state: DownloadChapterState.complete, error: null),
        'c2': (state: DownloadChapterState.queued, error: null),
        'c3': (state: DownloadChapterState.queued, error: null),
      },
      pause: DownloadQueuePauseReason.freeSpaceFloor,
      free: 380 * 1024 * 1024,
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Out of room: only 380 MB free. Remove some downloads and run it again.'), findsOneWidget);
    expect(find.text('Manage downloads'), findsOneWidget);
    expect(find.text('NOTE'), findsOneWidget);
  });
}
