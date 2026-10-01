// ignore_for_file: directives_ordering, prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/app/skin_app.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/app/switch_skin.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart' show skinRestartCarriesSessionProvider;
import 'package:manhwamaniacs/features/profiles/providers/skin_outbox.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/liquid.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import '../shell/shell_rig.dart' show shellTestOverrides;

/// mobile/45 M. `Flags.glassAvailable` is false, so the real `SkinBoot.resolveSkin` maps a debug `glass` to Cinematic (stack 8.0.7, tested
/// in `test/app/skin_boot_test.dart`). These tests therefore build the restart's tree the way the release that flips the flag will:
/// the debug key wins. They assert everything the debug path does up to and after that point; the gap is an open issue in qa.md.
SkinId _bootSkin(SharedPreferences p) => skinIdFromName(p.getString(kSkinDebugKey)) ?? SkinBoot.resolveSkinWithoutDebug(p);

class _Rig {
  _Rig(this.prefs, this.builds, this.skins, this.routes);
  final SharedPreferences prefs;
  final int Function() builds;
  final List<SkinId> skins;
  final List<String?> routes;
}

Future<_Rig> _pump(WidgetTester t, {required SkinId start, required String route, Size size = const Size(390, 844), Map<String, Object> prefs0 = const {}}) async {
  SharedPreferences.setMockInitialValues(testPrefsDefaults({kSkinActiveKey: start.name, kSkinReturnKey: route, if (start == SkinId.glass) kSkinDebugKey: 'glass', ...prefs0}));
  final prefs = await SharedPreferences.getInstance();
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  const haptics = MethodChannel('gaimon');
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(haptics, (_) async => null);
  addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(haptics, null));
  var builds = 0;
  final skins = <SkinId>[];
  final routes = <String?>[];
  await t.pumpWidget(AppRestart(builder: () {
    builds++;
    final boot = SkinBoot.read(prefs);
    final skin = start == SkinId.glass || prefs.getString(kSkinDebugKey) != null ? _bootSkin(prefs) : boot.skin;
    skins.add(skin);
    routes.add(boot.returnRoute);
    return ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        skinIdProvider.overrideWithValue(skin),
        returnRouteProvider.overrideWithValue(boot.returnRoute),
        skinRestartCarriesSessionProvider.overrideWithValue(boot.carrySession),
        ...shellTestOverrides(),
      ],
      child: const SkinApp(),
    );
  }));
  await t.pump(const Duration(milliseconds: 600));
  await t.pump(const Duration(milliseconds: 600));
  return _Rig(prefs, () => builds, skins, routes);
}

Finder get _cine => find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('Cine'));

Future<void> _pumpUntil(WidgetTester t, bool Function() done, {int maxMs = 4000}) async {
  for (var ms = 0; ms < maxMs && !done(); ms += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late GlassMotionRecorder recorder;
  late int inits;
  setUp(() {
    recorder = GlassMotionRecorder();
    GlassMotion.recorder = recorder;
    GlassHaptics.debugLog.clear();
    inits = 0;
    resetLiquidGlassReadyForTest();
    liquidGlassInitializer = () async => inits++;
  });
  tearDown(() {
    GlassMotion.recorder = GlassMotionRecorder.instance;
    GlassMotion.isReduced = () => false;
  });

  testWidgets('Cinematic to Glass: the debug row writes only mm.skin.debug, restarts once, prepares Glass, restores the route and leaves no Cinematic widget', (t) async {
    final rig = await _pump(t, start: SkinId.cinematic, route: '/library/collections');
    expect(rig.skins, [SkinId.cinematic]);
    expect(_cine, findsWidgets, reason: 'the start tree is Cinematic');
    // A Consumer in an overlay hands out a WidgetRef; the context is the app's own.
    late WidgetRef ref;
    final ctx = t.element(find.byType(Navigator).first);
    Overlay.of(ctx).insert(OverlayEntry(builder: (_) => Consumer(builder: (c, r, _) {
          ref = r;
          return const SizedBox.shrink();
        })));
    await t.pump();
    final queuedBefore = rig.prefs.getString(kSkinOutboxKey);
    final done = debugSwitchSkin(ctx, ref, SkinId.glass);
    await t.pump(const Duration(milliseconds: 250));
    await t.pump(const Duration(milliseconds: 50));
    await t.runAsync(() => done);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));

    expect(rig.prefs.getString(kSkinDebugKey), 'glass');
    expect(rig.prefs.getString(kSkinActiveKey), 'cinematic', reason: 'the profile mirror is untouched');
    expect(rig.prefs.getString(kSkinOutboxKey), queuedBefore, reason: 'no PATCH /profiles/{id} was queued');
    expect(rig.prefs.getInt(kSkinRestartLastKey), isNotNull, reason: 'mm.skin.t0 was written at confirm and the first frame logged the restart time');
    expect(rig.prefs.getString(kSkinReturnKey), isNull, reason: 'the return route was consumed at boot');
    expect(rig.prefs.getString(kSkinFromKey), isNull, reason: 'the debug path writes no mm.skin.prev, so there is no arrival toast');
    expect(rig.builds(), 2);
    expect(rig.skins, [SkinId.cinematic, SkinId.glass]);
    expect(rig.routes.last, '/settings/diagnostics');
    expect(inits, 1, reason: 'Glass prepare() awaited the shader initialiser before the restart');
    expect(_cine, findsNothing, reason: 'nothing of the other skin is in the tree');
    await _pumpUntil(t, () => false, maxMs: 1500);
    expect(Flags.glassAvailable, isFalse);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 20));
  });

  testWidgets('Glass to Cinematic: the debug row leaves through the Skin melt (615 ms), fires skin.switch, restores /settings/diagnostics and leaves no Glass widget', (t) async {
    final rig = await _pump(t, start: SkinId.glass, route: '/settings/diagnostics');
    expect(rig.skins, [SkinId.glass]);
    await t.scrollUntilVisible(find.text('Preview Glass skin'), 300, scrollable: find.byType(Scrollable).first);
    await t.pump(const Duration(milliseconds: 300));
    final tab = find.descendant(of: find.ancestor(of: find.text('Preview Glass skin'), matching: find.byType(Column)).first, matching: find.text('Cinematic'));
    expect(tab, findsWidgets);
    final before = rig.prefs.getString(kSkinActiveKey);
    await t.ensureVisible(tab.first);
    await t.tap(tab.first);
    await t.pump();
    // The melt is in the motion log with its planned settle, and the heavy haptic fired.
    expect(recorder.entries.map((e) => (e.label, e.plannedMs)), contains(('SKIN MELT', 615)));
    expect(GlassHaptics.debugLog.map((e) => e.event), contains(HapticEvent.skinSwitch));
    var elapsed = 0;
    while (rig.builds() < 2 && elapsed < 5000) {
      await t.pump(const Duration(milliseconds: 50));
      elapsed += 50;
      await t.runAsync(() async {});
    }
    expect(rig.builds(), 2, reason: 'the restart happened');
    // Budget: the melt, the 200 ms curtain of the debug path and one frame; nothing waits longer.
    expect(elapsed, lessThanOrEqualTo(615 + 200 + 50 + 50));
    expect(rig.prefs.getString(kSkinDebugKey), 'cinematic');
    expect(rig.prefs.getString(kSkinActiveKey), before);
    expect(rig.skins.last, SkinId.cinematic);
    expect(rig.routes.last, '/settings/diagnostics');
    await t.pump(const Duration(milliseconds: 600));
    expect(find.byWidgetPredicate((w) => RegExp(r'^_?Glass').hasMatch(w.runtimeType.toString())), findsNothing, reason: 'nothing of Glass remains');
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 20));
  });

  testWidgets('Reduce Motion: the melt is a 200 ms fade to black', (t) async {
    final rig = await _pump(t, start: SkinId.glass, route: '/settings/diagnostics', prefs0: const {'mm.a11y.p1.reduceMotion': true});
    await t.scrollUntilVisible(find.text('Preview Glass skin'), 300, scrollable: find.byType(Scrollable).first);
    await t.pump(const Duration(milliseconds: 300));
    final tab = find.descendant(of: find.ancestor(of: find.text('Preview Glass skin'), matching: find.byType(Column)).first, matching: find.text('Cinematic'));
    await t.ensureVisible(tab.first);
    await t.tap(tab.first);
    await t.pump();
    var elapsed = 0;
    while (rig.builds() < 2 && elapsed < 3000) {
      await t.pump(const Duration(milliseconds: 50));
      elapsed += 50;
      await t.runAsync(() async {});
    }
    expect(rig.builds(), 2);
    expect(elapsed, lessThanOrEqualTo(200 + 200 + 100));
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 20));
  });
}
