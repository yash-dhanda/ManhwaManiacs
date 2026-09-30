import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/scrollbar.dart';

/// Bouncing physics on every platform, no glow, no stretch, the Glass scrollbar (glass 8.0.7).
class GlassScrollBehavior extends ScrollBehavior {
  const GlassScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => GlassScrollbar(controller: details.controller, child: child);

  @override
  Set<PointerDeviceKind> get dragDevices => {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.stylus, PointerDeviceKind.trackpad};
}

/// What every Glass scroll view passes: bounce, and the keyboard closes on drag.
const ScrollPhysics glassScrollPhysics = BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
const ScrollViewKeyboardDismissBehavior glassKeyboardDismiss = ScrollViewKeyboardDismissBehavior.onDrag;

/// `CustomScrollView(physics: ..., keyboardDismissBehavior: ...)` arguments in one place.
({ScrollPhysics physics, ScrollViewKeyboardDismissBehavior keyboardDismissBehavior}) glassScrollDefaults() =>
    (physics: glassScrollPhysics, keyboardDismissBehavior: glassKeyboardDismiss);
