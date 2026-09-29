// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/shelf_query.dart';

import 'library_test_support.dart';

const _storedKey = 'mm.shelf-query.u1p1';

Map<String, Object> _stored(ShelfQuery q) => {_storedKey: q.toStoredJson()};

/// Screen rects of every visible tappable control (full-width rows and slug lines sit flush by
/// design, so only controls under 200 px wide count).
List<(String, Rect)> _targets(WidgetTester tester, {double maxY = 780, double minY = 100}) {
  final out = <(String, Rect)>[];
  void walk(SemanticsNode n, Matrix4 m) {
    if (n.isInvisible || n.flagsCollection.isHidden) return;
    final Matrix4 t = n.transform == null ? m : (m * n.transform) as Matrix4;
    // The tab row and the slug line are flush bands by design (cinematic 7.5, 7.12).
    final band = RegExp(r'^(All|Reading|Not started|Done|On hold|Plan to read|Dropped)(, \d+)?$|^0\d, ').hasMatch(n.label);
    if (n.getSemanticsData().hasAction(SemanticsAction.tap) && n.rect.width < 200 && !band) {
      final r = MatrixUtils.transformRect(t, n.rect);
      if (r.top >= minY && r.bottom <= maxY) out.add((n.label, r));
    }
    n.visitChildren((c) {
      walk(c, t);
      return true;
    });
  }

  // ignore: deprecated_member_use
  walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!, Matrix4.identity());
  return out;
}

List<String> _tooClose(List<(String, Rect)> ts) {
  final bad = <String>[];
  for (var i = 0; i < ts.length; i++) {
    for (var j = i + 1; j < ts.length; j++) {
      final a = ts[i].$2, b = ts[j].$2;
      if (a.overlaps(b)) continue;
      final xOverlap = a.left < b.right && b.left < a.right;
      final yOverlap = a.top < b.bottom && b.top < a.bottom;
      final gap = xOverlap ? (a.top >= b.bottom ? a.top - b.bottom : b.top - a.bottom) : yOverlap ? (a.left >= b.right ? a.left - b.right : b.left - a.right) : double.infinity;
      if (gap < 8) bad.add('${ts[i].$1} / ${ts[j].$1}: $gap');
    }
  }
  return bad;
}

Future<void> _guidelines(WidgetTester t, TargetPlatform platform) async {
  await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(t, meetsGuideline(platform == TargetPlatform.iOS ? iOSTapTargetGuideline : androidTapTargetGuideline));
}

void main() {
  for (final d in ShelfDensity.values) {
    testWidgets('adjacent targets on the shelf are at least 8 px apart in ${d.name}', (t) async {
      final h = t.ensureSemantics();
      await pumpShelf(t, prefs: _stored(ShelfQuery(density: d)));
      final ts = _targets(t);
      expect(ts.length, greaterThanOrEqualTo(3), reason: d.name);
      expect(_tooClose(ts), isEmpty, reason: d.name);
      h.dispose();
    });
  }

  testWidgets('select-mode bar buttons are at least 8 px apart', (t) async {
    final h = t.ensureSemantics();
    await pumpShelf(t);
    await t.tap(find.text('Select'));
    await settleShelf(t, by: const Duration(milliseconds: 400));
    final ts = _targets(t, minY: 600, maxY: 800);
    expect(ts.length, greaterThan(2));
    expect(_tooClose(ts), isEmpty);
    h.dispose();
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    group('tap targets on ${platform.name}', () {
      testWidgets('the WALL', (t) async {
        final h = t.ensureSemantics();
        await pumpShelf(t, platform: platform);
        await _guidelines(t, platform);
        h.dispose();
      });

      testWidgets('the LIST', (t) async {
        final h = t.ensureSemantics();
        await pumpShelf(t, platform: platform, prefs: _stored(const ShelfQuery(density: ShelfDensity.list)));
        await _guidelines(t, platform);
        h.dispose();
      });

      testWidgets('select mode', (t) async {
        final h = t.ensureSemantics();
        await pumpShelf(t, platform: platform);
        await t.tap(find.text('Select'));
        await settleShelf(t, by: const Duration(milliseconds: 400));
        await _guidelines(t, platform);
        h.dispose();
      });

      testWidgets('the Filters sheet', (t) async {
        final h = t.ensureSemantics();
        await pumpShelf(t, platform: platform);
        await t.tap(find.text('Filters'));
        await settleShelf(t, by: const Duration(milliseconds: 700));
        await _guidelines(t, platform);
        h.dispose();
      });
    });
  }
}
