import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// `·` at 0.5 em intervals in `ink.30` `typeFolio`, on the baseline, between a label and its
/// value (cinematic 7.16). Decorative: excluded from semantics. It reports the folio baseline, so
/// [CineLeaderRow] (or a baseline `Row`) sets the dots on the line.
class CineDotLeader extends StatelessWidget {
  const CineDotLeader({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final style = CineText.style(context, c.typeFolio).copyWith(color: c.colorInk30);
    final scaler = CineText.scaler(context, c.typeFolio);
    final tp = TextPainter(text: TextSpan(text: '·', style: style), textDirection: TextDirection.ltr, textScaler: scaler)..layout();
    final step = (style.fontSize ?? 12) * 0.5 * scaler.scale(1);
    // No LayoutBuilder (it has no dry layout): fill the width offered (none when unbounded); the
    // empty folio-style text gives the line box and the baseline the dots sit on.
    return ExcludeSemantics(
      child: LimitedBox(
        maxWidth: 0,
        child: SizedBox(
          width: double.infinity,
          child: Stack(fit: StackFit.passthrough, children: [
            Text('', style: style, textScaler: scaler),
            Positioned.fill(child: CustomPaint(key: const Key('cine-dot-leader'), painter: _Dots(tp, step))),
          ],),
        ),
      ),
    );
  }
}

class _Dots extends CustomPainter {
  _Dots(this.tp, this.step);
  final TextPainter tp;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    for (var x = 0.0; x < size.width - tp.width; x += step + tp.width) {
      tp.paint(canvas, Offset(x, 0));
    }
  }

  @override
  bool shouldRepaint(_Dots o) => o.step != step || o.tp.text != tp.text;
}

/// Label → dot leaders → value on one baseline (cinematic 7.16). The value keeps its own width
/// (up to 70 % of the row), the label wraps only when the two cannot share the line, and the
/// leaders take exactly what is left, so every value and trailing mark ends on the row's edge.
/// The value sits on the label's last line.
///
/// A `Row` of `Flexible(label)` + `Expanded(leader)` cannot do this: flex children split the
/// free space evenly, so a short label left a gap after the value (ragged right edges) and a long
/// one wrapped at half the width.
class CineLeaderRow extends MultiChildRenderObjectWidget {
  CineLeaderRow({super.key, required Widget label, Widget? value, Widget leader = const CineDotLeader(), this.gap = 8})
      : super(children: [label, leader, if (value != null) value]);

  /// Space on each side of the leaders.
  final double gap;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderLeaderRow(gap);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) => (renderObject as _RenderLeaderRow).gap = gap;
}

class _LeaderParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderLeaderRow extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _LeaderParentData>, RenderBoxContainerDefaultsMixin<RenderBox, _LeaderParentData> {
  _RenderLeaderRow(this._gap);

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  static const _minLeader = 24.0; // at least three dots, so a leader reads as one
  static const _a = TextBaseline.alphabetic;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _LeaderParentData) child.parentData = _LeaderParentData();
  }

  List<RenderBox> get _kids => getChildrenAsList();

  /// Sizes and places the children; [dry] measures without laying out.
  Size _solve(BoxConstraints cs, {required bool dry}) {
    final kids = _kids;
    final label = kids[0], leader = kids[1];
    final value = kids.length > 2 ? kids[2] : null;
    final w = cs.maxWidth.isFinite ? cs.maxWidth : label.getMaxIntrinsicWidth(double.infinity) + _gap + _minLeader + (value?.getMaxIntrinsicWidth(double.infinity) ?? 0) + (value == null ? 0 : _gap);

    Size lay(RenderBox c, BoxConstraints k) => dry ? c.getDryLayout(k) : (c..layout(k, parentUsesSize: true)).size;
    double base(RenderBox c, BoxConstraints k, Size s) => (dry ? c.getDryBaseline(k, _a) : c.getDistanceToBaseline(_a, onlyReal: true)) ?? s.height;

    // Its own width up to half the row, more (to 70 %) rather than wrap or overflow a value.
    final vNat = value?.getMaxIntrinsicWidth(double.infinity) ?? 0;
    final vk = BoxConstraints(maxWidth: math.max(0, math.min(math.max(w / 2, vNat), w * 0.7 - 2 * _gap - _minLeader)));
    final vs = value == null ? Size.zero : lay(value, vk);
    final vRun = value == null ? 0.0 : _gap + vs.width;
    final lk = BoxConstraints(maxWidth: math.max(0, w - vRun - _gap - _minLeader));
    final ls = lay(label, lk);
    final dk = BoxConstraints.tightFor(width: math.max(0, w - ls.width - _gap - vRun));
    final ds = lay(leader, dk);

    // The label's last baseline: its first baseline plus the height wrapping added (its height
    // less its one-line height, an intrinsic: dry baselines fail on plain boxes like ColoredBox).
    final oneHeight = label.getMinIntrinsicHeight(1e5);
    final labelLast = base(label, lk, ls) + math.max(0, ls.height - oneHeight);
    final vb = value == null ? 0.0 : base(value, vk, vs);
    final db = base(leader, dk, ds);
    final line = math.max(labelLast, math.max(vb, db));
    final tops = [line - labelLast, line - db, if (value != null) line - vb];
    final sizes = [ls, ds, if (value != null) vs];
    var h = 0.0;
    for (var i = 0; i < sizes.length; i++) {
      h = math.max(h, tops[i] + sizes[i].height);
    }
    if (!dry) {
      final xs = [0.0, ls.width + _gap, if (value != null) w - vs.width];
      for (var i = 0; i < kids.length; i++) {
        (kids[i].parentData! as _LeaderParentData).offset = Offset(xs[i], tops[i]);
      }
    }
    return cs.constrain(Size(w, h));
  }

  @override
  void performLayout() => size = _solve(constraints, dry: false);

  @override
  Size computeDryLayout(BoxConstraints constraints) => _solve(constraints, dry: true);

  @override
  double computeMinIntrinsicWidth(double height) => _kids.fold(_minLeader + 2 * _gap, (s, c) => s + c.getMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) => _kids.fold(_minLeader + 2 * _gap, (s, c) => s + c.getMaxIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) => _solve(BoxConstraints(maxWidth: width), dry: true).height;

  @override
  double computeMaxIntrinsicHeight(double width) => computeMinIntrinsicHeight(width);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => defaultComputeDistanceToFirstActualBaseline(baseline);

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => defaultHitTestChildren(result, position: position);
}
