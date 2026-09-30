// ignore_for_file: directives_ordering, require_trailing_commas, prefer_const_constructors, avoid_redundant_argument_values, unnecessary_lambdas, unnecessary_await_in_return
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// One failed rule on one screen: what was measured, on which element.
class QaViolation {
  const QaViolation(this.rule, this.finder, this.measured);
  final String rule;
  final String finder;
  final String measured;

  Map<String, String> toJson() => {'rule': rule, 'finder': finder, 'measured': measured};

  @override
  String toString() => '[$rule] $finder: $measured';
}

/// The stable rule ids `qa_accepted.dart` matches on.
abstract final class QaRule {
  static const exception = 'exception';
  static const tapTarget = 'tap-target';
  static const tapSpacing = 'tap-spacing';
  static const label = 'label';
  static const heading = 'heading';
  static const contrast = 'contrast';
  static const ink45 = 'ink45-ground';
  static const textFloor = 'text-floor';
  static const image = 'image-label';
}

const double kQaFloorPx = 11;

/// Audits what is on screen now (call after the screen settled). [platform] picks the tap-target
/// guideline: 44 pt on iOS, 48 dp on Android (cinematic 7 intro, 14.6).
Future<List<QaViolation>> auditScreen(WidgetTester tester, {required TargetPlatform platform}) async {
  final out = <QaViolation>[];
  final handle = tester.ensureSemantics();
  try {
    await tester.pump();
    final ex = tester.takeException();
    if (ex != null) out.add(QaViolation(QaRule.exception, 'pump', ex.toString().split('\n').first));

    Future<void> guide(String rule, AccessibilityGuideline g) async {
      final e = await g.evaluate(tester);
      if (e.passed) return;
      for (final line in (e.reason ?? g.description).split('\n').where((l) => l.trim().isNotEmpty)) {
        out.add(QaViolation(rule, _finderOf(line), _measuredOf(line)));
      }
    }

    await guide(QaRule.tapTarget, platform == TargetPlatform.iOS ? iOSTapTargetGuideline : androidTapTargetGuideline);
    await guide(QaRule.label, labeledTapTargetGuideline);
    await guide(QaRule.contrast, textContrastGuideline);
    out.addAll(_spacing(tester));
    out.addAll(_headings(tester));
    out.addAll(_paragraphs(tester));
    out.addAll(_images(tester));
  } finally {
    handle.dispose();
  }
  return out;
}

String _finderOf(String reason) {
  final i = reason.indexOf(': ');
  return (i > 0 ? reason.substring(0, i) : reason).trim();
}

String _measuredOf(String reason) {
  final i = reason.indexOf(': ');
  return (i > 0 ? reason.substring(i + 2) : '').trim();
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

/// At least 8 px between the rects of adjacent tappable nodes that are not ancestors of each other;
/// inline links inside running text are exempt (and reported through the `isLink` flag, not listed).
List<QaViolation> _spacing(WidgetTester tester) {
  final root = tester.binding.rootPipelineOwner.semanticsOwner?.rootSemanticsNode;
  if (root == null) return const [];
  final taps = <(SemanticsNode, Rect)>[];
  _walk(root, (n) {
    final d = n.getSemanticsData();
    if (n.isInvisible || d.flagsCollection.isHidden) return;
    if (!d.hasAction(SemanticsAction.tap)) return;
    if (d.flagsCollection.isLink) return;
    final r = _globalRect(n);
    if (r.isEmpty) return;
    taps.add((n, r));
  });
  final out = <QaViolation>[];
  for (var i = 0; i < taps.length; i++) {
    for (var j = i + 1; j < taps.length; j++) {
      final (a, ra) = taps[i];
      final (b, rb) = taps[j];
      if (_isAncestor(a, b) || _isAncestor(b, a)) continue;
      if (ra.overlaps(rb)) continue; // layered, not adjacent
      final dx = ra.left > rb.right ? ra.left - rb.right : (rb.left > ra.right ? rb.left - ra.right : 0.0);
      final dy = ra.top > rb.bottom ? ra.top - rb.bottom : (rb.top > ra.bottom ? rb.top - ra.bottom : 0.0);
      final gap = dx > 0 && dy > 0 ? (dx < dy ? dx : dy) : (dx > 0 ? dx : dy);
      // Abutting cells (gap 0) are one strip or list, and a 1 px gap is a divider rule; a dead zone
      // of 2 to 8 px between two controls is what 14.6 forbids.
      if (gap >= 2 && gap < 8) {
        out.add(QaViolation(QaRule.tapSpacing, '${_describe(a)} / ${_describe(b)}', 'gap ${gap.toStringAsFixed(1)} px < 8'));
      }
    }
  }
  return out;
}

/// Exactly one level-1 heading per screen; section heads are level 2 (checked by the screens' own tests).
List<QaViolation> _headings(WidgetTester tester) {
  final root = tester.binding.rootPipelineOwner.semanticsOwner?.rootSemanticsNode;
  if (root == null) return const [];
  final h1 = <String>[];
  _walk(root, (n) {
    final d = n.getSemanticsData();
    if (n.isInvisible || d.flagsCollection.isHidden) return;
    if (d.flagsCollection.isHeader && d.headingLevel == 1) h1.add(_describe(n));
  });
  if (h1.length == 1) return const [];
  return [QaViolation(QaRule.heading, 'semantics tree', '${h1.length} level-1 headings: ${h1.join(', ')}')];
}

// ---- paragraphs: ink.45 ground and the text floor ----

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

bool _hidden(Element e) {
  var hidden = false;
  e.visitAncestorElements((a) {
    final w = a.widget;
    if (w is Offstage && w.offstage) hidden = true;
    if (w is Opacity && w.opacity == 0) hidden = true;
    if (w is Visibility && !w.visible) hidden = true;
    return !hidden;
  });
  return hidden;
}

/// `null` when the first opaque ground found walking up is paper.0; else a reason.
String? _groundProblem(Element e) {
  String? problem;
  var decided = false;
  e.visitAncestorElements((a) {
    final w = a.widget;
    Color? c;
    if (w is ColoredBox) c = w.color;
    if (w is DecoratedBox) {
      final d = w.decoration;
      if (d is BoxDecoration) {
        if (d.image != null) {
          problem = 'over an image';
          decided = true;
          return false;
        }
        if (d.gradient != null) {
          problem = 'over a gradient';
          decided = true;
          return false;
        }
        c = d.color;
      }
    }
    if (w is Material && w.type != MaterialType.transparency) c = w.color ?? c;
    if (w is Image || w is RawImage) {
      problem = 'over an image';
      decided = true;
      return false;
    }
    if (c != null && c.a == 1.0) {
      decided = true;
      if (c != CineColors.paper0) problem = 'on #${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
      return false;
    }
    return true;
  });
  if (!decided) return null; // reaches the scaffold: paper.0 by the theme
  return problem;
}

List<QaViolation> _paragraphs(WidgetTester tester) {
  final out = <QaViolation>[];
  for (final e in find.byType(RichText).evaluate()) {
    final w = e.widget as RichText;
    final ro = e.renderObject;
    if (ro is! RenderParagraph || !ro.hasSize || ro.size.isEmpty || _hidden(e)) continue;
    final leaves = _leaves(w.text, null).toList();
    if (leaves.isEmpty) continue;
    final first = leaves.first.text.replaceAll('\n', ' ');
    final name = 'RichText "${first.length > 32 ? '${first.substring(0, 32)}…' : first}"';
    for (final l in leaves) {
      if (l.size != null && l.size! < kQaFloorPx) {
        out.add(QaViolation(QaRule.textFloor, name, '${l.size!.toStringAsFixed(1)} px < $kQaFloorPx'));
        break;
      }
    }
    if (leaves.any((l) => l.color != null && l.color!.toARGB32() == CineColors.ink45.toARGB32())) {
      final p = _groundProblem(e);
      final t45 = leaves.firstWhere((l) => l.color != null && l.color!.toARGB32() == CineColors.ink45.toARGB32()).text.replaceAll('\n', ' ');
      if (p != null) out.add(QaViolation(QaRule.ink45, 'RichText "${t45.length > 32 ? '${t45.substring(0, 32)}…' : t45}" (${t45.codeUnits.take(6).join(',')}) ${e.debugGetCreatorChain(16)}', 'ink.45 text $p'));
    }
  }
  return out;
}

// ---- images ----

List<QaViolation> _images(WidgetTester tester) {
  final out = <QaViolation>[];
  for (final e in find.byType(RawImage).evaluate()) {
    final ro = e.renderObject;
    if (ro is! RenderImage || !ro.hasSize || ro.size.isEmpty || _hidden(e)) continue;
    var ok = false;
    e.visitAncestorElements((a) {
      final w = a.widget;
      if (w is Semantics && ((w.properties.label ?? '').isNotEmpty || w.excludeSemantics)) ok = true;
      if (w is ExcludeSemantics && w.excluding) ok = true;
      if (w is Image && ((w.semanticLabel ?? '').isNotEmpty || w.excludeFromSemantics)) ok = true;
      if (w is MergeSemantics || w is BlockSemantics) ok = true;
      return !ok;
    });
    if (!ok) out.add(QaViolation(QaRule.image, 'image ${ro.size.width.round()}x${ro.size.height.round()}', 'no semantics label and not excluded as decorative'));
  }
  return out;
}
