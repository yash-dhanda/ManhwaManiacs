import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' show AdaptiveGlass;
import 'package:manhwamaniacs/skins/glass/glass/focus_ring.dart';
import 'package:manhwamaniacs/skins/glass/glass/liquid.dart';
import 'package:manhwamaniacs/skins/glass/glass/rim_painter.dart';
import 'package:manhwamaniacs/skins/glass/glass/tier_math.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

Widget host(
  Widget child, {
  List<Override> overrides = const [],
  Size size = const Size(390, 844),
}) =>
    ProviderScope(
      overrides: overrides,
      child: MediaQuery(
        data: MediaQueryData(size: size, devicePixelRatio: 3),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SkinGlassRoot(child: Center(child: child)),
        ),
      ),
    );

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(SkinGlassRoot)));

/// The colour a layer of [fill] over a [dim] black layer gives over [backdrop] (0..255 channels), source-over.
List<double> manualComposite(Color fill, double dim, double backdrop) {
  final afterDim = backdrop * (1 - dim);
  double ch(double c) => c * 255 * fill.a + afterDim * (1 - fill.a);
  return [ch(fill.r), ch(fill.g), ch(fill.b)];
}

List<double> foldedComposite(Color folded, double backdrop) {
  double ch(double c) => c * 255 * folded.a + backdrop * (1 - folded.a);
  return [ch(folded.r), ch(folded.g), ch(folded.b)];
}

void main() {
  group('foldDim', () {
    test('equals the two-layer composite over white and black within 1/255', () {
      for (final fill in const [Color(0x12FFFFFF), Color(0xDB7563F2), Color(0x851C1C22), Color(0x05FFFFFF)]) {
        for (final dim in const [0.22, 0.4, 0.64, 0.72]) {
          for (final backdrop in const [0.0, 255.0]) {
            final want = manualComposite(fill, dim, backdrop);
            final got = foldedComposite(foldDim(fill, dim), backdrop);
            for (var i = 0; i < 3; i++) {
              expect((want[i] - got[i]).abs(), lessThan(1.0), reason: '$fill dim $dim over $backdrop');
            }
          }
        }
      }
    });
  });

  group('tier table', () {
    test('T1 to T5 map to LiquidGlassSettings field by field (glass 2.4.3 Flutter mapping)', () {
      const thickness = [12.0, 20.0, 24.0, 40.0, 56.0];
      const blur = [2.0, 8.0, 10.0, 22.0, 32.0];
      const saturation = [1.4, 1.8, 1.8, 1.8, 1.7];
      const light = [0.55, 0.42, 0.40, 0.30, 0.26];
      const chroma = [0.0, 0.0, 0.0, 0.35, 0.5];
      const ids = [GlassTierId.t1, GlassTierId.t2, GlassTierId.t3, GlassTierId.t4, GlassTierId.t5];
      for (var i = 0; i < 5; i++) {
        final p = tierParams(ids[i]);
        final fill = foldDim(p.fill, 0.5);
        final s = liquidSettingsFor(p: p, fill: fill, angle: kFixedAngle);
        expect(s.thickness, thickness[i], reason: 'T${i + 1}');
        expect(s.blur, blur[i]);
        expect(s.saturation, saturation[i]);
        expect(s.lightIntensity, light[i]);
        expect(s.chromaticAberration, chroma[i]);
        expect(s.refractiveIndex, 1.2);
        expect(s.glassColor, fill);
        expect(s.lightAngle, kFixedAngle);
      }
    });

    test('materialise scales thickness and chromatic aberration only', () {
      final s = liquidSettingsFor(p: tierParams(GlassTierId.t5), fill: const Color(0x00000000), angle: 0, materialize: 0.5);
      expect(s.thickness, 28);
      expect(s.chromaticAberration, 0.25);
      expect(s.blur, 32);
    });

    test('lerpTier interpolates every parameter between neighbours', () {
      final mid = lerpTier(2.5);
      final a = tierParams(GlassTierId.t2), b = tierParams(GlassTierId.t3);
      expect(mid.thickness, closeTo((a.thickness + b.thickness) / 2, 1e-9));
      expect(mid.blur, closeTo((a.blur + b.blur) / 2, 1e-9));
      expect(mid.specular, closeTo((a.specular + b.specular) / 2, 1e-9));
      expect(mid.rond, closeTo(50, 1e-9));
      expect(mid.shadowOffsetY, closeTo((a.shadowOffsetY + b.shadowOffsetY) / 2, 1e-9));
      expect(lerpTier(1).thickness, 12);
      expect(lerpTier(5).thickness, 56);
      expect(lerpTier(4.5).chromatic, closeTo(0.425, 1e-9));
    });
  });

  group('render paths', () {
    testWidgets('a twin subtree has no BackdropFilter and no AdaptiveGlass and is not registered', (tester) async {
      await tester.pumpWidget(host(const SkinGlass(twin: GlassTwin.content, size: Size(100, 50), child: SizedBox())));
      await tester.pump();
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(AdaptiveGlass), findsNothing);
      expect(containerOf(tester).read(glassRegistryProvider).layers, 0);
    });

    testWidgets('disposing a SkinGlass mid-sweep frees the sweep coordinator', (tester) async {
      GlassSweep.reset();
      await tester.pumpWidget(host(const SkinGlass(size: Size(100, 50), materialize: false, child: SizedBox())));
      final state = tester.state<SkinGlassState>(find.byType(SkinGlass));
      expect(GlassSweep.request(state), isTrue);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(host(const SizedBox()));
      await tester.pump();
      GlassSweep.now = () => Duration(microseconds: DateTime.now().microsecondsSinceEpoch) + const Duration(seconds: 5);
      addTearDown(() => GlassSweep.now = () => Duration(microseconds: DateTime.now().microsecondsSinceEpoch));
      await tester.pumpWidget(host(const SkinGlass(size: Size(100, 50), materialize: false, child: SizedBox())));
      expect(GlassSweep.request(tester.state<SkinGlassState>(find.byType(SkinGlass))), isTrue);
      GlassSweep.reset();
    });

    testWidgets('a live surface registers once and unregisters on dispose', (tester) async {
      await tester.pumpWidget(host(const SkinGlass(size: Size(100, 50), materialize: false, child: SizedBox())));
      await tester.pump();
      final c = containerOf(tester);
      expect(c.read(glassRegistryProvider).layers, 1);
      expect(c.read(glassRegistryProvider).shapes, 1);
      await tester.pumpWidget(host(const SizedBox()));
      await tester.pump();
      expect(c.read(glassRegistryProvider).layers, 0);
    });

    testWidgets('a nested SkinGlass without a twin renders the onGlass twin, and no glass nests in glass', (tester) async {
      await tester.pumpWidget(
        host(
          const SkinGlass(
            size: Size(200, 100),
            materialize: false,
            child: SkinGlass(size: Size(60, 30), materialize: false, child: SizedBox()),
          ),
        ),
      );
      await tester.pump();
      expect(containerOf(tester).read(glassRegistryProvider).layers, 1);
      final inner = find.descendant(of: find.byType(SkinGlass), matching: find.byType(SkinGlass));
      expect(inner, findsOneWidget);
      expect(
        find.descendant(of: inner, matching: find.byWidgetPredicate((w) => w is ColoredBox && w.color == twinFill(GlassTwin.onGlass))),
        findsOneWidget,
      );
      // Exactly one backdrop filter in the whole tree (the outer surface).
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.descendant(of: find.byType(BackdropFilter), matching: find.byType(BackdropFilter)), findsNothing);
    });

    testWidgets('the frost path blurs and saturates through one BackdropFilter under the root BackdropGroup', (tester) async {
      await tester.pumpWidget(host(const SkinGlass(size: Size(100, 50), materialize: false, child: SizedBox())));
      await tester.pump();
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(BackdropGroup), findsOneWidget);
    });

    testWidgets('a frost surface without a BackdropGroup asserts in debug', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SkinGlass(size: Size(100, 50), materialize: false, child: SizedBox()),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('the solid path uses #1C1C22 (T1-T3), #26262E (T4-T5), tinted #5B4AD1, and no BackdropFilter', (tester) async {
      final solid = glassA11yProvider.overrideWith((ref) => const GlassA11y(solid: true));
      Future<void> check(GlassTierId tier, GlassFinishKind finish, Color color) async {
        await tester.pumpWidget(host(SkinGlass(tier: tier, finish: finish, size: const Size(100, 50), materialize: false, child: const SizedBox()), overrides: [solid]));
        await tester.pump();
        expect(find.byType(BackdropFilter), findsNothing);
        expect(find.byType(AdaptiveGlass), findsNothing);
        expect(find.byWidgetPredicate((w) => w is ColoredBox && w.color == color), findsOneWidget, reason: '$tier $finish');
        expect(containerOf(tester).read(glassRegistryProvider).layers, 0);
      }

      await check(GlassTierId.t2, GlassFinishKind.regular, const Color(0xFF1C1C22));
      await check(GlassTierId.t4, GlassFinishKind.regular, const Color(0xFF26262E));
      await check(GlassTierId.t2, GlassFinishKind.tinted, const Color(0xFF5B4AD1));
    });

    testWidgets('Increase Contrast paints the 1 px 0x8CFFFFFF border and lifts the dim floor to 0.40', (tester) async {
      final hc = glassA11yProvider.overrideWith((ref) => const GlassA11y(increaseContrast: true));
      await tester.pumpWidget(host(const SkinGlass(size: Size(100, 50), materialize: false, lb: 0, child: SizedBox()), overrides: [hc]));
      await tester.pump();
      final rim = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is GlassRimPainter);
      final painter = tester.widget<CustomPaint>(rim.first).painter! as GlassRimPainter;
      expect(painter.highContrast, isTrue);
      expect(GlassRimPainter.hcBorder, const Color(0x8CFFFFFF));
      expect(tester.renderObject(rim.first), paints..path(color: const Color(0x8CFFFFFF), strokeWidth: 1));
      expect(dimFor(0, highContrast: true), 0.40);
      // The frost fill carries the folded dim: with lb 0 it is the 0.40 floor, not 0.22.
      final filled = find.descendant(of: find.byType(BackdropFilter), matching: find.byType(ColoredBox));
      final colour = tester.widget<ColoredBox>(filled).color;
      expect(colour.a, closeTo(foldDim(glassTokens.glassT2.fill, 0.40).a, 0.01));
    });
  });

  group('budget and stacking', () {
    test('the seventh layer and the ninth shape log one warning naming every registrant; exempt scopes are ignored', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ctl = container.read(glassRegistryProvider.notifier);
      final logs = <String>[];
      final old = debugPrint;
      debugPrint = (String? m, {int? wrapWidth}) => logs.add(m ?? '');
      addTearDown(() => debugPrint = old);
      GlassRegistration reg(int i, {int shapes = 1, bool exempt = false}) =>
          GlassRegistration(id: ctl.newId(), label: 'r$i', kind: GlassLayerKind.controls, shapes: shapes, rect: () => null, exempt: exempt);
      for (var i = 0; i < 6; i++) {
        ctl.register(reg(i));
      }
      expect(logs.where((l) => l.contains('budget')), isEmpty);
      ctl.register(reg(6));
      expect(logs.where((l) => l.contains('budget')).length, 1);
      expect(logs.last, contains('r0'));
      expect(logs.last, contains('r6'));
      ctl.register(reg(7));
      expect(logs.where((l) => l.contains('budget')).length, 1, reason: 'one warning per crossing');

      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      final ctl2 = c2.read(glassRegistryProvider.notifier);
      logs.clear();
      ctl2.register(GlassRegistration(id: ctl2.newId(), label: 'group', kind: GlassLayerKind.controls, shapes: 8, rect: () => null));
      expect(logs, isEmpty);
      ctl2.register(GlassRegistration(id: ctl2.newId(), label: 'one more', kind: GlassLayerKind.controls, shapes: 1, rect: () => null));
      expect(logs.where((l) => l.contains('budget')).length, 1, reason: 'nine shapes');
      expect(c2.read(glassRegistryProvider).shapes, 9);

      final c3 = ProviderContainer();
      addTearDown(c3.dispose);
      final ctl3 = c3.read(glassRegistryProvider.notifier);
      logs.clear();
      for (var i = 0; i < 10; i++) {
        ctl3.register(GlassRegistration(id: ctl3.newId(), label: 'gallery', kind: GlassLayerKind.controls, shapes: 2, rect: () => null, exempt: true));
      }
      expect(logs, isEmpty);
      expect(c3.read(glassRegistryProvider).layers, 0);
    });

    testWidgets('a surface built under GlassBudgetScope(exempt) is not counted', (tester) async {
      await tester.pumpWidget(
        host(
          const GlassBudgetScope(
            exempt: true,
            label: 'gallery',
            child: SkinGlass(size: Size(100, 50), materialize: false, child: SizedBox()),
          ),
        ),
      );
      await tester.pump();
      final s = containerOf(tester).read(glassRegistryProvider);
      expect(s.entries.length, 1);
      expect(s.layers, 0);
    });

    test('three overlapping layers force the lowest solid until the stack clears', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ctl = container.read(glassRegistryProvider.notifier);
      const r = Rect.fromLTWH(0, 0, 100, 100);
      final low = GlassRegistration(id: ctl.newId(), label: 'low', kind: GlassLayerKind.controls, shapes: 1, rect: () => r);
      final mid = GlassRegistration(id: ctl.newId(), label: 'mid', kind: GlassLayerKind.overlays, shapes: 1, rect: () => r.shift(const Offset(20, 20)));
      final top = GlassRegistration(id: ctl.newId(), label: 'top', kind: GlassLayerKind.interruptions, shapes: 1, rect: () => r.shift(const Offset(40, 40)));
      ctl.register(low);
      ctl.register(mid);
      ctl.recompute();
      expect(container.read(glassRegistryProvider).forcedSolid, isEmpty, reason: 'two layers may stack');
      ctl.register(top);
      ctl.recompute();
      expect(container.read(glassRegistryProvider).forcedSolid, {low.id});
      ctl.unregister(top.id);
      ctl.recompute();
      expect(container.read(glassRegistryProvider).forcedSolid, isEmpty);
    });
  });

  group('focus ring', () {
    testWidgets('is a foregroundPainter on the wrapper, outside ClipRSuperellipse, and keyboard only', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
      await tester.pumpWidget(
        host(
          GlassFocusRing(
            shape: const GlassShape.capsule(),
            child: Focus(
              focusNode: node,
              child: const SkinGlass(size: Size(100, 50), materialize: false, child: SizedBox()),
            ),
          ),
        ),
      );
      final ring = find.byWidgetPredicate((w) => w is CustomPaint && w.foregroundPainter is GlassFocusPainter);
      expect(ring, findsOneWidget);
      expect(find.descendant(of: find.byType(ClipRSuperellipse), matching: ring), findsNothing);
      expect(find.ancestor(of: find.byType(ClipRSuperellipse), matching: ring), findsWidgets);
      expect((tester.widget<CustomPaint>(ring).foregroundPainter! as GlassFocusPainter).opacity, 0);
      node.requestFocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 130));
      expect((tester.widget<CustomPaint>(ring).foregroundPainter! as GlassFocusPainter).opacity, 1);
      // Touch and mouse never show it.
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 130));
      expect((tester.widget<CustomPaint>(ring).foregroundPainter! as GlassFocusPainter).opacity, 0);
    });
  });

  test('skin_glass.dart and its glass/ helpers are the only importers of liquid_glass_widgets under lib/skins/glass', () {
    final importers = <String>[];
    for (final f in Directory('lib/skins/glass').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      if (f.readAsStringSync().contains('package:liquid_glass_widgets')) importers.add(f.path.replaceAll('\\', '/'));
    }
    const allowed = {
      'lib/skins/glass/skin_glass.dart',
      'lib/skins/glass/glass/liquid.dart', // mobile/03's prepare(); deleted with the gate at release/00
      'lib/skins/glass/glass/gate_demo.dart', // mobile/03's gate page; deleted at release/00
    };
    for (final p in importers) {
      expect(allowed.contains(p) || p.startsWith('lib/skins/glass/glass/'), isTrue, reason: p);
    }
    expect(importers, contains('lib/skins/glass/skin_glass.dart'));
  });
}

const double kFixedAngle = 2.356;
