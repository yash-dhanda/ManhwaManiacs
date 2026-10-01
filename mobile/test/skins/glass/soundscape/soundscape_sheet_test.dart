import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/providers/soundscape_defaults_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/recipes.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/soundscape_controller.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/soundscape_sheet.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';

import 'soundscape_fakes.dart';

Future<SoundscapeRig> pumpSheet(WidgetTester t, {Size size = const Size(390, 844), String? seriesRef, TargetPlatform platform = TargetPlatform.iOS}) async {
  t.view.physicalSize = Size(size.width * 3, size.height * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final rig = await SoundscapeRig.create();
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: rig.container,
      child: MediaQuery(
        data: MediaQueryData(size: size, devicePixelRatio: 3),
        child: Theme(
          data: ThemeData(platform: platform),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SkinGlassRoot(child: Material(child: SingleChildScrollView(child: SoundscapeSheetBody(seriesRef: seriesRef)))),
          ),
        ),
      ),
    ),
  );
  await t.pump();
  return rig;
}

void main() {
  testWidgets('seven orbs form one mutually exclusive group under a "Soundscape" container; Off is checked while nothing plays', (t) async {
    final handle = t.ensureSemantics();
    final rig = await pumpSheet(t);
    expect(find.bySemanticsLabel('Soundscape'), findsWidgets);
    for (final s in SoundScene.values) {
      expect(find.bySemanticsLabel(s.label), findsOneWidget, reason: s.label);
    }
    expect(find.bySemanticsLabel('Off'), findsOneWidget);
    final off = t.getSemantics(find.bySemanticsLabel('Off'));
    expect(off.getSemanticsData().flagsCollection.isChecked, CheckedState.isTrue);
    expect(off.getSemanticsData().flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    expect(rig.view.state, SoundscapeState.off);
    handle.dispose();
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('choosing Rain starts it; the Match the story orb carries "matched to this series" and "Matched: Hearth"', (t) async {
    final handle = t.ensureSemantics();
    final rig = await pumpSheet(t, seriesRef: 's:1');
    await rig.controller.enterReader(const SoundscapeReaderContext(seriesRef: 's:1', genres: ['Romance']));
    await t.pump();
    expect(find.bySemanticsLabel('Hearth, matched to this series'), findsOneWidget);
    expect(find.text('Matched: Hearth'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Rain'));
    await t.pump();
    expect(rig.view.scene, SoundScene.rain);
    expect(rig.view.state, SoundscapeState.starting);
    expect(rig.session.requests.first, AudioSessionState.soundscape);
    await t.pump(const Duration(seconds: 3));
    rig.controller.stopNow();
    await t.pump(const Duration(seconds: 2));
    handle.dispose();
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('with every file fetch failing the playing orb carries the cloud-slash badge and says it is built in', (t) async {
    final handle = t.ensureSemantics();
    final rig = await pumpSheet(t);
    await rig.controller.start(SoundScene.ocean);
    await t.pump(const Duration(seconds: 3));
    expect(rig.view.builtin, isTrue);
    expect(find.byWidgetPredicate((w) => w is Icon && w.icon?.codePoint == 0xe1b6), findsOneWidget);
    expect(t.getSemantics(find.bySemanticsLabel('Ocean')).hint, 'Playing the built-in version');
    expect(find.text('Ocean · built-in'), findsNothing);
    rig.controller.stopNow();
    await t.pump(const Duration(seconds: 2));
    handle.dispose();
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the mixer writes the defaults when Remember is off; the scope caption names the scope', (t) async {
    final rig = await pumpSheet(t, seriesRef: 's:1');
    expect(find.text('All series · Saved on this device'), findsOneWidget);
    expect(find.text('Remember for this series'), findsOneWidget);
    rig.controller.setMix(SoundLayer.bed, 0.3);
    await rig.container.read(soundscapeDefaultsRecordProvider.notifier).setMix('bed', 0.3);
    await t.pump();
    expect(rig.container.read(soundscapeDefaultsProvider).bed, 0.3);
    expect(find.text('30 %'), findsWidgets);
    expect(rig.container.read(sharedPrefsProvider).getKeys().any((k) => k.startsWith('mm.soundscape.defaults.')), isTrue);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('outside a reader there is no Remember switch', (t) async {
    await pumpSheet(t);
    expect(find.text('Remember for this series'), findsNothing);
    expect(find.text('Match the story'), findsOneWidget);
    expect(find.text('Lower under narration'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('wide frames lay the seven orbs in one row and phones in a 3 x 2 grid', (t) async {
    await pumpSheet(t, size: const Size(900, 700));
    final ys = {for (final s in SoundScene.values) t.getTopLeft(find.text(s.label)).dy.round()};
    expect(ys.length, 1);
    await t.pumpWidget(const SizedBox.shrink());
    await pumpSheet(t);
    final ys2 = {for (final s in SoundScene.values) t.getTopLeft(find.text(s.label)).dy.round()};
    expect(ys2.length, 2);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('every control meets the iOS and the Android tap-target guidelines', (t) async {
    final handle = t.ensureSemantics();
    await pumpSheet(t);
    await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    await t.pumpWidget(const SizedBox.shrink());
    await pumpSheet(t, platform: TargetPlatform.android);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
    await t.pumpWidget(const SizedBox.shrink());
  });
}
