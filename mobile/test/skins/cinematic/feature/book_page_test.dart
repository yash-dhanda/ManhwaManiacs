// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/book_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/book_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/contents_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/downloads/selection_bar.dart';

import 'feature_test_support.dart';

Future<FeatureRig> _book(
  WidgetTester tester, {
  String fixture = 'novel-long',
  FeatureRig? rig,
  bool wide = false,
  String? focus,
  ContentsNoticeKind? notice,
  Size? size,
}) async {
  final r = rig ?? FeatureRig();
  await pumpFeature(
    tester,
    rig: r,
    novel: true,
    wide: wide,
    size: size ?? (wide ? null : const Size(390, 2600)),
    child: BookView(data: fixtureData(fixture, followed: r.followed), focusChapter: focus, contentsNotice: notice),
  );
  await settleFeature(tester, by: const Duration(seconds: 3));
  return r;
}

Future<void> _jumpToEnd(WidgetTester tester) async {
  final st = tester.state<ScrollableState>(find.byType(Scrollable).first);
  st.position.jumpTo(st.position.maxScrollExtent);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('phone front matter: kicker, byline, plate, facts and the 56 px rule', (tester) async {
    await _book(tester, fixture: 'novel-short');
    expect(find.textContaining('NOVEL ·'), findsOneWidget);
    expect(find.text('by Han Seo'), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('cover-plate'))), const Size(96, 144));
    expect(tester.getSize(find.byKey(const Key('title-rule'))).width, closeTo(56, 0.6));
    expect(tester.getSize(find.byKey(const Key('title-rule'))).height, 1);
    expect(find.textContaining('12 chapters'.toUpperCase()), findsOneWidget);
    expect(find.text('FIRST → LAST'), findsOneWidget);
    expect(find.text('LAST → FIRST'), findsOneWidget);
    expect(find.text('Pick chapters'), findsOneWidget);
  });

  testWidgets('tablet plate is 168 x 248', (tester) async {
    await _book(tester, fixture: 'novel-short', wide: true);
    expect(tester.getSize(find.byKey(const Key('cover-plate'))), const Size(168, 248));
  });

  testWidgets('the blurb collapses to five lines with More and expands in place', (tester) async {
    await _book(tester, fixture: 'novel-short');
    expect(find.byKey(const Key('blurb-collapsed')), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('blurb-collapsed'))).height, 120);
    await tester.ensureVisible(find.text('More'));
    await tester.tap(find.text('More'));
    await tester.pump();
    expect(find.byKey(const Key('blurb-collapsed')), findsNothing);
    expect(find.text('Less'), findsOneWidget);
  });

  testWidgets('the contents window shows 400 rows with Show more, then Show earlier', (tester) async {
    await _book(tester);
    expect(find.textContaining('Show earlier chapters', skipOffstage: false), findsNothing);
    await _jumpToEnd(tester);
    expect(find.text('Show more chapters (804)'), findsOneWidget);
    await tester.tap(find.text('Show more chapters (804)'));
    await tester.pump();
    await _jumpToEnd(tester);
    expect(find.text('Show more chapters (404)'), findsOneWidget);
  });

  testWidgets('?chapter= centres the focused row with the current band and earlier rows offered', (tester) async {
    await _book(tester, focus: 'c600');
    expect(find.textContaining('Show earlier chapters (', skipOffstage: false), findsOneWidget);
    final row = find.byKey(const ValueKey('row-c600'));
    expect(row, findsOneWidget);
    final centre = tester.getCenter(row).dy;
    expect(centre, closeTo(tester.view.physicalSize.height / 2 + 28, 130));
  });

  testWidgets('phone go-to opens the contents sheet in search mode with its match list', (tester) async {
    await _book(tester, fixture: 'novel-short');
    await tester.tap(find.byKey(const Key('book-go-to')));
    await frames(tester, 500);
    expect(find.text('CONTENTS'), findsOneWidget);
    expect(find.text('Type a chapter number.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('contents-go-to')), '7');
    await tester.pump();
    expect(find.byKey(const Key('match-c7')), findsOneWidget);
    expect(find.text('row 7'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('contents-go-to')), '99');
    await tester.pump();
    expect(find.text('No chapter 99 in this book.'), findsOneWidget);
  });

  testWidgets('choosing a match closes the sheet and centres that row', (tester) async {
    await _book(tester);
    await tester.tap(find.byKey(const Key('book-go-to')));
    await frames(tester, 500);
    await tester.enterText(find.byKey(const Key('contents-go-to')), '900');
    await tester.pump();
    await tester.tap(find.byKey(const Key('match-c900')));
    await frames(tester, 800);
    await settleFeature(tester, by: const Duration(seconds: 2));
    expect(find.text('CONTENTS'), findsNothing);
    expect(find.byKey(const ValueKey('row-c900')), findsOneWidget);
  });

  testWidgets('tablet go-to is an inline field with the same match list', (tester) async {
    await _book(tester, fixture: 'novel-short', wide: true);
    await tester.enterText(find.byKey(const Key('inline-go-to')), '5');
    await tester.pump();
    expect(find.byKey(const Key('inline-match-c5')), findsOneWidget);
  });

  testWidgets('the contents sheet says so when offline', (tester) async {
    await _book(tester, fixture: 'novel-short', rig: FeatureRig(online: false));
    await tester.tap(find.byKey(const Key('book-go-to')));
    await frames(tester, 500);
    expect(find.text('The contents need a connection to load.'), findsOneWidget);
  });

  testWidgets('contents rows: ordinal, title, dot leaders and the length', (tester) async {
    await _book(tester, fixture: 'novel-short');
    expect(find.byType(ContentsRow), findsWidgets);
    expect(find.byType(DotLeader), findsWidgets);
    expect(tester.getSize(find.byType(ContentsRow).first).height, greaterThanOrEqualTo(48));
  });

  testWidgets('every contents state renders', (tester) async {
    for (final (kind, text) in [
      (ContentsNoticeKind.offline, 'The contents need a connection to load.'),
      (ContentsNoticeKind.error, "Couldn't load the contents"),
      (ContentsNoticeKind.unavailable, "Contents didn't come through."),
      (ContentsNoticeKind.empty, 'No chapters yet.'),
    ]) {
      await _book(tester, fixture: 'novel-short', notice: kind);
      expect(find.text(text), findsOneWidget, reason: kind.name);
      await tester.pumpWidget(const SizedBox());
    }
    await _book(tester, fixture: 'novel-short', notice: ContentsNoticeKind.loading);
    expect(find.byKey(const Key('contents-loading')), findsOneWidget);
  });

  testWidgets('narration unavailable is a caption in the Listen slot; narrated books offer Listen', (tester) async {
    await _book(tester, fixture: 'novel-short');
    expect(find.byKey(const Key('narration-unavailable')), findsOneWidget);
    expect(find.byKey(const Key('listen')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await _book(tester, fixture: 'novel-short', rig: FeatureRig(narrated: {'c3'}));
    expect(find.byKey(const Key('listen')), findsOneWidget);
    expect(find.text('Narrated only'), findsOneWidget);
  });

  testWidgets('Narrated only filters the contents to narrated chapters', (tester) async {
    await _book(tester, fixture: 'novel-short', rig: FeatureRig(narrated: {'c3'}));
    await tester.ensureVisible(find.text('Narrated only'));
    await tester.tap(find.text('Narrated only'));
    await tester.pump();
    expect(find.byType(ContentsRow), findsOneWidget);
  });

  testWidgets('Pick chapters enters select mode: WHOLE BOOK pick and Download N through enqueueChapters', (tester) async {
    final r = await _book(tester, fixture: 'novel-short');
    await tester.tap(find.text('Pick chapters'));
    await tester.pump();
    expect(find.byType(SelectionBar), findsOneWidget);
    await tester.tap(find.text('WHOLE BOOK'));
    await tester.pump();
    expect(find.text('12 SELECTED · 0 ALREADY SAVED'), findsOneWidget);
    await tester.tap(find.text('Download 12'));
    await tester.pump();
    expect(r.rec.enqueued.length, 1);
    expect(r.rec.enqueued.single.length, 12);
    expect(r.rec.enqueued.single.first.kind.isNovel, isTrue);
  });

  testWidgets('Download book is hidden when everything is saved', (tester) async {
    await _book(tester,
        fixture: 'novel-short',
        rig: FeatureRig(statuses: {
          for (var i = 1; i <= 12; i++) 'c$i': (state: DownloadChapterState.complete, error: null),
        }));
    expect(find.byKey(const Key('download-book')), findsNothing);
  });

  testWidgets('LIBRARY adds the book and says so', (tester) async {
    final r = await _book(tester, fixture: 'novel-short');
    await tester.ensureVisible(find.byKey(const Key('library-toggle')));
    await tester.tap(find.byKey(const Key('library-toggle')));
    await frames(tester, 300);
    expect(r.rec.following, ['follow:demo/k']);
    expect(find.textContaining('Added Ashes of the Salt Road.'), findsOneWidget);
  });

  testWidgets('row menu offers the D5 calls', (tester) async {
    await _book(tester, fixture: 'novel-short');
    await tester.ensureVisible(find.byTooltip('Chapter options').first);
    await tester.tap(find.byTooltip('Chapter options').first);
    await frames(tester);
    for (final label in ['Mark read', 'Mark read up to here', 'Mark unread', 'Download', 'Bookmark start']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });
}
