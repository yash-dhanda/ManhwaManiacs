// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/downloads/models/saved_chapter.dart' show DownloadKind;
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/repositories/novels_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/book/book_view.dart';

import '../../../features/novels/support/fake_novels_repository.dart';
import '../../../support/downloads_test_support.dart';
import '../../../support/test_overrides.dart';
import '../feature/feature_test_support.dart';

/// c1-c3 narrated (c1 and c2 rendered before the cast change), c4-c12 cached, c12 not.
NovelSeriesAudioDetail detail({bool canRender = true}) => (
      renderedAt: {'c1': DateTime.utc(2026, 9), 'c2': DateTime.utc(2026, 9, 10), 'c3': DateTime.utc(2026, 9, 25)},
      narratable: {for (var i = 1; i <= 11; i++) 'c$i'},
      canRender: canRender,
      castChangedAt: DateTime.utc(2026, 9, 20),
    );

class BookRig {
  BookRig(this.feature, this.repo);
  final FeatureRig feature;
  final FakeNovelsRepository repo;
}

Future<BookRig> pumpBook(
  WidgetTester tester, {
  bool owner = true,
  bool canRender = true,
  List<NovelAudioJob> jobs = const [],
  List<Override> extra = const [],
}) async {
  final repo = FakeNovelsRepository()
    ..seriesAudioDetailResult = Ok(detail(canRender: canRender))
    ..activeJobsResult = Ok(jobs)
    ..audioJobsResults = [Ok(jobs)];
  final r = FeatureRig(
    narrated: const {'c1', 'c2', 'c3'},
    extra: [
      if (owner) authenticatedAuthOverride(),
      novelsRepositoryProvider.overrideWithValue(repo),
      seriesAudioDetailProvider.overrideWith((ref, k) async => detail(canRender: canRender)),
      ...extra,
    ],
  );
  await pumpFeature(tester, rig: r, novel: true, size: const Size(390, 1800), child: BookView(data: fixtureData('novel-short')));
  await settleFeature(tester, by: const Duration(seconds: 2));
  return BookRig(r, repo);
}

/// Taps [f] after scrolling it into view (the quick picks and the chapter list both scroll).
Future<void> press(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(f);
}

Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('audiobook-button')));
  await settleFeature(tester, by: const Duration(milliseconds: 900));
}

void main() {
  initSqfliteFfiForTests();

  testWidgets('only the owner sees the Audiobook button on the book page', (tester) async {
    await pumpBook(tester, owner: false);
    expect(find.byKey(const Key('audiobook-button')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('the owner opens the sheet: kicker, segments, quick picks and per-chapter status captions', (tester) async {
    await pumpBook(tester);
    expect(find.byIcon(Icons.headphones), findsNothing, reason: 'the button is the Phosphor glyph');
    await openSheet(tester);
    expect(find.text('AUDIOBOOK'), findsOneWidget);
    expect(find.text('NARRATE'), findsNothing, reason: 'the segments show only with a downloads scope');
    expect(find.text('NEXT 10'), findsOneWidget);
    expect(find.text('ALL UN-NARRATED'), findsOneWidget);
    expect(find.text('RE-VOICE'), findsOneWidget);
    expect(find.text('NONE'), findsOneWidget);
    expect(find.text('ALREADY NARRATED'), findsWidgets);
    await tester.scrollUntilVisible(find.text('DOWNLOAD THE TEXT FIRST'), 200, scrollable: find.descendant(of: find.byKey(const Key('audiobook-chapters')), matching: find.byType(Scrollable)).first);
    expect(find.text('DOWNLOAD THE TEXT FIRST'), findsOneWidget);
    expect(find.text('About 9 minutes of rendering per chapter on the narration PC.'), findsOneWidget);
    expect(find.text('Narrate 0 chapters'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('RE-VOICE selects the stale chapters; the send is one request with force true for them', (tester) async {
    final r = await pumpBook(tester);
    await openSheet(tester);
    await press(tester, find.text('RE-VOICE'));
    await settleFeature(tester, by: const Duration(milliseconds: 400));
    expect(find.text('ALREADY NARRATED · WILL BE RE-VOICED'), findsNWidgets(2));
    expect(find.text('Narrate 2 chapters'), findsOneWidget);
    await tester.tap(find.text('Narrate 2 chapters'));
    await settleFeature(tester, by: const Duration(milliseconds: 600));
    expect(r.repo.renderCalls, hasLength(1));
    expect(r.repo.renderCalls.single.keys, ['c1', 'c2']);
    expect(r.repo.renderCalls.single.force, isTrue);
    expect(r.repo.renderCalls.single.priority, 0);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('a mixed selection goes out as force true for the narrated and force false for the rest', (tester) async {
    final r = await pumpBook(tester);
    await openSheet(tester);
    await press(tester, find.text('ALL UN-NARRATED'));
    await settleFeature(tester, by: const Duration(milliseconds: 300));
    // Add a narrated chapter by hand.
    await press(tester, find.textContaining('Chapter 1 ·').first);
    await settleFeature(tester, by: const Duration(milliseconds: 300));
    await tester.tap(find.textContaining('Narrate '));
    await settleFeature(tester, by: const Duration(milliseconds: 600));
    expect(r.repo.renderCalls.map((c) => c.force), containsAll([true, false]));
    final forced = r.repo.renderCalls.firstWhere((c) => c.force);
    expect(forced.keys, ['c1']);
    final fresh = r.repo.renderCalls.firstWhere((c) => !c.force);
    expect(fresh.keys, isNot(contains('c1')));
    expect(fresh.keys, contains('c4'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('a 503 narration_unavailable says narration is not available and keeps the sheet open', (tester) async {
    final r = await pumpBook(tester);
    r.repo.requestAudioResult = const Err(ApiError(statusCode: 503, code: 'narration_unavailable', message: 'Narration of new chapters is not available right now.'));
    await openSheet(tester);
    await press(tester, find.text('ALL UN-NARRATED'));
    await settleFeature(tester, by: const Duration(milliseconds: 300));
    await tester.tap(find.textContaining('Narrate '));
    await settleFeature(tester, by: const Duration(milliseconds: 600));
    expect(find.text("Narration of new chapters isn't available right now. Chapters that already have audio can still be saved."), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('without a render worker the caption shows up front and Narrate is off', (tester) async {
    await pumpBook(tester, canRender: false);
    await openSheet(tester);
    expect(find.byKey(const Key('narration-unavailable')), findsOneWidget);
    await press(tester, find.text('ALL UN-NARRATED'));
    await settleFeature(tester, by: const Duration(milliseconds: 300));
    final button = find.textContaining('Narrate ');
    expect(button, findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('the job list shows each state with a determinate rule and Cancel', (tester) async {
    final r = await pumpBook(tester, jobs: [
      const NovelAudioJob(jobId: 'j1', chapterKey: 'c4', chapterNumber: 4, status: 'queued', progress: 0, errorCode: null),
      const NovelAudioJob(jobId: 'j2', chapterKey: 'c5', chapterNumber: 5, status: 'rendering', progress: 0.4, errorCode: null),
      const NovelAudioJob(jobId: 'j3', chapterKey: 'c6', chapterNumber: 6, status: 'failed', progress: 0.1, errorCode: 'render_failed', errorDetail: 'The render box dropped the job.'),
    ]);
    await openSheet(tester);
    await settleFeature(tester, by: const Duration(milliseconds: 600));
    expect(find.text('QUEUED'), findsOneWidget);
    expect(find.text('RENDERING 40 %'), findsOneWidget);
    expect(find.textContaining('FAILED'), findsOneWidget);
    expect(find.text('Cancel'), findsNWidgets(2), reason: 'only the queued and the rendering job can be cancelled');
    await tester.ensureVisible(find.text('Cancel').first);
    await tester.tap(find.text('Cancel').first);
    await settleFeature(tester, by: const Duration(milliseconds: 500));
    expect(r.repo.cancelledJobs, ['j1']);
    await settleFeature(tester, by: const Duration(milliseconds: 1500));
    expect(find.text('IT STOPS SHORTLY.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('with a downloads scope the SAVE segment saves narrated chapters (and the text with them)', (tester) async {
    final harness = (await tester.runAsync(TestDownloadsHarness.create))!;
    addTearDown(harness.dispose);
    final r = await pumpBook(tester, extra: [downloadsStoreProvider.overrideWithValue(harness.storeFor('u1p1'))]);
    await openSheet(tester);
    expect(find.text('NARRATE'), findsOneWidget);
    await press(tester, find.text('SAVE TO THIS DEVICE'));
    await settleFeature(tester, by: const Duration(milliseconds: 400));
    expect(find.text('NEXT 10'), findsOneWidget);
    expect(find.text('ALL NARRATED'), findsOneWidget);
    expect(find.text('RE-VOICE'), findsNothing);
    expect(find.text('NOT NARRATED YET'), findsWidgets);
    expect(find.text('NARRATED'), findsWidgets);
    expect(find.text('Saves while the app is open; the text is saved too.'), findsOneWidget);
    await press(tester, find.text('ALL NARRATED'));
    await settleFeature(tester, by: const Duration(milliseconds: 300));
    expect(find.text('Save audio of 3 chapters'), findsOneWidget);
    await tester.tap(find.text('Save audio of 3 chapters'));
    await settleFeature(tester, by: const Duration(milliseconds: 600));
    final kinds = [for (final batch in r.feature.rec.enqueued) for (final q in batch) q.kind];
    expect(kinds.where((k) => k == DownloadKind.audio), hasLength(3));
    expect(kinds.where((k) => k == DownloadKind.novel), hasLength(3));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
  });
}
