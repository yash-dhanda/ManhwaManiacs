import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

import 'gallery_host.dart';

Widget _host(Widget child, {bool reduced = true}) => MaterialApp(
      theme: ThemeData(extensions: const [cinematicTokens]),
      builder: (context, app) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduced), child: app!),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('Flicker is static at 0.8', (t) async {
    await t.pumpWidget(_host(const CineFlicker(index: 3, child: SizedBox(width: 10, height: 10))));
    await t.pump(const Duration(milliseconds: 700));
    expect(t.widget<Opacity>(find.descendant(of: find.byType(CineFlicker), matching: find.byType(Opacity))).opacity, 0.8);
  });

  testWidgets('Flicker animates when motion is on', (t) async {
    await t.pumpWidget(_host(const CineFlicker(child: SizedBox(width: 10, height: 10)), reduced: false));
    await t.pump(const Duration(milliseconds: 700));
    expect(t.widget<Opacity>(find.descendant(of: find.byType(CineFlicker), matching: find.byType(Opacity))).opacity, isNot(0.8));
  });

  testWidgets('Drift holds still at scale 1.03', (t) async {
    await t.pumpWidget(_host(const CineDrift(child: SizedBox(width: 10, height: 10))));
    await t.pump(const Duration(seconds: 5));
    final tr = t.widget<Transform>(find.descendant(of: find.byType(CineDrift), matching: find.byType(Transform)).first);
    expect(tr.transform.getMaxScaleOnAxis(), closeTo(1.03, 1e-6));
  });

  testWidgets('Rack focus becomes a 160 ms fade', (t) async {
    await t.pumpWidget(_host(const CineRackImage(child: SizedBox(width: 10, height: 10))));
    await t.pump();
    double o() => t.widget<Opacity>(find.descendant(of: find.byType(CineRackImage), matching: find.byType(Opacity))).opacity;
    await t.pump(const Duration(milliseconds: 80));
    expect(o(), inExclusiveRange(0.2, 0.8));
    await t.pump(const Duration(milliseconds: 120));
    expect(o(), 1);
    expect(find.descendant(of: find.byType(CineRackImage), matching: find.byType(ImageFiltered)), findsNothing);
  });

  testWidgets('the indeterminate rule and the leader dial keep running', (t) async {
    await t.pumpWidget(_host(const SizedBox(width: 200, child: Column(mainAxisSize: MainAxisSize.min, children: [CineIndeterminateRule(), CineLeaderDial(showAfter: Duration.zero)]))));
    double left() => t.widget<Positioned>(find.descendant(of: find.byType(CineIndeterminateRule), matching: find.byType(Positioned)).last).left!;
    final a = left();
    await t.pump(const Duration(milliseconds: 300));
    expect(left(), isNot(a));
    final dial = find.descendant(of: find.byType(CineLeaderDial), matching: find.byType(CustomPaint));
    final p1 = t.widget<CustomPaint>(dial.first).painter!;
    await t.pump(const Duration(milliseconds: 300));
    expect(t.widget<CustomPaint>(dial.first).painter!.shouldRepaint(p1), isTrue);
  });

  testWidgets('the slug-line underline jumps under reduced motion and slides otherwise', (t) async {
    Future<double> gapAfterOneFrame({required bool reduced}) async {
      await pumpGallery(t, section: 'slug-lines', reduced: reduced);
      final line = find.descendant(of: find.byKey(const Key('g-slug-single')), matching: find.byKey(const Key('slug-underline')));
      final plan = find.descendant(of: find.byKey(const Key('g-slug-single')), matching: find.text('PLAN'));
      await t.tap(plan);
      await t.pump();
      await t.pump(const Duration(milliseconds: 16));
      return (t.getRect(line).left - t.getRect(plan).left).abs();
    }

    expect(await gapAfterOneFrame(reduced: true), lessThan(1));
    await t.pumpWidget(const SizedBox());
    expect(await gapAfterOneFrame(reduced: false), greaterThan(20));
  });

  testWidgets('the motion recorder is not touched by a reduced-motion rack image', (t) async {
    MotionRecorder.instance
      ..recording = true
      ..clear();
    addTearDown(() => MotionRecorder.instance.recording = false);
    await t.pumpWidget(_host(const CineRackImage(child: SizedBox(width: 10, height: 10))));
    await t.pump(const Duration(milliseconds: 300));
    expect(MotionRecorder.instance.entries.map((e) => e.label), ['DEVELOP']);
  });

  testWidgets('the contents-tab underline fades under reduced motion instead of sliding', (t) async {
    await pumpGallery(t, section: 'tabs', reduced: true);
    expect(find.byKey(const Key('cine-tab-indicator')), findsNothing);
    await t.pumpWidget(const SizedBox());
    await pumpGallery(t, section: 'tabs');
    expect(find.byKey(const Key('cine-tab-indicator')), findsWidgets);
  });

  testWidgets('the switch knob jumps and the folio flip is instant under reduced motion', (t) async {
    await pumpGallery(t, section: 'toggles', reduced: true);
    final knob = find.descendant(of: find.byKey(const Key('g-switch-off')), matching: find.byKey(const Key('cine-switch-knob')));
    final x0 = t.getTopLeft(knob).dx;
    await t.tap(find.byKey(const Key('g-switch-off')));
    await t.pump();
    expect(t.getTopLeft(knob).dx, greaterThan(x0 + 15));
    await t.tap(find.descendant(of: find.byKey(const Key('g-stepper')), matching: find.bySemanticsLabel('Increase')).first);
    await t.pump();
    expect(find.text('4'), findsWidgets);
  });
}
