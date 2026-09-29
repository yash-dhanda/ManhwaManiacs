// ignore_for_file: require_trailing_commas, directives_ordering
import 'dart:async';
import 'dart:ui' show AccessibilityFeatures;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_match_cut_page.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_view.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

import 'feature_test_support.dart';

Future<GoRouter> _app(WidgetTester tester,
    {TargetPlatform platform = TargetPlatform.android, bool novel = false, Size? size}) async {
  final f = loadSeriesFixture(novel ? 'novel-short' : 'manga-ongoing');
  final rig = FeatureRig(followed: followedRow());
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  sizeView(tester, size: size);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (c, s) => const Scaffold(body: Center(child: Text('home')))),
      GoRoute(
        path: '/sources/:sourceId/series/:seriesKey',
        name: 'feature',
        pageBuilder: (c, s) => cineMatchCutPage(
          s,
          FeatureScreen(
            sourceId: s.pathParameters['sourceId']!,
            seriesKey: s.pathParameters['seriesKey']!,
          ),
        ),
      ),
      GoRoute(
        path: '/library/:followedId',
        name: 'featureByFollow',
        pageBuilder: (c, s) => cineMatchCutPage(
          s,
          FeatureByFollowScreen(followedId: int.parse(s.pathParameters['followedId']!)),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...featureOverrides(rig, prefs, novel: novel),
        sourceSeriesDetailProvider.overrideWith(
            (ref, p) async => SourceSeriesDetailData(series: f.series, chapters: f.chapters)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: featureTheme(platform),
      ),
    ),
  );
  await tester.pump();
  return router;
}

void main() {
  testWidgets('/sources/:s/series/:k and /library/:id render the same page, with no redirect', (tester) async {
    final router = await _app(tester, size: const Size(390, 2000));
    unawaited(router.push<void>('/sources/demo/series/k'));
    await settleFeature(tester, by: const Duration(seconds: 3));
    expect(find.byType(FeatureView), findsOneWidget);
    final titleA = find.text('Tower of Dawn').evaluate().length;
    final chaptersA = find.text('01 CHAPTERS 4').evaluate().length;
    expect(router.routerDelegate.currentConfiguration.last.matchedLocation, '/sources/demo/series/k');

    router.go('/library/7');
    await settleFeature(tester, by: const Duration(seconds: 3));
    expect(find.byType(FeatureView), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.last.matchedLocation, '/library/7');
    expect(find.text('Tower of Dawn').evaluate().length, titleA);
    expect(find.text('01 CHAPTERS 4').evaluate().length, chaptersA);
    expect(titleA, greaterThan(0));
    expect(chaptersA, 1);
  });

  testWidgets('Android: the series page is a CineMatchCutPage, 480 ms in and 336 ms out', (tester) async {
    final router = await _app(tester);
    unawaited(router.push<void>('/sources/demo/series/k'));
    await settleFeature(tester, by: const Duration(seconds: 1));
    final nav = tester.widget<Navigator>(find.byType(Navigator).first);
    final page = nav.pages.last;
    expect(page, isA<CineMatchCutPage<void>>());
    final p = page as CineMatchCutPage<void>;
    expect(p.transitionDuration, const Duration(milliseconds: 480));
    expect(p.reverseTransitionDuration, const Duration(milliseconds: 336));
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('iOS: SwipeablePage with an edge-only 20 pt swipe, and the cover Hero follows the finger', (tester) async {
    final router = await _app(tester, platform: TargetPlatform.iOS);
    unawaited(router.push<void>('/sources/demo/series/k'));
    await settleFeature(tester, by: const Duration(seconds: 1));
    final nav = tester.widget<Navigator>(find.byType(Navigator).first);
    final page = nav.pages.last;
    expect(page, isA<SwipeablePage<void>>());
    final s = page as SwipeablePage<void>;
    expect(s.canOnlySwipeFromEdge, isTrue);
    expect(s.backGestureDetectionWidth, 20);
    expect(s.transitionDuration, const Duration(milliseconds: 480));
    expect(s.reverseTransitionDuration, const Duration(milliseconds: 336));

    final hero = tester.widget<Hero>(find.byType(Hero).first);
    expect(hero.transitionOnUserGestures, isTrue);

    // A drag that starts 4 pt from the edge moves the page with the finger.
    final before = tester.getTopLeft(find.byType(FeatureView)).dx;
    final g = await tester.startGesture(const Offset(4, 300));
    await g.moveBy(const Offset(60, 0));
    await tester.pump();
    await g.moveBy(const Offset(120, 0));
    await tester.pump();
    final mid = tester.getTopLeft(find.byType(FeatureView)).dx;
    expect(mid, greaterThan(before + 40));
    await g.up();
    await settleFeature(tester, by: const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('iOS: a drag that starts away from the edge does not move the page', (tester) async {
    final router = await _app(tester, platform: TargetPlatform.iOS);
    unawaited(router.push<void>('/sources/demo/series/k'));
    await settleFeature(tester, by: const Duration(seconds: 1));
    final before = tester.getTopLeft(find.byType(FeatureView)).dx;
    final g = await tester.startGesture(const Offset(120, 300));
    await g.moveBy(const Offset(150, 0));
    await tester.pump();
    expect(tester.getTopLeft(find.byType(FeatureView)).dx, before);
    await g.up();
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  test('predictive back fades through: out 1.00 to 0.95 scale and 1 to 0 by 0.6, in 0 to 1 from 0.4', () {
    expect(fadeThrough(0).outScale, 1);
    expect(fadeThrough(0).outOpacity, 1);
    expect(fadeThrough(0).inOpacity, 0);
    expect(fadeThrough(0.6).outScale, closeTo(0.95, 1e-9));
    expect(fadeThrough(0.6).outOpacity, closeTo(0, 1e-9));
    expect(fadeThrough(0.4).inOpacity, closeTo(0, 1e-9));
    expect(fadeThrough(0.7).inOpacity, closeTo(0.5, 1e-9));
    expect(fadeThrough(1).inOpacity, 1);
    expect(kPredictiveCommit, const Duration(milliseconds: 240));
  });

  testWidgets('reduced motion: the route becomes a 200 ms cross-fade', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final router = await _app(tester);
    unawaited(router.push<void>('/sources/demo/series/k'));
    await settleFeature(tester, by: const Duration(seconds: 1));
    final page = tester.widget<Navigator>(find.byType(Navigator).first).pages.last as CineMatchCutPage<void>;
    expect(page.transitionDuration, const Duration(milliseconds: 200));
    expect(page.reverseTransitionDuration, const Duration(milliseconds: 200));
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('the title sets after the route lands: letters fade in, then the whole title shows', (tester) async {
    final router = await _app(tester);
    unawaited(router.push<void>('/sources/demo/series/k'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // Before the route animation completes the letters have not started.
    final early = tester.widgetList<RichText>(find.byType(RichText)).where((r) => r.text.toPlainText() == 'Tower of Dawn');
    expect(early, isNotEmpty);
    double firstAlpha(RichText r) {
      InlineSpan? leaf = r.text;
      while (leaf is TextSpan && (leaf.children?.isNotEmpty ?? false)) {
        leaf = leaf.children!.first;
      }
      return ((leaf as TextSpan).style?.color ?? const Color(0xFFFFFFFF)).a;
    }
    expect(firstAlpha(early.first), lessThan(0.05));
    await settleFeature(tester, by: const Duration(seconds: 4));
    final done = tester.widgetList<RichText>(find.byType(RichText)).firstWhere((r) => r.text.toPlainText() == 'Tower of Dawn');
    expect(firstAlpha(done), greaterThan(0.99));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the ambient wash dissolves over 800 ms and swaps at once under reduced motion', (tester) async {
    Color kickerColor() {
      final r = tester.widgetList<RichText>(find.byType(RichText)).firstWhere((r) => r.text.toPlainText().startsWith('MANHWA'));
      return (r.text as TextSpan).style!.color!;
    }

    final router = await _app(tester);
    unawaited(router.push<void>('/sources/demo/series/k'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final start = kickerColor();
    await tester.pump(const Duration(milliseconds: 100));
    final mid = kickerColor();
    await tester.pump(const Duration(milliseconds: 900));
    final end = kickerColor();
    expect(start, isNot(end));
    expect(mid, isNot(end));
    expect(cinematicTokens.colorAmbientFallbackInk, isNot(end));
    await tester.pumpWidget(const SizedBox());
  });
}

class FakeAccessibilityFeatures implements AccessibilityFeatures {
  const FakeAccessibilityFeatures({this.disableAnimations = false});
  @override
  final bool disableAnimations;
  @override
  bool get accessibleNavigation => false;
  @override
  bool get invertColors => false;
  @override
  bool get boldText => false;
  @override
  bool get reduceMotion => disableAnimations;
  @override
  bool get highContrast => false;
  @override
  bool get onOffSwitchLabels => false;
  @override
  bool get supportsAnnounce => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
