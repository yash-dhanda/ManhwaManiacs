import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/new_chapters_capsule.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/shell/search_orb.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/skins.dart';

import '../../../screenshots/support/shot_harness.dart';
import 'shell_rig.dart';

Future<void> _settle(WidgetTester t, [int ms = 900]) async {
  await t.pump();
  await t.pump(Duration(milliseconds: ms));
}

({int layers, int shapes}) _counts(ShellRig rig) {
  final r = rig.container.read(glassRegistryProvider);
  return (layers: r.layers, shapes: r.shapes);
}

void _toast(ShellRig rig) => rig.container.read(glassToastProvider.notifier).show(const GlassToastSpec('Saved'));

void main() {
  setUpAll(loadAppFonts);

  testWidgets('§15.7 phone page with a sheet and a toast: at most 4 layers and 8 shapes', (t) async {
    final rig = await pumpGlassShell(t, start: '/dev/glass/shell');
    final router = rig.container.read(skinRouterProvider);
    // ignore: unawaited_futures
    router.push<void>('/sources/demo/series/x', extra: const GlassNavExtra());
    await _settle(t, 1200);
    _toast(rig);
    await _settle(t);
    final c = _counts(rig);
    // ignore: avoid_print
    print('BUDGET phone page+sheet+toast: ${c.layers} layers / ${c.shapes} shapes');
    expect(c.layers, lessThanOrEqualTo(4));
    expect(c.shapes, lessThanOrEqualTo(8));
  });

  testWidgets('§15.7 phone search open: at most 3 layers and 3 shapes', (t) async {
    final rig = await pumpGlassShell(t);
    await t.tap(find.byType(GlassSearchOrbBody));
    await _settle(t, 1000);
    final c = _counts(rig);
    // ignore: avoid_print
    print('BUDGET phone search: ${c.layers} layers / ${c.shapes} shapes');
    expect(c.layers, lessThanOrEqualTo(3));
    expect(c.shapes, lessThanOrEqualTo(3));
  });

  testWidgets('§15.7 tablet frame: sidebar, toolbar group, accessory, toast and a window: at most 6 layers and 6 shapes', (t) async {
    final rig = await pumpGlassShell(t, size: const Size(834, 1194), start: '/dev/glass/shell');
    rig.container.read(glassAccessoryProvider.notifier).setDownloading(GlassDownloadingAccessory(chapters: 2, progress: 0.3, paused: false, onToggle: () {}));
    // ignore: unawaited_futures
    rig.container.read(skinRouterProvider).push<void>('/sources/demo/series/x', extra: const GlassNavExtra());
    await _settle(t, 1200);
    _toast(rig);
    await _settle(t);
    final c = _counts(rig);
    // ignore: avoid_print
    print('BUDGET tablet: ${c.layers} layers / ${c.shapes} shapes');
    expect(c.layers, lessThanOrEqualTo(6));
    expect(c.shapes, lessThanOrEqualTo(6));
  });

  testWidgets('§15.7 desktop frame: sidebar, toolbar group, toast, app-update capsule and a window: at most 6 layers and 6 shapes', (t) async {
    final rig = await pumpGlassShell(t, size: const Size(1366, 1024), start: '/dev/glass/shell');
    rig.container.read(glassAppUpdateProvider.notifier).state = GlassAppUpdateSpec(onUpdate: () {});
    // ignore: unawaited_futures
    rig.container.read(skinRouterProvider).push<void>('/sources/demo/series/x', extra: const GlassNavExtra());
    await _settle(t, 1200);
    _toast(rig);
    await _settle(t);
    final c = _counts(rig);
    // ignore: avoid_print
    print('BUDGET desktop: ${c.layers} layers / ${c.shapes} shapes');
    expect(c.layers, lessThanOrEqualTo(6));
    expect(c.shapes, lessThanOrEqualTo(6));
  });
}
