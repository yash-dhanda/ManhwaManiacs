// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/manga_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/schedule_row.dart';

import 'feature_test_support.dart';

SourceChapterProgress _p(int page, int count, {bool done = false}) => SourceChapterProgress(
      page: page,
      pageCount: count,
      completed: done,
      updatedAt: DateTime.utc(2026, 9, 29),
    );

Future<FeatureRig> _pump(
  WidgetTester tester, {
  String fixture = 'manga-long',
  FeatureRig? rig,
  bool wide = false,
  Size? size,
}) async {
  final r = await pumpFeature(tester,
      rig: rig, wide: wide, size: size, child: MangaFeatureView(data: fixtureData(fixture)));
  // The hero fills the first screen; scroll the page up to the chapter rows.
  await tester.drag(find.byType(NestedScrollView), const Offset(0, -600));
  await frames(tester);
  return r;
}

Future<void> _menu(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Chapter options').first);
  await frames(tester);
  await tester.tap(find.text(label));
  await frames(tester, 600);
}

void main() {
  testWidgets('rows are 56 px with the number right-aligned, dots for null, and lazily built', (tester) async {
    await _pump(tester, fixture: 'manga-ongoing');
    final rows = find.byType(ScheduleRow);
    expect(rows, findsNWidgets(4));
    expect(tester.getSize(rows.first).height, 56);
    // The unnumbered bonus page prints a middle dot in the number column.
    expect(find.text('·'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a 201-row list builds only the rows on screen', (tester) async {
    await _pump(tester);
    final built = find.byType(ScheduleRow).evaluate().length;
    expect(built, lessThan(30));
    expect(built, greaterThan(3));
  });

  testWidgets('the current chapter carries the READING badge and the wash', (tester) async {
    await _pump(tester,
        rig: FeatureRig(serverProgress: {'c200': _p(3, 20)}));
    await tester.pump();
    expect(find.text('READING'), findsOneWidget);
  });

  testWidgets('a read chapter shows READ and a repeated number is not repeated in the title', (tester) async {
    await _pump(tester, rig: FeatureRig(serverProgress: {'c201': _p(20, 20, done: true)}));
    expect(find.text('READ'), findsWidgets);
  });

  testWidgets('the first 2 rows prefetch one manifest each on load', (tester) async {
    final r = await _pump(tester);
    await tester.pump(const Duration(milliseconds: 50));
    expect(r.rec.manifests.toSet(), {'c201', 'c200'});
    expect(r.rec.manifests.length, 2);
  });

  testWidgets('Mark read sends one manual row and Undo deletes the key', (tester) async {
    final r = await _pump(tester);
    await _menu(tester, 'Mark read');
    expect(r.rec.pushedRows.length, 1);
    expect(r.rec.pushedRows.single.manual, isTrue);
    expect(r.rec.pushedRows.single.isCompleted, isTrue);
    expect(r.rec.pushedRows.single.chapterKey, 'c201');
    expect(find.text('Marked chapter 201 read.'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(r.rec.deleted.single.keys, ['c201']);
  });

  testWidgets('Mark read up to here sends manual rows in chunks of 200', (tester) async {
    final r = await _pump(tester);
    await _menu(tester, 'Mark read up to here');
    expect(r.rec.pushed.map((b) => b.length).toList(), [200, 1]);
    expect(r.rec.pushedRows.every((p) => p.manual), isTrue);
    expect(find.text('Marked 201 chapters read.'), findsOneWidget);
  });

  testWidgets('Undo after up to here only deletes what was unread before', (tester) async {
    final r = await _pump(tester, rig: FeatureRig(serverProgress: {'c1': _p(20, 20, done: true)}));
    await tester.pump();
    await _menu(tester, 'Mark read up to here');
    await tester.tap(find.text('Undo'));
    await tester.pump();
    final keys = r.rec.deleted.expand((d) => d.keys).toList();
    expect(keys, isNot(contains('c1')));
    expect(keys.length, 200);
  });

  testWidgets('Mark unread deletes the key and Undo re-posts the row', (tester) async {
    final r = await _pump(tester, rig: FeatureRig(serverProgress: {'c201': _p(20, 20, done: true)}));
    await tester.pump();
    await _menu(tester, 'Mark unread');
    expect(r.rec.deleted.single.keys, ['c201']);
    expect(find.text('Marked chapter 201 unread.'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(r.rec.pushedRows.single.chapterKey, 'c201');
    expect(r.rec.pushedRows.single.isCompleted, isTrue);
    expect(r.rec.pushedRows.single.manual, isFalse);
  });

  testWidgets('offline every mark item is disabled with Needs a connection', (tester) async {
    final r = await _pump(tester, rig: FeatureRig(online: false));
    await tester.pump();
    await tester.tap(find.byTooltip('Chapter options').first);
    await frames(tester);
    await tester.tap(find.text('Mark read'));
    await frames(tester);
    expect(r.rec.pushedRows, isEmpty);
    expect(find.byTooltip('Needs a connection.'), findsNWidgets(3));
  });

  testWidgets('Bookmark start is offered on every row menu', (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('Chapter options').first);
    await frames(tester);
    expect(find.text('Bookmark start'), findsOneWidget);
    expect(find.text('Mark unread'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Download'), findsOneWidget);
  });

  testWidgets('select mode: tap toggles, long-press selects the range from the last toggled row', (tester) async {
    await _pump(tester, size: const Size(390, 1800));
    await tester.tap(find.text('Select'));
    await tester.pump();
    final rows = find.byType(ScheduleRow);
    await tester.tap(rows.at(0));
    await tester.pump();
    await tester.longPress(rows.at(3));
    await tester.pump();
    expect(find.text('4 SELECTED · 0 ALREADY SAVED'), findsOneWidget);
  });

  testWidgets('Download N calls enqueueChapters once with every selected chapter', (tester) async {
    final r = await _pump(tester);
    await tester.tap(find.text('Select'));
    await tester.pump();
    await tester.tap(find.text('NEXT 10'));
    await tester.pump();
    await tester.tap(find.text('Download 10'));
    await tester.pump();
    expect(r.rec.enqueued.length, 1);
    expect(r.rec.enqueued.single.map((q) => q.id.chapterKey).toSet(),
        {for (var i = 1; i <= 10; i++) 'c$i'});
  });

  testWidgets('saved chapters are checked and disabled in select mode', (tester) async {
    await _pump(tester,
        size: const Size(390, 1800),
        rig: FeatureRig(statuses: {
          'c201': (state: DownloadChapterState.complete, error: null),
        }));
    await tester.pump();
    await tester.tap(find.text('Select'));
    await tester.pump();
    await tester.tap(find.byType(ScheduleRow).first);
    await tester.pump();
    expect(find.text('Select chapters to download'), findsOneWidget);
    expect(find.text('0 SELECTED · 1 ALREADY SAVED'), findsNothing);
  });

  testWidgets('a hardware Shift-click range works like the touch long-press', (tester) async {
    await _pump(tester, size: const Size(390, 1800));
    await tester.tap(find.text('Select'));
    await tester.pump();
    final rows = find.byType(ScheduleRow);
    await tester.tap(rows.at(1));
    await tester.pump();
    await tester.longPress(rows.at(2), kind: PointerDeviceKind.touch);
    await tester.pump();
    expect(find.text('2 SELECTED · 0 ALREADY SAVED'), findsOneWidget);
  });

  Future<void> emptyCase(WidgetTester tester, {required int listed, bool online = true}) async {
    final base = fixtureData('manga-ongoing');
    final series = SourceSeriesSummary(
      id: base.series.id,
      sourceId: base.series.sourceId,
      title: base.series.title,
      chapterCount: listed,
      genres: const [],
      coverUrl: '',
    );
    await pumpFeature(tester,
        size: const Size(390, 1800),
        rig: FeatureRig(online: online),
        child: MangaFeatureView(
          data: FeatureData(
            sourceId: base.sourceId,
            seriesKey: base.seriesKey,
            series: series,
            chapters: const [],
          ),
        ));
    await frames(tester);
  }

  testWidgets('no chapters listed: the source has not published any', (tester) async {
    await emptyCase(tester, listed: 0);
    expect(find.text("No chapters yet. The source hasn't published any."), findsOneWidget);
    expect(find.text('Back to the source'), findsOneWidget);
  });

  testWidgets('chapters listed but none returned: unavailable with Try again', (tester) async {
    await emptyCase(tester, listed: 201);
    expect(find.textContaining('lists 201 chapters but returned none just now'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('offline with no list: the chapter list needs a connection', (tester) async {
    await emptyCase(tester, listed: 201, online: false);
    expect(find.text('The chapter list needs a connection.'), findsOneWidget);
  });
}
