// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/run_feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_tabs.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/manga_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/schedule_row.dart';

import 'feature_test_support.dart';

Future<FeatureRig> _page(WidgetTester tester, {FeatureRig? rig, Size? size}) async {
  final r = rig ?? FeatureRig(followed: followedRow());
  await pumpFeature(tester,
      rig: r, size: size ?? const Size(390, 1800), child: MangaFeatureView(data: fixtureData('manga-long', followed: r.followed)));
  await scrollToPanels(tester);
  return r;
}

void main() {
  testWidgets('follow fires follow.add (stamp) and unfollow offers Undo', (tester) async {
    final r = await pumpFeature(tester,
        rig: FeatureRig(), child: MangaFeatureView(data: fixtureData('manga-ongoing')));
    await tester.tap(find.text('FOLLOW'));
    await frames(tester, 300);
    expect(r.rec.haptics, contains('follow.add'));
    expect(r.rec.following, ['follow:demo/k']);
    expect(find.text('Following Tower of Dawn. New chapters will notify you.'), findsOneWidget);
  });

  testWidgets('favourite fires favorite', (tester) async {
    final r = await pumpFeature(tester,
        rig: FeatureRig(followed: followedRow()),
        child: MangaFeatureView(data: fixtureData('manga-ongoing', followed: followedRow())));
    await tester.tap(find.text('FAVOURITE'));
    await frames(tester, 300);
    expect(r.rec.haptics, contains('favorite'));
    expect(r.rec.patches.single['is_favorite'], isTrue);
  });

  testWidgets('long-press opens the row menu with longpress.open; marks fire select', (tester) async {
    final r = await _page(tester);
    await tester.longPress(find.byType(ScheduleRow).first);
    await frames(tester, 500);
    expect(r.rec.haptics, contains('longpress.open'));
    await tester.tap(find.text('Mark read'));
    await frames(tester, 600);
    expect(r.rec.haptics, contains('select'));
  });

  testWidgets('Bookmark start is reported (no scope in this rig)', (tester) async {
    await _page(tester);
    await tester.tap(find.byTooltip('Chapter options').first);
    await frames(tester, 500);
    await tester.tap(find.text('Bookmark start'));
    await frames(tester, 600);
    expect(find.text("Couldn't bookmark it."), findsOneWidget);
  });

  testWidgets('Download N plays download.start when the queue accepts', (tester) async {
    final r = await _page(tester);
    await tester.tap(find.text('Select'));
    await frames(tester, 300);
    await tester.tap(find.text('NEXT 10'));
    await tester.pump();
    await tester.tap(find.text('Download 10'));
    await frames(tester);
    expect(r.rec.haptics, contains('download.start'));
    expect(r.rec.haptics, isNot(contains('download.done')));
  });

  testWidgets('RunFeedback: download.done once when the batch settles, download.fail once on a failure', (tester) async {
    final r = FeatureRig();
    final fb = RunFeedback();
    late WidgetRef captured;
    await pumpFeature(
      tester,
      rig: r,
      child: Consumer(builder: (context, ref, _) {
        captured = ref;
        return const SizedBox();
      }),
    );
    ChapterDownloadStatus st(DownloadChapterState s) => (state: s, error: null);
    fb.check(captured, {'a', 'b'}, {'a': st(DownloadChapterState.complete), 'b': st(DownloadChapterState.downloading)});
    expect(r.rec.haptics, isEmpty);
    fb.check(captured, {'a', 'b'}, {'a': st(DownloadChapterState.complete), 'b': st(DownloadChapterState.complete)});
    fb.check(captured, {'a', 'b'}, {'a': st(DownloadChapterState.complete), 'b': st(DownloadChapterState.complete)});
    expect(r.rec.haptics, ['download.done']);
    fb.reset();
    fb.check(captured, {'a', 'b'}, {'a': st(DownloadChapterState.failed), 'b': st(DownloadChapterState.queued)});
    fb.check(captured, {'a', 'b'}, {'a': st(DownloadChapterState.failed), 'b': st(DownloadChapterState.queued)});
    expect(r.rec.haptics.where((h) => h == 'download.fail').length, 1);
  });

  testWidgets('a tab list is data: extra tabs append without renumbering', (tester) async {
    await pumpFeature(
      tester,
      size: const Size(390, 2000),
      child: MangaFeatureView(
        data: fixtureData('manga-ongoing'),
        extraTabs: [
          FeatureTab(id: 'more', label: 'MORE LIKE THIS', panelBuilder: (_) => const Center(child: Text('similar'))),
        ],
      ),
    );
    expect(find.textContaining('01 CHAPTERS'), findsOneWidget);
    expect(find.text('02 DETAILS'), findsOneWidget);
    expect(find.text('03 MORE LIKE THIS'), findsOneWidget);
  });
}
