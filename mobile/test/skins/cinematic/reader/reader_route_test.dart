import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_route_page.dart';
import 'package:manhwamaniacs/skins/cinematic/wipe_geometry.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

Future<GoRouter> _app(WidgetTester t, Size size, {bool reduced = false}) async {
  if (reduced) {
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (c, s) => const Scaffold(body: Text('home'))),
    GoRoute(path: '/reader/:a', pageBuilder: (c, s) => cineReaderPage(c, s, const Scaffold(body: Text('reader')))),
  ],);
  addTearDown(router.dispose);
  await t.pumpWidget(MaterialApp.router(
    routerConfig: router,
    theme: CinematicSkin.baseTheme,
  ),);
  await t.pumpAndSettle();
  return router;
}

SwipeablePage<void> _top(WidgetTester t) => t.widget<Navigator>(find.byType(Navigator).first).pages.last as SwipeablePage<void>;

const _phone = Size(390, 844), _tablet = Size(834, 1194);

void main() {
  test('the blade count and the planned durations', () {
    expect(wipeBladeCount(390), 4);
    expect(wipeBladeCount(834), 8);
    expect(readerDurations(ReaderEntry.wipe, 390, reduced: false).forward.inMilliseconds, 616);
    expect(readerDurations(ReaderEntry.wipe, 834, reduced: false).forward.inMilliseconds, 744);
    for (final w in [390.0, 834.0]) {
      expect(readerDurations(ReaderEntry.dip, w, reduced: false), (forward: const Duration(milliseconds: 440), reverse: const Duration(milliseconds: 440)));
      expect(readerDurations(ReaderEntry.wipe, w, reduced: false).reverse.inMilliseconds, 440);
      expect(readerDurations(ReaderEntry.wipe, w, reduced: true), (forward: const Duration(milliseconds: 200), reverse: const Duration(milliseconds: 150)));
      expect(readerDurations(ReaderEntry.dip, w, reduced: true), (forward: const Duration(milliseconds: 150), reverse: const Duration(milliseconds: 150)));
    }
  });

  testWidgets('the pushed page takes 616 ms at 390 px, 744 ms at 834 px, 440 ms for a Dip and a pop', (t) async {
    var r = await _app(t, _phone);
    unawaited(r.push<void>('/reader/x', extra: <String, String>{'entry': 'wipe'}));
    await t.pump();
    expect(_top(t).transitionDuration!.inMilliseconds, 616);
    expect(_top(t).reverseTransitionDuration!.inMilliseconds, 440);
    await t.pumpAndSettle();
    r.pop();
    await t.pumpAndSettle();
    unawaited(r.push<void>('/reader/y', extra: <String, String>{'entry': 'dip'}));
    await t.pump();
    expect(_top(t).transitionDuration!.inMilliseconds, 440);
    await t.pumpAndSettle();
    r = await _app(t, _tablet);
    unawaited(r.push<void>('/reader/x', extra: <String, String>{'entry': 'wipe'}));
    await t.pump();
    expect(_top(t).transitionDuration!.inMilliseconds, 744);
    await t.pumpAndSettle();
  });

  testWidgets('reduced motion: 200 ms wipe, 150 ms Dip', (t) async {
    final r = await _app(t, _phone, reduced: true);
    unawaited(r.push<void>('/reader/x', extra: <String, String>{'entry': 'wipe'}));
    await t.pump();
    expect(_top(t).transitionDuration!.inMilliseconds, 200);
    await t.pumpAndSettle();
    r.pop();
    await t.pumpAndSettle();
    unawaited(r.push<void>('/reader/y', extra: <String, String>{'entry': 'dip'}));
    await t.pump();
    expect(_top(t).transitionDuration!.inMilliseconds, 150);
    await t.pumpAndSettle();
  });

  testWidgets('a tap within 120 ms of the blades opens the page', (t) async {
    final r = await _app(t, _phone);
    unawaited(r.push<void>('/reader/x', extra: <String, String>{'entry': 'wipe'}));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(t.widgetList<CustomPaint>(find.byType(CustomPaint)).where((c) => c.painter is ColumnWipePainter), isNotEmpty);
    await t.tapAt(const Offset(200, 400));
    await t.pump();
    await t.pump(const Duration(milliseconds: 120));
    await t.pump(const Duration(milliseconds: 16));
    expect(t.widgetList<CustomPaint>(find.byType(CustomPaint)).where((c) => c.painter is ColumnWipePainter), isEmpty);
    await t.pumpAndSettle();
  });

  testWidgets('the motion-timings overlay logs COLUMN WIPE and DIP with their planned durations', (t) async {
    final rec = MotionRecorder.instance;
    final was = rec.recording;
    rec.recording = true;
    addTearDown(() => rec.recording = was);
    final before = rec.entries.length;
    final r = await _app(t, _phone);
    unawaited(r.push<void>('/reader/x', extra: <String, String>{'entry': 'wipe'}));
    await t.pumpAndSettle();
    r.pop();
    await t.pumpAndSettle();
    unawaited(r.push<void>('/reader/y', extra: <String, String>{'entry': 'dip'}));
    await t.pumpAndSettle();
    final logged = rec.entries.skip(before).toList();
    final wipe = logged.where((e) => e.label == 'COLUMN WIPE');
    final dip = logged.where((e) => e.label == 'DIP');
    expect(wipe, isNotEmpty);
    expect(wipe.first.plannedMs, 616);
    expect(dip, isNotEmpty);
    expect(dip.map((e) => e.plannedMs), everyElement(440));
  });
}
