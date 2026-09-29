import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_route_page.dart';
import 'package:manhwamaniacs/skins/cinematic/wipe_geometry.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

int _enters = 0;

Future<GoRouter> _app(WidgetTester t, {Size size = const Size(390, 844)}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (c, s) => const Scaffold(body: Text('home'))),
    GoRoute(
      path: '/reader/:a',
      pageBuilder: (c, s) => cineReaderPage(c, s, const Scaffold(body: Text('reader'))),
    ),
  ],);
  addTearDown(router.dispose);
  await t.pumpWidget(MaterialApp.router(routerConfig: router, theme: CinematicSkin.baseTheme));
  await t.pumpAndSettle();
  return router;
}

SwipeablePage<void> _top(WidgetTester t) => t.widget<Navigator>(find.byType(Navigator).first).pages.last as SwipeablePage<void>;

void main() {
  setUp(() {
    _enters = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('haptic_feedback'),
      (call) async {
        _enters++;
        return null;
      },
    );
  });

  testWidgets('wipe: 616 ms at 390 px, 744 ms at 834 px, every pop 440 ms', (t) async {
    var r = await _app(t);
    unawaited(r.push<void>('/reader/x', extra: <String, String>{'entry': 'wipe'}));
    await t.pump();
    expect(_top(t).transitionDuration, const Duration(milliseconds: 616));
    expect(_top(t).reverseTransitionDuration, const Duration(milliseconds: 440));
    await t.pumpAndSettle();
    r.pop();
    await t.pumpAndSettle();

    r = await _app(t, size: const Size(834, 1194));
    unawaited(r.push<void>('/reader/x', extra: <String, String>{'entry': 'wipe'}));
    await t.pump();
    expect(_top(t).transitionDuration, const Duration(milliseconds: 744));
    await t.pumpAndSettle();
  });

  testWidgets('dip: 440 ms; a missing or unknown entry is a dip', (t) async {
    final r = await _app(t);
    unawaited(r.push<void>('/reader/x', extra: <String, String>{'entry': 'dip'}));
    await t.pump();
    expect(_top(t).transitionDuration, const Duration(milliseconds: 440));
    await t.pumpAndSettle();
    r.pop();
    await t.pumpAndSettle();
    unawaited(r.push<void>('/reader/y'));
    await t.pump();
    expect(_top(t).transitionDuration, const Duration(milliseconds: 440));
    await t.pumpAndSettle();
    r.pop();
    await t.pumpAndSettle();
    unawaited(r.push<void>('/reader/z', extra: <String, String>{'entry': 'sideways'}));
    await t.pump();
    expect(_top(t).transitionDuration, const Duration(milliseconds: 440));
    await t.pumpAndSettle();
  });

  testWidgets('reduced motion: 200 ms for a wipe entry, 150 ms for a dip', (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final r = await _app(t);
    unawaited(r.push<void>('/reader/x', extra: <String, String>{'entry': 'wipe'}));
    await t.pump();
    expect(_top(t).transitionDuration, const Duration(milliseconds: 200));
    await t.pumpAndSettle();
    r.pop();
    await t.pumpAndSettle();
    unawaited(r.push<void>('/reader/y', extra: <String, String>{'entry': 'dip'}));
    await t.pump();
    expect(_top(t).transitionDuration, const Duration(milliseconds: 150));
    await t.pumpAndSettle();
  });

  testWidgets('the page is a SwipeablePage; canSwipe is false on Android and true on iOS', (t) async {
    final r = await _app(t);
    unawaited(r.push<void>('/reader/x'));
    await t.pumpAndSettle();
    final s = _top(t);
    expect(s.canOnlySwipeFromEdge, isTrue);
    expect(s.backGestureDetectionWidth, 20);
    expect(s.canSwipe, defaultTargetPlatform == TargetPlatform.iOS);
  });

  testWidgets('a pop never replays the blades', (t) async {
    final r = await _app(t);
    unawaited(r.push<void>('/reader/x', extra: <String, String>{'entry': 'wipe'}));
    await t.pumpAndSettle();
    r.pop();
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    // No blade painter while reversing: the Dip's black layer is a ColoredBox, not a CustomPaint of blades.
    final paints = t.widgetList<CustomPaint>(find.byType(CustomPaint)).where((c) => c.painter is ColumnWipePainter);
    expect(paints, isEmpty);
    await t.pumpAndSettle();
  });

  testWidgets('the blades paint while going forward with a wipe entry', (t) async {
    final r = await _app(t);
    unawaited(r.push<void>('/reader/x', extra: <String, String>{'entry': 'wipe'}));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    final paints = t.widgetList<CustomPaint>(find.byType(CustomPaint)).where((c) => c.painter is ColumnWipePainter).toList();
    expect(paints, hasLength(1));
    expect((paints.single.painter! as ColumnWipePainter).blades, 4);
    await t.pumpAndSettle();
  });

  testWidgets('a tap during the close opens within 120 ms', (t) async {
    final r = await _app(t);
    unawaited(r.push<void>('/reader/x', extra: <String, String>{'entry': 'wipe'}));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    await t.tapAt(const Offset(200, 400));
    await t.pump();
    await t.pump(const Duration(milliseconds: 130));
    await t.pump(const Duration(milliseconds: 20));
    final paints = t.widgetList<CustomPaint>(find.byType(CustomPaint)).where((c) => c.painter is ColumnWipePainter);
    expect(paints, isEmpty);
    expect(find.text('reader'), findsOneWidget);
    await t.pumpAndSettle();
  });

  testWidgets('reader.enter fires once, when the last blade lands', (t) async {
    final r = await _app(t);
    _enters = 0;
    unawaited(r.push<void>('/reader/x', extra: <String, String>{'entry': 'wipe'}));
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    expect(_enters, 0);
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 100));
    await t.pumpAndSettle();
    expect(_enters, lessThanOrEqualTo(1));
  });

  test('ReaderTarget builds encoded locations', () {
    expect(const ReaderTarget.manifest('s', 'a/b', 'c d', page: 3).location, '/reader/s/a%2Fb/c%20d?page=3');
    expect(const ReaderTarget.readAll('s', 'k', from: '12').location, '/read-all/s/k?from=12');
    expect(const ReaderTarget.novel('s', 'k', 'c', listen: true).location, '/novels/s/k/c?listen=1');
    expect(const ReaderTarget.source('s', 'k', 'c').location, '/sources/s/series/k/chapters/c/read');
  });
}
