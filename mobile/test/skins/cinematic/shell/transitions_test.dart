import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/transitions.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

Duration? _in, _out;
final _Scale _scale = _Scale();

class _Scale {
  double min = 1;
}

/// Records the route's own durations from inside it.
Widget _probe(String label) => Builder(
      builder: (context) {
        final r = ModalRoute.of(context)!;
        _in = r.transitionDuration;
        _out = r.reverseTransitionDuration;
        return Scaffold(body: Center(child: Text(label)));
      },
    );

Future<GoRouter> _app(WidgetTester t) async {
  final router = GoRouter(routes: [
    GoRoute(path: '/', pageBuilder: (c, s) => cineCutPage(s, const Scaffold(body: Text('home')))),
    GoRoute(path: '/a', pageBuilder: (c, s) => cinePage(s, _probe('page a'))),
    GoRoute(path: '/m', pageBuilder: (c, s) => cineMatchCutPage(s, _probe('page m'))),
    GoRoute(path: '/d', pageBuilder: (c, s) => cineDipPage(s, _probe('page d'))),
  ],);
  addTearDown(router.dispose);
  await t.pumpWidget(MaterialApp.router(routerConfig: router, theme: CinematicSkin.baseTheme));
  await t.pumpAndSettle();
  return router;
}

/// The smallest scale any ancestor `Transform` of [finder] applies.
double _minScale(WidgetTester t, Finder finder) {
  var m = 1.0;
  for (final tr in t.widgetList<Transform>(find.ancestor(of: finder, matching: find.byType(Transform)))) {
    final s = tr.transform.storage[0];
    if (s > 0 && s < m) m = s;
  }
  return m;
}

Future<void> _gesture(WidgetTester t, String method, [Map<String, Object?>? args]) async {
  final completer = Completer<void>();
  unawaited(t.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
    (_) => completer.complete(),
  ),);
  await completer.future;
  await t.pump();
}

Map<String, Object?> _ev(double p) => {'touchOffset': <double>[5, 400], 'progress': p, 'swipeEdge': 0};

void main() {
  setUp(() {
    CineBackGesture.instance.reset();
    _in = null;
    _out = null;
    _scale.min = 1;
  });

  group('Android', () {
    testWidgets('Page 320 / 224 ms, match cut 480 / 336 ms, Dip 440 / 440 ms', (t) async {
      final r = await _app(t);
      unawaited(r.push<void>('/a'));
      await t.pumpAndSettle();
      expect((_in, _out), (const Duration(milliseconds: 320), const Duration(milliseconds: 224)));
      r.pop();
      await t.pumpAndSettle();
      unawaited(r.push<void>('/m'));
      await t.pumpAndSettle();
      expect((_in, _out), (const Duration(milliseconds: 480), const Duration(milliseconds: 336)));
      r.pop();
      await t.pumpAndSettle();
      unawaited(r.push<void>('/d'));
      await t.pumpAndSettle();
      expect((_in, _out), (const Duration(milliseconds: 440), const Duration(milliseconds: 440)));
    }, variant: TargetPlatformVariant.only(TargetPlatform.android),);

    testWidgets('a match cut is a CineMatchCutPage; extra {transition: dip} makes any push a Dip', (t) async {
      final r = await _app(t);
      unawaited(r.push<void>('/m'));
      await t.pumpAndSettle();
      expect(t.widget<Navigator>(find.byType(Navigator).first).pages.last, isA<CineMatchCutPage<void>>());
      r.pop();
      await t.pumpAndSettle();
      unawaited(r.push<void>('/a', extra: <String, String>{'transition': 'dip'}));
      await t.pumpAndSettle();
      expect((_in, _out), (const Duration(milliseconds: 440), const Duration(milliseconds: 440)));
    }, variant: TargetPlatformVariant.only(TargetPlatform.android),);

    testWidgets('predictive back fades through: scale 0.95 at progress 0.6; commit pops', (t) async {
      final r = await _app(t);
      unawaited(r.push<void>('/a'));
      await t.pumpAndSettle();
      await _gesture(t, 'startBackGesture', _ev(0));
      await _gesture(t, 'updateBackGestureProgress', _ev(0.5));
      expect(_minScale(t, find.text('page a')), closeTo(0.9583, 0.01));
      await _gesture(t, 'updateBackGestureProgress', _ev(0.6));
      expect(_minScale(t, find.text('page a')), closeTo(0.95, 0.01));
      await _gesture(t, 'commitBackGesture');
      await t.pumpAndSettle();
      expect(find.text('page a'), findsNothing);
      expect(find.text('home'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android),);

    testWidgets('a cancelled gesture returns to the page', (t) async {
      final r = await _app(t);
      unawaited(r.push<void>('/a'));
      await t.pumpAndSettle();
      await _gesture(t, 'startBackGesture', _ev(0));
      await _gesture(t, 'updateBackGestureProgress', _ev(0.3));
      await _gesture(t, 'cancelBackGesture');
      await t.pumpAndSettle();
      expect(find.text('page a'), findsOneWidget);
      expect(_minScale(t, find.text('page a')), 1);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android),);

    testWidgets('a button pop plays Page: no scale at any frame', (t) async {
      final r = await _app(t);
      unawaited(r.push<void>('/a'));
      await t.pumpAndSettle();
      r.pop();
      var min = 1.0;
      for (var i = 0; i < 8; i++) {
        await t.pump(const Duration(milliseconds: 28));
        if (find.text('page a').evaluate().isNotEmpty) {
          final s = _minScale(t, find.text('page a'));
          if (s < min) min = s;
        }
      }
      expect(min, 1);
      await t.pumpAndSettle();
    }, variant: TargetPlatformVariant.only(TargetPlatform.android),);

    testWidgets('reduced motion: Page and Dip are 150 ms, the match cut 200 ms', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final r = await _app(t);
      unawaited(r.push<void>('/a'));
      await t.pumpAndSettle();
      expect((_in, _out), (const Duration(milliseconds: 150), const Duration(milliseconds: 150)));
      r.pop();
      await t.pumpAndSettle();
      unawaited(r.push<void>('/m'));
      await t.pumpAndSettle();
      expect((_in, _out), (const Duration(milliseconds: 200), const Duration(milliseconds: 200)));
      r.pop();
      await t.pumpAndSettle();
      unawaited(r.push<void>('/d'));
      await t.pumpAndSettle();
      expect((_in, _out), (const Duration(milliseconds: 150), const Duration(milliseconds: 150)));
    }, variant: TargetPlatformVariant.only(TargetPlatform.android),);
  });

  group('iOS', () {
    testWidgets('a pushed page is a SwipeablePage: edge only, 20 pt, 320 / 224 ms', (t) async {
      final r = await _app(t);
      unawaited(r.push<void>('/a'));
      await t.pumpAndSettle();
      final page = t.widget<Navigator>(find.byType(Navigator).first).pages.last;
      expect(page, isA<SwipeablePage<void>>());
      final s = page as SwipeablePage<void>;
      expect(s.canOnlySwipeFromEdge, isTrue);
      expect(s.backGestureDetectionWidth, 20);
      expect(s.transitionDuration, const Duration(milliseconds: 320));
      expect(s.reverseTransitionDuration, const Duration(milliseconds: 224));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS),);

    testWidgets('match cut 480 / 336 ms and Dip 440 / 440 ms', (t) async {
      final r = await _app(t);
      unawaited(r.push<void>('/m'));
      await t.pumpAndSettle();
      var s = t.widget<Navigator>(find.byType(Navigator).first).pages.last as SwipeablePage<void>;
      expect((s.transitionDuration, s.reverseTransitionDuration), (const Duration(milliseconds: 480), const Duration(milliseconds: 336)));
      r.pop();
      await t.pumpAndSettle();
      unawaited(r.push<void>('/d'));
      await t.pumpAndSettle();
      s = t.widget<Navigator>(find.byType(Navigator).first).pages.last as SwipeablePage<void>;
      expect((s.transitionDuration, s.reverseTransitionDuration), (const Duration(milliseconds: 440), const Duration(milliseconds: 440)));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS),);

    testWidgets('the edge swipe follows the finger; the page beneath slides from -30 % under a 0.6 dim', (t) async {
      final r = await _app(t);
      unawaited(r.push<void>('/a'));
      await t.pumpAndSettle();
      final w = t.getSize(find.byType(MaterialApp)).width;
      final g = await t.startGesture(const Offset(4, 300));
      await g.moveBy(const Offset(40, 0));
      await g.moveBy(Offset(w / 2 - 40, 0));
      await t.pump();
      // The top page's left edge is at half the width (linear).
      expect(t.getTopLeft(find.text('page a')).dx, greaterThan(w / 4));
      // The page beneath: -30 % x at rest under the fully covered state, easing to 0 as it is revealed.
      final beneathX = t.getTopLeft(find.text('home')).dx;
      expect(beneathX, lessThan(0));
      expect(beneathX, greaterThan(-0.3 * w - 1));
      await g.up();
      await t.pumpAndSettle();
      expect(t.state<NavigatorState>(find.byType(Navigator).first).userGestureInProgress, isFalse);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS),);

    testWidgets('a route removed mid-swipe (a go under the finger) does not leave the gesture open', (t) async {
      final r = await _app(t);
      final nav = t.state<NavigatorState>(find.byType(Navigator).first);
      unawaited(r.push<void>('/a'));
      await t.pumpAndSettle();
      final g = await t.startGesture(const Offset(4, 300));
      await g.moveBy(const Offset(20, 0));
      await t.pump();
      await g.moveBy(const Offset(60, 0));
      await t.pump();
      expect(nav.userGestureInProgress, isTrue);
      r.go('/');
      await t.pumpAndSettle();
      await g.up();
      await t.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(nav.userGestureInProgress, isFalse);
      // And the next swipe works.
      unawaited(r.push<void>('/a'));
      await t.pumpAndSettle();
      final g2 = await t.startGesture(const Offset(4, 300));
      await g2.moveBy(const Offset(20, 0));
      await t.pump();
      await g2.moveBy(const Offset(600, 0));
      await t.pump();
      await g2.up();
      await t.pumpAndSettle();
      expect(find.text('page a'), findsNothing);
      expect(nav.userGestureInProgress, isFalse);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS),);

    // 3.5.3 freeze: the detector remounted when the swipe started, the release never arrived,
    // and the navigator stayed in a user gesture (every route ignoring pointers) forever.
    for (final (kind, path) in [('page', '/a'), ('match', '/m'), ('dip', '/d')]) {
      testWidgets('$kind: a released swipe ends the gesture (pop past half, return before it)', (t) async {
        final r = await _app(t);
        final nav = t.state<NavigatorState>(find.byType(Navigator).first);
        final w = t.getSize(find.byType(MaterialApp)).width;
        Future<void> swipe(double dx) async {
          final g = await t.startGesture(const Offset(4, 300));
          await g.moveBy(const Offset(20, 0));
          await t.pump();
          await g.moveBy(Offset(dx - 20, 0));
          await t.pump();
          expect(nav.userGestureInProgress, isTrue);
          await g.up();
          await t.pumpAndSettle();
          expect(nav.userGestureInProgress, isFalse);
        }

        unawaited(r.push<void>(path));
        await t.pumpAndSettle();
        await swipe(w * 0.2);
        expect(find.text('page ${path[1]}'), findsOneWidget);
        expect(t.getTopLeft(find.ancestor(of: find.text('page ${path[1]}'), matching: find.byType(Scaffold))).dx, 0);
        await swipe(w * 0.7);
        expect(find.text('page ${path[1]}'), findsNothing);
        expect(find.text('home'), findsOneWidget);
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS),);
    }

    testWidgets('the slide maths: top follows linearly, beneath -30 % to 0, dim 0.6 to 0', (t) async {
      expect(CineSwipeSlide.topOffset(1), 0);
      expect(CineSwipeSlide.topOffset(0.5), 0.5);
      expect(CineSwipeSlide.beneathOffset(1), closeTo(-0.3, 1e-12));
      expect(CineSwipeSlide.beneathOffset(0), 0);
      expect(CineSwipeSlide.beneathDim(1), closeTo(0.6, 1e-12));
      expect(CineSwipeSlide.beneathDim(0), 0);
    });
  });

  test('the fade-through and the Dip are pure functions', () {
    expect(fadeThrough(0.6).outScale, closeTo(0.95, 1e-9));
    expect(fadeThrough(0.4).inOpacity, closeTo(0, 1e-9));
    expect(dipBlack(0), 0);
    expect(dipBlack(160), 1);
    expect(dipBlack(180), 1);
    expect(dipBlack(200), 1);
    expect(dipBlack(320), inExclusiveRange(0, 1));
    expect(dipBlack(440), 0);
    expect(dipChildVisible(199, reverse: false), isFalse);
    expect(dipChildVisible(200, reverse: false), isTrue);
    expect(dipChildVisible(199, reverse: true), isTrue);
    expect(dipChildVisible(200, reverse: true), isFalse);
    expect(pageIncoming(0).dx, 24);
    expect(pageOutgoing(1).dx, -24);
    expect(kPredictiveCommit, const Duration(milliseconds: 240));
    expect(kPredictiveCancel, const Duration(milliseconds: 160));
  });

  testWidgets('the match cut cover flies through CineCurves.turn', (t) async {
    await t.pumpWidget(const CineHero(tag: ('s', 'k'), child: SizedBox()));
    const a = Rect.fromLTWH(0, 0, 40, 60);
    const b = Rect.fromLTWH(100, 200, 160, 240);
    final tween = t.widget<Hero>(find.byType(Hero)).createRectTween!(a, b);
    expect(tween.begin, a);
    expect(tween.end, b);
    expect(tween.transform(0.5), Rect.lerp(a, b, CineCurves.turn.transform(0.5)));
    expect(tween.transform(0.25), Rect.lerp(a, b, CineCurves.turn.transform(0.25)));
  });
}
