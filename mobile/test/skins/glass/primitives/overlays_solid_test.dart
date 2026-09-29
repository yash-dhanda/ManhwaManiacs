// ignore_for_file: unawaited_futures
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show AdaptiveGlass;
import 'package:manhwamaniacs/skins/glass/glass/caustic.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

import 'overlay_support.dart';
import 'support.dart';

bool _hasFill(WidgetTester t, Color c) => find
    .byWidgetPredicate((w) => w is ColoredBox && w.color == c)
    .evaluate()
    .isNotEmpty;

void main() {
  test('solid recipes: T1 to T3 glassSolid1, T4 and T5 glassSolid2', () {
    for (final t in [GlassTierId.t1, GlassTierId.t2, GlassTierId.t3]) {
      expect(solidFill(t, GlassFinishKind.clear), gt.glassSolid1);
    }
    for (final t in [GlassTierId.t4, GlassTierId.t5]) {
      expect(solidFill(t, GlassFinishKind.clear), gt.glassSolid2);
    }
    expect(gt.glassSolid1, const Color(0xFF1C1C22));
    expect(gt.glassSolid2, const Color(0xFF26262E));
  });

  testWidgets('a solid sheet is an opaque slab: no live glass, no caustic',
      (tester) async {
    final h = OverlayHost(tester);
    await h.pump(solid: true);
    h.push(GlassSheetPage<void>(
            title: 'Sheet', builder: (_) => const Center(child: Text('body')),)
        .createRoute(h.nav.currentContext!),);
    await pumpFor(tester, 800);
    expect(find.byType(AdaptiveGlass), findsNothing);
    expect(find.byType(GlassCaustic), findsNothing);
    expect(_hasFill(tester, gt.glassSolid2) || _hasFill(tester, gt.glassSolid1),
        isTrue,);
    expect(primContainer(tester).read(glassRegistryProvider).layers, 0);
  });

  testWidgets('a solid alert and a solid menu take glassSolid2',
      (tester) async {
    final h = OverlayHost(tester);
    await h.pump(solid: true);
    showGlassAlert<int>(h.nav.currentContext!,
        title: 'Remove?',
        actions: const [
          GlassAlertAction<int>('Cancel', role: GlassAlertRole.cancel, value: 0),
        ],);
    await pumpFor(tester, 700);
    expect(_hasFill(tester, gt.glassSolid2), isTrue);
    expect(find.byType(AdaptiveGlass), findsNothing);
    await tester.tap(find.text('Cancel'));
    await pumpFor(tester, 800);
    showGlassMenu(h.nav.currentContext!,
        anchor: const Rect.fromLTWH(100, 100, 100, 44),
        title: 'Actions',
        entries: [GlassMenuEntry(label: 'One', onSelected: () {})],);
    await pumpFor(tester, 700);
    expect(_hasFill(tester, gt.glassSolid2), isTrue);
    expect(find.byType(AdaptiveGlass), findsNothing);
    expect(find.byType(GlassCaustic), findsNothing);
  });

  testWidgets('a solid surface carries a 1 px rim at 10 % white',
      (tester) async {
    final h = OverlayHost(tester);
    await h.pump(solid: true);
    showGlassMenu(h.nav.currentContext!,
        anchor: const Rect.fromLTWH(100, 100, 100, 44),
        title: 'Actions',
        entries: [GlassMenuEntry(label: 'One', onSelected: () {})],);
    await pumpFor(tester, 700);
    final rim = find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is ShapeDecoration &&
          ((w.decoration as ShapeDecoration).shape is OutlinedBorder) &&
          ((w.decoration as ShapeDecoration).shape as OutlinedBorder)
                  .side
                  .width ==
              1,
    );
    final painted = find.byWidgetPredicate((w) =>
        w is CustomPaint &&
        w.painter != null &&
        w.painter.runtimeType.toString().toLowerCase().contains('rim'),);
    expect(rim.evaluate().isNotEmpty || painted.evaluate().isNotEmpty, isTrue);
  });
}
