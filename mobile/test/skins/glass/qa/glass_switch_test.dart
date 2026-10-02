// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, prefer_const_declarations, directives_ordering, prefer_function_declarations_over_variables
// ignore_for_file: prefer_const_constructors
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/app_restart.dart';
import 'package:manhwamaniacs/app/skin_app.dart';
import 'package:manhwamaniacs/app/skin_boot.dart';
import 'package:manhwamaniacs/app/switch_skin.dart';
import 'package:manhwamaniacs/core/platform/app_icon_switcher.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart' show skinRestartCarriesSessionProvider;
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/liquid.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/shell/skin_switch_flow.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import '../shell/shell_rig.dart' show shellTestOverrides;

/// The in-app Reduce Motion switch: the shared `mm.boot.a11y` record (both skins' Settings), for the signed-in profile and
/// the device; the old Glass-only `mm.a11y.p1.reduceMotion` key is still read where that record cannot be built.
const _appReduced = <String, Object>{'mm.a11y.p1.reduceMotion': true, 'mm.boot.a11y.u1p1': '{"motion":"reduced"}', 'mm.boot.a11y.device': '{"motion":"reduced"}'};

/// mobile/45 M with the flag on: the real switch (`switchSkinFrom` from Cinematic, `runSkinSwitch` from Glass) through the real
/// `SkinBoot.read` at the restart.

class _Rig {
  _Rig(this.prefs, this.builds, this.skins, this.routes);
  final SharedPreferences prefs;
  final int Function() builds;
  final List<SkinId> skins;
  final List<String?> routes;
}

Future<_Rig> _pump(WidgetTester t, {required SkinId start, required String route, Size size = const Size(390, 844), Map<String, Object> prefs0 = const {}}) async {
  SharedPreferences.setMockInitialValues(testPrefsDefaults({kSkinActiveKey: start.name, kSkinReturnKey: route, ...prefs0}));
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
    final skin = boot.skin;
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

/// A Consumer in the app's root overlay hands out a WidgetRef and a context under the router.
Future<(WidgetRef, BuildContext)> _ref(WidgetTester t) async {
  late WidgetRef ref;
  late BuildContext ctx;
  t.state<NavigatorState>(find.byType(Navigator).first).overlay!.insert(OverlayEntry(builder: (_) => Consumer(builder: (c, r, _) {
        ref = r;
        ctx = c;
        return const SizedBox.shrink();
      })));
  await t.pump();
  return (ref, ctx);
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

  testWidgets('Cinematic to Glass: the switch writes mm.skin.active, restarts once, prepares Glass, restores the route and leaves no Cinematic widget', (t) async {
    final rig = await _pump(t, start: SkinId.cinematic, route: '/library/collections');
    expect(rig.skins, [SkinId.cinematic]);
    expect(_cine, findsWidgets, reason: 'the start tree is Cinematic');
    final (ref, ctx) = await _ref(t);
    final done = switchSkinFrom(ctx, ref, to: SkinId.glass, outgoing: () async {});
    await t.pump(const Duration(milliseconds: 250));
    await t.pump(const Duration(milliseconds: 50));
    await t.runAsync(() => done);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));

    expect(rig.prefs.getString(kSkinActiveKey), 'glass', reason: 'the device mirror follows the switch');
    expect(rig.prefs.getInt(kSkinRestartLastKey), isNotNull, reason: 'mm.skin.t0 was written at confirm and the first frame logged the restart time');
    expect(rig.prefs.getString(kSkinReturnKey), isNull, reason: 'the return route was consumed at boot');
    expect(rig.builds(), 2);
    expect(rig.skins, [SkinId.cinematic, SkinId.glass]);
    expect(rig.routes.last, '/library/collections');
    expect(inits, 1, reason: 'Glass prepare() awaited the shader initialiser before the restart');
    expect(_cine, findsNothing, reason: 'nothing of the other skin is in the tree');
    await _pumpUntil(t, () => false, maxMs: 1500);
    expect(Flags.glassAvailable, isTrue);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 20));
  });

  testWidgets('Glass to Cinematic: the switch leaves through the Skin melt (615 ms), fires skin.switch, restores /settings/diagnostics and leaves no Glass widget', (t) async {
    // "App icon follows the skin" on: runSkinSwitch (also the arrival toast's Undo) moves the icon (release/01 D2).
    final rig = await _pump(t, start: SkinId.glass, route: '/settings/diagnostics', prefs0: {kIconFollowKey: true});
    expect(rig.skins, [SkinId.glass]);
    final (ref, ctx) = await _ref(t);
    unawaited(runSkinSwitch(ctx, ref, SkinId.cinematic));
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
    // Budget: the melt and one frame; nothing waits longer.
    expect(elapsed, lessThanOrEqualTo(615 + 50 + 50));
    expect(rig.prefs.getString(kSkinActiveKey), 'cinematic');
    expect(rig.skins.last, SkinId.cinematic);
    expect(rig.routes.last, '/settings/diagnostics');
    expect(rig.prefs.getString(kIconPendingKey), kAndroidCinematicIconAlias, reason: 'the icon follows an explicit switch');
    await t.pump(const Duration(milliseconds: 600));
    expect(find.byWidgetPredicate((w) => RegExp(r'^_?Glass').hasMatch(w.runtimeType.toString())), findsNothing, reason: 'nothing of Glass remains');
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 20));
  });

  testWidgets('Reduce Motion: the melt is a 200 ms fade to black', (t) async {
    final rig = await _pump(t, start: SkinId.glass, route: '/settings/diagnostics', prefs0: _appReduced);
    final (ref, ctx) = await _ref(t);
    unawaited(runSkinSwitch(ctx, ref, SkinId.cinematic));
    await t.pump();
    var elapsed = 0;
    while (rig.builds() < 2 && elapsed < 3000) {
      await t.pump(const Duration(milliseconds: 50));
      elapsed += 50;
      await t.runAsync(() async {});
    }
    expect(rig.builds(), 2);
    expect(elapsed, lessThanOrEqualTo(200 + 100));
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 20));
  });
}
