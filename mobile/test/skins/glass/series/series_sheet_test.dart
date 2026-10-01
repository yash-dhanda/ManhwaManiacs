import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/feature_screen.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_detail.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../shell/shell_rig.dart';
import 'series_rig.dart';

const _loc = '/sources/demo/series/k1000';

Future<ShellRig> _sheet(WidgetTester t, {Offset? velocity, List<dynamic> extra = const [], Size size = const Size(390, 844)}) async {
  final r = await pumpGlassShell(t, size: size, extra: [...seriesOverrides(), ...extra.cast()]);
  r.router.push<void>(_loc, extra: GlassNavExtra(velocity: velocity)).ignore();
  await t.pump();
  await t.pump(const Duration(milliseconds: 800));
  await t.pump(const Duration(milliseconds: 800));
  return r;
}

GlassSheetRoute<dynamic>? _route(WidgetTester t) {
  final r = ModalRoute.of(t.element(find.byType(GlassSeriesPage)));
  return r is GlassSheetRoute ? r : null;
}

void main() {
  testWidgets('a push with a nav extra opens the sheet route at medium', (t) async {
    await _sheet(t);
    expect(find.byType(GlassSeriesPage), findsOneWidget);
    final route = _route(t)!;
    final m = route.sheetController.metrics!;
    expect(m.offset, closeTo(0.52 * 844, 2));
    expect(find.byKey(const ValueKey('series-facts')), findsOneWidget);
  });

  testWidgets('a -2400 px/s throw opens at large', (t) async {
    await _sheet(t, velocity: const Offset(0, -2400));
    final m = _route(t)!.sheetController.metrics!;
    expect(m.offset, greaterThan(0.52 * 844 + 100));
  });

  testWidgets('back closes the sheet and the page beneath stays', (t) async {
    final r = await _sheet(t);
    r.router.pop();
    await t.pump(const Duration(milliseconds: 800));
    await t.pump(const Duration(milliseconds: 800));
    expect(find.byType(GlassSeriesPage), findsNothing);
  });

  testWidgets('a cold deep link renders the full page with the back chevron', (t) async {
    await pumpGlassShell(t, start: _loc, extra: seriesOverrides());
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(GlassSeriesPage), findsOneWidget);
    expect(_route(t), isNull);
    expect(find.byKey(const ValueKey('series-back')), findsOneWidget);
  });

  testWidgets('featureByFollow renders the same screen with no redirect', (t) async {
    final r = await pumpGlassShell(t, start: '/library/7', extra: seriesOverrides(followed: [followRow()]));
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(GlassFeatureByFollowScreen), findsOneWidget);
    expect(find.byType(GlassSeriesPage), findsOneWidget);
    expect(r.at, '/library/7');
  });

  testWidgets('the 1,000-row list builds fewer than 40 rows while flung top to bottom', (t) async {
    await pumpGlassShell(t, start: _loc, extra: seriesOverrides());
    await t.pump(const Duration(seconds: 1));
    var most = builtRows(t);
    final scroll = find.byType(Scrollable).first;
    for (var i = 0; i < 12; i++) {
      await t.fling(scroll, const Offset(0, -3000), 8000);
      await t.pump(const Duration(milliseconds: 200));
      most = builtRows(t) > most ? builtRows(t) : most;
    }
    expect(most, lessThan(40));
    expect(most, greaterThan(0));
  });

  testWidgets('the desktop frame shows the 960 px window with the left column holding at top 24', (t) async {
    await _sheet(t, size: const Size(1180, 820));
    final page = find.byType(GlassSeriesPage);
    expect(t.getSize(page).width, 960);
    final left = find.byKey(const ValueKey('series-left-column'));
    expect(t.getTopLeft(left).dy - t.getTopLeft(page).dy, 120);
    await t.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await t.pump(const Duration(milliseconds: 500));
    expect(t.getTopLeft(left).dy - t.getTopLeft(page).dy, 24);
  });

  testWidgets('a mature series on a gate-closed profile opens the unavailable lens', (t) async {
    await pumpGlassShell(t, start: _loc, extra: seriesOverrides(mature: true));
    await t.pump(const Duration(seconds: 1));
    expect(find.text("This isn't available on this profile"), findsOneWidget);
    expect(find.text('Solo Leveling'), findsNothing);
  });

  testWidgets('Mark read sends only the batch call with manual rows', (t) async {
    await pumpGlassShell(t, start: _loc, extra: seriesOverrides());
    await t.pump(const Duration(seconds: 1));
    final row = find.byKey(const ValueKey('chapter-c1000'));
    await t.dragUntilVisible(row, find.byType(Scrollable).first, const Offset(0, -200));
    await t.pump(const Duration(milliseconds: 300));
    await t.longPress(row);
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(find.text('Mark read').hitTestable().last);
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(calls.where((c) => c.startsWith('batch')), ['batch:1:manual=true']);
    expect(calls.where((c) => c.contains('saveProgress(') || c.contains('#saveProgress')), isEmpty);
    await t.pump(const Duration(seconds: 11));
  });

  testWidgets('x enters select mode and Next 10 picks ten rows', (t) async {
    await pumpGlassShell(t, start: _loc, extra: seriesOverrides(progress: {'c1': SourceChapterProgress(page: 40, pageCount: 40, completed: true, updatedAt: DateTime(2026, 9, 1))}));
    await t.pump(const Duration(seconds: 1));
    await t.sendKeyEvent(LogicalKeyboardKey.keyX);
    await t.pump(const Duration(milliseconds: 400));
    await t.dragUntilVisible(find.byKey(const ValueKey('helper-Next 10')), find.byType(Scrollable).first, const Offset(0, -200));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.byKey(const ValueKey('helper-Next 10')));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('10 selected'), findsOneWidget);
  });

  testWidgets('the hero tilt reads the sensor only while the route is on top', (t) async {
    final events = StreamController<AccelerometerEvent>.broadcast();
    var subs = 0;
    events.onListen = () => subs++;
    final r = await pumpGlassShell(t, start: _loc, extra: [...seriesOverrides(), gravitySensorProvider.overrideWithValue(() => events.stream), glassLightAngleProvider.overrideWith((ref) => Stream.value(kLightAngleRest))]);
    await t.pump(const Duration(seconds: 1));
    final g = r.container.read(gravityProvider);
    expect(g.sensorSubscriptions, 1);
    r.router.push<void>('/dev/glass').ignore();
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    expect(g.sensorSubscriptions, 0);
    expect(subs, greaterThanOrEqualTo(1));
    await events.close();
  });
}
