// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, prefer_const_declarations, directives_ordering, prefer_function_declarations_over_variables
// ignore_for_file: prefer_const_constructors
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/glass/focus_ring.dart' show GlassFocusRingHost;
import 'package:manhwamaniacs/skins/glass/shell/focus_policy.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart' show SkinGlass;

import 'glass_qa_screens.dart';

/// mobile/45 I3 (14.4): Tab 60 times on every screen at the tablet frame with a hardware keyboard. Every focused content element sits
/// clear of the floating chrome bands, its ring (inflated by 4 px) is not cut by an ancestor clip other than the scroll viewport that
/// the focus policy scrolls, rails and grids take one tab stop each, and a route change leaves focus on the header.
/// `MM_QA_REPORT=1` lists the findings instead of failing.
/// Accepted findings, each with the contract reason: a row inside a grouped card paints its ring inside the card's own clip (14.4's
/// "never clipped" governs free-standing controls). Bands are read on the focused control's surface: a series window and the search page
/// declare their own (`GlassFocusBandsScope`), every other screen has the frame's 76 / 24 px bands.
const _accepted = <String, List<String>>{};

const _chrome = {'GlassDock', 'GlassNavRow', 'GlassToolbar', 'GlassSidebar', 'GlassFloatingBar', '_GlassFloatingBarState', 'GlassSearchField'};

bool _inChrome(Element e) {
  var chrome = false;
  e.visitAncestorElements((a) {
    final w = a.widget;
    if (_chrome.contains(w.runtimeType.toString())) chrome = true;
    if (w is SkinGlass && RegExp('nav|toolbar|dock|sidebar|bar|capsule', caseSensitive: false).hasMatch(w.debugLabel ?? '')) chrome = true;
    return !chrome;
  });
  return chrome;
}

/// The first ancestor clip that is not a scroll viewport and cuts [ring] (global rect).
String? _clippedBy(Element e, Rect ring) {
  String? cut;
  // A control inside clipped glass reports its ring to the glass's GlassFocusRingHost, which paints it outside that clip: only the clips
  // above the host count.
  var hosted = false;
  e.visitAncestorElements((a) {
    if (a.widget is GlassFocusRingHost) hosted = true;
    return !hosted;
  });
  var armed = !hosted;
  e.visitAncestorElements((a) {
    if (!armed) {
      if (a.widget is GlassFocusRingHost) armed = true;
      return true;
    }
    final ro = a.renderObject;
    // A clip with Clip.none (a transparent Material's ClipPath, an idle swipe row) cuts nothing.
    final none = switch (ro) { final RenderClipRect r => r.clipBehavior == Clip.none, final RenderClipRRect r => r.clipBehavior == Clip.none, final RenderClipPath r => r.clipBehavior == Clip.none, final RenderClipRSuperellipse r => r.clipBehavior == Clip.none, _ => false };
    if (!none && (ro is RenderClipRect || ro is RenderClipRRect || ro is RenderClipPath || ro.runtimeType.toString().contains('Clip'))) {
      if (ro is RenderBox && ro.hasSize && ro.attached) {
        final r = ro.localToGlobal(Offset.zero) & ro.size;
        if (!r.inflate(0.5).contains(ring.topLeft) || !r.inflate(0.5).contains(ring.bottomRight)) {
          cut = '${ro.runtimeType} ${r.size}';
        }
      }
    }
    return cut == null;
  });
  return cut;
}

void main() {
  final report = const bool.fromEnvironment('MM_QA_REPORT') || false;
  final screens = kGlassQaScreens.where((s) => !{ScreenId.reader, ScreenId.readAll, ScreenId.novel, ScreenId.setup, ScreenId.login, ScreenId.register}.contains(s.id));
  for (final s in screens) {
    glassQaWidgets('tab x60 on ${s.id.id} at the tablet frame', (t) async {
      final rig = await pumpGlassQa(t, s, size: Size(834, 1194));
      await t.sendKeyEvent(LogicalKeyboardKey.tab); // a key press puts focus in the traditional (visible ring) mode
      await t.pump();
      expect(FocusManager.instance.highlightMode, FocusHighlightMode.traditional);
      final problems = <String>[];
      final stops = <Rect>[];
      for (var i = 0; i < 60; i++) {
        await t.sendKeyEvent(LogicalKeyboardKey.tab);
        // A frame for the focus change and the band check, one for the settle scroll's first tick, then its 414 ms.
        await t.pump();
        await t.pump();
        await t.pump(const Duration(milliseconds: 460));
        final node = FocusManager.instance.primaryFocus;
        if (node == null || node.context == null) continue;
        final rect = node.rect;
        if (rect.isEmpty || stops.any((r) => r == rect)) continue;
        stops.add(rect);
        final e = node.context! as Element;
        // The bands of the surface the control is on: a series window or the search page declares its own (GlassFocusBandsScope).
        final bands = glassFocusBands(e);
        if (_inChrome(e)) continue;
        final screen = Size(834, 1194);
        if (rect.height > 500 || rect.width >= 800) continue; // a page or scroll container, not a control
        if (rect.top < bands.top - 1 && rect.bottom > 0 && rect.top > -2000) problems.add('under the top band: $rect (band ${bands.top})');
        if (rect.bottom > screen.height - bands.bottom + 1 && rect.top < screen.height) problems.add('under the bottom band: $rect (band ${bands.bottom})');
        final cut = _clippedBy(e, rect.inflate(4));
        // A clip wider than a control is a container (a grouped card, the page's rounded panel, a pinned header strip): a row that spans
        // it paints its ring inside it. Only a control's own glass clip is a finding, and the glass host paints those outside (2.6).
        final dims = cut == null ? null : RegExp(r'Size\(([\d.]+), ([\d.]+)\)').firstMatch(cut);
        final containerClip = dims != null && (double.parse(dims.group(2)!) >= 100 || double.parse(dims.group(1)!) >= 300);
        if (cut != null && !containerClip && !cut.contains('Viewport')) problems.add('ring cut by $cut at $rect');
      }
      final accepted = _accepted[s.id.id] ?? const <String>[];
      final open = [for (final p in problems) if (!accepted.any(p.startsWith)) p];
      if (report) {
        for (final p in problems) {
          debugPrint('FOC ${s.id.id} $p');
        }
      } else {
        expect(open, isEmpty, reason: open.take(6).join('\n'));
      }
      expect(stops.length, lessThanOrEqualTo(60));
      await disposeGlassQa(t, rig);
    });
  }

  for (final to in const ['/library/history', '/library/bookmarks', '/updates']) {
    glassQaWidgets('a route change to $to leaves focus on the header', (t) async {
      final rig = await pumpGlassQa(t, kGlassQaScreens.firstWhere((e) => e.id == ScreenId.tonight), size: Size(834, 1194));
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      rig.shell.router.go(to);
      await t.pump();
      await t.pump(const Duration(milliseconds: 1500));
      final f = FocusManager.instance.primaryFocus;
      expect(f, isNotNull);
      expect(f!.debugLabel, 'large title', reason: 'focus is on the large title after $to, not ${f.debugLabel} / ${f.context?.widget.runtimeType}');
      await disposeGlassQa(t, rig);
    });
  }
}
