// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, prefer_const_declarations, directives_ordering, prefer_function_declarations_over_variables
// ignore_for_file: prefer_const_constructors
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/utils/recent_searches.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/route_snapshot.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/snapshot_store.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/shell/unavailable_content.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../shell/shell_rig.dart';
import '../primitives/support.dart' show primHost;

/// mobile/45 J: the gate-close checklist of 14.11 and the 18+ purge steps of 8.0.8 over the real shell, for both scenarios (the gate
/// closing, and a switch to a gate-closed profile: both run `purgeMatureLocal`). The share-card, hold and offline-payload items are
/// proven by `share/share_render_test.dart`, `primitives/hold_test.dart` and `stats/numbers_purge_test.dart`, which `qa.md` names.
const _demo = '/dev/glass/shell';

String _sha(File f) => sha256.convert(f.readAsBytesSync()).toString();

void main() {
  setUpAll(loadAppFonts);
  setUp(() {
    GlassStops.reset();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity_status'), (_) async => null);
    m.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity'), (_) async => <String>['wifi']);
    m.setMockMethodCallHandler(const MethodChannel('gaimon'), (_) async => null);
  });
  tearDown(GlassStops.reset);

  for (final scenario in const ['the gate closes in Settings > Content', 'a switch to a gate-closed profile']) {
    testWidgets('gate-close checklist, $scenario', (t) async {
      final rig = await pumpGlassShell(t, start: _demo);
      final c = rig.container;
      final prefs = c.read(sharedPrefsProvider);

      // The seed: a mature level open in the You stack with its snapshot flagged mature, a downloaded blob, a gate-open recent
      // search, narration/cruise/soundscape running, a "Recap ready" toast pending, a cached payload held for the purge.
      for (var i = 0; i < 3; i++) {
        await t.tap(find.text('Push a level').first);
        await t.pump();
        await t.pump(const Duration(milliseconds: 900));
      }
      expect(c.read(glassDepthProvider)[GlassTab.you], 3);
      c.read(glassSnapshotStoreProvider.notifier).put(const GlassRouteSnapshot(routeKey: 'mature-level', title: 'Hidden', depth: 3, tab: GlassTab.you, mature: true, rimTint: Color(0xFF000000)));
      expect(c.read(glassSnapshotStoreProvider).containsKey('mature-level'), isTrue);

      final dir = Directory.systemTemp.createTempSync('mm-gate-');
      final blob = File('${dir.path}/c1.blob')..writeAsBytesSync(List<int>.generate(512, (i) => i % 251));
      final shaBefore = _sha(blob);

      await writeRecentSearch(prefs, 'The Ninth Regression', profileId: 1, gateOpen: true);
      await writeRecentSearch(prefs, 'Moonlit Bakery', profileId: 1, gateOpen: false);

      var narration = 0, cruise = 0, soundscape = 0, holder = 0, mature = 0;
      registerMatureStop('narration', () => narration++);
      registerPlaybackStop('cruise', () => cruise++);
      registerPlaybackStop('soundscape', () => soundscape++);
      registerMatureStop('cruise-mature', () => mature++);
      registerPurgeHolder('recap-and-circle-payloads', (_) => holder++);
      c.read(glassAccessoryProvider.notifier).setNarration(GlassNarrationAccessory(title: 'Chapter 3 · Hidden', playing: true, progress: 0.2, onPlayPause: () {}, openPlayer: (_) {}));
      c.read(glassToastProvider.notifier).show(const GlassToastSpec('Recap ready', tag: 'mature:recap'));
      await t.pump();

      final img = (await t.runAsync(() => createTestImage(width: 4, height: 4)))!;
      final cache = PaintingBinding.instance.imageCache..clear();
      cache.putIfAbsent('mature-cover', () => OneFrameImageStreamCompleter(Future.value(ImageInfo(image: img))));
      await t.pump();
      expect(cache.currentSize, 1);

      // The purge: before the next frame paints.
      c.read(glassPurgeProbeProvider)();
      await t.pump();
      await t.pump(const Duration(milliseconds: 900));

      // 1 narration, cruise and the soundscape stop and the accessory leaves
      expect(narration, 1);
      expect(mature, 1);
      expect(c.read(glassAccessoryProvider).narration, isNull);
      // 2 the Recap ready toast is gone
      expect(c.read(glassToastProvider).where((e) => e.spec.tag?.startsWith('mature:') ?? false), isEmpty);
      // 3 every tab whose top route was mature is at its root level or above it
      expect(c.read(glassDepthProvider)[GlassTab.you], 2);
      // 4 the stack overview shows no mature level (the snapshot was disposed)
      expect(c.read(glassSnapshotStoreProvider).values.where((s) => s.mature), isEmpty);
      // 5 recent searches typed with the gate open are gone
      expect(readRecentSearches(prefs, profileId: 1), ['Moonlit Bakery']);
      // 6 the image caches were cleared
      expect(cache.currentSize, 0);
      // 7 held payloads (Home, Statistics, Wrapped, the recap, the Circle) are deleted
      expect(holder, 1);
      // 8 and 9 downloads are filtered on read and never deleted: the blob is byte-identical after the purge and a reopened gate
      expect(blob.existsSync(), isTrue);
      expect(_sha(blob), shaBefore);
      dir.deleteSync(recursive: true);
      // playback (cruise, soundscape) stops with the profile switch and sign-out, not with the gate alone
      GlassStops.stopAllPlayback();
      expect((cruise, soundscape), (1, 1));
    });
  }

  testWidgets('a deep link to mature content on a gated profile opens the lens "This isn\'t available on this profile" with "Back home" and no title or cover', (t) async {
    var home = 0;
    await t.pumpWidget(primHost(GlassUnavailableContent(matureBlocked: true, onBack: () {}, onHome: () => home++)));
    await t.pump(const Duration(milliseconds: 1500));
    expect(find.text("This isn't available on this profile"), findsOneWidget);
    expect(find.text('Back home'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    await t.tap(find.text('Back home'));
    await t.pump(const Duration(milliseconds: 400));
    expect(home, 1);
  });
}
