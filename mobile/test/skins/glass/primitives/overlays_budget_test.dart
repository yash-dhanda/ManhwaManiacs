// ignore_for_file: unawaited_futures
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/glass/registry.dart';
import 'package:manhwamaniacs/skins/glass/primitives/context_menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast_host.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';

import 'overlay_support.dart';
import 'support.dart';

/// The glass 15.7 phone case: a nav-row group of 3 shapes, a dock group with its orb and accessory (2 shapes),
/// and an overlay on top. Bars are registered by hand (they belong to `mobile/29`); the overlays are real.
void _bars(WidgetTester tester) {
  final ctl = primContainer(tester).read(glassRegistryProvider.notifier);
  ctl.register(GlassRegistration(
      id: ctl.newId(),
      label: 'nav row',
      kind: GlassLayerKind.controls,
      shapes: 3,
      rect: () => const Rect.fromLTWH(0, 60, 390, 48),),);
  ctl.register(GlassRegistration(
      id: ctl.newId(),
      label: 'dock',
      kind: GlassLayerKind.controls,
      shapes: 2,
      rect: () => const Rect.fromLTWH(0, 760, 390, 64),),);
}

void main() {
  testWidgets('bars + a sheet + a toast stay at 4 layers and 8 shapes',
      (tester) async {
    final h = OverlayHost(tester);
    await h.pump(page: const GlassToastHost(child: SizedBox.expand()));
    _bars(tester);
    h.push(GlassSheetPage<void>(
            title: 'Sheet', builder: (_) => const Center(child: Text('body')),)
        .createRoute(h.nav.currentContext!),);
    primContainer(tester)
        .read(glassToastProvider.notifier)
        .show(const GlassToastSpec('Saved'));
    await pumpFor(tester, 900);
    final s = primContainer(tester).read(glassRegistryProvider);
    expect(s.layers, lessThanOrEqualTo(4),
        reason: s.entries.map((e) => e.label).join(', '),);
    expect(s.shapes, lessThanOrEqualTo(8));
    // ignore: avoid_print
    print(
        'measured phone case with sheet and toast: ${s.layers} layers, ${s.shapes} shapes, ${s.scrims} scrims',);
  });

  testWidgets('bars + a menu stay within budget', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    _bars(tester);
    showGlassMenu(h.nav.currentContext!,
        anchor: const Rect.fromLTWH(100, 300, 100, 44),
        title: 'Actions',
        entries: [GlassMenuEntry(label: 'One', onSelected: () {})],);
    await pumpFor(tester, 700);
    final s = primContainer(tester).read(glassRegistryProvider);
    expect(s.layers, lessThanOrEqualTo(4));
    expect(s.shapes, lessThanOrEqualTo(8));
    // ignore: avoid_print
    print(
        'measured phone case with menu: ${s.layers} layers, ${s.shapes} shapes, ${s.scrims} scrims',);
  });

  testWidgets('a context menu registers dimContext as a scrim, not a layer',
      (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    _bars(tester);
    showGlassContextMenu(
      h.nav.currentContext!,
      sourceRect: const Rect.fromLTWH(140, 260, 110, 165),
      preview: const SizedBox(width: 110, height: 165),
      kind: GlassPreviewKind.poster,
      entries: [GlassMenuEntry(label: 'One', onSelected: () {})],
    );
    await pumpFor(tester, 900);
    final s = primContainer(tester).read(glassRegistryProvider);
    expect(s.scrims, greaterThanOrEqualTo(1));
    expect(s.layers, lessThanOrEqualTo(4));
    expect(s.shapes, lessThanOrEqualTo(8));
  });

  test('scrims (dimContext, scroll edges) are not layers or shapes', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final ctl = c.read(glassRegistryProvider.notifier);
    for (var i = 0; i < 3; i++) {
      ctl.register(GlassRegistration(
          id: ctl.newId(),
          label: 'scrim$i',
          kind: GlassLayerKind.overlays,
          shapes: 1,
          rect: () => null,
          scrim: true,),);
    }
    final s = c.read(glassRegistryProvider);
    expect(s.layers, 0);
    expect(s.shapes, 0);
    expect(s.scrims, 3);
  });

  test('a third stacked glass layer forces the lowest solid', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final ctl = c.read(glassRegistryProvider.notifier);
    const r = Rect.fromLTWH(0, 0, 200, 200);
    final low = GlassRegistration(
        id: ctl.newId(),
        label: 'bar',
        kind: GlassLayerKind.controls,
        shapes: 1,
        rect: () => r,);
    final sheet = GlassRegistration(
        id: ctl.newId(),
        label: 'sheet',
        kind: GlassLayerKind.overlays,
        shapes: 1,
        rect: () => r.shift(const Offset(10, 10)),);
    final toast = GlassRegistration(
        id: ctl.newId(),
        label: 'alert',
        kind: GlassLayerKind.interruptions,
        shapes: 1,
        rect: () => r.shift(const Offset(20, 20)),);
    ctl
      ..register(low)
      ..register(sheet)
      ..recompute();
    expect(c.read(glassRegistryProvider).forcedSolid, isEmpty);
    ctl
      ..register(toast)
      ..recompute();
    expect(c.read(glassRegistryProvider).forcedSolid, {low.id});
  });
}
