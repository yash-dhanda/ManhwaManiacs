// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/manga_view.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/schedule_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/offline_edition.dart';

import 'feature_test_support.dart';

Future<FeatureRig> _view(
  WidgetTester tester,
  FeatureRig rig, {
  bool novel = false,
  Size? size,
}) =>
    pumpFeature(
      tester,
      novel: novel,
      size: size,
      rig: rig,
      child: const FeatureView(sourceId: 'demo', seriesKey: 'k'),
    );

FeatureRig _rigWith(
  Future<SourceSeriesDetailData> Function() detail, {
  List<Override> extra = const [],
  bool online = true,
  FollowedSeries? followed,
}) =>
    FeatureRig(online: online, followed: followed, extra: [
      sourceSeriesDetailProvider.overrideWith((ref, p) => detail()),
      ...extra,
    ]);

void main() {
  testWidgets('loading shows the galley', (tester) async {
    await _view(tester, _rigWith(() => Future<SourceSeriesDetailData>.delayed(const Duration(seconds: 30))));
    expect(find.bySemanticsLabel('Loading'), findsNothing); // semantics off; the galley is a plain plate
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Tower of Dawn'), findsNothing);
    await tester.pump(const Duration(seconds: 31));
  });

  testWidgets('a series error is CORRECTION with Try again and Back to the source', (tester) async {
    await _view(tester, _rigWith(() async => throw const ApiError(statusCode: 500, code: 'boom', message: 'x')));
    await settleFeature(tester, by: const Duration(seconds: 3));
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(find.text("Couldn't load this series."), findsOneWidget);
    expect(find.text('The source did not answer.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Back to the source'), findsOneWidget);
  });

  testWidgets('notice headlines type at 50 ms per character', (tester) async {
    await _view(tester, _rigWith(() async => throw const ApiError(statusCode: 500, code: 'boom', message: 'x')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    String typed() => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((s) => s.isNotEmpty && "Couldn't load this series.".startsWith(s) && s.length < 27,
            orElse: () => '');
    final early = typed();
    expect(early.length, lessThan(12));
    await settleFeature(tester, by: const Duration(seconds: 3));
    expect(find.text("Couldn't load this series."), findsWidgets);
  });

  testWidgets('offline with saved chapters renders the page under OFFLINE EDITION with only saved rows', (tester) async {
    final f = loadSeriesFixture('manga-ongoing');
    final saved = (series: f.series, chapters: f.chapters.take(2).toList());
    await _view(
      tester,
      size: const Size(390, 2000),
      _rigWith(() async => throw const NetworkError(message: 'offline'), online: false, extra: [
        offlineEditionProvider.overrideWith((ref, k) async => saved),
      ]),
    );
    await settleFeature(tester, by: const Duration(seconds: 3));
    expect(find.text('OFFLINE EDITION'), findsOneWidget);
    await scrollToPanels(tester);
    expect(find.byType(ScheduleRow), findsNWidgets(2));
    expect(find.text('Tower of Dawn'), findsWidgets);
  });

  testWidgets('a stale payload wears the SAVED COPY badge', (tester) async {
    final f = loadSeriesFixture('manga-ongoing');
    final s = f.series;
    final stale = SourceSeriesSummary(
      id: s.id,
      sourceId: s.sourceId,
      title: s.title,
      chapterCount: s.chapterCount,
      genres: s.genres,
      coverUrl: '',
      cacheStale: true,
      cacheFetchedAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 5)),
    );
    await _view(
      tester,
      size: const Size(390, 2000),
      _rigWith(() async => SourceSeriesDetailData(series: stale, chapters: f.chapters)),
    );
    await settleFeature(tester, by: const Duration(seconds: 2));
    expect(find.text('SAVED COPY · 3 H'), findsOneWidget);
  });

  testWidgets('a book that cannot load offline says so, and errors are CORRECTION', (tester) async {
    await _view(
      tester,
      novel: true,
      _rigWith(() async => throw const NetworkError(message: 'offline'), online: false),
    );
    await settleFeature(tester, by: const Duration(seconds: 3));
    expect(find.text('This book needs a connection to load.'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    await _view(
      tester,
      novel: true,
      _rigWith(() async => throw const ApiError(statusCode: 500, code: 'boom', message: 'x')),
    );
    await settleFeature(tester, by: const Duration(seconds: 3));
    expect(find.text('CORRECTION'), findsOneWidget);
    expect(find.text("Couldn't load this book."), findsWidgets);
    expect(find.text('Back to the source'), findsOneWidget);
  });

  testWidgets('the rating card shows for a mature series (gate open), 3 s, and never blocks', (tester) async {
    await pumpFeature(
      tester,
      rig: FeatureRig(followed: followedRow(rating: 'mature')),
      child: MangaFeatureView(data: fixtureData('manga-mature', followed: followedRow(rating: 'mature'))),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('rating-card')), findsOneWidget);
    expect(find.text('18+'), findsOneWidget);
    expect(find.text('Violence · Sexual content'), findsOneWidget);
    // The page underneath still takes taps while it shows.
    expect(find.byType(IgnorePointer), findsWidgets);
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('rating-card')), findsNothing);
  });

  testWidgets('no rating card for a safe series or with the gate closed', (tester) async {
    await pumpFeature(
      tester,
      rig: FeatureRig(followed: followedRow()),
      child: MangaFeatureView(data: fixtureData('manga-ongoing', followed: followedRow())),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('rating-card')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await pumpFeature(
      tester,
      rig: FeatureRig(followed: followedRow(rating: 'mature'), extra: [
        matureContentProvider.overrideWith(_MatureOff.new),
      ]),
      child: MangaFeatureView(data: fixtureData('manga-mature', followed: followedRow(rating: 'mature'))),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('rating-card')), findsNothing);
  });

  testWidgets('the running head: transparent, then black with the running title after scrolling', (tester) async {
    await pumpFeature(tester, child: MangaFeatureView(data: fixtureData('manga-ongoing')));
    await settleFeature(tester, by: const Duration(seconds: 1));
    expect(tester.widget<AnimatedOpacity>(find.ancestor(of: find.byKey(const Key('running-title')), matching: find.byType(AnimatedOpacity)).first).opacity, 0);
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -700));
    await frames(tester, 500);
    expect(tester.widget<AnimatedOpacity>(find.ancestor(of: find.byKey(const Key('running-title')), matching: find.byType(AnimatedOpacity)).first).opacity, 1);
  });

  testWidgets('the tablet spread: art in columns 5-8, height clamp(520, 0.64 x screen, 760)', (tester) async {
    await pumpFeature(tester, wide: true, child: MangaFeatureView(data: fixtureData('manga-ongoing')));
    final spread = tester.getSize(find.byKey(const Key('feature-spread')));
    expect(spread.height, closeTo((1194 * 0.64).clamp(520.0, 760.0), 0.5));
    expect(spread.width, 834);
  });

  testWidgets('the phone hero is 4:5, height min(width x 1.25, 0.70 x screen)', (tester) async {
    await pumpFeature(tester, child: MangaFeatureView(data: fixtureData('manga-ongoing')));
    final cover = tester.getSize(find.byKey(const Key('feature-cover-frame'), skipOffstage: false));
    expect(cover.height, closeTo((390 * 1.25).clamp(0.0, 844 * 0.70), 0.5));
    expect(cover.width, 390);
  });
}

class _MatureOff extends MatureContentController {
  @override
  Future<bool> build() async => false;
}
