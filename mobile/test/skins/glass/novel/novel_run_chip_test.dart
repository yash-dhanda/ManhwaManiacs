import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/chrome_top.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/glass_paragraph.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/tinted_run_chip.dart';

import 'novel_rig.dart';

void main() {
  testWidgets('D10: tapping a tinted run shows the chip for 2 s and does not toggle the chrome', (t) async {
    await pumpGlassNovel(t, attribution: fixtureAttribution());
    await settle(t);
    // The first paragraph's rest piece carries Alice's run.
    final piece = find.byWidgetPredicate((w) => w is GlassTextPiece && w.runs.isNotEmpty && w.runs.first.start >= w.start && w.runs.first.start < w.endOffset).first;
    final para = t.widget<GlassTextPiece>(piece);
    final run = para.runs.first;
    final ro = t.renderObjectList<RenderParagraph>(find.descendant(of: piece, matching: find.byType(RichText))).first;
    final box = ro.getBoxesForSelection(TextSelection(baseOffset: run.start - para.start + 2, extentOffset: run.start - para.start + 5)).first;
    final at = ro.localToGlobal(box.toRect().center);
    await t.ensureVisible(piece);
    await settle(t, ms: 300);
    await t.tapAt(ro.localToGlobal(box.toRect().center));
    await settle(t, ms: 400);
    expect(find.byType(GlassRunChip), findsOneWidget);
    expect(find.text(runChipText(run.name, null)), findsOneWidget);
    expect(find.byType(NovelChromeTop), findsNothing);
    await settle(t, ms: 2600);
    expect(find.byType(GlassRunChip), findsNothing);
    expect(at, isNotNull);
    await disposeGlassNovel(t);
  });
}
