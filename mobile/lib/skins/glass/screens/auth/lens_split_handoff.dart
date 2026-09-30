import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the Login or Register lens was when it split: the picker's orbs spring outward from [centre] (glass 4.10, Lens split).
@immutable
class GlassLensSplit {
  const GlassLensSplit({required this.centre, required this.radius});
  final Offset centre;
  final double radius;
}

/// Written by Login and Register before the guard lands on `/profiles`; the picker reads it once and clears it.
final glassLensSplitProvider = StateProvider<GlassLensSplit?>((ref) => null, name: 'glassLensSplit');
