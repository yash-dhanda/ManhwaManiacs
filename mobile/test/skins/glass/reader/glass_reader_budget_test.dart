// ignore_for_file: require_trailing_commas
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/reader/engine/seam.dart';
import 'package:manhwamaniacs/skins/glass/glass/registry.dart';
import 'package:manhwamaniacs/skins/glass/primitives/scrub_rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/glass_manga_reader.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

import 'glass_reader_rig.dart';

const _ocr = [
  PageText(page: 1, text: 'The gate opens at dawn.', boxes: [OcrTextBox(text: 'The gate opens at dawn.', x: 0.3, y: 0.2, width: 0.5, height: 0.06)]),
];

void main() {
  testWidgets('15.7: the manga-reader case stays inside the budget and the frost-path BackdropGroup holds at most 8 members', (t) async {
    await pumpGlassReader(t, ocr: _ocr, query: '?q=gate', extra: [glassRendererOverrideProvider.overrideWith((ref) => GlassRenderer.frosted)]);
    await settleReader(t, ms: 1500);
    final s = t.state<GlassMangaReaderState>(find.byType(GlassMangaReader));
    // Chrome shown, the seam chip, the hit lens (from ?q=), the scrub lens held, the settings sheet at medium.
    s.engine.showChrome();
    s.engine.emitSeam(const SeamEvent.top('c3'));
    await settleReader(t, ms: 200);
    final rail = find.byType(GlassScrubRail);
    final g = await t.startGesture(t.getCenter(rail));
    await g.moveBy(const Offset(0, 30));
    await settleReader(t, ms: 400);
    final members = readerBackdropMembers(t.element(find.byType(GlassMangaReader)));
    expect(members.length, lessThanOrEqualTo(kReaderBackdropBudget), reason: members.join(', '));
    final reg = ProviderScope.containerOf(t.element(find.byType(GlassMangaReader))).read(glassRegistryProvider);
    expect(reg.layers, lessThanOrEqualTo(kGlassLayerBudget));
    expect(reg.shapes, lessThanOrEqualTo(kGlassShapeBudget));
    // ignore: avoid_print
    print('reader budget: layers ${reg.layers}, shapes ${reg.shapes}, backdrop members ${members.length} (${members.join(', ')})');
    await g.up();
    await t.sendKeyEvent(LogicalKeyboardKey.comma, character: ',');
    await settleReader(t, ms: 800);
    final reg2 = ProviderScope.containerOf(t.element(find.byType(GlassMangaReader))).read(glassRegistryProvider);
    // ignore: avoid_print
    print('with the settings sheet: layers ${reg2.layers}, shapes ${reg2.shapes}');
    expect(reg2.layers, lessThanOrEqualTo(kGlassLayerBudget));
    await disposeGlassReader(t);
  });

  testWidgets('no glass inside the strip: every SkinGlass sits outside the page list', (t) async {
    await pumpGlassReader(t);
    await settleReader(t, ms: 1000);
    final inStrip = find.descendant(of: find.byType(Scrollable).first, matching: find.byType(SkinGlass));
    expect(inStrip, findsNothing);
    await disposeGlassReader(t);
  });
}
