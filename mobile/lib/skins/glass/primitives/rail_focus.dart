import 'package:flutter/widgets.dart';

/// The focus node a rail hands its item, so the rail can move focus between items (`←` `→`) and keep the
/// remembered item as the rail's single tab stop (glass 7.9). The item's main control takes it.
class GlassRailItemScope extends InheritedWidget {
  const GlassRailItemScope({super.key, required this.node, required super.child, this.width});
  final FocusNode node;

  /// The rail's item slot width: a poster inside fills it (2.8 visible on phones, 1.6 from text scale 1.9).
  final double? width;

  static FocusNode? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GlassRailItemScope>()?.node;

  static double? widthOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GlassRailItemScope>()?.width;

  @override
  bool updateShouldNotify(GlassRailItemScope old) => old.node != node || old.width != width;
}
