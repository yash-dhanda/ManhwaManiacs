// ignore_for_file: directives_ordering, require_trailing_commas, prefer_const_constructors, avoid_redundant_argument_values, unnecessary_lambdas
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart' show GlassHost;
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// One failed rule on one screen: what was measured, on which element.
class GlassViolation {
  const GlassViolation(this.rule, this.finder, this.measured);
  final String rule;
  final String finder;
  final String measured;
  Map<String, String> toJson() => {'rule': rule, 'finder': finder, 'measured': measured};
  @override
  String toString() => '[$rule] $finder: $measured';
}

/// The rule ids of `mobile/45` B2 (`glass/DESIGN.md` 15.8). `kGlassQaAccepted` matches on them.
abstract final class GlassRule {
  static const g1Errors = 'G1-errors';
  static const g2Headings = 'G2-headings';
  static const g3Names = 'G3-names';
  static const g4Target = 'G4-target';
  static const g4Spacing = 'G4-spacing';
  static const g5AlphaText = 'G5-alpha-text';
  static const g6Grey = 'G6-grey';
  static const g7Field = 'G7-field';
  static const g9TextSize = 'G9-text-size';
  static const g10Images = 'G10-images';
}

/// Screens whose field is brighter than 20 % (2.1.8): Home, the hero enlargement, the image viewer, series detail,
/// book page, the recap deck, the profile picker, Statistics and Wrapped. Settings, You and admin only under a bright mood.
const kGlassBrightFieldScreens = {
  ScreenId.tonight, ScreenId.feature, ScreenId.featureByFollow, ScreenId.recap, ScreenId.profiles, ScreenId.numbers, ScreenId.annual,
};

const double kGlassFloorPx = 11;

/// Audits what is on screen now (call after the screen settled). [platform] picks the tap-target guideline (44 iOS, 48 Android; 14.6).
/// G8 (cover overlay backings) is checked by the poster, tile and droplet widget tests, not here: no generic cover marker exists.
Future<List<GlassViolation>> auditGlass(WidgetTester tester, {required TargetPlatform platform, ScreenId? screen}) async {
  final out = <GlassViolation>[];
  final handle = tester.ensureSemantics();
  try {
    await tester.pump();
    final ex = tester.takeException();
    if (ex != null) out.add(GlassViolation(GlassRule.g1Errors, 'pump', ex.toString().split('\n').first));

    Future<void> guide(String rule, AccessibilityGuideline g) async {
      final e = await g.evaluate(tester);
      if (e.passed) return;
      for (final line in (e.reason ?? g.description).split('\n').where((l) => l.trim().isNotEmpty)) {
        final i = line.indexOf(': ');
        out.add(GlassViolation(rule, (i > 0 ? line.substring(0, i) : line).trim(), (i > 0 ? line.substring(i + 2) : '').trim()));
      }
    }

    await guide(GlassRule.g4Target, platform == TargetPlatform.iOS ? iOSTapTargetGuideline : androidTapTargetGuideline);
    await guide(GlassRule.g3Names, labeledTapTargetGuideline);
    out.addAll(_spacing(tester));
    out.addAll(_headings(tester));
    out.addAll(_paragraphs(tester, screen));
    out.addAll(_images(tester));
  } finally {
    handle.dispose();
  }
  return out;
}

// ---- semantics helpers ----

Rect _globalRect(SemanticsNode n) {
  var rect = n.rect;
  SemanticsNode? cur = n;
  while (cur != null) {
    final t = cur.transform;
    if (t != null) rect = MatrixUtils.transformRect(t, rect);
    cur = cur.parent;
  }
  return rect;
}

void _walk(SemanticsNode n, void Function(SemanticsNode) f) {
  f(n);
  n.visitChildren((c) {
    _walk(c, f);
    return true;
  });
}

bool _isAncestor(SemanticsNode a, SemanticsNode b) {
  SemanticsNode? p = b.parent;
  while (p != null) {
    if (p == a) return true;
    p = p.parent;
  }
  return false;
}

String _describe(SemanticsNode n) {
  final d = n.getSemanticsData();
  final l = d.label.isNotEmpty ? d.label : (d.tooltip.isNotEmpty ? d.tooltip : d.value);
  return 'node#${n.id}${l.isEmpty ? '' : ' "${l.replaceAll('\n', ' ')}"'}';
}

/// At least 8 px between the rects of adjacent tappable nodes that are not ancestors of each other. Abutting cells (gap 0: one
/// strip, one list, or sibling shapes of one glass group) and 1 px divider gaps are not flagged; a dead zone of 2 to 8 px is.
List<GlassViolation> _spacing(WidgetTester tester) {
  final root = tester.binding.renderViews.first.owner?.semanticsOwner?.rootSemanticsNode;
  if (root == null) return const [];
  final taps = <(SemanticsNode, Rect)>[];
  _walk(root, (n) {
    final d = n.getSemanticsData();
    if (n.isInvisible || d.flagsCollection.isHidden) return;
    if (!d.hasAction(SemanticsAction.tap) || d.flagsCollection.isLink) return;
    final r = _globalRect(n);
    if (r.isEmpty) return;
    taps.add((n, r));
  });
  // Sibling shapes of one glass group (the dock, a toolbar, a segmented track, a `GlassGroup`) abut by design (14.6).
  const groups = {'GlassGroup', 'GlassDock', 'GlassToolbar', 'GlassSegmentedBar', 'GlassFloatingBar', 'GlassLbBar', 'GlassCapsuleHost', 'GlassShelfBulkBar'};
  final groupRects = <Rect>[
    for (final e in find.byWidgetPredicate((w) => groups.contains(w.runtimeType.toString())).evaluate())
      if (e.renderObject case final RenderBox b when b.hasSize && b.attached) b.localToGlobal(Offset.zero) & b.size,
  ];
  bool grouped(Rect a, Rect b) => groupRects.any((g) => g.inflate(1).contains(a.topLeft) && g.inflate(1).contains(a.bottomRight) && g.inflate(1).contains(b.topLeft) && g.inflate(1).contains(b.bottomRight));
  final out = <GlassViolation>[];
  for (var i = 0; i < taps.length; i++) {
    for (var j = i + 1; j < taps.length; j++) {
      final (a, ra) = taps[i];
      final (b, rb) = taps[j];
      if (_isAncestor(a, b) || _isAncestor(b, a) || ra.overlaps(rb) || grouped(ra, rb)) continue;
      final dx = ra.left > rb.right ? ra.left - rb.right : (rb.left > ra.right ? rb.left - ra.right : 0.0);
      final dy = ra.top > rb.bottom ? ra.top - rb.bottom : (rb.top > ra.bottom ? rb.top - ra.bottom : 0.0);
      final gap = dx > 0 && dy > 0 ? math.sqrt(dx * dx + dy * dy) : (dx > 0 ? dx : dy); // diagonal neighbours: the corner distance
      if (gap >= 2 && gap < 8) {
        out.add(GlassViolation(GlassRule.g4Spacing, '${_describe(a)} / ${_describe(b)}', 'gap ${gap.toStringAsFixed(1)} px < 8'));
      }
    }
  }
  return out;
}

/// G2: exactly one level-1 (or unlevelled) `Semantics(header: true)` node that is neither hidden nor under an excluded or offstage subtree.
List<GlassViolation> _headings(WidgetTester tester) {
  final root = tester.binding.renderViews.first.owner?.semanticsOwner?.rootSemanticsNode;
  if (root == null) return const [];
  final h = <String>[];
  _walk(root, (n) {
    final d = n.getSemanticsData();
    if (n.isInvisible || d.flagsCollection.isHidden) return;
    if (d.flagsCollection.isHeader && d.headingLevel <= 1) h.add(_describe(n)); // level 2 and below are section heads
  });
  if (h.length == 1) return const [];
  return [GlassViolation(GlassRule.g2Headings, 'semantics tree', '${h.length} headers: ${h.join(', ')}')];
}

// ---- paragraphs: G5, G6, G7, G9 ----

class _Leaf {
  const _Leaf(this.text, this.color, this.size);
  final String text;
  final Color? color;
  final double? size;
}

Iterable<_Leaf> _leaves(InlineSpan span, TextStyle? inherited) sync* {
  if (span is TextSpan) {
    final style = inherited == null ? span.style : inherited.merge(span.style);
    final t = span.text;
    if (t != null && t.trim().isNotEmpty) yield _Leaf(t, style?.color, style?.fontSize);
    for (final c in span.children ?? const <InlineSpan>[]) {
      yield* _leaves(c, style);
    }
  }
}

class _Ctx {
  bool hidden = false;
  bool onLiveGlass = false;
  bool disabled = false;
  bool decorative = false;
  bool onSlab = false; // text on a GlassSlab sits on the slab, not directly on the ambient field (2.1.8)
  bool well = false; // a text well (wellOnGlass, 2.1.2): placeholders inside it use label2
}

_Ctx _context(Element e) {
  final c = _Ctx();
  e.visitAncestorElements((a) {
    final w = a.widget;
    if (w is Offstage && w.offstage) c.hidden = true;
    if (w is Opacity && w.opacity == 0) c.hidden = true;
    if (w is Visibility && !w.visible) c.hidden = true;
    if (w is GlassHost) c.onLiveGlass = true;
    if (w is IgnorePointer && w.ignoring) c.disabled = true;
    if (w is AbsorbPointer && w.absorbing) c.disabled = true;
    if (w is Semantics && w.properties.enabled == false) c.disabled = true;
    if (w is ExcludeSemantics && w.excluding) c.decorative = true;
    if (w.runtimeType.toString() == 'GlassSlab') c.onSlab = true;
    if (w is InputDecorator || w is EditableText) c.well = true;
    return !c.hidden;
  });
  return c;
}

String _name(String text) {
  final t = text.replaceAll('\n', ' ');
  return 'RichText "${t.length > 32 ? '${t.substring(0, 32)}…' : t}"';
}

String _hex(Color c) => '#${c.toARGB32().toRadixString(16).padLeft(8, '0')}';

List<GlassViolation> _paragraphs(WidgetTester tester, ScreenId? screen) {
  final out = <GlassViolation>[];
  final view = tester.view;
  final topBand = view.physicalSize.height / view.devicePixelRatio * 0.6;
  for (final e in find.byType(RichText).evaluate()) {
    final w = e.widget as RichText;
    final ro = e.renderObject;
    if (ro is! RenderParagraph || !ro.hasSize || ro.size.isEmpty) continue;
    final c = _context(e);
    if (c.hidden) continue;
    final leaves = _leaves(w.text, null).toList();
    // Icon glyphs are non-text (a Private Use Area code point from an icon font): 14.2 gives them the 3:1 non-text rule.
    leaves.removeWhere((l) => l.text.runes.every((r) => r >= 0xE000 && r <= 0xF8FF));
    if (leaves.isEmpty) continue;
    final scaler = w.textScaler;
    final name = _name(leaves.first.text);
    for (final l in leaves) {
      if (l.size != null && scaler.scale(l.size!) < kGlassFloorPx) {
        out.add(GlassViolation(GlassRule.g9TextSize, name, '${scaler.scale(l.size!).toStringAsFixed(1)} px < $kGlassFloorPx'));
        break;
      }
    }
    if (c.onLiveGlass && !c.well) {
      for (final l in leaves) {
        final col = l.color;
        if (col == null) continue;
        if (col.a != 1.0 || (col != GlassColors.onGlass && col != GlassColors.onTint)) {
          out.add(GlassViolation(GlassRule.g5AlphaText, name, 'colour ${_hex(col)} on live glass (want onGlass or onTint, alpha 1)'));
          break;
        }
      }
    }
    for (final l in leaves) {
      final col = l.color;
      if (col == null) continue;
      final grey = col == GlassColors.label4 || col == GlassColors.g500 || col == GlassColors.g600;
      if (grey && !c.disabled) {
        out.add(GlassViolation(GlassRule.g6Grey, name, '${_hex(col)} outside a disabled control'));
        break;
      }
    }
    if (screen != null && kGlassBrightFieldScreens.contains(screen) && !c.onLiveGlass && !c.onSlab) {
      final top = ro.localToGlobal(Offset.zero).dy;
      if (top < topBand && leaves.any((l) => l.color == GlassColors.label3)) {
        out.add(GlassViolation(GlassRule.g7Field, name, 'label3 ${_hex(GlassColors.label3)} in the top 60 % over a bright field'));
      }
    }
  }
  return out;
}

// ---- images (G10) ----

List<GlassViolation> _images(WidgetTester tester) {
  final out = <GlassViolation>[];
  for (final e in find.byType(RawImage).evaluate()) {
    final ro = e.renderObject;
    if (ro is! RenderImage || !ro.hasSize || ro.size.isEmpty || _context(e).hidden) continue;
    var ok = false;
    e.visitAncestorElements((a) {
      final w = a.widget;
      if (w is Semantics && ((w.properties.label ?? '').isNotEmpty || w.excludeSemantics)) ok = true;
      if (w is ExcludeSemantics && w.excluding) ok = true;
      if (w is Image && ((w.semanticLabel ?? '').isNotEmpty || w.excludeFromSemantics)) ok = true;
      if (w is MergeSemantics || w is BlockSemantics) ok = true;
      return !ok;
    });
    if (!ok) out.add(GlassViolation(GlassRule.g10Images, 'image ${ro.size.width.round()}x${ro.size.height.round()}', 'no semantics label and not excluded as decorative'));
  }
  return out;
}
