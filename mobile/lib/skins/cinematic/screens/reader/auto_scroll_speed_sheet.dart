import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/speed_ruler.dart';

/// The chip's long-press sheet (cinematic 9.4.1): `PROJECTION SPEED`, the shared [SpeedRuler]
/// (0.50-3.00x in 0.05 steps, presets, hold to reset) and the px/s or wpm equivalent under the
/// value. [onChanged] is live while dragging, [onCommit] on release.
Future<void> showAutoScrollSpeedSheet(
  BuildContext context, {
  required double value,
  required ValueChanged<double> onChanged,
  required ValueChanged<double> onCommit,
  required String Function(double speedX) equivalent,
}) =>
    showCineSheet<void>(
      context,
      kicker: 'PROJECTION SPEED',
      title: 'Auto-scroll speed',
      builder: (sheetContext) => _Body(value: value, onChanged: onChanged, onCommit: onCommit, equivalent: equivalent),
    );

class _Body extends StatefulWidget {
  const _Body({required this.value, required this.onChanged, required this.onCommit, required this.equivalent});
  final double value;
  final ValueChanged<double> onChanged, onCommit;
  final String Function(double) equivalent;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late double _v = widget.value;

  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: SpeedRuler(
            value: _v,
            onChanged: (x) {
              setState(() => _v = x);
              widget.onChanged(x);
            },
            onCommit: (x) {
              setState(() => _v = x);
              widget.onCommit(x);
            },
            pxCaption: widget.equivalent,
          ),
        ),
      );
}
