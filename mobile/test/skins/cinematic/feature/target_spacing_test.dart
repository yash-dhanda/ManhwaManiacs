// ignore_for_file: require_trailing_commas, directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/manga_view.dart';

import 'feature_test_support.dart';

/// Screen rects of every tappable, visible semantics node.
List<(String, Rect)> _targets(WidgetTester tester) {
  final out = <(String, Rect)>[];
  void walk(SemanticsNode n, Matrix4 m) {
    if (n.isInvisible || n.flagsCollection.isHidden) return;
    final Matrix4 t = n.transform == null ? m : (m * n.transform) as Matrix4;
    // Controls only: full-width list rows and the two-tab strip (one segmented
    // control, a single 48 px band) sit flush by design.
    if (n.getSemanticsData().hasAction(SemanticsAction.tap) && n.rect.width < 200 && !RegExp(r'Tab \d of \d').hasMatch(n.label)) {
      out.add((n.label, MatrixUtils.transformRect(t, n.rect)));
    }
    n.visitChildren((c) {
      walk(c, t);
      return true;
    });
  }

  walk(tester.binding.rootPipelineOwner.semanticsOwner!.rootSemanticsNode!, Matrix4.identity());
  return out;
}

/// Pairs of targets that sit side by side (they overlap on one axis) with a
/// gap under 8 px. Nested or overlapping targets are one control, not two.
List<String> _tooClose(List<(String, Rect)> ts, Size screen) {
  final bad = <String>[];
  final view = Offset.zero & screen;
  for (var i = 0; i < ts.length; i++) {
    for (var j = i + 1; j < ts.length; j++) {
      final a = ts[i].$2, b = ts[j].$2;
      if (!view.overlaps(a) || !view.overlaps(b) || a.overlaps(b)) continue;
      final xOverlap = a.left < b.right && b.left < a.right;
      final yOverlap = a.top < b.bottom && b.top < a.bottom;
      final gap = xOverlap ? (a.top >= b.bottom ? a.top - b.bottom : b.top - a.bottom) : yOverlap ? (a.left >= b.right ? a.left - b.right : b.left - a.right) : double.infinity;
      if (gap < 8) bad.add('${ts[i].$1} / ${ts[j].$1}: $gap');
    }
  }
  return bad;
}

void main() {
  testWidgets('adjacent hero targets are at least 8 px apart', (tester) async {
    final h = tester.ensureSemantics();
    await pumpFeature(tester,
        rig: FeatureRig(followed: followedRow()),
        child: MangaFeatureView(data: fixtureData('manga-ongoing', followed: followedRow())));
    await settleFeature(tester, by: const Duration(seconds: 2));
    final ts = _targets(tester);
        expect(_tooClose(ts, const Size(390, 844)), isEmpty);
    h.dispose();
  });

  testWidgets('select-mode bar buttons are at least 8 px apart', (tester) async {
    final h = tester.ensureSemantics();
    await pumpFeature(tester,
        size: const Size(390, 1800), child: MangaFeatureView(data: fixtureData('manga-ongoing')));
    await scrollToPanels(tester);
    await tester.tap(find.text('Select'));
    await frames(tester, 300);
    final ts = _targets(tester);
    expect(ts.length, greaterThan(3));
    expect(_tooClose(ts, const Size(390, 1800)), isEmpty);
    h.dispose();
  });
}
