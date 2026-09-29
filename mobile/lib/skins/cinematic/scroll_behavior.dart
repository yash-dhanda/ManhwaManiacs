import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

/// Clamping physics with a stretch overscroll on both OSes, no scrollbar (cinematic 8.0.5, 15.3).
class CineScrollBehavior extends ScrollBehavior {
  const CineScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) =>
      StretchingOverscrollIndicator(axisDirection: details.direction, child: child);

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.invertedStylus,
      };
}
