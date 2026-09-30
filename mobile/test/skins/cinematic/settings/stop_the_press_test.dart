// ignore_for_file: directives_ordering, unawaited_futures, avoid_dynamic_calls, library_private_types_in_public_api, inference_failure_on_collection_literal
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/overlays/stop_the_press.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/wipe_geometry.dart';

import '../downloads/downloads_rig.dart' show rigTheme, settle;

Future<void> frame(WidgetTester t, double ms, {Size size = const Size(390, 844), bool reduced = false, bool reverse = false}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = size;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(theme: rigTheme(TargetPlatform.android), home: Scaffold(body: StopThePressFrame(ms: ms, reduced: reduced, reverse: reverse))));
}

Finder blade(int i) => find.byKey(Key('press-blade-$i'));

void main() {
  test('the timeline: the rack ends at 160 ms, the blades land at 328 (phones) and 392 (tablets), the masthead cuts in at 456', () {
    expect(StopThePressTimeline.rack(0), 0);
    expect(StopThePressTimeline.rack(160), 1);
    expect(StopThePressTimeline.bladesDoneMs(4), 328);
    expect(StopThePressTimeline.bladesDoneMs(8), 392);
    expect(StopThePressTimeline.blade(0, 79), 0, reason: 'the first blade starts at 80 ms');
    expect(StopThePressTimeline.blade(3, 328), 1);
    expect(StopThePressTimeline.blade(1, 96 + 200), 1, reason: 'blades are 16 ms apart');
    expect(StopThePressTimeline.mastheadMs, 456);
    expect(StopThePressTimeline.totalMs, CineDur.stoppress.inMilliseconds);
  });

  testWidgets('at 100 ms the screen is racked out and the first blades are just starting', (t) async {
    await frame(t, 100);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(blade(0), findsOneWidget);
    expect(blade(3), findsNothing, reason: 'the fourth blade starts at 128 ms');
    expect(find.byKey(const Key('press-masthead')), findsNothing);
  });

  testWidgets('at 300 ms four blades have all but closed on phones', (t) async {
    await frame(t, 300);
    for (var i = 0; i < 4; i++) {
      expect(blade(i), findsOneWidget);
      expect(t.getSize(blade(i)).height, greaterThan(800), reason: 'blade $i');
    }
    expect(blade(4), findsNothing);
    expect(find.byKey(const Key('press-masthead')), findsNothing);
  });

  testWidgets('tablets get eight blades', (t) async {
    await frame(t, 380, size: const Size(834, 1194));
    expect(wipeBladeCount(834), 8);
    for (var i = 0; i < 8; i++) {
      expect(blade(i), findsOneWidget, reason: '$i');
    }
  });

  testWidgets('at 470 ms the masthead has cut in on black', (t) async {
    await frame(t, 470);
    expect(find.byKey(const Key('press-masthead')), findsOneWidget);
    expect(find.text('MANHWAMANIACS'), findsOneWidget);
  });

  testWidgets('reduced motion is a 200 ms fade to black with the masthead at 160 ms', (t) async {
    await frame(t, 100, reduced: true);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(blade(0), findsNothing);
    expect(find.byKey(const Key('press-masthead')), findsNothing);
    await frame(t, 170, reduced: true);
    expect(find.byKey(const Key('press-masthead')), findsOneWidget);
    expect(StopThePressTimeline.reducedMs, 200);
  });

  testWidgets('the failure reversal opens the blades and racks back into focus', (t) async {
    await frame(t, 0, reverse: true);
    expect(blade(0), findsOneWidget, reason: 'it starts from the closed frame');
    await frame(t, 200, reverse: true);
    expect(blade(0), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('dryRun: forward, a 600 ms hold on black, the reversal, then the error toast for the failure path', (t) async {
    final errors = <String>[];
    late BuildContext ctx;
    await t.pumpWidget(MaterialApp(theme: rigTheme(TargetPlatform.android), home: Scaffold(body: Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    },),),),);
    StopThePress.dryRun(ctx, failure: true, onError: errors.add);
    await t.pump();
    await t.pump(const Duration(milliseconds: 20));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('press-masthead')), findsOneWidget);
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('press-masthead')), findsOneWidget, reason: 'still holding the black frame');
    expect(errors, isEmpty);
    await settle(t);
    expect(find.byKey(const Key('press-masthead')), findsNothing);
    expect(errors, ["Couldn't switch editions. Try again."]);
  });
}
