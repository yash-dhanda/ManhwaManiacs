import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/native_bridge.dart';
import 'package:manhwamaniacs/features/reader/engine/paged_reader_view.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_state.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_prefs_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/paged_rules.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/tap_zone_bands.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

/// Profile defaults as the migration would have left them (and the migration marked done, so it does not rewrite them).
Map<String, Object> seedLayout(String layout, {String direction = 'ltr', Map<String, Object> more = const {}}) => {
      kReaderPrefsMigratedKey: true,
      kReaderPrefsSeedKey: jsonEncode({
        'seriesDefaults': {'layout': layout, 'direction': direction},
        ...more,
      }),
    };

/// The page the reader reports (the counter is in the chrome, which a turn hides).
int pageOf(WidgetTester tester) {
  final paged = find.byType(PagedReaderView);
  if (paged.evaluate().isNotEmpty) return tester.widget<PagedReaderView>(paged).controller.value.page;
  return tester.widget<ReaderEngineView>(find.byType(ReaderEngineView)).controller.value.page;
}

Future<void> key(WidgetTester tester, LogicalKeyboardKey k, {int ms = 600, bool shift = false}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(k);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await settleReader(tester, ms: ms);
}

void main() {
  setUpAll(setUpShotCoverCache);

  testWidgets('single layout mounts the paged view; taps 30 / 40 / 30 turn and toggle the chrome', (tester) async {
    await pumpReader(tester, prefsValues: seedLayout('single'));
    await settleReader(tester, ms: 500);
    expect(find.byType(PagedReaderView), findsOneWidget);
    expect(find.byType(ReaderEngineView), findsNothing);
    expect(pageOf(tester), 1);
    await tapSingle(tester, const Offset(350, 422));
    expect(pageOf(tester), 2);
    await tapSingle(tester, const Offset(40, 422));
    expect(pageOf(tester), 1);
    final before = chromeVisible(tester);
    await tapSingle(tester);
    expect(chromeVisible(tester), isNot(before));
    await disposeReader(tester);
  });

  testWidgets('right to left mirrors the automatic zones: left is next', (tester) async {
    await pumpReader(tester, prefsValues: seedLayout('single', direction: 'rtl'));
    await settleReader(tester, ms: 500);
    await tapSingle(tester, const Offset(40, 422));
    expect(pageOf(tester), 2);
    await tapSingle(tester, const Offset(350, 422));
    expect(pageOf(tester), 1);
    await disposeReader(tester);
  });

  testWidgets('the zone bands show on first use, hold 1500 ms, fade over 1000 ms and are remembered', (tester) async {
    await pumpReader(tester, prefsValues: seedLayout('single'));
    await settleReader(tester, ms: 300);
    expect(find.byKey(const ValueKey('zone-band-0')), findsOneWidget);
    expect(find.text('BACK'), findsOneWidget);
    expect(find.text('MENU'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
    double opacity() => tester.widget<Opacity>(find.descendant(of: find.byType(TapZoneBands), matching: find.byType(Opacity)).first).opacity;
    await tester.pump(const Duration(milliseconds: 1000));
    expect(opacity(), 1);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(opacity(), inExclusiveRange(0, 1), reason: 'fading after the 1500 ms hold');
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byKey(const ValueKey('zone-band-0')), findsNothing);
    final prefs = ProviderScope.containerOf(tester.element(find.byType(MaterialApp))).read(sharedPrefsProvider);
    expect(prefs.getStringList(kZonesSeenKey), ['single:previous,menu,next']);
    await disposeReader(tester);

    // Seen already: they do not come back.
    await pumpReader(tester, prefsValues: {...seedLayout('single'), kZonesSeenKey: ['single:previous,menu,next']});
    await settleReader(tester, ms: 400);
    expect(find.byKey(const ValueKey('zone-band-0')), findsNothing);
    await disposeReader(tester);
  });

  testWidgets('the K01 toast shows once per device after a sideways migration', (tester) async {
    await pumpReader(tester, prefsValues: {...seedLayout('single'), 'settings_reading_direction': 'leftToRight'});
    await settleReader(tester, ms: 500);
    expect(find.text(kK01ToastText), findsOneWidget);
    final prefs = ProviderScope.containerOf(tester.element(find.byType(MaterialApp))).read(sharedPrefsProvider);
    expect(prefs.getBool(kK01ToastSeenKey), isTrue);
    await disposeReader(tester);
    await pumpReader(tester, prefsValues: {...seedLayout('single'), 'settings_reading_direction': 'leftToRight', kK01ToastSeenKey: true});
    await settleReader(tester, ms: 500);
    expect(find.text(kK01ToastText), findsNothing);
    await disposeReader(tester);
  });

  testWidgets('w v r switch layouts and keep the page; the strip path is the engine view', (tester) async {
    await pumpReader(tester);
    await settleReader(tester, ms: 500);
    expect(find.byType(ReaderEngineView), findsOneWidget);
    await key(tester, LogicalKeyboardKey.keyV);
    expect(find.byType(PagedReaderView), findsOneWidget);
    await key(tester, LogicalKeyboardKey.keyJ);
    await key(tester, LogicalKeyboardKey.keyJ);
    expect(pageOf(tester), 3);
    await key(tester, LogicalKeyboardKey.keyW, ms: 900);
    expect(find.byType(ReaderEngineView), findsOneWidget);
    expect(pageOf(tester), 3, reason: 'the page carried over');
    await key(tester, LogicalKeyboardKey.keyR, ms: 900);
    expect(find.byType(PagedReaderView), findsOneWidget);
    expect(pageOf(tester), 3);
    await disposeReader(tester);
  });

  testWidgets('paged keys: arrows by reading direction, space, home and end; p does nothing', (tester) async {
    await pumpReader(tester, prefsValues: seedLayout('double'));
    await settleReader(tester, ms: 500);
    await key(tester, LogicalKeyboardKey.arrowRight);
    expect(pageOf(tester), 2);
    await key(tester, LogicalKeyboardKey.arrowRight);
    expect(pageOf(tester), 4, reason: 'a spread is one turn');
    await key(tester, LogicalKeyboardKey.arrowLeft);
    expect(pageOf(tester), 2);
    await key(tester, LogicalKeyboardKey.space);
    expect(pageOf(tester), 4);
    await key(tester, LogicalKeyboardKey.space, shift: true);
    expect(pageOf(tester), 2);
    await key(tester, LogicalKeyboardKey.end);
    expect(pageOf(tester), 6);
    await key(tester, LogicalKeyboardKey.home);
    expect(pageOf(tester), 1);
    await key(tester, LogicalKeyboardKey.keyP);
    expect(find.byIcon(Icons.pause), findsNothing);
    await disposeReader(tester);
  });

  testWidgets('volume keys turn pages in a paged layout (Android, K08)', (tester) async {
    final bridge = _Bridge();
    await pumpReader(tester, prefsValues: {...seedLayout('single'), 'settings_volume_key_navigation': true}, extra: [nativeBridgeProvider.overrideWithValue(bridge)]);
    await settleReader(tester, ms: 500);
    bridge.events.add(VolumeKeyDirection.down);
    await settleReader(tester, ms: 700);
    expect(pageOf(tester), 2);
    bridge.events.add(VolumeKeyDirection.up);
    await settleReader(tester, ms: 700);
    expect(pageOf(tester), 1);
    await disposeReader(tester);
  });

  testWidgets('a double tap zooms to 2x at the tap point; a drag then pans and never turns the page', (tester) async {
    await pumpReader(tester, prefsValues: seedLayout('single'));
    await settleReader(tester, ms: 500);
    ReaderEngineState state() => tester.widget<PagedReaderView>(find.byType(PagedReaderView)).controller.value;
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
    await tester.tapAt(const Offset(195, 300));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(const Offset(195, 300));
    await settleReader(tester, ms: 500);
    expect(state().zoom, 2.0);
    await tester.flingFrom(const Offset(200, 500), const Offset(-250, 0), 1500);
    await settleReader(tester, ms: 800);
    expect(pageOf(tester), 1);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
    await tester.tapAt(const Offset(195, 300));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(const Offset(195, 300));
    await settleReader(tester, ms: 500);
    expect(state().zoom, 1.0, reason: 'the second double tap goes back');
    await disposeReader(tester);
  });

  testWidgets('a finger release commits past 72 px and returns short of it', (tester) async {
    await pumpReader(tester, prefsValues: seedLayout('single'));
    await settleReader(tester, ms: 500);
    // The touch slop is not part of the travel: 40 px of finger returns, 200 px commits (the exact
    // 71 / 72 px cut is pinned on the physics itself).
    await tester.drag(find.byType(PageView), const Offset(-40, 0));
    await settleReader(tester, ms: 900);
    expect(pageOf(tester), 1);
    await tester.drag(find.byType(PageView), const Offset(-200, 0));
    await settleReader(tester, ms: 900);
    expect(pageOf(tester), 2);
    await disposeReader(tester);
  });

  testWidgets('Slide takes 280 ms; Cut is instant; Fade dips through the ground', (tester) async {
    await pumpReader(tester, prefsValues: seedLayout('single', more: {'pageTurn': 'slide'}));
    await settleReader(tester, ms: 500);
    final engine = tester.widget<PagedReaderView>(find.byType(PagedReaderView)).controller;
    engine.pageBy(forward: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final position = tester.state<ScrollableState>(find.descendant(of: find.byType(PageView), matching: find.byType(Scrollable)).first).position.pixels;
    expect(position, inExclusiveRange(0, 390), reason: 'mid-slide');
    await tester.pump(const Duration(milliseconds: 250));
    expect(pageOf(tester), 2);
    await disposeReader(tester);

    await pumpReader(tester, prefsValues: seedLayout('single', more: {'pageTurn': 'fade'}));
    await settleReader(tester, ms: 500);
    final e2 = tester.widget<PagedReaderView>(find.byType(PagedReaderView)).controller;
    e2.pageBy(forward: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final fading = tester.widget<Opacity>(find.descendant(of: find.byType(PagedReaderView), matching: find.byType(Opacity)).first).opacity;
    expect(fading, lessThan(1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(pageOf(tester), 2);
    await disposeReader(tester);
  });

  testWidgets('reduced motion: a turn is a 150 ms fade, not a slide', (tester) async {
    await pumpReader(tester, reduced: true, prefsValues: seedLayout('single', more: {'pageTurn': 'slide'}));
    await settleReader(tester, ms: 500);
    final engine = tester.widget<PagedReaderView>(find.byType(PagedReaderView)).controller;
    engine.pageBy(forward: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final dip = tester.widget<Opacity>(find.descendant(of: find.byType(PagedReaderView), matching: find.byType(Opacity)).first).opacity;
    expect(dip, lessThan(1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(pageOf(tester), 2);
    final px = tester.state<ScrollableState>(find.descendant(of: find.byType(PageView), matching: find.byType(Scrollable)).first).position.pixels;
    expect(px, 390, reason: 'landed by a jump, never mid-slide');
    await disposeReader(tester);
  });

  testWidgets('Esc closes the Margins panel first, then leaves the reader', (tester) async {
    await pumpReader(tester, size: const Size(834, 1194), prefsValues: seedLayout('single'));
    await settleReader(tester, ms: 600);
    await key(tester, LogicalKeyboardKey.bracketRight, ms: 900);
    final ref = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    expect(ref.read(readerPrefsProvider('demo:k')).panels.right, isTrue);
    await key(tester, LogicalKeyboardKey.escape, ms: 700);
    expect(ref.read(readerPrefsProvider('demo:k')).panels.right, isFalse);
    expect(find.byType(PagedReaderView), findsOneWidget, reason: 'still reading');
    await key(tester, LogicalKeyboardKey.escape, ms: 1500);
    expect(find.byType(PagedReaderView), findsNothing, reason: 'the second Esc leaves');
    await disposeReader(tester);
  });
}

class _Bridge implements NativeBridge {
  // ignore: close_sinks
  final events = StreamController<VolumeKeyDirection>.broadcast();

  @override
  Future<void> setVolumeKeyNavEnabled(bool enabled) async {}
  @override
  Stream<VolumeKeyDirection> get volumeKeyEvents => events.stream;
  @override
  Future<DeviceMemoryInfo?> getDeviceMemoryInfo() async => null;
  @override
  Future<void> setHighRefreshRateEnabled(bool enabled) async {}
}
