import 'package:flutter/widgets.dart';

/// The focus node a rail hands its item, so the rail can move focus between items (`←` `→`) and keep the
/// remembered item as the rail's single tab stop (glass 7.9). The item's main control takes it.
class GlassRailItemScope extends InheritedWidget {
  const GlassRailItemScope({super.key, required this.node, required super.child});
  final FocusNode node;

  static FocusNode? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GlassRailItemScope>()?.node;

  @override
  bool updateShouldNotify(GlassRailItemScope old) => old.node != node;
}
