// ignore_for_file: require_trailing_commas
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/thumb_index.dart';

import 'qa_screens.dart';

/// 4.0.1 (cinematic 14.4, the Glass tablet band check's twin): Tab 60 times on every screen at the 834 x 1194 tablet frame. No
/// focused control is left above the page or under the running head (a Tab that wraps to a scrolled-away control is cut back into
/// view), none sits under the thumb index, and no ancestor clip other than a scroll viewport cuts its ring (inflated by 4 px).
bool _under<T>(Element e) {
  var hit = false;
  e.visitAncestorElements((a) {
    hit = a.widget is T;
    return !hit;
  });
  return hit;
}

String? _clippedBy(Element e, Rect ring) {
  String? cut;
  e.visitAncestorElements((a) {
    final ro = a.renderObject;
    final none = switch (ro) {
      final RenderClipRect r => r.clipBehavior == Clip.none,
      final RenderClipRRect r => r.clipBehavior == Clip.none,
      final RenderClipPath r => r.clipBehavior == Clip.none,
      final RenderClipRSuperellipse r => r.clipBehavior == Clip.none,
      _ => false,
    };
    if (!none && ro is RenderBox && ro.runtimeType.toString().contains('Clip') && ro.hasSize && ro.attached) {
      final r = ro.localToGlobal(Offset.zero) & ro.size;
      if (!r.inflate(0.5).contains(ring.topLeft) || !r.inflate(0.5).contains(ring.bottomRight)) cut = '${ro.runtimeType} ${r.size}';
    }
    return cut == null;
  });
  return cut;
}

void main() {
  test('the reveal shift: the distance plus 8 px, negative upwards, 0 when the control fits', () {
    expect(cineRevealShift(focused: const Rect.fromLTRB(0, -5, 10, 43), top: 44, bottom: 1100), -5 - 44 - 8);
    expect(cineRevealShift(focused: const Rect.fromLTRB(0, 1080, 10, 1120), top: 44, bottom: 1100), 1120 - 1100 + 8);
    expect(cineRevealShift(focused: const Rect.fromLTRB(0, 100, 10, 140), top: 44, bottom: 1100), 0);
  });

  for (final s in kQaScreens) {
    testWidgets('tablet bands: ${s.id.id}', (t) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        const size = Size(834, 1194);
        final rig = await pumpQaScreen(t, s, size: size);
        final index = find.byType(CineThumbIndex);
        final indexTop = index.evaluate().isEmpty ? size.height : t.getTopLeft(index.first).dy;
        final problems = <String>[];
        final seen = <Rect>{};
        for (var i = 0; i < 60; i++) {
          await t.sendKeyEvent(LogicalKeyboardKey.tab);
          await t.pump();
          await t.pump(const Duration(milliseconds: 100));
          final f = FocusManager.instance.primaryFocus;
          final ctx = f?.context;
          if (f == null || ctx == null) continue;
          final r = f.rect;
          if (r.isEmpty || !seen.add(r) || r.height > 500 || r.width >= 800) continue; // a page or a scroll container
          final e = ctx as Element;
          if (_under<CineThumbIndex>(e) || Scrollable.maybeOf(ctx, axis: Axis.vertical) == null) continue; // chrome, fixed layouts
          final head = CineScaffoldScope.topExtentOf(ctx);
          if (r.top < head - 1 && r.bottom > 0) problems.add('under the running head ($head): $r');
          if (r.bottom > indexTop + 1 && r.top < size.height) problems.add('under the thumb index ($indexTop): $r');
          final cut = _clippedBy(e, r.inflate(4));
          if (cut != null && !cut.contains('Viewport')) problems.add('ring cut by $cut at $r');
        }
        await disposeQa(t, rig);
        expect(problems, isEmpty, reason: problems.take(6).join('\n'));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
