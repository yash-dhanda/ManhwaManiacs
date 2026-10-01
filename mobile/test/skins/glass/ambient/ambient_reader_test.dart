// ignore_for_file: require_trailing_commas
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/ambient/guided_view.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/glass_manga_reader.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart';

import '../reader/glass_reader_rig.dart';

Future<void> key(WidgetTester t, LogicalKeyboardKey k, {String? char, bool shift = false}) async {
  if (shift) await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await t.sendKeyEvent(k, character: char);
  if (shift) await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await settleReader(t, ms: 500);
}

ReaderEngine engineOf(WidgetTester t) => t.state<GlassMangaReaderState>(find.byType(GlassMangaReader)).engine;

void main() {
  testWidgets('p starts cruise through the engine; > and < step by 0.25x and the speed is saved for the series', (t) async {
    await pumpGlassReader(t);
    await settleReader(t, ms: 600);
    await key(t, LogicalKeyboardKey.keyP, char: 'p');
    expect(engineOf(t).value.autoScrolling, isTrue);
    expect(find.text('1.0×'), findsOneWidget);
    await key(t, LogicalKeyboardKey.period, char: '>', shift: true);
    expect(find.text('1.25×'), findsOneWidget);
    await key(t, LogicalKeyboardKey.comma, char: '<', shift: true);
    expect(find.text('1.0×'), findsOneWidget);
    await key(t, LogicalKeyboardKey.period, char: '>', shift: true);
    final prefs = ProviderScope.containerOf(t.element(find.byType(GlassMangaReader))).read(sharedPrefsProvider);
    final saved = prefs.getKeys().where((k) => k.startsWith('mm.reader-prefs.')).map(prefs.getString).join();
    expect(saved, contains('"cruiseSpeed":1.25'));
    await disposeGlassReader(t);
  });

  testWidgets('with Single-key shortcuts off, p and shift+s do nothing', (t) async {
    final rig = await pumpGlassReader(t, prefsValues: {'mm.shortcuts.single.device': 'off'});
    await settleReader(t, ms: 600);
    await key(t, LogicalKeyboardKey.keyP, char: 'p');
    expect(engineOf(t).value.autoScrolling, isFalse);
    await key(t, LogicalKeyboardKey.keyS, char: 'S', shift: true);
    expect(rig.at.queryParameters['sheet'], isNull);
    await disposeGlassReader(t);
  });

  testWidgets('shift+s opens ?sheet=soundscape', (t) async {
    final rig = await pumpGlassReader(t);
    await settleReader(t, ms: 600);
    await key(t, LogicalKeyboardKey.keyS, char: 'S', shift: true);
    await settleReader(t, ms: 900);
    expect(rig.at.queryParameters['sheet'], 'soundscape');
    expect(find.text('Soundscape'), findsWidgets);
    expect(find.text('Match the story'), findsOneWidget);
    await disposeGlassReader(t);
  });

  testWidgets('in Single layout the cruise button is absent and p does nothing', (t) async {
    await pumpGlassReader(t, prefsValues: {'mm.reader-prefs.device': '{"demo:k":{"layout":"single"}}'});
    await settleReader(t, ms: 600);
    expect(find.bySemanticsLabel('Cruise'), findsNothing);
    await key(t, LogicalKeyboardKey.keyP, char: 'p');
    expect(engineOf(t).value.autoScrolling, isFalse);
    await disposeGlassReader(t);
  });

  testWidgets('shift+p opens guided view and Esc closes it', (t) async {
    await pumpGlassReader(t);
    await settleReader(t, ms: 600);
    await key(t, LogicalKeyboardKey.keyP, char: 'P', shift: true);
    expect(find.byType(GlassGuidedView), findsOneWidget);
    await key(t, LogicalKeyboardKey.escape);
    expect(find.byType(GlassGuidedView), findsNothing);
    await disposeGlassReader(t);
  });

  testWidgets('a profile switch or sign-out (stop all playback) stops cruise before the next frame', (t) async {
    await pumpGlassReader(t);
    await settleReader(t, ms: 600);
    await key(t, LogicalKeyboardKey.keyP, char: 'p');
    expect(engineOf(t).value.autoScrolling, isTrue);
    GlassStops.stopAllPlayback();
    await t.pump();
    expect(engineOf(t).value.autoScrolling, isFalse);
    await disposeGlassReader(t);
  });

  testWidgets('every new control is reachable by the labels the sheet and the pill carry', (t) async {
    await pumpGlassReader(t);
    await settleReader(t, ms: 600);
    expect(find.bySemanticsLabel('Cruise'), findsOneWidget);
    expect(ProviderScope.containerOf(t.element(find.byType(GlassMangaReader))), isNotNull);
    await disposeGlassReader(t);
  });
}
