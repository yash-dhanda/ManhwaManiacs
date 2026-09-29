import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Caps a text block at [ch] x the width of "0" in [style] (62 body, 58 dek, 48 narrow), measured
/// once. [baseline] rounds a display block's height up to the next multiple of 4 px (cinematic 2.2.1).
class CineMeasure extends StatefulWidget {
  const CineMeasure({super.key, required this.ch, required this.style, required this.child, this.baseline = false});
  final int ch;
  final TextStyle style;
  final Widget child;
  final bool baseline;

  @override
  State<CineMeasure> createState() => _CineMeasureState();
}

class _CineMeasureState extends State<CineMeasure> {
  double? _zero;
  TextStyle? _for;

  double _measure(BuildContext context) {
    if (_zero != null && _for == widget.style) return _zero!;
    final p = TextPainter(text: TextSpan(text: '0', style: widget.style), textDirection: Directionality.of(context), textScaler: MediaQuery.textScalerOf(context))..layout();
    _zero = p.width;
    _for = widget.style;
    p.dispose();
    return _zero!;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.ch * _measure(context);
    Widget child = Align(alignment: Alignment.topLeft, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: w), child: widget.child));
    if (widget.baseline) child = _Baseline4(child: child);
    return child;
  }
}

class _Baseline4 extends SingleChildRenderObjectWidget {
  const _Baseline4({required Widget child}) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBaseline4();
}

class _RenderBaseline4 extends RenderShiftedBox {
  _RenderBaseline4() : super(null);

  @override
  void performLayout() {
    final c = child!..layout(constraints.loosen(), parentUsesSize: true);
    final h = (c.size.height / 4).ceil() * 4.0;
    size = constraints.constrain(Size(c.size.width, h));
    (c.parentData! as BoxParentData).offset = Offset.zero;
  }
}
