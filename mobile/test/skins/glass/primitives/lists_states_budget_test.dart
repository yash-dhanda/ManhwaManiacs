// ignore_for_file: unawaited_futures
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' show AdaptiveGlass;
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/glass/registry.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/glass_chart.dart';
import 'package:manhwamaniacs/skins/glass/primitives/download_control.dart';
import 'package:manhwamaniacs/skins/glass/primitives/download_state.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/chapter_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/list_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reactions/reaction_picker.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/bulk_toolbar.dart';
import 'package:manhwamaniacs/skins/glass/primitives/select/select_mode.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';
import 'support.dart';

bool _noBackdrop(WidgetTester t) => find.byType(BackdropFilter).evaluate().isEmpty && find.byType(AdaptiveGlass).evaluate().isEmpty;

void main() {
  testWidgets('no row, pill, chart readout, lens ring, download control or inline lens creates a BackdropFilter or an AdaptiveGlass', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final data = [for (var i = 0; i < 10; i++) ChartDatum(day: DateTime(2026, 9, 1 + i), value: (i + 1).toDouble())];
    await tester.pumpWidget(primHost(
      SingleChildScrollView(
        child: SizedBox(
          width: 390,
          child: Column(children: [
            GlassSwipeRow(
              name: 'Row',
              trailing: [SwipeAction(id: 'remove', label: 'Remove', glyph: const IconData(0xE1FE, fontFamily: 'PhosphorRegular'), destructive: true, run: () async {})],
              child: const GlassListRow(title: 'Row', subtitle: 'sub'),
            ),
            const GlassChapterRow(number: 3, title: 'Ch', pageCount: 30, trailing: GlassDownloadControl(view: ChapterDownloadView(ChapterDownloadKind.saved), chapterLabel: 'chapter 3')),
            SizedBox(height: 300, child: GlassChart(kind: GlassChartKind.bars, data: data, chartId: 'b', summary: 's', readout: (d) => 'r${d.value}')),
            const GlassObjectLens(situation: LensSituation.library, title: 'Empty', placement: GlassLensPlacement.inline),
          ],),
        ),
      ),
      overrides: [sharedPrefsProvider.overrideWithValue(prefs), authenticatedAuthOverride(), activeProfileOverride()],
    ),);
    await pumpFor(tester, 900);
    await tester.drag(find.text('Row').first, const Offset(-120, 0));
    await pumpFor(tester, 600);
    await tester.tapAt(const Offset(60, 440));
    await pumpFor(tester, 300);
    expect(_noBackdrop(tester), isTrue);
    expect(primContainer(tester).read(glassRegistryProvider).layers, 0, reason: 'twins are not live layers');
  });

  testWidgets('the full lens, the floating bar and the six reaction bubbles each register as one layer', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = GlassSelectModeController<int>()..enter(1);
    addTearDown(c.dispose);
    await tester.pumpWidget(primHost(
      Stack(children: [
        const Positioned.fill(child: GlassObjectLens(situation: LensSituation.offline, tone: GlassLensTone.offline, title: 'Offline')),
        GlassBulkToolbar<int>(controller: c, actions: const []),
        Center(child: GlassReactionButton(onSend: (_) {}, onClear: () {})),
      ],),
      align: false,
    ),);
    await pumpFor(tester, 900);
    var s = primContainer(tester).read(glassRegistryProvider);
    Iterable<GlassRegistration> only(String label) => s.entries.where((e) => e.label == label);
    expect(only('GlassObjectLens').length, 1);
    expect(only('GlassObjectLens').single.shapes, 1);
    expect(only('GlassBulkToolbar').length, 1);
    expect(only('GlassBulkToolbar').single.kind, GlassLayerKind.controls);
    final g = await tester.startGesture(tester.getCenter(find.byType(GlassReactionButton)));
    await pumpFor(tester, 600);
    s = primContainer(tester).read(glassRegistryProvider);
    expect(only('ReactionBubbles').length, 1, reason: 'one layer');
    expect(only('ReactionBubbles').single.shapes, 6, reason: 'six shapes');
    expect(s.layers, lessThanOrEqualTo(kGlassLayerBudget));
    expect(s.shapes, lessThanOrEqualTo(kGlassShapeBudget));
    await g.up();
    await pumpFor(tester, 800);
    expect(ReactionKind.values, isNotEmpty);
  });
}
