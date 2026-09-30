import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/skins.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../shell/shell_rig.dart';
import 'home_rig.dart';

({int layers, int shapes}) counts(ShellRig rig) {
  final r = rig.container.read(glassRegistryProvider);
  return (layers: r.layers, shapes: r.shapes);
}

Future<void> settle(WidgetTester t, [int ms = 900]) async {
  await t.pump();
  await t.pump(Duration(milliseconds: ms));
}

void main() {
  setUpAll(loadAppFonts);

  // The two spotlight controls are two separate glass buttons, not one group: one layer more than glass 15.7's phone count of 3 at the top
  // of Home (the nav-row group, the dock group, the primary and the secondary), and never above the Flutter budget of 6 layers and 8 shapes.
  homeTest('§15.7 phone top of Home: the nav row, the dock and the two spotlight controls', (t) async {
    final rig = await pumpHome(t, homeRepoOf('ready'));
    final c = counts(rig);
    // ignore: avoid_print
    print('BUDGET home phone top: ${c.layers} layers / ${c.shapes} shapes');
    expect(c.layers, lessThanOrEqualTo(4));
    expect(c.shapes, lessThanOrEqualTo(7));
  });

  homeTest('§15.7 phone scrolled with the accessory, a sheet and a toast: at most 4 layers and 8 shapes', (t) async {
    final rig = await pumpHome(t, homeRepoOf('ready'));
    await t.fling(find.byType(Scrollable).first, const Offset(0, -900), 2500);
    await settle(t, 1200);
    // The spotlight controls are content twins now; the accessory joins the dock group.
    final scrolled = counts(rig);
    // ignore: avoid_print
    print('BUDGET home phone scrolled: ${scrolled.layers} layers / ${scrolled.shapes} shapes');
    expect(scrolled.layers, lessThanOrEqualTo(3));
    // ignore: unawaited_futures
    rig.container.read(skinRouterProvider).push<void>('/sources/demo/series/x', extra: const GlassNavExtra());
    await settle(t, 1200);
    rig.container.read(glassToastProvider.notifier).show(const GlassToastSpec('Saved'));
    await settle(t);
    final c = counts(rig);
    // ignore: avoid_print
    print('BUDGET home phone sheet+toast: ${c.layers} layers / ${c.shapes} shapes');
    expect(c.layers, lessThanOrEqualTo(4));
    expect(c.shapes, lessThanOrEqualTo(8));
    expect(rig.container.read(glassAccessoryProvider).hasContent, isTrue);
  });

  homeTest('§15.7 desktop frame at rest: the sidebar, the toolbar group and the spotlight controls', (t) async {
    final rig = await pumpHome(t, homeRepoOf('ready'), size: const Size(1366, 1024));
    final c = counts(rig);
    // ignore: avoid_print
    print('BUDGET home desktop rest: ${c.layers} layers / ${c.shapes} shapes');
    expect(c.layers, lessThanOrEqualTo(5));
    expect(c.shapes, lessThanOrEqualTo(8));
  });

  homeTest('§15.7 desktop frame with a window and a toast: at most 5 layers and 8 shapes', (t) async {
    final rig = await pumpHome(t, homeRepoOf('ready'), size: const Size(1366, 1024));
    // ignore: unawaited_futures
    rig.container.read(skinRouterProvider).push<void>('/sources/demo/series/x', extra: const GlassNavExtra());
    await settle(t, 1200);
    rig.container.read(glassToastProvider.notifier).show(const GlassToastSpec('Saved'));
    await settle(t);
    final c = counts(rig);
    // ignore: avoid_print
    print('BUDGET home desktop window: ${c.layers} layers / ${c.shapes} shapes');
    expect(c.layers, lessThanOrEqualTo(5));
    expect(c.shapes, lessThanOrEqualTo(8));
  });
}
