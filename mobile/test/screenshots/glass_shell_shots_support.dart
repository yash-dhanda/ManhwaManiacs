import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/skin_app.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../skins/glass/shell/shell_rig.dart';
import '../support/test_overrides.dart';
import 'support/shot_harness.dart';
import 'support/skin_shots.dart';

/// One capture session of the shell shots: the real app (`SkinApp` with the Glass router) at a proof size.
class ShotSession {
  ShotSession(this.t, this.container);
  final WidgetTester t;
  final ProviderContainer container;

  GoRouter get router => container.read(skinRouterProvider);

  Future<void> settle([int ms = 700]) async {
    await t.pump();
    await t.pump(Duration(milliseconds: ms));
  }

  /// Writes `<MM_PROOF_DIR>/<name>-<size.name>.png` (or rasterises and discards when unset).
  Future<void> snap(String name, SkinShotSize size) async {
    final finder = find.byKey(kSkinShotKey);
    final dir = proofDir;
    if (dir == null) {
      final boundary = t.renderObject<RenderRepaintBoundary>(finder);
      await t.runAsync(() async {
        (await boundary.toImage(pixelRatio: size.pixelRatio)).dispose();
      });
    } else {
      await writeShot(t, finder, '$dir/$name-${size.name}.png', pixelRatio: size.pixelRatio);
    }
  }
}

/// Pumps the Glass app at [size] starting at [start], signed in with a profile and no network.
Future<ShotSession> openShell(
  WidgetTester t,
  SkinShotSize size, {
  String start = '/',
  List<Override> extra = const [],
  bool settle = true,
  bool forceKind = true,
}) async {
  await t.pumpWidget(const SizedBox.shrink());
  setSkinShotView(t, size);
  const haptics = MethodChannel('gaimon');
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(haptics, (_) async => null);
  addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(haptics, null));
  SharedPreferences.setMockInitialValues(testPrefsDefaults());
  final prefs = await SharedPreferences.getInstance();
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        skinIdProvider.overrideWithValue(SkinId.glass),
        returnRouteProvider.overrideWithValue(start),
        ...shellTestOverrides(),
        ...extra,
      ],
      child: RepaintBoundary(key: kSkinShotKey, child: const SkinApp()),
    ),
  );
  final container = ProviderScope.containerOf(t.element(find.byType(SkinApp)));
  final s = ShotSession(t, container);
  if (settle) {
    await s.settle(600);
    await s.settle(600);
  } else {
    await t.pump();
  }
  return s;
}
