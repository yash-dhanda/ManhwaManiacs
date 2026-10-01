import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

import '../skin_glass_test.dart' show containerOf, host;
import 'glass_gpu_probe.dart';

/// G3: the layer budget is enforced per frame, and a surface it forces solid stays forced (no live/solid ping-pong).
void main() {
  Widget at(double x, double y, GlassLayerKind kind) => Positioned(
        left: x,
        top: y,
        child: SkinGlass(size: const Size(120, 60), materialize: false, layer: kind, child: const SizedBox()),
      );

  testWidgets('three stacked layers: the lowest goes solid and stays solid, nothing rebuilds while idle', (t) async {
    await t.pumpWidget(host(SizedBox(
      width: 390,
      height: 844,
      child: Stack(children: [
        at(0, 0, GlassLayerKind.controls),
        at(20, 20, GlassLayerKind.overlays),
        at(40, 40, GlassLayerKind.interruptions),
      ]),
    )));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    final seen = <String>[];
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 16));
      final r = containerOf(t).read(glassRegistryProvider);
      seen.add('${r.entries.length}/${r.forcedSolid.length}/${countGpuPasses(t).backdrop}');
    }
    final s = containerOf(t).read(glassRegistryProvider);
    expect(s.forcedSolid.length, 1, reason: 'entries/forced/backdrop per frame: $seen');
    var rebuilds = 0;
    debugOnRebuildDirtyWidget = (_, __) => rebuilds++;
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    debugOnRebuildDirtyWidget = null;
    expect(rebuilds, 0, reason: 'a forced surface flipping live and solid rebuilds every frame');
    expect(containerOf(t).read(glassRegistryProvider).forcedSolid, s.forcedSolid);
    expect(countGpuPasses(t).backdrop, 2);
  });

  testWidgets('nine separate surfaces: six read the backdrop, the three lowest and oldest render solid', (t) async {
    await t.pumpWidget(host(SizedBox(
      width: 390,
      height: 844,
      child: Stack(children: [for (var i = 0; i < 9; i++) at(0, i * 80.0, GlassLayerKind.controls)]),
    )));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    final s = containerOf(t).read(glassRegistryProvider);
    expect(s.forcedSolid.length, 3);
    expect(s.layers, kGlassLayerBudget);
    expect(countGpuPasses(t).backdrop, kGlassLayerBudget);
  });

  testWidgets('content keeps its state when the surface flips between live, solid and back (a drag on it survives)', (t) async {
    await t.pumpWidget(host(const SkinGlass(size: Size(200, 60), child: _Probe())));
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 16)); // through the materialise, whose end used to rebuild the content too
    }
    final probe = t.state(find.byType(_Probe));
    final a11y = containerOf(t).read(glassA11yProvider.notifier);
    a11y.state = const GlassA11y(solid: true);
    await t.pump();
    expect(identical(t.state(find.byType(_Probe)), probe), isTrue, reason: 'live -> solid');
    a11y.state = const GlassA11y();
    await t.pump();
    expect(identical(t.state(find.byType(_Probe)), probe), isTrue, reason: 'solid -> live');
  });
}

class _Probe extends StatefulWidget {
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
