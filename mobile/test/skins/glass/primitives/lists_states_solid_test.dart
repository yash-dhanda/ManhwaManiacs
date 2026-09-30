// ignore_for_file: unawaited_futures
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' show AdaptiveGlass;
import 'package:manhwamaniacs/skins/glass/glass/caustic.dart';
import 'package:manhwamaniacs/skins/glass/glass/registry.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart' show gt;
import 'package:manhwamaniacs/skins/glass/primitives/gate/mature_gate_alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/reaction_picker.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/bulk_toolbar.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/select_mode.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

import 'overlay_support.dart';
import 'support.dart';

bool _hasFill(WidgetTester t, Color c) => find.byWidgetPredicate((w) => w is ColoredBox && w.color == c).evaluate().isNotEmpty;

void main() {
  testWidgets('a solid lens and a solid floating bar are opaque slabs: glassSolid1, no live glass, no caustic', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = GlassSelectModeController<int>()..enter(1);
    addTearDown(c.dispose);
    await tester.pumpWidget(primHost(
      Stack(children: [
        const Positioned.fill(child: GlassObjectLens(situation: LensSituation.library, title: 'Empty')),
        GlassBulkToolbar<int>(controller: c, actions: const []),
      ],),
      solid: true,
      align: false,
    ),);
    await pumpFor(tester, 900);
    expect(find.byType(AdaptiveGlass), findsNothing);
    expect(find.byType(GlassCaustic), findsNothing);
    expect(_hasFill(tester, gt.glassSolid1), isTrue);
    expect(primContainer(tester).read(glassRegistryProvider).layers, 0);
  });

  testWidgets('a solid gate alert takes glassSolid2', (tester) async {
    final h = OverlayHost(tester);
    await h.pump(solid: true);
    showMatureGateAlert(h.nav.currentContext!);
    await pumpFor(tester, 800);
    expect(find.text('Show mature content?'), findsOneWidget);
    expect(_hasFill(tester, gt.glassSolid2), isTrue);
    expect(find.byType(AdaptiveGlass), findsNothing);
    expect(find.byType(GlassCaustic), findsNothing);
  });

  testWidgets('solid reaction bubbles are glassSolid1 discs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(primHost(Center(child: GlassReactionButton(onSend: (_) {}, onClear: () {})), solid: true, align: false));
    final g = await tester.startGesture(tester.getCenter(find.byType(GlassReactionButton)));
    await pumpFor(tester, 800);
    expect(find.byKey(const ValueKey('glass-reaction-bubbles')), findsOneWidget);
    expect(find.byType(AdaptiveGlass), findsNothing);
    expect(_hasFill(tester, gt.glassSolid1), isTrue);
    await g.up();
    await pumpFor(tester, 800);
  });
}
